#!/bin/bash
# Builds a release Android App Bundle for Google Play:
#
#   APP=rider  GOOGLE_MAPS_KEY=… ./scripts/build_mobile.sh
#   APP=driver GOOGLE_MAPS_KEY=… [PROJECT=luxelane-staging] ./scripts/build_mobile.sh
#
# Firebase config comes from .env.<project>.<app>.android (written by
# scripts/setup_mobile.sh). GOOGLE_MAPS_KEY is the Android Maps SDK key
# (restricted to the app's package and signing certificate). Signing uses
# android/key.properties (see android/app/build.gradle.kts).
set -euo pipefail

APP="${APP:?Set APP=rider or APP=driver}"
PROJECT="${PROJECT:-luxelane-4e7ae}"
: "${GOOGLE_MAPS_KEY:?Set GOOGLE_MAPS_KEY (Android Maps SDK key)}"
cd "$(dirname "$0")/.."

case "$APP" in
  rider) TARGET=lib/main.dart ;;
  driver) TARGET=lib/main_driver.dart ;;
  *) echo "✗ APP must be rider or driver"; exit 1 ;;
esac
ENV_FILE=".env.${PROJECT}.${APP}.android"
[[ -f "$ENV_FILE" ]] || { echo "✗ $ENV_FILE not found — run PROJECT=$PROJECT ./scripts/setup_mobile.sh"; exit 1; }
[[ -f android/key.properties ]] || echo "⚠ android/key.properties missing — the bundle will be debug-signed and Play will reject it."

APP_VERSION="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "▶ Building $APP for $PROJECT ($APP_VERSION)…"
MAPS_API_KEY="$GOOGLE_MAPS_KEY" flutter build appbundle --release \
  --flavor "$APP" -t "$TARGET" \
  --dart-define-from-file="$ENV_FILE" \
  --dart-define=ENV=prod \
  --dart-define=GOOGLE_MAPS_KEY="$GOOGLE_MAPS_KEY" \
  --dart-define=APP_VERSION="$APP_VERSION" \
  --obfuscate --split-debug-info="build/debug-info-$APP"

echo "✓ build/app/outputs/bundle/${APP}Release/app-${APP}-release.aab"
