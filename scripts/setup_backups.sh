#!/bin/bash
# Turns on Firestore backups for a project (run once, as a project owner):
#
#   PROJECT=luxelane-4e7ae ./scripts/setup_backups.sh
#
# 1. Point-in-time recovery: any minute of the last 7 days can be read back
#    (e.g. right before a bad deploy or an accidental delete).
# 2. Scheduled backups of the whole database: daily, kept 14 days, and
#    weekly (Sundays), kept 13 weeks.
#
# Safe to run again: existing settings and schedules are kept.
# Restoring is described in DEPLOY.md ("Backups and restore").
set -euo pipefail

: "${PROJECT:?Set PROJECT (Firebase project id)}"
DB='(default)'
gcloud config set project "$PROJECT" >/dev/null

if gcloud firestore databases describe --database="$DB" --format='value(pointInTimeRecoveryEnablement)' | grep -q ENABLED; then
  echo "✓ Point-in-time recovery already on"
else
  gcloud firestore databases update --database="$DB" --enable-pitr >/dev/null
  echo "✓ Point-in-time recovery on (7 days)"
fi

if gcloud firestore backups schedules list --database="$DB" --format=json | grep -q '"dailyRecurrence"'; then
  echo "✓ Daily backup already scheduled"
else
  gcloud firestore backups schedules create --database="$DB" --recurrence=daily --retention=14d >/dev/null
  echo "✓ Daily backup scheduled (kept 14 days)"
fi
if gcloud firestore backups schedules list --database="$DB" --format=json | grep -q '"weeklyRecurrence"'; then
  echo "✓ Weekly backup already scheduled"
else
  gcloud firestore backups schedules create --database="$DB" --recurrence=weekly --day-of-week=SUN --retention=13w >/dev/null
  echo "✓ Weekly backup scheduled (Sundays, kept 13 weeks)"
fi

echo
echo "Backups so far: gcloud firestore backups list --project=$PROJECT"
