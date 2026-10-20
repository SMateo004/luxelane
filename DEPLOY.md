# Deploy Guide

## Prerequisites

1. Install Firebase CLI: `npm install -g firebase-tools`
2. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. Install Flutter 3.24+
4. Stripe account with live keys

---

## Entornos

| Alias (`.firebaserc`) | Proyecto | Uso |
|---|---|---|
| `staging` | `REEMPLAZAR_PROYECTO_STAGING` (por crear) | Pruebas previas, claves de prueba de Stripe |
| `production` | `luxelane-4e7ae` | Usuarios reales |

La app elige el proyecto al compilar con `--dart-define=FIREBASE_ENV=staging`
o `--dart-define=FIREBASE_ENV=production`. **Sin FIREBASE_ENV compila para
staging; nunca para producción por omisión.**

## First-time Setup

1. Crear el proyecto de staging en Firebase Console (plan Blaze) y ponerlo en
   `.firebaserc` en lugar de `REEMPLAZAR_PROYECTO_STAGING`.

2. Registrar la app web en staging y copiar sus valores (apiKey, appId,
   messagingSenderId, projectId) a las constantes `_staging*` y
   `stagingWeb` de `lib/firebase_options.dart`. Las apps Android/iOS de
   cada proyecto reciben su App ID con `--dart-define` (más abajo).

3. Clave secreta de Stripe en Secret Manager, una por proyecto (la CLI pide
   el valor; nunca se escribe en un archivo):
   ```
   firebase functions:secrets:set STRIPE_SECRET_KEY --project staging      # clave de prueba
   firebase functions:secrets:set STRIPE_SECRET_KEY --project production   # clave real
   ```
   Si el secreto falta, las funciones de pago fallan con un error claro y el
   CI no despliega.

4. Enable in Firebase Console (both projects):
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
3. Copiar el **App ID** (`1:51157842817:android:...`) y la **clave de API
   de la app Android** (ver «Claves de Firebase de las apps nativas»).
4. Google Cloud Console → APIs & Services → Credentials → copiar el
   **Client ID** de "Web client (auto created by Google Service)".
5. GitHub → Settings → Secrets → Actions:
   ```
   FIREBASE_ANDROID_APP_ID   → App ID del paso 3
   FIREBASE_ANDROID_API_KEY  → clave de API de la app Android del paso 3
   GOOGLE_SERVER_CLIENT_ID   → Client ID web del paso 4
   ```
   En local:
   ```
   flutter run --dart-define=FIREBASE_ANDROID_APP_ID=... \
               --dart-define=FIREBASE_ANDROID_API_KEY=... \
               --dart-define=GOOGLE_SERVER_CLIENT_ID=...
   ```

> Google Maps en Android: la clave va en el manifiesto vía
> `android/app/build.gradle.kts` (variable de entorno `GOOGLE_MAPS_API_KEY`,
> que el CI toma del secreto `GOOGLE_MAPS_ANDROID_API_KEY`). Ver «Claves de
> Google Maps».

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
   La clave de Maps de iOS no va aquí sino en `ios/Flutter/Secrets.xcconfig`
   (ver «Claves de Google Maps»).
3. GitHub → Secrets → `FIREBASE_IOS_APP_ID` → `GOOGLE_APP_ID` del plist
   (`1:51157842817:ios:...`) y `FIREBASE_IOS_API_KEY` → `API_KEY` del plist.
   En local:
   `flutter run --dart-define=FIREBASE_IOS_APP_ID=... --dart-define=FIREBASE_IOS_API_KEY=...`
4. Compilar/firmar: en una Mac con Xcode, `open ios/Runner.xcworkspace`,
   elegir el Team en *Signing & Capabilities* y, para notificaciones push,
   añadir la capability **Push Notifications** y la clave APNs en Firebase
   → Cloud Messaging.

---

## Deploy

Siempre **staging primero**; producción solo después, con aprobación.

### 1. Staging (desde la máquina de un responsable, nunca desde el CI)
```
(cd functions && npm ci && npm run build && npm test)
(cd tools/rules-tests && npm ci) && npm run test:rules
firebase deploy --only functions,firestore --project staging
```
Hosting de staging: compilar la web con `--dart-define=FIREBASE_ENV=staging`
y configurar sus sitios como `target` de staging en `.firebaserc` antes de
`firebase deploy --only hosting --project staging`.

