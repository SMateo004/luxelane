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

4. Grant the first admin with the Admin SDK (the app never self-promotes).
   Register that account in the app first:
   ```
   PROJECT=luxelane-4e7ae EMAIL=you@example.com node scripts/promote_admin.mjs
   ```

5. Enable in Firebase Console (both projects):
   - Authentication → Email/Password + Phone + **Google** (see below)
   - Firestore → create database (production mode)
   - Cloud Functions → enable billing (Blaze plan required)
   - Cloud Messaging → enabled by default
   - Storage → enable it (Build → Storage → Get started). Chauffeur
     verification documents are stored there under `driver_documents/`.

6. **Primer administrador.** Las reglas de Firestore no permiten que nadie se
   asigne `admin` (ni `driver`) desde la app: todo registro nace como `rider`.
   Para el primer admin: registrarse normalmente y, en Firestore Console →
   `users/{uid}`, cambiar `role` a `admin`. A partir de ahí, ese admin
   asigna roles desde el panel `/admin`.

---

## Inicio de sesión con Google

El botón "Continuar con Google" está en login, registro y en el diálogo de
acceso al confirmar una reserva. En web usa el popup de Firebase; en
Android/iOS, el selector nativo de cuentas (`google_sign_in`). La primera vez
crea el perfil en `users/{uid}` con rol `rider`.

### 1. Firebase Console (proyecto `luxelane-4e7ae`)
1. Authentication → Sign-in method → **Google** → Habilitar → correo de soporte → Guardar.
2. Authentication → Settings → **Authorized domains**: deben estar los dominios
   de los dos sitios de Hosting (`.firebaserc`):
   - Pasajeros (`rider` → sitio `luxelane-4e7ae`): `luxelane-4e7ae.web.app` y
     `luxelane-4e7ae.firebaseapp.com` (Firebase los autoriza por defecto).
   - Chóferes (`driver` → sitio `luxelane-driver`): **añadir**
     `luxelane-driver.web.app` y `luxelane-driver.firebaseapp.com`.
   - Cualquier dominio propio conectado en Hosting. `localhost` ya viene incluido.

Con eso **la web ya funciona**; no requiere más configuración.

### 2. Android (dos apps: `com.luxelane.rider` y `com.luxelane.driver`)
1. Project settings → Your apps → **Add app → Android**, una por paquete:
   `com.luxelane.rider` y `com.luxelane.driver` (`scripts/setup_mobile.sh`
   las registra).
2. Añadir las huellas **SHA-1 y SHA-256** de cada firma que usarás:
   - debug: `cd android && ./gradlew signingReport`
   - release/Play: Play Console → Integridad de la app → certificado de firma.
3. Copiar el **App ID** (`1:51157842817:android:...`).
4. Google Cloud Console → APIs & Services → Credentials → copiar el
   **Client ID** de "Web client (auto created by Google Service)".
5. GitHub → Settings → Secrets → Actions:
   ```
   FIREBASE_ANDROID_APP_ID   → App ID del paso 3
   GOOGLE_SERVER_CLIENT_ID   → Client ID web del paso 4
   ```
   En local:
   ```
   flutter run --dart-define=FIREBASE_ANDROID_APP_ID=... \
               --dart-define=GOOGLE_SERVER_CLIENT_ID=...
   ```

> Google Maps en Android: la clave va en el manifiesto vía
> `android/app/build.gradle.kts` (variable de entorno `GOOGLE_MAPS_API_KEY`,
> que el CI toma del secret del mismo nombre). En Google Cloud Console →
> Credentials, si la clave está restringida, añade las apps Android
> `com.luxelane.rider` y `com.luxelane.driver` con su SHA-1 y habilita *Maps SDK for Android*.

### 3. iOS (Bundle IDs `com.luxelane.rider` y `com.luxelane.driver`, iOS 14+)
1. Firebase → Project settings → **Add app → iOS**, una por Bundle ID
   (`scripts/setup_mobile.sh` las registra). Descargar `GoogleService-Info.plist` (no hace falta
   añadirlo al proyecto; solo se leen dos valores de él).
2. En `ios/Flutter/Luxelane.xcconfig` reemplazar:
   - `GOOGLE_IOS_CLIENT_ID` → `CLIENT_ID` del plist.
   - `GOOGLE_REVERSED_CLIENT_ID` → `REVERSED_CLIENT_ID` del plist.
   No son secretos (viajan dentro de la app); se pueden commitear.
