# Deploy Guide

## Prerequisites

1. Install Firebase CLI: `npm install -g firebase-tools`
2. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. Install Flutter 3.24+
4. Stripe account with live keys

---

## First-time Setup

1. Create two Firebase projects: `luxelane-dev` and `luxelane-prod`

2. Configure Firebase per project:
   ```
   flutterfire configure --project=luxelane-dev
   flutterfire configure --project=luxelane-prod
   ```

3. Set the Stripe secret (Cloud Functions v2 uses Secret Manager, not `functions:config`):
   ```
   firebase functions:secrets:set STRIPE_SECRET_KEY --project=luxelane-4e7ae
   ```

   Flight tracking (AeroDataBox via RapidAPI). The secret must exist to deploy; set it to `none` to keep tracking off:
   ```
   firebase functions:secrets:set FLIGHT_API_KEY --project=luxelane-4e7ae
   ```

4. Grant the first admin with the Admin SDK (the app never self-promotes):
   ```
   node scripts/promote_admin.mjs
   ```

5. Enable in Firebase Console (both projects):
   - Authentication → Email/Password + Phone
   - Firestore → create database (production mode)
   - Cloud Functions → enable billing (Blaze plan required)
   - Cloud Messaging → enabled by default

---

## Deploy

### Functions + Rules + Indexes
```
firebase use luxelane-prod
firebase deploy --only functions,firestore
```

### Flutter Android (prod)
```
flutter build appbundle --release \
  --dart-define=ENV=prod \
  --dart-define=GOOGLE_MAPS_KEY=YOUR_KEY \
  --obfuscate \
  --split-debug-info=build/debug-info
```

### Flutter iOS (prod)
```
flutter build ios --release \
  --dart-define=ENV=prod \
  --dart-define=GOOGLE_MAPS_KEY=YOUR_KEY
open ios/Runner.xcworkspace   # archive from Xcode
```

### Flutter Android (dev)
```
flutter run --dart-define=ENV=dev --dart-define=GOOGLE_MAPS_KEY=YOUR_KEY
```

---

## GitHub Secrets Required

```
FIREBASE_TOKEN          → firebase login:ci
GOOGLE_MAPS_API_KEY     → Google Cloud Console
STRIPE_SECRET_KEY       → Stripe Dashboard
```

---

## Tests

```
flutter test                      # Dart unit/widget tests
(cd functions && npm test)        # Cloud Functions business rules
(cd rules-tests && npm test)      # Firestore security rules (needs Java)
```

---

## Emulator (local dev)

```
firebase emulators:start
flutter run --dart-define=ENV=dev
```

---

## Rollout

1. Internal test (5 users) → `firebase app:distribution:release`
2. Closed beta (50) → TestFlight + Play Internal
3. 10% production rollout → Play Console staged rollout
4. 100% → lift staged rollout + App Store release
