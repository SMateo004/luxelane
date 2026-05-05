#!/bin/bash
set -e
echo "▶ Building Flutter web..."
flutter build web --release --dart-define=GOOGLE_MAPS_KEY=placeholder

echo "▶ Syncing build/web → hosting/public..."
cp -r build/web/. hosting/public/

echo "▶ Deploying to Firebase Hosting (rider)..."
firebase deploy --only hosting:rider

echo "✓ Deploy complete → https://luxelane-4e7ae.web.app"