3. GitHub → Secrets → `FIREBASE_IOS_APP_ID` → `GOOGLE_APP_ID` del plist
   (`1:51157842817:ios:...`). En local:
   `flutter run --dart-define=FIREBASE_IOS_APP_ID=...`
4. Compilar/firmar: en una Mac con Xcode, `open ios/Runner.xcworkspace`,
   elegir el Team en *Signing & Capabilities* y, para notificaciones push,
   añadir la capability **Push Notifications** y la clave APNs en Firebase
   → Cloud Messaging.

---

## Deploy

### Functions + Rules + Indexes + Storage rules
```
firebase use luxelane-prod
firebase deploy --only functions,firestore,storage
```
Storage rules read the admin role from Firestore (cross-service rules); the
first deploy asks to grant that permission — accept it.

### Flutter Android (prod)
See **Mobile release (Android)** below:
```
APP=rider  GOOGLE_MAPS_KEY=… ./scripts/build_mobile.sh
APP=driver GOOGLE_MAPS_KEY=… ./scripts/build_mobile.sh
```
The native Maps SDK reads its key from the manifest, which Gradle fills from
`-PMAPS_API_KEY=…`, the `MAPS_API_KEY` or `GOOGLE_MAPS_API_KEY` env var, or
`MAPS_API_KEY=...` in `android/local.properties`.

### Flutter iOS (prod)
See **Mobile release (iOS)** below (needs a Mac with Xcode):
```
APP=rider  GOOGLE_MAPS_KEY=… ./scripts/build_ios.sh
APP=driver GOOGLE_MAPS_KEY=… ./scripts/build_ios.sh
```

### Flutter Android (dev)
```
# android/local.properties must contain MAPS_API_KEY=YOUR_KEY
flutter run --dart-define=ENV=dev --dart-define=GOOGLE_MAPS_KEY=YOUR_KEY
```

---

## GitHub Secrets Required

```
GCP_SA_KEY                   → service-account JSON for deploys (replaces FIREBASE_TOKEN)
GOOGLE_MAPS_API_KEY          → Google Cloud Console (web key)
GOOGLE_MAPS_ANDROID_KEY      → Google Cloud Console (Android key)
FIREBASE_RIDER_ANDROID_ENV   → content of .env.luxelane-4e7ae.rider.android
FIREBASE_DRIVER_ANDROID_ENV  → content of .env.luxelane-4e7ae.driver.android
FIREBASE_ANDROID_APP_ID      → Firebase → Project settings → app Android
FIREBASE_IOS_APP_ID          → GOOGLE_APP_ID of GoogleService-Info.plist
GOOGLE_SERVER_CLIENT_ID      → OAuth "Web client" del proyecto (Google Sign-In en Android)
GOOGLE_IOS_CLIENT_ID         → CLIENT_ID of GoogleService-Info.plist
FCM_VAPID_KEY                → Firebase Console → Cloud Messaging (web push)
APP_CHECK_WEB_KEY            → reCAPTCHA Enterprise site key (App Check, web)
```
`STRIPE_SECRET_KEY` and `FLIGHT_API_KEY` live in Secret Manager (step 3), not
in GitHub. The Android jobs warn when a `FIREBASE_*_ANDROID_ENV` secret is
missing; that bundle then depends on `FIREBASE_ANDROID_APP_ID`.

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

1. **Firebase for Android:** the apps read their Firebase config at build
   time (dart-defines, `lib/core/config/firebase_env.dart`); without it they
   show "No pudimos iniciar Luxelane" instead of starting. Register both
   apps and write their config once per project:
   ```
   ./scripts/setup_mobile.sh                          # production
   PROJECT=luxelane-staging ./scripts/setup_mobile.sh # staging, optional
   ```
   It creates `.env.<project>.rider.android` and `.env.<project>.driver.android`
   (git-ignored). For CI, paste their content into the
   `FIREBASE_RIDER_ANDROID_ENV` / `FIREBASE_DRIVER_ANDROID_ENV` secrets.
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
4. **Build** (signed with `android/key.properties`, obfuscated, tagged with the commit):
   ```
   APP=rider  GOOGLE_MAPS_KEY=$ANDROID_KEY ./scripts/build_mobile.sh
   APP=driver GOOGLE_MAPS_KEY=$ANDROID_KEY ./scripts/build_mobile.sh
   ```
   Add `PROJECT=luxelane-staging` for a staging build (it shows the STAGING ribbon).
