#!/bin/bash
# Builds and deploys both web apps (rider + driver) to Firebase Hosting.
#
#   GOOGLE_MAPS_KEY=... [FCM_VAPID_KEY=...] ./scripts/deploy_web.sh
#
# The Maps key must be restricted by HTTP referrer in Google Cloud Console.
set -euo pipefail

: "${GOOGLE_MAPS_KEY:?Set GOOGLE_MAPS_KEY (restricted browser key)}"
# The commit goes into error reports (admin → Salud) to tell releases apart.
APP_VERSION="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
DEFINES=(--dart-define=ENV=prod --dart-define=GOOGLE_MAPS_KEY="$GOOGLE_MAPS_KEY" --dart-define=APP_VERSION="$APP_VERSION")
if [[ -n "${FCM_VAPID_KEY:-}" ]]; then
  DEFINES+=(--dart-define=FCM_VAPID_KEY="$FCM_VAPID_KEY")
else
  echo "⚠ FCM_VAPID_KEY not set — web push notifications will be disabled."
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
firebase deploy --only hosting

echo "✓ Deploy complete"