### 2. Producción (CI con aprobación)
Cada push a `main` ejecuta lint, tests y builds. Los jobs *Deploy Functions*
(functions + reglas) y *Deploy Hosting* usan el entorno de GitHub
`production`: esperan la aprobación de un revisor y nunca corren dos a la vez.
Antes de desplegar, el CI comprueba que existan los secretos de GitHub y
`STRIPE_SECRET_KEY` en Secret Manager.

### Flutter Android (prod)
The native Maps SDK reads its key from the manifest, which Gradle fills from
the `GOOGLE_MAPS_API_KEY` env var (or `MAPS_API_KEY=...` in
`android/local.properties` for local builds). Without it the release build
stops. Requires `android/key.properties` (see «Firma de Android»).
```
GOOGLE_MAPS_API_KEY=ANDROID_SDK_KEY flutter build appbundle --release \
  --dart-define=ENV=prod \
  --dart-define=FIREBASE_ENV=production \
  --dart-define=GOOGLE_MAPS_KEY=MOBILE_REST_KEY \
  --dart-define=FIREBASE_ANDROID_APP_ID=... \
  --dart-define=FIREBASE_ANDROID_API_KEY=... \
  --obfuscate \
  --split-debug-info=build/debug-info
```

### Flutter iOS (prod)
Requires `ios/Flutter/Secrets.xcconfig` with the iOS SDK key.
```
flutter build ios --release \
  --dart-define=ENV=prod \
  --dart-define=FIREBASE_ENV=production \
  --dart-define=GOOGLE_MAPS_KEY=MOBILE_REST_KEY \
  --dart-define=FIREBASE_IOS_APP_ID=... \
  --dart-define=FIREBASE_IOS_API_KEY=...
open ios/Runner.xcworkspace   # archive from Xcode
```

### Flutter Android (dev)
```
# android/local.properties may contain MAPS_API_KEY=ANDROID_SDK_KEY
flutter run --dart-define-from-file=env.local.json
```

---

## Orden de despliegue de createBooking (D2)

Las reservas pasan a crearse solo en el servidor (`createBooking`), que
calcula el precio. Las reglas nuevas (`bookings: allow create: if false`)
dejan sin poder reservar a cualquier app antigua, así que el orden es:

1. **Configuración** en el proyecto (ver «Configuración de precios» abajo) y
   el secreto `MAPS_SERVER_KEY`:
   `firebase functions:secrets:set MAPS_SERVER_KEY --project <alias>`.
2. **Functions** (`quoteBooking`, `createBooking`, `onBookingCreated` nuevo):
   `firebase deploy --only functions --project <alias>`. Las apps antiguas
   siguen reservando (aún con las reglas viejas).
3. **App nueva** en web (hosting) y en las tiendas. Esperar a que la
   versión nueva esté **publicada y visible** en Google Play y en la App
   Store (no solo enviada a revisión).
4. **Versión mínima**: en `config/global` poner `minAppVersion` = la
   versión publicada (`x.y.z`, la de `version:` en `pubspec.yaml`, sin el
   `+build`) y, si existen, `androidStoreUrl` e `iosStoreUrl` (https).
   Desde ese momento una app más vieja recibe «Actualiza la app para
   reservar» en lugar de un error. Nunca subir `minAppVersion` antes de que
   la versión esté en las tiendas y en la web: bloquearía a todos.
5. **Reglas** al final: `firebase deploy --only firestore:rules --project <alias>`.

Las apps que ya existían antes de esta versión no envían `appVersion` ni
llaman a `createBooking`: tras el paso 5 no pueden reservar y verán un
error genérico, no el aviso (no saben mostrarlo). El aviso protege a partir
de esta versión. La web se actualiza sola con el despliegue de hosting.

### Configuración de precios (Firestore)

No hay tarifas en el código (D20): sin `pricingRules` la web y la app
muestran «Cotiza al reservar» y el servidor no reserva esa clase. Para
cargarlas en staging:

```
cp tools/pricing/pricing.seed.example.json ~/luxelane-tarifas/staging.json   # fuera del repo
# completar cada "REEMPLAZAR" (importes en Bs)
npm run pricing:check -- --file ~/luxelane-tarifas/staging.json
npm run pricing:seed  -- --file ~/luxelane-tarifas/staging.json --project <ID_STAGING>           # dry-run
npm run pricing:seed  -- --file ~/luxelane-tarifas/staging.json --project <ID_STAGING> --apply   # escribe
```
`pricing:seed` se niega a escribir en `luxelane-4e7ae`: en producción las
tarifas se cargan desde el panel admin (Tarifas). `routeFactor` se calibra
con `node tools/pricing/calibrar_ruta.mjs <trayectos.csv>` (ver
`tools/pricing/ejemplo_rutas.csv`, datos ficticios).

- `pricingRules/{clase}_{servicio}` para cada combinación que se venda:
  `basePriceUsd`, `pricePerKmUsd`, `pricePerHourUsd`, `minimumPriceUsd`
  (números, en **bolivianos** aunque el nombre diga Usd) e `isActive`.
  Si falta, `createBooking` no reserva esa clase (no usa tarifas de fábrica).
- `config/pricing.routeFactor` (número ≥ 1): distancia de respaldo cuando la
  ruta por calles falla. Sin él y sin ruta, no se reserva.
- Opcionales, apagados si no existen: `config/pricing.nightSurchargePct`,
  `nightStartHour`, `nightEndHour` y `fixedAirportFares`
  (`"VVI|Santa Cruz de la Sierra|business": importe`).

---

## Claves de Google Maps

No hay ninguna clave en el repositorio. Cada plataforma usa la suya y una
build de release sin clave se detiene con un mensaje (Android: Gradle; iOS:
fase *Check Google Maps key*). En debug sin clave la app arranca y los mapas
muestran «Mapa no disponible».

| Dónde se usa | Cómo llega | Secreto de GitHub |
|---|---|---|
| SDK nativo de Android (manifiesto) | env `GOOGLE_MAPS_API_KEY` o `MAPS_API_KEY` en `android/local.properties` | `GOOGLE_MAPS_ANDROID_API_KEY` |
| SDK nativo de iOS (`Info.plist` → `GMSApiKey`) | `ios/Flutter/Secrets.xcconfig` (ver `Secrets.xcconfig.example`) | `GOOGLE_MAPS_IOS_API_KEY` |
| Web (Maps JavaScript y Places en el navegador) | `--dart-define=GOOGLE_MAPS_KEY=...` en la build web | `GOOGLE_MAPS_WEB_API_KEY` |
| Llamadas REST desde Android/iOS (Places, Geocoding, Directions) | `--dart-define=GOOGLE_MAPS_KEY=...` en la build móvil | `GOOGLE_MAPS_API_KEY` |

En local, las claves de Dart van en un archivo que git ignora:

```
cp env.example.json env.local.json      # completar los valores
flutter run --dart-define-from-file=env.local.json
flutter build web --release --dart-define-from-file=env.local.json
```

`env.local.json`, `android/local.properties`, `android/key.properties` e
`ios/Flutter/Secrets.xcconfig` están en `.gitignore`.

> La `apiKey` de Firebase web (`lib/firebase_options.dart`,
> `web/firebase-messaging-sw.js`) es pública por diseño: identifica el
> proyecto, no da acceso. Lo que protege los datos son las reglas de
> Firestore/Storage y App Check. Las apps nativas ya no la usan: ver la
> sección siguiente.

---

## Claves de Firebase de las apps nativas

Cada app nativa usa la clave de API de **su** app registrada en Firebase.
`lib/firebase_options.dart` no trae ningún valor por defecto: las cuatro
variables llegan con `--dart-define`. Sin ellas:

- la release de Android se detiene en Gradle con
  `Release build without Firebase Android config: pass --dart-define=...`;
- la release de iOS se detiene en la fase *Check Google Maps and Firebase
  keys* con `Release build without Firebase iOS config: pass --dart-define=...`;
- en debug la app arranca, pero `Firebase.initializeApp` lanza un error que
  nombra los `--dart-define` que faltan.

Los mensajes solo nombran las variables; nunca imprimen sus valores.

| Plataforma | `--dart-define` | Secreto de GitHub | De dónde sale |
|---|---|---|---|
| Android | `FIREBASE_ANDROID_APP_ID` | `FIREBASE_ANDROID_APP_ID` | `google-services.json` → `client[].client_info.mobilesdk_app_id` |
| Android | `FIREBASE_ANDROID_API_KEY` | `FIREBASE_ANDROID_API_KEY` | `google-services.json` → `client[].api_key[0].current_key` |
| iOS | `FIREBASE_IOS_APP_ID` | `FIREBASE_IOS_APP_ID` | `GoogleService-Info.plist` → `GOOGLE_APP_ID` |
| iOS | `FIREBASE_IOS_API_KEY` | `FIREBASE_IOS_API_KEY` | `GoogleService-Info.plist` → `API_KEY` |