5. **Play Console:**
   - Privacy policy URL: `https://<tu-dominio>/privacidad`
   - Account deletion URL: `https://<tu-dominio>/eliminar-cuenta`
   - Data safety: location (driver: while on duty, foreground service), name, email, phone, app activity.
   - Driver app: declare the *location* foreground service with a short video of the "Disponible" toggle.

## Mobile release (iOS)

`ios/` holds one Runner target for both apps. `ios/Flutter/App.xcconfig` picks
the app — bundle id (`com.luxelane.rider` / `com.luxelane.driver`), display name
and `Runner/Info-<app>.plist` (location texts; the driver plist adds the
background `location` mode) — and `scripts/build_ios.sh` rewrites it per build.
The committed default is the rider app, so opening Xcode just works.

1. **Apple Developer account** (USD 99/year) and both bundle ids registered
   with the **Push Notifications** capability.
2. **Firebase:** `./scripts/setup_mobile.sh` also registers the iOS apps and
   writes `.env.<project>.<app>.ios`. In Firebase Console → Project settings →
   Cloud Messaging, upload an **APNs authentication key** (.p8) — without it
   iOS gets no push.
3. **Maps:** a Maps SDK for iOS key restricted to both bundle ids.
4. **Signing (once):** `open ios/Runner.xcworkspace`, select Runner → Signing &
   Capabilities, choose your team (automatic signing). Do it once with the
   rider default and once after `APP=driver` (or set both profiles).
5. **Build and upload:**
   ```
   APP=rider  GOOGLE_MAPS_KEY=$IOS_KEY ./scripts/build_ios.sh
   APP=driver GOOGLE_MAPS_KEY=$IOS_KEY ./scripts/build_ios.sh
   ```
   Upload `build/ios/ipa/*.ipa` with Transporter, test on TestFlight, then
   fill the listing from `docs/APP_STORE.md`.

The first build runs `pod install` (iOS 13+, set in `ios/Podfile`).

## Versions, forced updates and maintenance

- **Build number:** every store upload needs a higher `+N` in `pubspec.yaml`
  (`version: 1.0.0+N`). The build scripts and the CI pass it to the app
  (`LUX_BUILD`).
- **Forced update:** Admin → Ajustes → *Versión mínima de las apps*. A build
  below the minimum shows "Actualiza Luxelane" with a link to Google Play (or
  to the App Store page, once you paste its link there) and can't be used.
  Raise it only after the new build is live in both stores, and only when a
  server change breaks old versions. Debug and web builds are never blocked.
- **Maintenance mode** (Admin → Ajustes) pauses new bookings: the server
  refuses quotes and bookings, and riders see a notice on the app and the web.
  Rides already booked or in progress carry on. It asks for confirmation.

## App Check (only the real apps can call the server)

The apps send a Firebase App Check token with every call: Play Integrity on
Android, App Attest on iOS (DeviceCheck before iOS 14), reCAPTCHA Enterprise
on the web. The server (`functions/src/app_check.ts`) starts in **monitor
mode**: calls without a token still work and are logged as
`appcheck/missing`.

1. Firebase Console → App Check: register the two Android apps (Play
   Integrity, with the SHA-256 of the **Play app signing** key), the two iOS
   apps (App Attest, plus DeviceCheck with a DeviceCheck .p8 key from Apple) and the web
   app (create a reCAPTCHA Enterprise key for your domains). Put the web key
   in `APP_CHECK_WEB_KEY` (GitHub secret, or the env var for
   `scripts/deploy_web.sh`).
2. Debug builds use the debug provider: run the app, copy the debug token it
   prints and add it under App Check → Manage debug tokens.
3. Once the new builds are in use, check the logs:
   `gcloud logging read 'jsonPayload.message="appcheck/missing"' --freshness=7d --limit=50`.
   When only old app versions show up (raise the minimum version if needed),
   create `functions/.env` with `APP_CHECK_ENFORCE=true` and run
   `firebase deploy --only functions`. Calls without a token then fail.
4. Optionally enforce App Check for Firestore and Storage in the console
   (same order: watch its metrics first).

`reportClientError` stays open so error reports arrive even when App Check
is the problem; it is capped per day.

## Backups and restore

