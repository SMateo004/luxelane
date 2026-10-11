#!/bin/bash
# Registers the mobile apps (rider com.luxelane.rider, driver
# com.luxelane.driver; Android and iOS) in a Firebase project and writes
# their config as dart-define files for scripts/build_mobile.sh (Android)
# and scripts/build_ios.sh (iOS):
#
#   ./scripts/setup_mobile.sh                         # production
#   PROJECT=luxelane-staging ./scripts/setup_mobile.sh
#
# Writes .env.<project>.<rider|driver>.<android|ios> (git-ignored). Needs the
# Firebase CLI logged in as a project owner. Safe to re-run: existing apps are
# reused. Push on iOS also needs an APNs key uploaded in the Firebase console
# (see DEPLOY.md, "Mobile release (iOS)").
set -euo pipefail

PROJECT="${PROJECT:-luxelane-4e7ae}"
cd "$(dirname "$0")/.."
command -v firebase >/dev/null || { echo "✗ Install the Firebase CLI: npm i -g firebase-tools"; exit 1; }
command -v node >/dev/null || { echo "✗ Install Node.js 20+"; exit 1; }

setup_app() { # app package display-name
  local app="$1" package="$2" name="$3" out=".env.${PROJECT}.$1.android"
  echo "▶ $name ($package) in $PROJECT"
  local id
  id="$(firebase apps:list ANDROID --project "$PROJECT" --json | node -e "
    const a = JSON.parse(require('fs').readFileSync(0)).result || [];
    const m = a.find((x) => x.packageName === process.argv[1]);
    process.stdout.write(m ? m.appId : '');" "$package")"
  if [[ -z "$id" ]]; then
    id="$(firebase apps:create ANDROID "$name" --package-name "$package" --project "$PROJECT" --json |
      node -e "process.stdout.write(JSON.parse(require('fs').readFileSync(0)).result.appId)")"
    echo "  ✓ registered"
  else
    echo "  ✓ already registered"
  fi
  # sdkconfig returns the google-services.json content for this app.
  firebase apps:sdkconfig ANDROID "$id" --project "$PROJECT" --json | node -e "
    const r = JSON.parse(require('fs').readFileSync(0)).result;
    const raw = r.fileContents || r.sdkConfig;
    const g = typeof raw === 'string' ? JSON.parse(raw) : raw;
    const client = g.client.find((c) => c.client_info.android_client_info.package_name === process.argv[1]) || g.client[0];
    const lines = [
      '# Written by scripts/setup_mobile.sh — Firebase config for the $app Android app.',
      'FIREBASE_PROJECT_ID=' + g.project_info.project_id,
      'FIREBASE_API_KEY=' + client.api_key[0].current_key,
      'FIREBASE_APP_ID=' + client.client_info.mobilesdk_app_id,
      'FIREBASE_MESSAGING_SENDER_ID=' + g.project_info.project_number,
      'FIREBASE_STORAGE_BUCKET=' + (g.project_info.storage_bucket || ''),
    ];
    require('fs').writeFileSync(process.argv[2], lines.join('\n') + '\n');
  " "$package" "$out"
  echo "  ✓ wrote $out"
}

setup_ios() { # app bundle display-name
  local app="$1" bundle="$2" name="$3" out=".env.${PROJECT}.$1.ios"
  echo "▶ $name iOS ($bundle) in $PROJECT"
  local id
  id="$(firebase apps:list IOS --project "$PROJECT" --json | node -e "
    const a = JSON.parse(require('fs').readFileSync(0)).result || [];
    const m = a.find((x) => x.bundleId === process.argv[1]);
    process.stdout.write(m ? m.appId : '');" "$bundle")"
  if [[ -z "$id" ]]; then
    id="$(firebase apps:create IOS "$name" --bundle-id "$bundle" --project "$PROJECT" --json |
      node -e "process.stdout.write(JSON.parse(require('fs').readFileSync(0)).result.appId)")"
    echo "  ✓ registered"
  else
    echo "  ✓ already registered"
  fi
  # sdkconfig returns GoogleService-Info.plist (XML) for this app.
  firebase apps:sdkconfig IOS "$id" --project "$PROJECT" --json | node -e "
    const r = JSON.parse(require('fs').readFileSync(0)).result;
    const xml = r.fileContents || r.sdkConfig;
    const get = (k) => ((xml.match(new RegExp('<key>' + k + '</key>[^<]*<string>([^<]*)</string>')) || [])[1] || '');
    const lines = [
      '# Written by scripts/setup_mobile.sh — Firebase config for the $app iOS app.',
      'FIREBASE_PROJECT_ID=' + get('PROJECT_ID'),
      'FIREBASE_API_KEY=' + get('API_KEY'),
      'FIREBASE_APP_ID=' + get('GOOGLE_APP_ID'),
      'FIREBASE_MESSAGING_SENDER_ID=' + get('GCM_SENDER_ID'),
      'FIREBASE_STORAGE_BUCKET=' + get('STORAGE_BUCKET'),
      'FIREBASE_IOS_BUNDLE_ID=' + (get('BUNDLE_ID') || process.argv[1]),
    ];
    require('fs').writeFileSync(process.argv[2], lines.join('\n') + '\n');
  " "$bundle" "$out"
  echo "  ✓ wrote $out"
}

setup_app rider com.luxelane.rider "Luxelane"
setup_app driver com.luxelane.driver "Luxelane Chófer"
setup_ios rider com.luxelane.rider "Luxelane"
setup_ios driver com.luxelane.driver "Luxelane Chófer"

cat <<NEXT

✓ Mobile apps ready in $PROJECT. Build them with:
  APP=rider  GOOGLE_MAPS_KEY=… ./scripts/build_mobile.sh   # Android
  APP=driver GOOGLE_MAPS_KEY=… ./scripts/build_mobile.sh
  APP=rider  GOOGLE_MAPS_KEY=… ./scripts/build_ios.sh      # iOS, on a Mac
  APP=driver GOOGLE_MAPS_KEY=… ./scripts/build_ios.sh
For CI, store each file's content as a secret (see DEPLOY.md).
NEXT
