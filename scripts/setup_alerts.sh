#!/bin/bash
# Creates Cloud Monitoring alerts for the Luxelane backend (run once per
# project, from a machine with gcloud signed in as a project owner):
#
#   PROJECT=luxelane-4e7ae ALERT_EMAIL=ops@tu-dominio.com ./scripts/setup_alerts.sh
#
# 1. A log-based metric counting ERROR entries from the Cloud Functions
#    (functions/src/logger.ts writes severity=ERROR).
# 2. An e-mail notification channel.
# 3. An alert policy: more than 5 errors in 10 minutes.
#
# Operational alerts (bookings without a chauffeur, nobody online) don't need
# this: the opsWatch function already pushes them to admins in the app.
set -euo pipefail

: "${PROJECT:?Set PROJECT (Firebase project id)}"
: "${ALERT_EMAIL:?Set ALERT_EMAIL (who gets the alerts)}"
gcloud config set project "$PROJECT" >/dev/null

METRIC=luxelane_function_errors
if gcloud logging metrics describe "$METRIC" >/dev/null 2>&1; then
  echo "✓ Metric $METRIC already exists"
else
  gcloud logging metrics create "$METRIC" \
    --description="Errors logged by Luxelane Cloud Functions" \
    --log-filter='resource.type="cloud_run_revision" AND severity>=ERROR'
  echo "✓ Metric $METRIC created"
fi

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
gcloud alpha monitoring policies create --policy-from-file="$POLICY_FILE"
echo "✓ Alert policy created — errors will e-mail $ALERT_EMAIL"