### Obtener la clave de la app Android
1. Firebase Console → proyecto (staging o producción) → ⚙ Project settings
   → **General** → *Your apps* → app Android `com.luxelane.app`. Si no
   existe, registrarla (ver «Inicio de sesión con Google» → Android).
2. Pulsar **google-services.json** para descargarlo. No se añade al
   repositorio (el proyecto no usa el plugin de Gradle de Google Services).
3. En el JSON, dentro del objeto `client` cuyo
   `client_info.android_client_info.package_name` es `com.luxelane.app`:
   - `client_info.mobilesdk_app_id` → `FIREBASE_ANDROID_APP_ID`;
   - `api_key[0].current_key` → `FIREBASE_ANDROID_API_KEY`.
4. GitHub → Settings → Secrets and variables → Actions → *New repository
   secret* con esos dos nombres. Borrar el JSON descargado.

### Obtener la clave de la app iOS
1. Firebase Console → ⚙ Project settings → **General** → *Your apps* → app
   iOS `com.luxelane.app` (si no existe, ver «Inicio de sesión con Google»
   → iOS).
2. Descargar **GoogleService-Info.plist** (no se añade al proyecto).
3. Copiar `GOOGLE_APP_ID` → `FIREBASE_IOS_APP_ID` y `API_KEY` →
   `FIREBASE_IOS_API_KEY` en los secretos de GitHub. Borrar el plist.

Cada proyecto (staging y producción) tiene sus propias apps y claves; en
staging se pasan igual, con los valores de las apps de staging.

### Restringir las claves (Google Cloud Console)
APIs & Services → Credentials → cada clave «(auto created by Firebase)»:

- **Clave de Android**: *Application restrictions* → *Android apps* →
  paquete `com.luxelane.app` + SHA-1 de cada firma (debug, upload y la de
  Play App Signing).
- **Clave de iOS**: *Application restrictions* → *iOS apps* → bundle
  `com.luxelane.app`.
- En las tres claves, *API restrictions* con solo las APIs de Firebase que
  usa la app (Identity Toolkit, Token Service, Cloud Firestore, Firebase
  Installations, FCM Registration, Cloud Functions). **[Probable]**: la
  lista exacta hay que confirmarla en la consola (APIs & Services → Metrics,
  filtrando por credencial) antes de aplicarla.

### Cuándo restringir la clave web por referentes HTTP
Las peticiones de una app nativa no envían cabecera `Referer`, así que una
clave restringida por referentes HTTP las rechaza. Hasta este cambio las
builds nativas usaban, por defecto, la misma clave que la web. Por eso la
clave web solo se puede restringir por referentes cuando **ninguna versión
nativa en uso dependa de ella**:

1. Publicar en las tiendas la versión compilada con `FIREBASE_ANDROID_API_KEY`
   y `FIREBASE_IOS_API_KEY`.
2. Subir `minAppVersion` en `config/global` a esa versión (ver «Orden de
   despliegue de createBooking»). Las versiones antiguas ya no pueden
   reservar y ven el aviso de actualización.
3. Esperar a que el tráfico de la clave web desde apps nativas sea cero:
   APIs & Services → Metrics → filtrar por la credencial web. Una app
   antigua con la clave restringida no llega ni a iniciar sesión, así que no
   vería el aviso de actualización: por eso se espera.
4. Restringir la clave web a *Websites* con los dominios de Hosting
   (`luxelane-4e7ae.web.app`, `luxelane-4e7ae.firebaseapp.com`,
   `luxelane-driver.web.app`, `luxelane-driver.firebaseapp.com`, los
   dominios propios) y `localhost` solo en la clave de staging.

Si alguna build nativa se publicó alguna vez sin estas variables, la clave
web estaba embebida en ella: además de restringirla conviene rotarla cuando
el paso 3 se cumpla.

---

## Firma de Android

La build de release se firma con la **clave de subida** (upload key) que
indica `android/key.properties`; sin ese archivo `flutter build appbundle
--release` se detiene con un mensaje. Las builds de debug no lo necesitan.

