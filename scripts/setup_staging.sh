#!/bin/bash
# Creates and configures the Luxelane staging project, so changes can be
# tested without touching real bookings. Run once, from a machine with the
# Firebase CLI (`firebase login`) and gcloud signed in as the account that
# owns the production project:
#
#   PROJECT=luxelane-staging ./scripts/setup_staging.sh
#
# Optional: FIRESTORE_LOCATION (default nam5 — use the same as production),
#           FLIGHT_API_KEY (AeroDataBox; without it flight tracking is off).
#
# Safe to run again: every step checks what already exists. Two things can
# only be done in the console and the script stops to ask for them: linking
# a billing account (Blaze plan, needed for Cloud Functions) and turning on
# e-mail/password sign-in and Storage.
set -euo pipefail

PROJECT="${PROJECT:-luxelane-staging}"
FIRESTORE_LOCATION="${FIRESTORE_LOCATION:-nam5}"
DRIVER_SITE="${PROJECT}-driver"
ENV_FILE=".env.staging"
cd "$(dirname "$0")/.."

need() { command -v "$1" >/dev/null || { echo "✗ Missing '$1'. $2"; exit 1; }; }
need firebase "Install it with: npm i -g firebase-tools"
need gcloud "Install the Google Cloud CLI: https://cloud.google.com/sdk"
need node "Install Node.js 20+"

pause() { read -r -p "  $1 — press Enter when done… " _; }

echo "▶ 1/8 Project $PROJECT"
if firebase projects:list --json | node -e "process.exit(JSON.parse(require('fs').readFileSync(0)).result.some(p=>p.projectId===process.argv[1])?0:1)" "$PROJECT"; then
  echo "  ✓ already exists"
else
  firebase projects:create "$PROJECT" --display-name "Luxelane Staging"
fi
gcloud config set project "$PROJECT" >/dev/null

echo "▶ 2/8 Billing (Blaze plan)"
until [[ "$(gcloud beta billing projects describe "$PROJECT" --format='value(billingEnabled)' 2>/dev/null)" == "True" ]]; do
  echo "  Link a billing account: https://console.firebase.google.com/project/$PROJECT/usage/details"
  pause "Upgrade $PROJECT to the Blaze plan"
done
echo "  ✓ billing enabled"

echo "▶ 3/8 APIs"
gcloud services enable firestore.googleapis.com cloudfunctions.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com run.googleapis.com eventarc.googleapis.com cloudscheduler.googleapis.com \
  secretmanager.googleapis.com pubsub.googleapis.com storage.googleapis.com identitytoolkit.googleapis.com \
  firebasehosting.googleapis.com fcm.googleapis.com
echo "  ✓ enabled"

echo "▶ 4/8 Firestore ($FIRESTORE_LOCATION)"
if gcloud firestore databases describe --database='(default)' >/dev/null 2>&1; then
  echo "  ✓ already exists"
else
  gcloud firestore databases create --location="$FIRESTORE_LOCATION"
fi

echo "▶ 5/8 Sign-in and Storage (console)"
echo "  • Authentication → Sign-in method → enable Email/Password:"
echo "    https://console.firebase.google.com/project/$PROJECT/authentication/providers"
echo "  • Storage → Get started (same location as Firestore):"
echo "    https://console.firebase.google.com/project/$PROJECT/storage"
pause "Enable both"

echo "▶ 6/8 Web app and $ENV_FILE"
APP_ID="$(firebase apps:list WEB --project "$PROJECT" --json | node -e "const a=JSON.parse(require('fs').readFileSync(0)).result||[];const w=a.find(x=>x.displayName==='Luxelane Staging Web');process.stdout.write(w?w.appId:'')")"
if [[ -z "$APP_ID" ]]; then
  APP_ID="$(firebase apps:create WEB "Luxelane Staging Web" --project "$PROJECT" --json | node -e "process.stdout.write(JSON.parse(require('fs').readFileSync(0)).result.appId)")"
fi
firebase apps:sdkconfig WEB "$APP_ID" --project "$PROJECT" --json | node -e "
  const r = JSON.parse(require('fs').readFileSync(0)).result;
  const c = r.sdkConfig || r;
  const lines = [
    '# Written by scripts/setup_staging.sh — dart-defines for staging builds.',
    'FIREBASE_PROJECT_ID=' + c.projectId,
    'FIREBASE_API_KEY=' + c.apiKey,
    'FIREBASE_APP_ID=' + c.appId,
    'FIREBASE_MESSAGING_SENDER_ID=' + c.messagingSenderId,
    'FIREBASE_AUTH_DOMAIN=' + c.authDomain,
    'FIREBASE_STORAGE_BUCKET=' + (c.storageBucket || ''),
  ];
  require('fs').writeFileSync('$ENV_FILE', lines.join('\n') + '\n');
"
echo "  ✓ wrote $ENV_FILE (git-ignored)"

echo "▶ 7/8 Hosting sites and the 'staging' alias"
if ! firebase hosting:sites:list --project "$PROJECT" --json | grep -q "\"sites/$DRIVER_SITE\""; then
  firebase hosting:sites:create "$DRIVER_SITE" --project "$PROJECT"
fi
node -e "
  const fs = require('fs');
  const rc = JSON.parse(fs.readFileSync('.firebaserc', 'utf8'));
  rc.projects = { ...rc.projects, staging: '$PROJECT' };
  rc.targets = rc.targets || {};
  rc.targets['$PROJECT'] = { hosting: { rider: ['$PROJECT'], driver: ['$DRIVER_SITE'] } };
  fs.writeFileSync('.firebaserc', JSON.stringify(rc, null, 2) + '\n');
"
echo "  ✓ .firebaserc: alias 'staging', hosting targets rider/driver"

echo "▶ 8/8 Secrets and backend deploy"
set_secret() { # name value
  if firebase functions:secrets:access "$1" --project "$PROJECT" >/dev/null 2>&1; then
    echo "  ✓ secret $1 already set"
  else
    printf '%s' "$2" | firebase functions:secrets:set "$1" --data-file=- --project "$PROJECT" --force
  fi
}
# Luxelane doesn't charge cards; the Stripe secret only has to exist.
set_secret STRIPE_SECRET_KEY "not-used-in-staging"
set_secret FLIGHT_API_KEY "${FLIGHT_API_KEY:-none}"  # "none" = flight tracking off
firebase deploy --project "$PROJECT" --only firestore,storage,functions

cat <<NEXT

✓ Staging is ready: $PROJECT

Next:
  1. Web apps (they show a red "STAGING" ribbon):
       DEPLOY_ENV=staging GOOGLE_MAPS_KEY=… ./scripts/deploy_web.sh
     Add https://$PROJECT.web.app/* and https://$DRIVER_SITE.web.app/* to the
     Maps key's allowed referrers.
  2. Register on https://$PROJECT.web.app, then make that account admin:
       PROJECT=$PROJECT EMAIL=you@example.com node scripts/promote_admin.mjs
  3. Configure it like production from Admin (pricing, commission…).
  4. Optional e-mail alerts:
       PROJECT=$PROJECT ALERT_EMAIL=… ./scripts/setup_alerts.sh
  Deploy changes to staging first:  firebase deploy -P staging
NEXT
