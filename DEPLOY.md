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

3. Set Stripe secret in Functions config:
   ```
   firebase functions:config:set stripe.secret="sk_live_XXX" --project=luxelane-prod
   firebase functions:config:set stripe.secret="sk_test_XXX" --project=luxelane-dev
   ```

4. Set Firebase Auth custom claims via Admin SDK after first user creation

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