1. Generar el keystore **una sola vez, en tu equipo, fuera del repositorio**:
   ```
   mkdir -p ~/luxelane-keys
   keytool -genkeypair -v -keystore ~/luxelane-keys/luxelane-upload.jks \
     -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Guarda una copia del `.jks` y de sus contraseñas fuera del equipo (gestor
   de contraseñas o almacenamiento cifrado). Con Play App Signing, perder la
   clave de subida obliga a pedir a Google un restablecimiento; sin Play App
   Signing, perderla impide publicar actualizaciones de la app.
2. `cp android/key.properties.example android/key.properties` y completar las
   rutas y contraseñas. `storeFile` es relativo a `android/` (o una ruta
   absoluta). `key.properties`, `*.jks` y `*.keystore` están en
   `android/.gitignore`.
3. Play Console → la app → **Configuración → Integridad de la app → Firma de
   apps de Google Play**: aceptar Play App Signing (por defecto en apps
   nuevas). Google guarda la clave de firma de la app y tú subes los AAB con
   la clave de subida. Ahí mismo copia los certificados SHA-1/SHA-256 de la
   *clave de firma de la app* y de la *clave de subida* para Firebase y para
   la restricción de la clave de Maps.
4. CI (jobs *Build Android*): secretos del repositorio
   ```
   ANDROID_KEYSTORE_BASE64   → base64 -w0 ~/luxelane-keys/luxelane-upload.jks
   ANDROID_KEYSTORE_PASSWORD → contraseña del keystore
   ANDROID_KEY_ALIAS         → upload
   ANDROID_KEY_PASSWORD      → contraseña de la clave
   ```
   (en macOS: `base64 -i ~/luxelane-keys/luxelane-upload.jks | pbcopy`).
   El job escribe el keystore en `$RUNNER_TEMP` y genera
   `android/key.properties` antes de compilar.

---

## Cabeceras de seguridad del hosting (CSP)

`firebase.json` añade a los dos sitios (`rider` y `driver`): `X-Content-Type-Options:
nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy:
strict-origin-when-cross-origin`, `Permissions-Policy` (solo geolocalización
propia; cámara, micrófono, pagos y USB desactivados: la web no los usa),
`Strict-Transport-Security: max-age=31536000` y la CSP.

La CSP va como **`Content-Security-Policy-Report-Only`**: no bloquea nada, solo
avisa en la consola del navegador. Se construyó con lo que la build carga de
verdad (Chromium headless contra `flutter build web --release`, pasajeros y
chóferes: 0 violaciones). Excepciones y por qué:

| Directiva | Valor | Motivo |
|---|---|---|
| `script-src` | `'wasm-unsafe-eval'` | CanvasKit es WebAssembly; sin esto no se compila. No permite `eval` de JavaScript. |
| `script-src` | 12 hashes `sha256-…` | FlutterFire inyecta un script en línea por librería de Firebase (`window.ff_trigger_<lib>`, que importa el SDK desde `www.gstatic.com/firebasejs/<versión>/`). Hay 2 variantes por librería (con y sin Trusted Types). Cambian al actualizar `firebase_*` o la versión del SDK web. |
| `script-src` | `https://www.gstatic.com` | CanvasKit (`flutter-canvaskit/`, no está local) y el SDK de Firebase. |
| `script-src` | `https://*.googleapis.com`, `https://maps.gstatic.com` | Maps JavaScript API. |
| `script-src`, `frame-src` | `https://apis.google.com`, `https://accounts.google.com`, `https://*.firebaseapp.com` | Inicio de sesión con Google (Firebase Auth y Google Identity Services). |
| `style-src` | `'unsafe-inline'` | Flutter web y Maps escriben estilos en línea; no hay forma de evitarlo hoy. Es de bajo riesgo comparado con scripts. |
| `connect-src` | `*.googleapis.com`, `*.cloudfunctions.net`, `*.run.app`, `*.google.com`, `*.firebaseapp.com`, `fonts.*` | Firestore, Auth, Functions, mensajería, Places/Geocoding/Directions y fuentes. |
| `img-src` | `data:`, `blob:`, `*.googleapis.com`, `*.gstatic.com`, `*.google.com`, `*.googleusercontent.com` | Teselas e íconos de Maps, fotos de perfil de Google. |

