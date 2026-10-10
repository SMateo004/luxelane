#!/bin/bash
# Registers the Android apps (rider com.luxelane.rider, driver
# com.luxelane.driver) in a Firebase project and writes their config as
# dart-define files for scripts/build_mobile.sh:
#
#   ./scripts/setup_mobile.sh                         # production
#   PROJECT=luxelane-staging ./scripts/setup_mobile.sh
#
# Writes .env.<project>.rider.android and .env.<project>.driver.android
# (git-ignored). Needs the Firebase CLI logged in as a project owner. Safe to
# re-run: existing apps are reused.
#
# iOS is not covered yet: the ios/ folder still has to be created on a Mac
# (see DEPLOY.md, "Mobile apps").
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

setup_app rider com.luxelane.rider "Luxelane"
setup_app driver com.luxelane.driver "Luxelane Chófer"

cat <<NEXT

✓ Android apps ready in $PROJECT. Build them with:
  APP=rider  GOOGLE_MAPS_KEY=… ./scripts/build_mobile.sh
  APP=driver GOOGLE_MAPS_KEY=… ./scripts/build_mobile.sh
For CI, store each file's content as a secret (see DEPLOY.md).
NEXT
