#!/bin/bash
# Builds an App Store archive (IPA) on a Mac with Xcode:
#
#   APP=rider  GOOGLE_MAPS_KEY=… ./scripts/build_ios.sh
#   APP=driver GOOGLE_MAPS_KEY=… [PROJECT=luxelane-staging] ./scripts/build_ios.sh
#
# Both apps share the Runner target; this script points ios/Flutter/App.xcconfig
# at the chosen app (bundle id, name, Info-<app>.plist) and restores the rider
# default afterwards. Firebase config comes from .env.<project>.<app>.ios
# (scripts/setup_mobile.sh). GOOGLE_MAPS_KEY is the Maps SDK for iOS key.
# Signing: open ios/Runner.xcworkspace once and pick your team for the Runner
# target (automatic signing), for each bundle id.
set -euo pipefail

APP="${APP:?Set APP=rider or APP=driver}"
PROJECT="${PROJECT:-luxelane-4e7ae}"
: "${GOOGLE_MAPS_KEY:?Set GOOGLE_MAPS_KEY (Maps SDK for iOS key)}"
cd "$(dirname "$0")/.."
[[ "$(uname)" == "Darwin" ]] || { echo "✗ iOS builds need macOS with Xcode"; exit 1; }

case "$APP" in
  rider) TARGET=lib/main.dart; BUNDLE=com.luxelane.rider; NAME="Luxelane" ;;
  driver) TARGET=lib/main_driver.dart; BUNDLE=com.luxelane.driver; NAME="Luxelane Chófer" ;;
  *) echo "✗ APP must be rider or driver"; exit 1 ;;
esac
ENV_FILE=".env.${PROJECT}.${APP}.ios"
[[ -f "$ENV_FILE" ]] || { echo "✗ $ENV_FILE not found — run PROJECT=$PROJECT ./scripts/setup_mobile.sh"; exit 1; }

XC=ios/Flutter/App.xcconfig
cp "$XC" "$XC.bak"
trap 'mv "$XC.bak" "$XC"' EXIT
cat >"$XC" <<CONF
// Written by scripts/build_ios.sh for this build; restored afterwards.
LUX_APP = $APP
LUX_BUNDLE_ID = $BUNDLE
LUX_DISPLAY_NAME = $NAME
LUX_MAPS_KEY = $GOOGLE_MAPS_KEY
CONF

APP_VERSION="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "▶ Building $APP for $PROJECT ($APP_VERSION)…"
flutter build ipa --release -t "$TARGET" \
  --dart-define-from-file="$ENV_FILE" \
  --dart-define=ENV=prod \
  --dart-define=GOOGLE_MAPS_KEY="$GOOGLE_MAPS_KEY" \
  --dart-define=APP_VERSION="$APP_VERSION" \
  --obfuscate --split-debug-info="build/debug-info-ios-$APP"

echo "✓ build/ios/ipa — upload with Transporter or: xcrun altool --upload-app"
