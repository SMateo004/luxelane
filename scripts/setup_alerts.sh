#!/bin/bash
# Creates Cloud Monitoring alerts for the Luxelane backend (run once per
# project, from a machine with gcloud signed in as a project owner):
#
#   PROJECT=luxelane-4e7ae ALERT_EMAIL=ops@tu-dominio.com ./scripts/setup_alerts.sh
#
# 1. Log-based metrics: ERROR entries from the Cloud Functions
#    (functions/src/logger.ts writes severity=ERROR), and each opsWatch run.
# 2. An e-mail notification channel.
# 3. Alert policies:
#    - more than 5 errors in 10 minutes;
#    - the operations monitor (opsWatch, every 5 min) silent for 20 minutes.
#      The opsWatchdog function already pushes admins when opsWatch stops;
#      this e-mail covers the case where every function is down, so nobody
#      would get a push.
#
# Safe to run again: existing metrics, channel and policies are kept.
#
# Operational alerts (bookings without a chauffeur, nobody online) don't need
# this: the opsWatch function already pushes them to admins in the app.
set -euo pipefail

: "${PROJECT:?Set PROJECT (Firebase project id)}"
: "${ALERT_EMAIL:?Set ALERT_EMAIL (who gets the alerts)}"
gcloud config set project "$PROJECT" >/dev/null

ensure_metric() { # name description filter
  if gcloud logging metrics describe "$1" >/dev/null 2>&1; then
    echo "✓ Metric $1 already exists"
  else
    gcloud logging metrics create "$1" --description="$2" --log-filter="$3"
    echo "✓ Metric $1 created"
  fi
}

METRIC=luxelane_function_errors
ensure_metric "$METRIC" "Errors logged by Luxelane Cloud Functions" \
  'resource.type="cloud_run_revision" AND severity>=ERROR'

# One entry per opsWatch run: logger.info('opsWatch', 'checked', …).
RUNS_METRIC=luxelane_opswatch_runs
ensure_metric "$RUNS_METRIC" "Runs of the Luxelane operations monitor (opsWatch)" \
  'resource.type="cloud_run_revision" AND jsonPayload.fn="opsWatch" AND jsonPayload.message="checked"'

CHANNEL="$(gcloud beta monitoring channels list \
  --filter="type=\"email\" AND labels.email_address=\"$ALERT_EMAIL\"" --format='value(name)' | head -n1)"
if [[ -z "$CHANNEL" ]]; then
  CHANNEL="$(gcloud beta monitoring channels create \
    --display-name="Luxelane ops ($ALERT_EMAIL)" --type=email \
    --channel-labels=email_address="$ALERT_EMAIL" --format='value(name)')"
  echo "✓ Notification channel created"
fi

POLICY_FILE="$(mktemp)"
trap 'rm -f "$POLICY_FILE"' EXIT

# Creates the policy in $POLICY_FILE unless one with that name exists.
ensure_policy() { # display name
  if [[ -n "$(gcloud alpha monitoring policies list --filter="displayName=\"$1\"" --format='value(name)')" ]]; then
    echo "✓ Alert policy \"$1\" already exists"
  else
    gcloud alpha monitoring policies create --policy-from-file="$POLICY_FILE" >/dev/null
    echo "✓ Alert policy \"$1\" created — it e-mails $ALERT_EMAIL"
  fi
}

cat >"$POLICY_FILE" <<JSON
{
  "displayName": "Luxelane: errores en Cloud Functions",
  "combiner": "OR",
  "conditions": [{
    "displayName": "Más de 5 errores en 10 minutos",
    "conditionThreshold": {
      "filter": "metric.type=\"logging.googleapis.com/user/$METRIC\" AND resource.type=\"cloud_run_revision\"",
      "aggregations": [{
        "alignmentPeriod": "600s",
        "perSeriesAligner": "ALIGN_SUM",
        "crossSeriesReducer": "REDUCE_SUM"
      }],
      "comparison": "COMPARISON_GT",
      "thresholdValue": 5,
      "duration": "0s",
      "trigger": { "count": 1 }
    }
  }],
  "notificationChannels": ["$CHANNEL"],
  "alertStrategy": { "autoClose": "3600s" },
  "documentation": {
    "content": "Revisa los logs de Cloud Functions (severity>=ERROR) en la consola de Google Cloud.",
    "mimeType": "text/markdown"
  }
}
JSON
ensure_policy "Luxelane: errores en Cloud Functions"

cat >"$POLICY_FILE" <<JSON
{
  "displayName": "Luxelane: el monitor de operaciones no responde",
  "combiner": "OR",
  "conditions": [{
    "displayName": "opsWatch sin ejecutarse durante 20 minutos",
    "conditionAbsent": {
      "filter": "metric.type=\"logging.googleapis.com/user/$RUNS_METRIC\" AND resource.type=\"cloud_run_revision\"",
      "aggregations": [{
        "alignmentPeriod": "300s",
        "perSeriesAligner": "ALIGN_SUM",
        "crossSeriesReducer": "REDUCE_SUM"
      }],
      "duration": "1200s",
      "trigger": { "count": 1 }
    }
  }],
  "notificationChannels": ["$CHANNEL"],
  "alertStrategy": { "autoClose": "3600s" },
  "documentation": {
    "content": "El monitor de operaciones (opsWatch) no corrió en 20 minutos: no llegan avisos de reservas sin chófer ni de solicitudes urgentes. Revisa en la consola de Firebase → Functions que opsWatch esté activa y sus logs, y vigila Admin → Reservas a mano mientras tanto (docs/PROTOCOLO_INCIDENTES.md, §4.9).",
    "mimeType": "text/markdown"
  }
}
JSON
ensure_policy "Luxelane: el monitor de operaciones no responde"
