#!/bin/bash
# Builds and deploys both web apps (rider + driver) to Firebase Hosting.
#
#   GOOGLE_MAPS_KEY=... [FCM_VAPID_KEY=...] ./scripts/deploy_web.sh
#   DEPLOY_ENV=staging GOOGLE_MAPS_KEY=... ./scripts/deploy_web.sh   # staging project
#
# DEPLOY_ENV=staging builds against the project in .env.staging (written by
# scripts/setup_staging.sh) and deploys to the 'staging' alias; the apps
# show a "STAGING" ribbon. Without DEPLOY_ENV it is production.
#
# The Maps key must be restricted by HTTP referrer in Google Cloud Console.
set -euo pipefail

: "${GOOGLE_MAPS_KEY:?Set GOOGLE_MAPS_KEY (restricted browser key)}"
# The commit goes into error reports (admin → Salud) to tell releases apart.
APP_VERSION="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
DEFINES=(--dart-define=ENV=prod --dart-define=GOOGLE_MAPS_KEY="$GOOGLE_MAPS_KEY" --dart-define=APP_VERSION="$APP_VERSION")
TARGET=(--project luxelane)
if [[ "${DEPLOY_ENV:-prod}" == "staging" ]]; then
  [[ -f .env.staging ]] || { echo "✗ .env.staging not found — run scripts/setup_staging.sh first"; exit 1; }
  while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    DEFINES+=(--dart-define="$key=$value")
  done < .env.staging
  TARGET=(--project staging)
  echo "▶ Staging build ($(grep '^FIREBASE_PROJECT_ID=' .env.staging | cut -d= -f2))"
elif [[ "${DEPLOY_ENV:-prod}" != "prod" ]]; then
  echo "✗ DEPLOY_ENV must be prod or staging"; exit 1
fi
if [[ -n "${FCM_VAPID_KEY:-}" ]]; then
  DEFINES+=(--dart-define=FCM_VAPID_KEY="$FCM_VAPID_KEY")
else
  echo "⚠ FCM_VAPID_KEY not set — web push notifications will be disabled."
fi
if [[ -n "${APP_CHECK_WEB_KEY:-}" ]]; then
  DEFINES+=(--dart-define=APP_CHECK_WEB_KEY="$APP_CHECK_WEB_KEY")
else
  echo "⚠ APP_CHECK_WEB_KEY not set — the web won't send App Check tokens (don't enforce App Check yet)."
fi

echo "▶ Building rider web..."
flutter build web --release "${DEFINES[@]}" --output=build/web_rider
rm -rf hosting/public && mkdir -p hosting/public
cp -r build/web_rider/. hosting/public/

echo "▶ Building driver web..."
flutter build web --release -t lib/main_driver.dart "${DEFINES[@]}" --output=build/web_driver
rm -rf hosting/driver && mkdir -p hosting/driver
cp -r build/web_driver/. hosting/driver/

echo "▶ Deploying hosting (rider + driver)..."
firebase deploy --only hosting "${TARGET[@]}"

echo "✓ Deploy complete"