Run once per project (production first):
```
PROJECT=luxelane-4e7ae ./scripts/setup_backups.sh
```
It turns on **point-in-time recovery** (any minute of the last 7 days) and
schedules **daily backups kept 14 days** and **weekly backups kept 13 weeks**.
Driver documents in Storage are covered by Cloud Storage soft delete (7 days
by default).

Restore never overwrites the live database: it goes to a new database you
inspect first, then copy what you need back.
```
gcloud firestore backups list --project=luxelane-4e7ae
gcloud firestore databases restore --project=luxelane-4e7ae \
  --source-backup=projects/luxelane-4e7ae/locations/<loc>/backups/<id> \
  --destination-database=restore-<fecha>
```
For a moment in the last 7 days (e.g. just before a bad deploy), export that
snapshot and import the collections you need:
```
gcloud firestore export gs://<bucket>/pitr-<fecha> --snapshot-time=2026-10-17T14:00:00Z --project=luxelane-4e7ae
```

## Before launch: content you must provide

- `lib/core/config/legal.dart`: company name, NIT, address, support email and WhatsApp, record retention. The legal pages show a *borrador* banner until every placeholder is filled.
- Lawyer review of `lib/features/legal/presentation/pages/legal_content.dart`, including the bracketed decisions: late cancellation, extra waiting time and liability.


---

## Observability

- **Admin → Salud**: summary written every 5 minutes by `opsWatch`
  (chauffeurs online, bookings in the next 2 h, unassigned pickups,
  open safety reports, web errors). If it says the monitor stopped, the
  Cloud Functions are not deployed or the scheduler is off.
- **Operational alerts** (push to every admin): a booking still without a
  chauffeur 30 minutes before pickup, and no verified chauffeur online
  while bookings are coming up (at most hourly).
- **Web errors**: the web app reports uncaught errors to
  `reportClientError`, grouped in `clientErrors` (Crashlytics covers
  Android/iOS only). Deploys tag them with the commit (`APP_VERSION`).
- **Backend error alerts by e-mail** (run once per project):
  ```
  PROJECT=luxelane-4e7ae ALERT_EMAIL=ops@your-domain ./scripts/setup_alerts.sh
  ```
  Creates log-based metrics and two alert policies: > 5 errors in 10
  minutes, and the operations monitor (`opsWatch`) silent for 20 minutes.
  Safe to run again (existing ones are kept); re-run it after this update
  to add the second policy.
- **Monitor watchdog**: `opsWatchdog` runs every 10 minutes on its own
  schedule. If `opsWatch` hasn't written `system/health` for 15 minutes it
  pushes every admin (at most hourly) and again when it recovers. The
  e-mail policy above covers the case where all functions are down.

## Environments (staging / production)

Production is `luxelane-4e7ae` (alias `luxelane`). A staging project lets
you try changes without touching real bookings. Builds choose the project at
build time: the generated `firebase_options*.dart` are production, and
dart-defines (`FIREBASE_PROJECT_ID`, `FIREBASE_API_KEY`, `FIREBASE_APP_ID`,
`FIREBASE_MESSAGING_SENDER_ID`, …, see `lib/core/config/firebase_env.dart`)
point a build at any other project. Non-production builds show a red
**STAGING** ribbon on every screen.

**Create it once** (Firebase CLI logged in, gcloud signed in as the owner):
```
PROJECT=luxelane-staging ./scripts/setup_staging.sh
```
It creates the project, waits for you to link billing (Blaze) and to turn
on Email/Password sign-in and Storage in the console, enables the APIs,
creates Firestore (`FIRESTORE_LOCATION`, default `nam5` — use production's),
registers a web app and writes its config to `.env.staging` (git-ignored),
creates the driver hosting site, adds the `staging` alias and hosting
targets to `.firebaserc`, sets the function secrets (flight tracking off
unless `FLIGHT_API_KEY` is given) and deploys rules, indexes and functions.
Safe to re-run. It ends with the next steps: deploy the web apps, promote
an admin and configure pricing.

**Day to day**
```
firebase deploy -P staging --only functions,firestore,storage   # backend
DEPLOY_ENV=staging GOOGLE_MAPS_KEY=… ./scripts/deploy_web.sh    # web apps
```
Check it there, then deploy the same commit to production (`-P luxelane`,
and `deploy_web.sh` without `DEPLOY_ENV`).
