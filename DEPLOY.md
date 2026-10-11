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
   - Authentication → Email/Password + Phone + **Google** (see below)
   - Firestore → create database (production mode)
   - Cloud Functions → enable billing (Blaze plan required)
   - Cloud Messaging → enabled by default

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

### 2. Android (rider y chófer usan el mismo `applicationId`)
1. Project settings → Your apps → **Add app → Android**, package
   `com.luxelane.app`.
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
> Credentials, si la clave está restringida, añade la app Android
> `com.luxelane.app` con su SHA-1 y habilita *Maps SDK for Android*.

> Nota: la app de pasajeros y la de chóferes comparten hoy el mismo
> `applicationId` (`com.luxelane.app`). Para publicarlas como dos apps
> distintas en Google Play hará falta un ID por app (p. ej. con *flavors*)
> y registrar cada una en Firebase con sus huellas.

### 3. iOS (Bundle ID `com.luxelane.app`, iOS 14+)
1. Firebase → Project settings → **Add app → iOS**, Bundle ID
   `com.luxelane.app`. Descargar `GoogleService-Info.plist` (no hace falta
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

### Functions + Rules + Indexes
```
firebase use luxelane-prod
firebase deploy --only functions,firestore
```

### Flutter Android (prod)
The native Maps SDK reads its key from the manifest, which Gradle fills from
the `GOOGLE_MAPS_API_KEY` env var (or `MAPS_API_KEY=...` in
`android/local.properties` for local builds). Without it the map renders blank.
```
GOOGLE_MAPS_API_KEY=YOUR_KEY flutter build appbundle --release \
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
# android/local.properties must contain MAPS_API_KEY=YOUR_KEY
flutter run --dart-define=ENV=dev --dart-define=GOOGLE_MAPS_KEY=YOUR_KEY
```

---

## GitHub Secrets Required

```
FIREBASE_TOKEN          → firebase login:ci
GOOGLE_MAPS_API_KEY     → Google Cloud Console
FIREBASE_ANDROID_APP_ID → Firebase → Project settings → app Android
GOOGLE_SERVER_CLIENT_ID → OAuth "Web client" del proyecto (Google Sign-In en Android)
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
