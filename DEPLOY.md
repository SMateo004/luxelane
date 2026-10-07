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


---

## Mobile release (Android)

Two apps share this codebase via product flavors (`android/app/build.gradle.kts`):

| App | Flavor | Entry point | Application ID |
|---|---|---|---|
| Pasajero | `rider` | `lib/main.dart` | `com.luxelane.rider` |
| Chófer | `driver` | `lib/main_driver.dart` | `com.luxelane.driver` |

> ⚠ Application IDs can't change after the first Play Store upload. Confirm them before publishing.

1. **Firebase for Android:** today Firebase is configured for **web only**, so the Android apps crash on start until this step is done.
   ```
   flutterfire configure --project=luxelane-4e7ae --platforms=android,web \
     --android-package-name=com.luxelane.rider \
     --android-out=android/app/src/rider/google-services.json
   flutterfire configure --project=luxelane-4e7ae --platforms=android,web \
     --android-package-name=com.luxelane.driver \
     --out=lib/firebase_options_driver.dart \
     --android-out=android/app/src/driver/google-services.json
   ```
2. **Upload key:** create an upload keystore, then `android/key.properties`:
   ```
   keytool -genkey -v -keystore ~/luxelane-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   ```
   storeFile=/home/you/luxelane-upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```
3. **Maps key for Android:** an Android-restricted key (package name + SHA-1), passed at build time.
4. **Build:**
   ```
   flutter build appbundle --release --flavor rider  -t lib/main.dart \
     --dart-define=ENV=prod --dart-define=GOOGLE_MAPS_KEY=$WEB_KEY -PMAPS_API_KEY=$ANDROID_KEY
   flutter build appbundle --release --flavor driver -t lib/main_driver.dart \
     --dart-define=ENV=prod --dart-define=GOOGLE_MAPS_KEY=$WEB_KEY -PMAPS_API_KEY=$ANDROID_KEY
   ```
   (If your Flutter version doesn't forward `-P`, export `MAPS_API_KEY=$ANDROID_KEY` instead.)
5. **Play Console:**
   - Privacy policy URL: `https://<tu-dominio>/privacidad`
   - Account deletion URL: `https://<tu-dominio>/eliminar-cuenta`
   - Data safety: location (driver: while on duty, foreground service), name, email, phone, app activity.
   - Driver app: declare the *location* foreground service with a short video of the "Disponible" toggle.

iOS: there is no `ios/` folder yet. Create it with `flutter create --platforms=ios .`, then add location usage strings (`NSLocationWhenInUseUsageDescription`, plus background `location` mode for the driver target) before configuring Firebase for iOS.

## Before launch: content you must provide

- `lib/core/config/legal.dart`: company name, NIT, address, support email and WhatsApp, record retention. The legal pages show a *borrador* banner until every placeholder is filled.
- Lawyer review of `lib/features/legal/presentation/pages/legal_content.dart`, including the bracketed decisions: late cancellation, extra waiting time and liability.
