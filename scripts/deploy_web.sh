#!/bin/bash
set -e
echo "▶ Building Flutter web..."
# Keys come from env.local.json (see env.example.json); no key is built in.
if [ ! -f env.local.json ]; then
  echo "✗ Missing env.local.json (copy env.example.json and add the web Maps key)." >&2
  exit 1
fi
flutter build web --release --dart-define-from-file=env.local.json

echo "▶ Syncing build/web → hosting/public..."
cp -r build/web/. hosting/public/

echo "▶ Deploying to Firebase Hosting (rider)..."
firebase deploy --only hosting:rider

echo "✓ Deploy complete → https://luxelane-4e7ae.web.app"