Librerías de Firebase cuyos scripts tienen hash hoy: `firebase_core`, `firebase_firestore`, `firebase_functions`, `firebase_auth`, `firebase_messaging`, `firebase_performance` (SDK web 11.9.1).

**Pasar a obligatoria (enforcement)**:
1. Publicar con Report-Only y usar la web unos días (pasajeros, chóferes, admin,
   login con Google, mapas con la clave real, reservas).
2. Revisar violaciones: consola del navegador (`[Report Only] Refused to…`).
   Chrome muestra el hash exacto si falta uno (`'sha256-…'`). Opcional: añadir
   un endpoint de informes (`report-to`) para recogerlas en un servidor.
3. Ajustar la lista y, cuando una semana pase sin violaciones legítimas,
   renombrar la clave a `Content-Security-Policy` en los dos sitios de
   `firebase.json`. Mantener la Report-Only en paralelo con la siguiente
   versión de la política es buena práctica.
4. Al actualizar `firebase_*`/FlutterFire, volver a revisar los hashes (si
   cambian, Chrome lo reporta).

`includeSubDomains` y `preload` en HSTS no están activados: es una decisión del
responsable (afecta a todos los subdominios del dominio propio y el preload
es difícil de revertir).

---

## Migración de reservas existentes (D5/F4)

`functions/scripts/migrate-booking-pii.js` mueve los datos del invitado que
la app antigua guardaba en `notes` al campo `guest`, crea `openRequests`
para las reservas pendientes y quita el teléfono del chófer de `driverInfo`
(D16): en reservas confirmadas o en curso lo copia a
`driverContact/phone`; en el historial solo lo borra. **Por defecto es DRY-RUN**: informa qué haría
con cada reserva (sin mostrar datos personales) y no escribe nada.

Orden: desplegar functions y reglas en el proyecto, luego migrar, luego
publicar la app. Siempre staging primero.

```
cd functions && npm ci && npm run build
gcloud auth application-default login            # credenciales con acceso al proyecto
node scripts/migrate-booking-pii.js --project <ID_STAGING>            # dry-run
node scripts/migrate-booking-pii.js --project <ID_STAGING> --apply    # escribe
```
Repetir en producción solo después de revisar staging. Una segunda pasada
no encuentra nada que cambiar.

---

## GitHub Secrets Required

Secreto del entorno `production` (Settings → Environments → production),
solo visible para los jobs aprobados:
```
GCP_SA_KEY              → JSON de la cuenta de servicio que despliega
```
Secretos del repositorio (Settings → Secrets and variables → Actions), que
usan los builds:
```
GOOGLE_MAPS_API_KEY         → Maps: llamadas REST de las apps móviles (ver «Claves de Google Maps»)
GOOGLE_MAPS_WEB_API_KEY     → Maps: web
GOOGLE_MAPS_ANDROID_API_KEY → Maps: SDK de Android
GOOGLE_MAPS_IOS_API_KEY     → Maps: SDK de iOS
FCM_VAPID_KEY           → Firebase → Cloud Messaging → Web Push certificates
FIREBASE_ANDROID_APP_ID  → google-services.json → mobilesdk_app_id (ver «Claves de Firebase de las apps nativas»)
FIREBASE_ANDROID_API_KEY → google-services.json → api_key[0].current_key
FIREBASE_IOS_APP_ID      → GoogleService-Info.plist → GOOGLE_APP_ID
FIREBASE_IOS_API_KEY     → GoogleService-Info.plist → API_KEY
GOOGLE_SERVER_CLIENT_ID → OAuth "Web client" del proyecto (Google Sign-In en Android)
GOOGLE_IOS_CLIENT_ID    → GoogleService-Info.plist → CLIENT_ID
ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD,
ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD → ver «Firma de Android»
```
`STRIPE_SECRET_KEY` no va en GitHub: vive en Secret Manager (paso 3).

---

## Emulator (local dev)

Proyecto ficticio `demo-luxelane`; nunca toca un proyecto real.
```
cd tools/rules-tests && npm ci && cd ../..
npm run emulators     # Firestore y Auth locales
npm run test:rules    # tests de reglas contra el emulador
```

---

## Rollout

1. Internal test (5 users) → `firebase app:distribution:release`
2. Closed beta (50) → TestFlight + Play Internal
3. 10% production rollout → Play Console staged rollout
4. 100% → lift staged rollout + App Store release
