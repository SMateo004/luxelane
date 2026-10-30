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

4. Secreto del código de recogida (D1), distinto en cada proyecto. Generar
   un valor aleatorio y pegarlo cuando la CLI lo pida (no se guarda en
   ningún archivo ni se imprime en otro sitio):
   ```
   openssl rand -hex 32          # copiar el valor
   firebase functions:secrets:set PICKUP_CODE_SECRET --project staging
   firebase functions:secrets:set PICKUP_CODE_SECRET --project production
   ```
   Sin él, `getPickupCode` y `verifyPickup` fallan cerrado
   (`pickup_unavailable`) y el CI no despliega. Cambiarlo cambia el código
   de los viajes en «Chófer llegó»: rotarlo solo sin viajes en ese estado.

5. Sal de los límites del formulario de empresas (`submitBusinessLead`),
   distinta en cada proyecto, con el mismo procedimiento:
   ```
   openssl rand -hex 32          # copiar el valor
   firebase functions:secrets:set RATE_LIMIT_SALT --project staging
   firebase functions:secrets:set RATE_LIMIT_SALT --project production
   ```
   La IP del formulario solo se guarda como HMAC con esta sal. Sin ella la
   callable rechaza todo envío (falla cerrado) y, como la función la
   declara, el despliegue no termina **[Probable]**.

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
firebase deploy --only functions,firestore:indexes --project staging
# … apps publicadas y versiones mínimas puestas (ver los «Orden de despliegue») …
firebase deploy --only firestore:rules --project staging    # siempre al final
```
Hosting de staging: compilar la web con `--dart-define=FIREBASE_ENV=staging`
y configurar sus sitios como `target` de staging en `.firebaserc` antes de
`firebase deploy --only hosting --project staging`.

### 2. Producción (CI con aprobación)
Cada push a `main` ejecuta lint, tests y builds. Los jobs *Deploy Functions*
(solo functions) y *Deploy Hosting* usan el entorno de GitHub `production`:
esperan la aprobación de un revisor y nunca corren dos a la vez. Antes de
desplegar, el CI comprueba que existan los secretos de GitHub y
`STRIPE_SECRET_KEY` y `PICKUP_CODE_SECRET` en Secret Manager.

Las **reglas** no se despliegan con cada push: van al final, a mano, cuando
las apps nuevas están publicadas y las versiones mínimas puestas. GitHub →
Actions → *Luxelane CI/CD* → *Run workflow* (rama `main`) → marcar
`deploy_rules` → el job *Deploy Firestore rules* espera la aprobación de
`production`.

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

## Verificación en recogida (D1): orden de despliegue y viajes en curso

Desde esta versión el chófer no escribe el estado del viaje: «Salir hacia
la recogida», «He llegado», «Iniciar viaje» y «Completar» pasan por la
callable `advanceBooking`, y entre «Chófer llegó» y «En progreso» hay un
estado nuevo, **Verificada**, al que solo se llega con el código de 4
dígitos del pasajero (`verifyPickup`) o con «Forzar verificación» del admin
(`adminOverrideVerify`, con motivo). Las reglas nuevas niegan a cualquier
cliente escribir esos estados.

### Pasos manuales previos (decisiones del responsable)
1. `PICKUP_CODE_SECRET` en cada proyecto (ver «First-time Setup», paso 4).
2. `config/ops.arrivalRadiusMeters` (número, metros; ver «config/ops y
   config/security»): distancia a partir
   de la cual «He llegado» se marca lejos del punto de recogida y crea una
   alerta. No bloquea al chófer. Sin el campo no se compara y el evento lo
   anota (`no_radius`). **El valor lo decide el responsable.**
3. `config/global.dispatchPhone` (texto): teléfono de central. Sin él no
   aparece «Llamar a central» en la app del chófer. **El número lo decide el
   responsable**; el código no trae ninguno.
4. `config/global.minDriverAppVersion` (`x.y.z`): se pone en el paso 4 de
   abajo, nunca antes.

### Orden
1. Secreto y configuración (arriba).
2. **Functions** (push a `main` → *Deploy Functions*; staging:
   `firebase deploy --only functions --project staging`). Las apps nuevas
   ya funcionan con el servidor. Las antiguas siguen escribiendo el estado
   porque las reglas aún son las viejas: es el **periodo de gracia**, y
   esos viajes no piden código ni dejan eventos.
3. **Apps nuevas publicadas**: la del pasajero (muestra el código) y la del
   chófer (lo pide). Esperar a que estén visibles en Google Play y en la
   App Store; la web se actualiza con *Deploy Hosting*.
4. **Versiones mínimas** en `config/global`: `minAppVersion` (pasajero) y
   `minDriverAppVersion` (chófer) = las versiones publicadas. Las apps del
   chófer anteriores a esta versión no llaman a `advanceBooking`, así que
   `minDriverAppVersion` no las frena: solo las frenan las reglas (paso 6).
   El aviso de actualizar protege a partir de esta versión.
5. **Ventana sin viajes de la app antigua**: avisar a los chóferes de que
   actualicen y elegir una hora de poco movimiento. Comprobar que ningún
   viaje activo depende de la app antigua (los que avanzan con la nueva
   tienen «Registro del viaje»; los de la antigua, no):
   - Staging o emulador (solo lee; termina con código 2 si hay alguno):
     ```
     cd functions && npm ci
     gcloud auth application-default login
     npm run trips:in-flight -- --project <ID_STAGING>
     ```
     El script se niega a ejecutarse contra `luxelane-4e7ae`.
   - Producción: panel → Operaciones → filtrar «En camino», «Chófer llegó» y
     «En progreso» y abrir cada reserva: si «Registro del viaje» está vacío,
     va con la app antigua.
6. **Reglas** al final: staging
   `firebase deploy --only firestore:rules --project staging`; producción
   con el job manual *Deploy Firestore rules* (ver «Producción»).

### Qué le pasa a un viaje en curso con la app antigua tras las reglas
La app antigua intenta escribir el estado y las reglas lo rechazan: el
chófer ve «No se pudo actualizar el viaje» y el viaje se queda en su paso
(no se pierde nada; el estado no cambia).

| Estado al desplegar | Con la app antigua del chófer | Salida |
|---|---|---|
| Confirmado | «Ir a la recogida» falla | Actualizar la app: sigue desde el mismo paso |
| En camino | «He llegado» falla | Actualizar la app |
| Chófer llegó | «Iniciar viaje» falla | Actualizar la app y pedir el código; si el pasajero tiene la app antigua y no lo ve, «Forzar verificación» en el panel |
| En progreso | «Completar» falla y no se cobra | Actualizar la app para completar, o el admin «Marcar "Completado"» (el panel lo sigue permitiendo) |

El pasajero con la app antigua ve una reserva «Verificada» como
«Pendiente» (no conoce el estado) y no puede cancelarla (las reglas no lo
dejan desde Verificada). Se corrige al actualizar.

**Alternativa descartada:** desplegar unas reglas de transición que
acepten también los pasos antiguos durante unos días. Mantendría abierto
justo el hueco de D1 (pasar de «llegó» a «en progreso» sin código y
completar —y cobrar— desde el cliente). Si alguna vez hiciera falta, que
sean horas, no días, y vigilando el paso 5.

**Vuelta atrás:** antes del paso 6 no hay nada que deshacer (las reglas
viejas siguen y la app antigua funciona). Después, volver a las reglas
anteriores reabre D1: solo como emergencia, con
`git show <commit_anterior>:firestore.rules > firestore.rules` y el job
manual de reglas.

## SOS e incidentes (D1, F9): orden de despliegue

El botón SOS crea un incidente (`raiseIncident`) que avisa a central:
documento en `incidents`, alerta de severidad alta en `adminAlerts`, push a
los dispositivos de admin con token y franja con sonido arriba del panel. Si
nadie lo reconoce, `escalateIncidentsJob` (cada minuto) reenvía alerta y
push. **Sin una persona atendiendo el panel (o el push) el botón no protege
a nadie** (auditoría, D23).

Si quien lo disparó lo cancela, puede ser bajo coacción: el incidente pasa a
`cancel_requested`, central recibe «Cancelado por el usuario: verificar por
llamada» con prioridad alta y **la escalada sigue** hasta que un admin lo
reconozca y lo cierre con nota. Deja de publicarse la ubicación del usuario
(respeta su decisión); el seguimiento del chófer sigue visible en el panel.

**Limitación de la ubicación del SOS:** la app solo publica la ubicación de
quien pidió ayuda **mientras está en primer plano** (permiso «mientras se usa
la app»). La app de pasajeros no pide ubicación en segundo plano por el SOS
(riesgo de rechazo en tiendas, D18): si la persona bloquea el teléfono o
cambia de app, central ve la última ubicación publicada y el seguimiento del
chófer, que sí sigue en segundo plano.

### Pasos manuales previos (decisiones del responsable)
1. `config/global.dispatchPhone` (texto): teléfono de central. Sin él, la
   app no ofrece llamar ni enviar SMS a central si falla la red, y el panel
   no muestra «Llamar a central».
2. `config/global.emergencyNumbers` (mapa nombre → número, p. ej. en la
   consola de Firestore: tipo *map*). Sin él, la pantalla de ayuda dice
   «Contacta con las autoridades locales». **El código no trae ningún
   número, ni de emergencias.**
3. Quién recibe el push: los usuarios con `role: admin` que tengan
   `fcmTokens`. Se registran desde la **app móvil** (cualquier rol) y desde el
   **panel web solo para admins**, con `FCM_VAPID_KEY` (sin esa clave la web
   no registra nada). El push del navegador **no es fiable con el navegador
   cerrado** (y el sistema puede silenciarlo): la guardia debe tener la app
   móvil con su cuenta de admin. El panel abierto suena igualmente.
4. `config/ops.incidentLocationRetentionDays` (número de días): cuánto se
   guardan las ubicaciones de un incidente cerrado. Sin el valor no se borra
   nada y el panel lo indica.
5. Tiempos de operación en `config/ops` (opcionales, con su valor por defecto):
   `incidentAckSeconds` = 120 (escalar si nadie reconoce) e
   `incidentEscalateEverySeconds` = 120 (repetir la escalada).

### Orden
1. **Functions e índices** (push a `main` → *Deploy Functions*, que ya
   despliega `functions,firestore:indexes`; staging:
   `firebase deploy --only functions,firestore:indexes --project staging`).
   Incluye `raiseIncident`, `cancelIncident`, `acknowledgeIncident`,
   `closeIncident` y las funciones programadas `escalateIncidentsJob` (cada
   minuto) y `purgeIncidentLocationsJob` (diaria). Las programadas
   necesitan Cloud Scheduler habilitado en el proyecto **[Probable]**.
   Esperar a que los índices de `incidents` terminen de crearse (consola →
   Firestore → Índices).
2. **Apps nuevas publicadas** (pasajero y chófer con el botón) y **panel**
   (*Deploy Hosting*).
3. **Simulacro en staging**: con una reserva de prueba en curso, mantener
   SOS 2 s, comprobar la franja y el sonido del panel, el push en el móvil de
   un admin, la escalada a los 2 minutos sin reconocer, reconocer y cerrar
   con nota.
4. **Reglas al final** (job manual *Deploy Firestore rules*): añaden
   `incidents` y sus ubicaciones, impiden a cualquier cliente tocar
   `incidentOpen`/`activeIncidentId` y que el admin complete una reserva
   que no esté en curso.

### Apps antiguas
No tienen botón SOS; todo lo demás sigue funcionando igual (el incidente no
es un estado de la reserva y las reglas nuevas no cambian nada que la app
antigua escriba). No hace falta subir la versión mínima por el SOS.

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

## Endurecimiento: App Check, límites de tasa y errores (D3, D11, D13)

Todas las callables pasan por `secureCallable` (`functions/src/callable.ts`):
App Check, límite de tasa por usuario y traducción de errores. Los triggers
y las funciones programadas no cambian. El emulador **no simula App Check**:
los tests prueban la puerta con peticiones con y sin token
(`callable_security.test.ts`).

### Pasos manuales previos (consola; decisiones del responsable)
1. **Registrar las apps en App Check** (consola de Firebase → App Check →
   Apps), en staging y luego en producción:
   - Android: proveedor **Play Integrity**. Requiere la huella SHA-256 del
     certificado de firma de la app (la de Play App Signing, ver «Firma de
     Android») en la configuración del proyecto, y la app vinculada en Play
     Console.
   - iOS: **App Attest** (con DeviceCheck de respaldo). En Xcode, añadir la
     capacidad *App Attest* (entitlement
     `com.apple.developer.devicecheck.appattest-environment` = `production`);
     el repositorio no tiene archivo de entitlements, hay que crearlo
     (NO VERIFICADO en un dispositivo).
   - Web (panel y web del pasajero): **reCAPTCHA v3**. Crear la clave del
     sitio para los dominios del hosting en la consola de reCAPTCHA,
     registrar su clave secreta en App Check y guardar la clave del sitio en
     el secreto de GitHub `RECAPTCHA_SITE_KEY`. Sin ese secreto el build web
     de release falla con un mensaje claro. (Las notas oficiales sobre qué
     proveedor web recomiendan hoy no se pudieron consultar: NO VERIFICADO.)
2. **Tokens de depuración** (solo builds de depuración): generar un token en
   App Check → Apps → *Administrar tokens de depuración* y pasarlo con
   `--dart-define=APP_CHECK_DEBUG_TOKEN=<token>`. Nunca en un build de
   release (el código lo ignora fuera de depuración) ni en el repositorio.
3. **TTL de `rateLimits`**: consola de Google Cloud → Firestore →
   *Time-to-live (TTL)* → *Create policy*: grupo de colecciones `rateLimits`,
   campo `expireAt`. O bien:
   `gcloud firestore fields ttls update expireAt --collection-group=rateLimits --enable-ttl --project=<proyecto>`.
   El borrado ocurre en algún momento después de `expireAt` (puede tardar
   horas) **[Probable]**. Sin la política los límites funcionan igual; los
   documentos (uno por usuario y callable) se acumulan.

### Fase 1: medir sin imponer
1. **Functions** con `APP_CHECK_ENFORCE=false` (valor por defecto del
   parámetro; se fija en `functions/.env.<proyecto>` o lo pide el CLI al
   desplegar **[Probable]**). Con `false`, cada llamada registra solo el nombre de la
   función y si llegó un token válido, sin datos personales:
   Logs Explorer → `jsonPayload.fn="appCheck"` y
   `jsonPayload.data.appCheck="missing"`. (las líneas JSON del log llegan como
   `jsonPayload` **[Probable]**).
2. **Apps y hosting** con App Check (pasajero, chófer, panel y web).
3. **Mirar las métricas** (Logs Explorer y App Check → métricas de cada
   servicio) hasta que las llamadas sin token sean solo de versiones
   antiguas. Entonces subir `minAppVersion` y `minDriverAppVersion` a las
   primeras versiones con App Check (ver «Versión mínima» más arriba).

### Fase 2: imponer
1. **Callables**: `APP_CHECK_ENFORCE=true` y volver a desplegar functions.
   Sin token válido la callable responde `unauthenticated` con motivo
   `app_check_required` y la app muestra «No se pudo verificar la app».
   Vuelta atrás: `false` y desplegar.
2. **Firestore** (consola → App Check → APIs → Cloud Firestore →
   *Enforce*): es otro interruptor, solo en la consola. **Rompe todas las
   lecturas y escrituras de las apps sin App Check**: hacerlo solo cuando
   `minAppVersion` y `minDriverAppVersion` ya exijan versiones con App
   Check y las métricas de Firestore muestren casi todo verificado. Mitiga
   también el envío masivo del formulario de empresas (matriz, H5).

### Límites de tasa
Tabla y justificación en `functions/src/rate_limit.ts` (`RATE_LIMITS`).
Ventana fija por usuario y callable, contada en una transacción en
`rateLimits/{callable}__{uid}` (solo el servidor). Si el contador falla,
la callable se rechaza (`resource_exhausted`), salvo `raiseIncident`: un
SOS nunca se pierde por el contador.

### Diagnóstico de x-forwarded-for (0.4)

`submitBusinessLead` cuenta los envíos por IP tomando el **último**
elemento de `x-forwarded-for`. Que en Cloud Functions (2.ª gen.) ese sea
siempre el cliente y no un salto de Google está NO VERIFICADO. Para
contrastarlo en **staging** hay un modo de diagnóstico temporal, apagado
por defecto (parámetro `XFF_DIAGNOSTIC`):

1. **Encender**: en `functions/.env.<proyecto-de-staging>` poner
   `XFF_DIAGNOSTIC=true` y desplegar functions en staging (o responder
   `true` cuando el CLI pregunte por el parámetro **[Probable]**).
2. **Probar desde dos redes distintas** (por ejemplo, el wifi de la
   oficina y los datos del móvil): enviar el formulario de empresas una vez
   desde cada una.
3. **Leer**: Logs Explorer → `jsonPayload.fn="submitBusinessLead"` y
   `jsonPayload.message="xff_diagnostic"`. Cada envío deja
   `chosenHash` (hash con la sal del elemento elegido; nunca la IP) y
   `headerElements` (cuántos elementos traía el encabezado).
   - Hashes **distintos** entre las dos redes: el elemento elegido es el
     cliente. Lo esperado.
   - Hashes **iguales**: el elegido es un salto de Google y el límite por
     IP no sirve (queda el tope global). Avisar antes de producción.
   - `usedFallback: true`: no llegó el encabezado y se usó `rawRequest.ip`.
4. **Apagar**: `XFF_DIAGNOSTIC=false` (o quitar la línea) y volver a
   desplegar functions. No dejarlo encendido en producción.

### Errores
El cliente solo recibe `invalid_request`, `unauthenticated`,
`permission_denied`, `failed_precondition`, `resource_exhausted`,
`not_found` o `internal`, con un motivo corto en `details.reason`; nunca
texto de Stripe, Firestore o zod. El log del servidor tacha correos,
teléfonos, tokens, claves, tarjetas, códigos de recogida y coordenadas.
**Apps antiguas:** leían «card-in-use» y «active-bookings» del mensaje;
con las functions nuevas muestran el texto genérico de error (quitar
tarjeta, eliminar cuenta). Nada se rompe, pero conviene que
`minAppVersion` alcance la versión nueva (decisión del responsable).

### Reglas (matriz de acceso)
Ver `docs/MATRIZ_ACCESO.md`. Con el job *Deploy Firestore rules*:
`isVerified` pasa a ser campo privilegiado y los avisos de
`users/{uid}/notifications` solo los crea el servidor. Ninguna pantalla
actual escribe ninguno de los dos: no hace falta subir versiones mínimas.

Hallazgos de la matriz corregidos en cierre/identidad (H1, H4, H5, H7, H8,
H9). Orden:
1. `RATE_LIMIT_SALT` creado (First-time Setup, paso 5).
2. **Functions**: añade `submitBusinessLead` y retira `onRideCompleted`.
   Antes, borrarla a mano (ver «Funciones retiradas»); los documentos de
   `rides` no se tocan.
3. **Hosting y apps**: la web envía el formulario de empresas por la
   callable; el panel trae la advertencia al bloquear y «Editar datos» del
   chófer; la app del chófer, «Cuenta suspendida» y los campos bloqueados.
4. **Reglas al final**: niegan crear `businessLeads` desde el cliente. Una
   web antigua (que escribía directo) deja de poder enviar el formulario:
   desplegar el hosting antes que las reglas. Un chófer bloqueado deja de
   leer sus viajes en el acto: reasignarlos antes de bloquearlo (el panel
   lo avisa).

### Eventos: datos solo para central (A8.7)
El motivo del admin al forzar la verificación y el control de llegada
(`farFromPickup`, `arrivalCheck`) se escriben ahora en
`bookings/{id}/eventDetails`, que solo lee el admin. Los eventos ya
escritos los llevan dentro (visibles para pasajero y chófer). Tras desplegar
functions y reglas, migrarlos (primero dry-run, primero staging):
```
cd functions
npm run migrate:event-details -- --project staging           # dry-run
npm run migrate:event-details -- --project staging --apply
```
El panel nuevo lee ambos sitios, así que el orden no rompe nada.

Desde 0.2 la misma migración saca también el uid del admin: en los eventos
de reserva con actor admin queda solo `actor.role = 'admin'` y el uid pasa a
`eventDetails.actorUid`; en `incidents/{id}` borra `acknowledgedBy` y
`closedBy` (el documento lo lee quien disparó el SOS; el uid sigue en los
eventos del incidente y en admin_logs). En producción exige
`--i-understand-this-writes-to-production-luxelane-4e7ae`.

### config/ops y config/security (A8.9)
`config/global` es público (lo leen las apps sin sesión) y el panel lo
escribe. Lo que solo usa el servidor va aparte; el servidor lo lee con el
Admin SDK:
- `config/ops`: `incidentAckSeconds`, `incidentEscalateEverySeconds`,
  `incidentLocationRetentionDays` y `arrivalRadiusMeters`. La lee el admin;
  ningún cliente la escribe. Ninguna app ni el panel leían o editaban estas
  claves en `config/global` [seguro].
- `config/security` (Parte B: `mfaEnforced`, `adminSessionMaxHours`):
  ningún cliente la lee ni la escribe, ni el admin.

Las dos se editan solo en la consola de Firebase (Firestore → Datos →
colección `config` → documento `ops` o `security` → editar campo).
Traslado en un proyecto ya configurado, después de desplegar functions:
1. Crear `config/ops` con los valores que tenga hoy `config/global` para
   esas cuatro claves (mismo nombre y tipo número).
2. Comprobar que deja de aparecer la alerta «Configuración por mover a
   config/ops» en el panel (Alertas) y, en Logs Explorer,
   `opsConfig … keys still in config/global`. Mientras falte una clave en
   ops, el servidor usa la de global, lo anota en el log y deja esa alerta
   de severidad baja, como mucho una por día (0.3); la alerta dice qué
   claves faltan. Paso manual: mover esas claves y resolver la alerta.
3. Borrar esas cuatro claves de `config/global` en la consola.

### Funciones retiradas
El job *Deploy Functions* (`.github/workflows/ci.yml`, paso
`deploy --only functions,firestore:indexes`) corre sin terminal y sin
`--force`: si una función sigue en el proyecto pero ya no está en el
código, la CLI no puede preguntar y el despliegue se detiene
**[Probable]**. No se añade `--force` porque borraría sin preguntar
cualquier función que faltara por error. Antes del despliegue, desde la
máquina de un responsable (primero staging):
```
firebase functions:delete onRideCompleted --region us-central1 --project staging --force
firebase functions:delete onRideCompleted --region us-central1 --project production --force
```
La región es la por defecto (el código no fija otra) **[Probable]**: si la
CLI no la encuentra, `firebase functions:list --project <proyecto>` la
muestra.

---

## Escrituras de admin por el servidor (auditoría, Parte A)

El panel ya no escribe Firestore: cada cambio va a una callable
(`adminUpdateBooking`, `adminRecordPayment`, `adminUpdateConfig`,
`adminUpdatePricingRule`, `adminVerifyDriver`,
`adminUpdateDriverSensitive`, `adminSetVehicleActive`,
`adminSetLeadHandled`) que exige rol admin, segundo factor con
`mfaEnforced`, un motivo de al menos 10 caracteres y escribe la auditoría
en la misma transacción. Las reglas dejan al admin solo lectura y
`admin_logs` solo lo escribe el servidor.

### Orden

1. **Functions** (las callables nuevas). El panel anterior sigue
   funcionando: aún escribe directo y las reglas viejas lo permiten.
2. **Panel** nuevo (hosting). Desde aquí todo pasa por las callables.
3. **Reglas** al final. Un panel anterior que siga abierto verá
   «Permiso denegado» en cada cambio: recargar la página.

### Pasos manuales (decisiones del responsable)

- `config/ops.maxPriceAdjustmentPercent`: **sin él se rechaza todo ajuste
  de importe** (`price_adjustment_disabled`). Si se quiere permitir
  ajustes, fijar el porcentaje máximo (0–100) en la consola o con
  `adminUpdateConfig`. El valor es decisión del responsable.
- El ajuste de importe ahora solo se hace **antes de completar** el viaje
  (antes el panel lo hacía después). Tras completar, se corrige el cobro
  manual («Corregir cobro») o se reembolsa.
- «Quitar tarifa» pasa a «Desactivar tarifa»: la tarifa queda con
  `isActive: false` en vez de borrarse.

### Reparto y pago al chófer

`bookings/{id}.settlement` (lo escriben `settleBooking`, `backfillSettlements`
y la corrección de un cobro) es el **reparto calculado**: importe,
comisión y parte del chófer. **No registra si al chófer se le pagó**: esa
marca no existe. El contador «Repartos de viajes» del panel
(`AdminState.unsettledCount`) cuenta los viajes completados sin reparto o
con un reparto de otro importe; no cuenta liquidaciones.

Consecuencia: **«Corregir cobro» recalcula y reescribe el reparto (y la
parte del chófer) aunque ese viaje ya se le haya liquidado al chófer por
fuera de la app**. No lo comprueba porque no hay de dónde. Hasta que se
decida cómo registrar los pagos al chófer (decisión del responsable),
antes de corregir un cobro hay que verificar a mano si ese viaje ya se
liquidó y, si es así, ajustar la diferencia en la siguiente liquidación.

### Auditoría anterior

No hace falta migrar `admin_logs` (A9): las entradas nuevas llevan los
mismos campos que leía el panel (`adminId`, `action`, `targetId`,
`targetType`, `details`) más los nuevos (`operation`, `actor`, `docPath`,
`changes`, `reason`). El panel lee las dos formas sin cambios.

## Cancelación, liberar y «no aparece» (auditoría, Parte B)

Qué cambia (rama cierre/auditoria, B2–B7): solo el servidor cancela.
El pasajero usa `cancelBooking` (motivo de lista cerrada, recargo
calculado con `config/ops.cancellationPolicy`, evento); el chófer
devuelve un viaje antes de llegar con `releaseBooking` (vuelve a buscar
chófer, alerta a central, contador en `driverProfiles`) y marca
«el pasajero no aparece» (`advanceBooking` a `no_show`) pasado el tiempo
de espera; central decide con `adminUpdateBooking` (cancelar con o sin
recargo). **El recargo se anota en la reserva y en el evento; no se
cobra** (`cancellationFeeCharged: false`). Las reglas dejan de permitir
que la app escriba `status: cancelled`.

### Orden

1. **Functions** (`cancelBooking`, `releaseBooking`, `no_show` en
   `advanceBooking`, decisión en `adminUpdateBooking`, aviso «Buscamos
   otro chófer»). Las apps anteriores siguen cancelando como antes: las
   reglas viejas aún lo permiten.
2. **Apps** nuevas (pasajero, chófer) y **panel** (hosting).
3. **Subir `minAppVersion` y `minDriverAppVersion`** a la versión de esas
   apps, cuando estén publicadas en las tiendas.
4. **Reglas** al final.
5. **Política** (`config/ops.cancellationPolicy`) solo después del paso 3:
   sin ella no hay recargo (`no_policy`) ni botón «no aparece». Es una
   decisión del responsable (ver abajo); no se fija ningún valor aquí.

### Qué ven las apps antiguas

- Tras el paso 4, **cancelar desde una app del pasajero anterior falla**
  con «Esta reserva ya no se puede cancelar: el viaje está en curso o
  terminó» (el mensaje que esa app muestra ante un permiso denegado),
  aunque la reserva aún se pueda cancelar. La app no comprueba su versión
  al abrirse: `minAppVersion` solo la frena al cotizar o reservar
  (`app_update_required`). Con el paso 3 las reservas nuevas ya salen de
  apps actualizadas, pero quien reservó antes con una app vieja puede
  toparse con este error: por eso el aviso del piloto (abajo) va antes
  del paso 4, y central puede cancelar desde el panel.
- Una reserva en `no_show` se ve en una app anterior como **«Pendiente»**
  (esas apps leen como pendiente cualquier estado que no conocen). Por eso
  la política, que es lo que habilita `no_show`, va después del paso 3.
- Una app del chófer anterior no tiene «No puedo hacer este viaje» ni
  «El pasajero no aparece»: sigue llamando a central como hasta ahora.
- Un panel anterior no muestra el recargo, el motivo ni el estado
  «No se presentó»: recargar la página.

### Aviso a los usuarios del piloto

Antes del paso 4, avisar por el canal habitual del piloto (mensaje
directo o correo; texto a decidir por el responsable) de que:
hay que actualizar la app para cancelar; al cancelar se verá si hay
recargo antes de confirmar; si el chófer no puede hacer el viaje, la app
busca otro y avisa. No mencionar importes ni plazos hasta que la política
esté decidida.

### Pasos manuales (decisiones del responsable)

- `config/ops.cancellationPolicy`: **sustituida en pagos (A7)** por la
  política por etapas; ver «Pagos: el pago antes de pedir chófer». La
  forma de B3 (`freeWithinMinutesOfBooking`, `feeType`, …) ya no es
  válida: con ella la retención es 0 % (`policy_invalid`) y no hay botón
  «no aparece».
- Qué hacer con `driverProfiles.releasedBookingsCount`: el servidor solo
  cuenta; no hay sanción automática.

## Pagos: el pago antes de pedir chófer (rama cierre/pagos, Partes A y B)

Qué cambia (decisiones del responsable 1–6):

- `createBooking` crea la reserva y su estado de pago
  (`bookings/{id}/payment/state`: `awaiting_payment`, importe en céntimos,
  referencia corta, plazo). **No crea `openRequests`**: ningún chófer ve,
  acepta ni recibe aviso de la reserva hasta que su pago esté en `paid`
  (`acceptBooking`, `assignNearestDriver`, asignación del admin,
  reconciliación, regla de auto-aceptación y aviso a los chóferes, que
  pasa a `notifyDriversOnPaid`).
- **Sin ningún método de pago activo en `config/ops`, `createBooking`
  responde `payments_unavailable` y no crea nada.**
- Pago manual (QR o transferencia): `startPayment` da las instrucciones;
  el pasajero avisa «ya pagué» (`markPaymentSent`, alerta alta) y central
  confirma (`adminConfirmPayment`: importe exacto, número de operación
  único) o rechaza (`adminRejectPayment`).
- Tarjeta: interfaz lista (`startPayment` y `paymentWebhook`), **proveedor
  sin decidir**. Stripe queda desactivado mientras
  `config/ops.paymentMethods.card` no sea `true`; su webhook rechaza todo
  (sin secreto). `createPaymentIntent` responde `method_disabled`.
- Vencimiento (`expirePaymentsJob`, cada 5 min): solo con
  `paymentWindowMinutes`.
- Cancelación con retención por etapas (A7); devoluciones al método
  original (`adminRecordRefund`; con tarjeta, por el proveedor); diferencia
  del importe final como saldo o devolución pendiente (A9); bandejas del
  panel (`adminPaymentInbox`).
- El código de recogida solo se muestra en la app (decisión 6). No se
  envía por WhatsApp: ninguna función lo hace (se comprobó con una
  búsqueda).

Parte B (apps y panel):

- Pasajero: reservar lleva a `/pay/<id>` (importe exacto, referencia,
  plazo si lo hay, datos del pago manual, «Ya pagué» con número de
  operación opcional, esperando confirmación, rechazado, vencido). El
  viaje muestra «Pago pendiente» hasta el pago y el comprobante después
  («no es una factura»). Cancelar muestra la retención solo si es mayor
  que cero.
- **Web: solo pago manual.** La web manda `channel: 'web'` y
  `createBooking` responde `payments_unavailable` si el pago manual no
  está activo (E38): la web nunca crea una reserva que no pueda pagar.
- **Tarjeta en la app: interfaz sin proveedor.** La app solo ofrece la
  tarjeta con un `CardPaymentPresenter` registrado, y hoy no hay ninguno.
  **No activar `paymentMethods.card` hasta integrar el formulario del
  proveedor en la app**: con solo tarjeta activa, la app nativa crearía
  reservas que dice no poder cobrar («Contacta con central»).
- Panel: sección «Pagos» con las bandejas (por confirmar, pendientes,
  devoluciones y saldos), confirmar, rechazar y registrar devoluciones,
  con motivo y 2FA. Cancelar y decidir «no se presentó» piden la causa
  (pasajero, chófer o plataforma), no un importe.

### Orden

Este orden es obligatorio (G4): **`config/ops` completo ANTES de publicar
las apps y ANTES de subir `minAppVersion`**. Una app con pantalla de pago
sin datos de cobro no puede cobrar; y subir `minAppVersion` obliga a
actualizar a una app que tiene que poder cobrar desde el primer minuto.

1. **Índices** (`firebase deploy --only firestore:indexes`): grupo de
   colecciones `payment` (vencimiento y bandejas). Esperar a que estén
   listos.
2. **Functions**. Desde aquí, como **ningún método de pago está activo**,
   `createBooking` responde `payments_unavailable` a TODAS las apps: no se
   pueden hacer reservas nuevas hasta el paso 3. Las reservas ya creadas
   siguen su curso (ver «Reservas existentes»).
3. **`config/ops`**, con `adminUpdateConfig` (motivo, auditoría) o la
   consola, en este orden (valores del responsable; ver «Pasos
   manuales»):
   1. `paymentInstructions.manual_qr` (datos de cobro y QR);
   2. `paymentWindowMinutes`;
   3. `cancellationPolicy`;
   4. por último `paymentMethods.manual_qr: true`: es la clave que
      enciende las reservas. Antes de ponerla, comprobar las otras tres
      (si una no es válida, el sistema hace lo más restrictivo: sin
      método, sin vencimiento o sin retención).
4. **Hosting** (web del pasajero y panel, que van en la misma
   publicación), en cuanto termine el paso 3: la web nueva ya puede cobrar
   y central ya tiene la sección «Pagos» para confirmar. Hasta este paso
   el panel anterior no puede decidir un «no se presentó» (mandaba un
   importe que el servidor ya no acepta: `invalid_request`); cancelar sí
   funciona y cuenta como causa de la plataforma (0 % de retención).
5. **Apps nativas** en las tiendas (pasajero con la pantalla de pago;
   chófer sin cambios de flujo).
6. **`minAppVersion`** en `config/global` = la versión de la app del
   pasajero con pago, cuando esté publicada y disponible en las dos
   tiendas.
7. **Reglas** al final (estado de pago legible por el pasajero dueño y
   el admin; auto-aceptación del chófer solo con pago confirmado).

### Apps antiguas durante el despliegue (H1)

Una app anterior no tiene pantalla de pago: una reserva suya quedaría en
`awaiting_payment` sin que el pasajero supiera que debe pagar. **Desde H1
no pasa**: `createBooking` exige `channel`, que solo mandan las apps con
pantalla de pago, y sin él responde `app_update_required` (la app antigua
muestra «Actualiza la app»), aunque `minAppVersion` aún no esté subido.
Consecuencias:

- **Desde el paso 2, las apps nativas antiguas no pueden reservar** y ven
  «Actualiza la app», aunque la versión nueva aún no esté en las tiendas
  (paso 5). Por eso las apps nuevas deben estar aprobadas y listas para
  publicar **antes** del paso 2, y el paso 5 hacerse lo antes posible.
- Entre los pasos 2 y 3 tampoco reservan las apps nuevas
  (`payments_unavailable`): no se crea nada.
- La web antigua deja de existir en el paso 4 (se sirve la nueva), que va
  justo después del 3; hasta entonces también recibe «Actualiza la app».
- `minAppVersion` (paso 6) sigue haciendo falta: frena también al
  cotizar y en el resto de llamadas que lo comprueban.
- Si aun así quedara una reserva sin pagar, aparece en Pagos →
  «Pendientes de pago» y, con `paymentWindowMinutes`, vence sola sin
  cobrar nada ni ofrecerse a ningún chófer.

Quien cree reservas en el futuro (p. ej. `adminCreateBooking`, D21)
también tiene que mandar `channel`; sin él, `createBooking` no crea nada.

### Conciliación diaria de pagos manuales

Cada día (hora y responsable a decidir), quien tenga acceso al extracto
del banco coteja lo confirmado en el panel contra lo que entró en la
cuenta del día anterior:

1. Panel → Auditoría: escribir en la búsqueda «Pago confirmado» y luego
   «Saldo cobrado» (G2). Cada fila dice la referencia del pago, el número
   de operación del banco, el importe en bolivianos y quién lo registró
   («Pago PRB… · operación … · 120.00 bob · Motivo: …»). Las devoluciones
   son «Devolución registrada», con el importe y la referencia de la
   transferencia de salida.
2. Extracto del banco del mismo día: cada ingreso debe tener su
   confirmación con el **mismo número de operación y el mismo importe**,
   y cada confirmación su ingreso. Cada devolución registrada, su
   transferencia de salida.
3. Diferencias:
   - confirmación sin ingreso: no se borra nada (la auditoría no se
     edita); se escala al responsable con la reserva y la referencia;
   - ingreso sin confirmación: buscar la referencia en Pagos → «Por
     confirmar» o «Pendientes de pago» y confirmarlo con su número de
     operación (vale aunque la reserva haya vencido: se marca fuera de
     plazo y, si ya no se puede reactivar, queda la devolución pendiente);
   - importe distinto: no se confirma (el servidor exige el importe
     exacto); se contacta con el pasajero.
4. Revisar también Pagos → «Devoluciones» y «Saldos»: nada debería quedar
   pendiente más tiempo del que fije el responsable.
5. Anotar la conciliación (fecha, quién, diferencias y qué se hizo) donde
   decida el responsable. El sistema no guarda esta nota.

### Reservas existentes al desplegar

Las reservas creadas antes no tienen estado de pago. **No se ofrecen a
chóferes nuevos** (sin `paid`, ni `acceptBooking`, ni la asignación, ni la
reconciliación). Las que ya tenían chófer siguen su curso: completar no
compara importes (sin estado de pago, A9 no hace nada), y cancelarlas no
retiene ni devuelve nada (`no_payment_state`). Antes del paso 2:
`npm --prefix functions run trips:in-flight` para ver cuántas hay, y
decidir con cada pasajero (central). Las pendientes sin chófer, o se
atienden antes del despliegue o se cancelan desde el panel. Desde el paso
2, el panel solo puede asignar una reserva pendiente con pago confirmado.

### Aviso a los usuarios del piloto

Antes del paso 2, por el canal habitual del piloto (texto a decidir por el
responsable): durante la actualización no se podrán hacer reservas;
después hará falta la app nueva; el pago se hace al pedir el chófer y no
se busca chófer hasta que esté confirmado. No mencionar plazos, importes,
porcentajes de retención ni datos bancarios hasta que estén decididos y
en `config/ops`.

### Pasos manuales (decisiones del responsable; nada de esto lo fija el código)

Todas en `config/ops`. Se editan con `adminUpdateConfig` (motivo,
auditoría) o en la consola. Si faltan, el sistema hace lo más restrictivo:

| Clave | Forma | Si falta o no es válida |
|---|---|---|
| `paymentMethods` | `{ manual_qr?: bool, card?: bool }` | Ningún método: no se puede reservar (`payments_unavailable`). |
| `paymentInstructions.manual_qr` | `{ holderName, bankName?, accountType?, accountNumber?, qrImageUrl? (https), note? }`, con `accountNumber` o `qrImageUrl` | El método manual no se ofrece aunque esté activado. |
| `paymentInstructions.card` | `{ provider: 'stripe' }` (único con código hoy) | La tarjeta no se ofrece. Elegir otro proveedor exige integrarlo antes. |
| `paymentWindowMinutes` | entero, 1 a 10080 | Sin vencimiento automático: central ve los impagos en la bandeja. |
| `cancellationPolicy` | `{ stages: [{ fromStatus: confirmed\|driver_arriving\|driver_arrived\|no_show, percent: 0–100, graceMinutes? }], noShowWaitMinutes? }` | Retención 0 % en todo (`no_policy` / `policy_invalid`); sin `noShowWaitMinutes`, sin botón «no aparece». |

- Datos bancarios y QR: solo los pone el responsable en
  `paymentInstructions.manual_qr`. El repositorio no contiene ninguno.
- Proveedor de tarjeta: sin decidir. Para activarlo hace falta integrar su
  `verifyWebhook` (secreto en Secret Manager), registrar la URL de
  `paymentWebhook` en el proveedor y poner `paymentMethods.card: true`.
- `adminRecordPayment` (cobro manual al completar, de antes) sigue para
  reservas antiguas; con estado de pago responde `use_confirm_payment`
  (Q2): las nuevas solo se cobran con `adminConfirmPayment`.
- Saldos pendientes (importe final mayor que lo pagado, A9): el pasajero
  los paga fuera del sistema y central los registra en Pagos → Saldos
  («Cobrar saldo», `adminCollectBalance`: importe igual al saldo o menor,
  método, número de operación único y motivo; 2FA). Cómo se le pide el
  pago al pasajero es decisión del responsable.
- Textos a revisar antes del paso 3 (decisión del responsable, el código
  no los cambia): la página legal (`lib/features/legal/presentation/pages/
  legal_page.dart`) aún describe el flujo anterior (tarjeta autorizada al
  reservar y cobrada al completar, «la retención se libera», el
  procesador de tarjetas por su nombre); y la página de recogida
  inmediata promete «Asignamos un chófer de inmediato», que ya no es así
  mientras el pago no esté confirmado.

## Identidad (Parte B)

Qué cambia (rama cierre/identidad, B1–B9): reservar exige el correo
verificado (`email_not_verified`) y, si `config/global.legalVersion`
existe, los términos vigentes aceptados (`terms_required`); el rol sale
del custom claim `role` (con respaldo en `users/{uid}.role` durante la
transición); bloquear deshabilita la cuenta en Auth y revoca sus
sesiones; los chóferes y admins pueden activar TOTP y, con
`config/security.mfaEnforced`, quedan obligados; borrar la cuenta y
cambiar o quitar tarjetas exigen un inicio de sesión de menos de 5
minutos y las callables de admin una sesión de menos de
`adminSessionMaxHours` (12 por defecto), ambos con `reauth_required`
(salvo acknowledgeIncident, closeIncident y resolveAlert, para atender un
SOS o una alerta sin esperar; siguen exigiendo rol admin y, con
`mfaEnforced`, segundo factor); el
chófer registra su dispositivo (`registerDriverDevice`, sin bloqueo).

### Pasos manuales previos (consola; decisiones del responsable)

1. **Actualizar a Firebase Authentication with Identity Platform** (cada
   proyecto). Consola de Firebase → Authentication → Settings → «Upgrade».
   TOTP solo existe con Identity Platform. **Coste: NO VERIFICADO**; [Probable]
   Identity Platform cobra por usuario activo al mes por encima de un
   tramo gratuito y los SMS aparte (aquí no se usan SMS). Revisar la página
   de precios de Identity Platform antes de actualizar: es una decisión del
   responsable.
2. **Activar TOTP** (no hay interruptor en la consola; [Probable]). Con el
   Admin SDK (firebase-admin ≥ 11.6.0; functions usa 12.7.0) y credenciales
   del proyecto, desde la máquina de un responsable:

   ```js
   await admin.auth().projectConfigManager().updateProjectConfig({
     multiFactorConfig: {
       providerConfigs: [{ state: 'ENABLED', totpProviderConfig: { adjacentIntervals: 5 } }],
     },
   });
   ```

   `adjacentIntervals` admite 0–10 (5 por defecto): ventanas de 30 s
   aceptadas a cada lado. El segundo factor exige el correo verificado.
3. **Protección contra la enumeración de correos**: ver el apartado de
   abajo (B8).
4. **`config/security`** (solo consola; ningún cliente lo lee ni escribe):
   crear con `mfaEnforced: false` y, si se quiere otro valor que 12,
   `adminSessionMaxHours: <número>`.
5. **`config/global.legalVersion`**: dejarlo SIN crear por ahora (ver
   «Orden de legalVersion»). Los textos de /legal no se tocaron.

### Orden

1. **Functions** (incluye las callables nuevas: syncEmailVerification,
   setUserRole, setUserBlocked, acceptTerms, registerDriverDevice; y los
   cambios de createBooking y de las de admin y pagos).
2. **Backfill de claims, DRY-RUN**: `cd functions && npm run
   backfill:role-claims -- --project <id>`. Revisar la lista.
3. **Backfill real**: lo mismo con `--apply` (en producción, además
   `--i-understand-this-writes-to-production-luxelane-4e7ae`). El claim
   llega con el siguiente token (como mucho en una hora). Las reglas y el
   servidor aceptan mientras el rol de Firestore; cuando el responsable
   confirme el backfill, poner `CLAIM_ONLY = true` en
   functions/src/identity.ts y quitar el respaldo de `getUserRole()` en
   firestore.rules (tarea aparte, con su prueba).
4. **Reglas de Firestore** (ya con el respaldo de la transición).
5. **Apps** (pasajero, chófer y panel). Ver «Apps antiguas».
6. **Alta del segundo factor**: cada chófer y admin entra en Perfil →
   «Verificación en dos pasos» y escanea el QR. La portada del chófer y
   el panel muestran el aviso mientras no lo tengan.
7. **Procedimiento de emergencia escrito y probado** (abajo), **al menos
   dos admins con TOTP activado** y **las pruebas en dispositivos reales
   hechas** (lista de abajo, todas en staging).
8. **`config/security.mfaEnforced: true`** desde la consola. Desde ese
   momento las callables de admin y del viaje del chófer (acceptBooking,
   advanceBooking, verifyPickup) y las escrituras de admin en las reglas
   exigen el segundo factor (`mfa_required`).

### Orden de legalVersion

`config/global.legalVersion` es lo que obliga a aceptar los términos para
reservar. Crearlo antes de tiempo deja sin reservar a quien tenga una app
que no sabe pedir la aceptación, o hace aceptar textos sin revisar. Solo
cuando se cumplan las dos condiciones, en este orden:

1. **Apps publicadas** con la aceptación (casilla en el registro y diálogo
   «Acepta los términos para reservar») en las tiendas y en la web, y
   `minAppVersion` subido a esa versión (decisión del responsable): una
   app anterior no sabe mostrar `terms_required`.
2. **Textos revisados por el abogado** y publicados en /legal/terminos y
   /legal/privacidad.
3. Entonces, crear `config/global.legalVersion` con un texto corto que
   identifique esa versión (p. ej. la fecha de publicación). Desde ese
   momento, cada pasajero acepta una vez al registrarse o en su siguiente
   reserva; las cuentas quedan con `terms.version`, la hora del servidor y
   la versión de la app.
4. Al cambiar los textos más adelante: publicar los nuevos y después
   cambiar `legalVersion`; todos vuelven a aceptar.

### Pruebas en dispositivos reales antes de activar mfaEnforced

Ninguna de estas se puede hacer con los emuladores ni con las pruebas
automáticas (el SDK nativo y la app autenticadora son reales). Hacerlas en
**staging**, con un Android, un iPhone y un navegador de escritorio, y una
app autenticadora real (cualquiera compatible con TOTP), y anotar el
resultado de cada una:

1. **Alta de TOTP en el móvil**: chófer y admin, Perfil → «Verificación en
   dos pasos»; escanear el QR o usar «Abrir en la app autenticadora»;
   escribir el código; el aviso de la portada desaparece.
2. **Alta de TOTP en la web**: admin en el panel web; QR en pantalla y
   clave para escribirla a mano (en web no se abre la app); código
   aceptado.
3. **Segundo paso al iniciar sesión**: cerrar sesión y entrar con
   contraseña en móvil y en web: pide el código; un código incorrecto da
   un mensaje claro; el correcto entra. Repetir con «Continuar con
   Google» en una cuenta con TOTP.
4. **Hora del teléfono**: con la hora automática, el código entra al
   primer intento; anotar si falla con unos segundos de desfase.
5. **Reautenticación con contraseña**: en una cuenta de pasajero, quitar
   una tarjeta más de 5 minutos después de entrar: aparece «Confirma que
   eres tú», y tras la contraseña se puede repetir.
6. **Reautenticación con Google**: lo mismo con una cuenta de Google en
   Android, iPhone y web (en web, ventana emergente).
7. **Reautenticación con TOTP**: admin con TOTP y sesión de más de
   `adminSessionMaxHours` (bajar el valor a 1 en staging para probar):
   una acción del panel pide la contraseña y después el código; atender un
   SOS o resolver una alerta no lo pide.
8. **Eliminar la cuenta** con una sesión de más de 5 minutos: pide
   confirmar y luego elimina.
9. **Bloqueo y desbloqueo**: bloquear un chófer conectado desde el panel:
   su app sale en menos de una hora (al renovar el token) o al instante si
   intenta escribir; no puede volver a entrar («cuenta bloqueada»);
   desbloquear y comprobar que entra.
10. **Recuperación con reset_mfa**: en una cuenta de prueba con TOTP,
    borrar la entrada de la app autenticadora (simula el teléfono
    perdido), ejecutar `reset_mfa` en DRY-RUN y con `--apply`, comprobar
    que la sesión abierta se cierra, que entra solo con la contraseña, que
    puede dar de alta TOTP de nuevo y que admin_logs tiene `reset_mfa`.
11. **Imposición en staging**: con `mfaEnforced: true`, un admin sin TOTP
    recibe el aviso al usar el panel y un chófer sin TOTP no puede
    aceptar viajes; con TOTP, todo funciona. Volver a `false` y comprobar
    que se levanta.

### pricingRules sin `updatedBy` (C3)

Las reglas nuevas rechazan `updatedBy` en pricingRules (era el uid del
admin, a la vista de cualquiera). El panel anterior lo sigue enviando, así
que el orden importa:

1. Publicar el panel nuevo (ya no lo escribe).
2. Desplegar las reglas.
3. `cd functions && npm run migrate:pricing-updated-by -- --project <id>
   --operator "<quién>"` (DRY-RUN); revisar la lista y repetir con
   `--apply` (en producción, además
   `--i-understand-this-writes-to-production-luxelane-4e7ae`). Deja una
   entrada en admin_logs por documento, con el uid anterior.

### Procedimiento de emergencia (antes de activar mfaEnforced)

Importante: una cuenta con el segundo factor dado de alta lo necesita para
**entrar**, esté `mfaEnforced` como esté (lo pide Firebase al iniciar
sesión; [Probable]). Poner `mfaEnforced: false` solo ayuda a quien aún no
dio de alta su factor; a quien perdió el teléfono solo lo saca
`scripts/reset_mfa.mjs` (o la consola).

**Requisitos antes de activar mfaEnforced**

- Al menos dos admins con TOTP activado y probado (que hayan entrado con el
  código).
- Un responsable con acceso de propietario al proyecto (Google Cloud IAM)
  y credenciales en su máquina (`gcloud auth application-default login`):
  es quien ejecuta `reset_mfa` y `promote_admin`. No depende del panel.
- Decidir cómo se confirma la identidad de quien pide el reinicio (por
  ejemplo, llamada al número registrado o en persona). **Decisión del
  responsable; no está definida.** El método usado se escribe en
  `--reason` y queda en admin_logs.

**Un admin pierde el teléfono**

1. Otro admin (o el responsable) confirma su identidad por el método
   acordado.
2. El responsable ejecuta, desde su máquina:
   `node scripts/reset_mfa.mjs --project <id> --email <correo>
   --reason "perdió el teléfono; identidad confirmada por <método>"
   --operator "<quién>"` (DRY-RUN) y, si la salida es la esperada, lo
   mismo con `--apply` (en producción, además
   `--i-understand-this-writes-to-production-luxelane-4e7ae`).
3. El script quita los factores, revoca sus sesiones (también la del
   teléfono perdido) y deja `reset_mfa` en admin_logs.
4. El admin entra con su contraseña y da de alta TOTP de nuevo (Perfil →
   «Verificación en dos pasos»). Mientras no lo haga, con `mfaEnforced`
   las acciones de admin le responden `mfa_required`.
5. Si se sospecha que el teléfono está en manos de otra persona: además,
   cambiar su contraseña desde la consola (Authentication → Users).

**Los dos admins pierden el teléfono**

1. Nadie puede entrar al panel. El responsable con acceso al proyecto
   ejecuta `reset_mfa` para uno de ellos (pasos 2–4 de arriba).
2. Sin credenciales en ninguna máquina: en la consola de Firebase →
   Authentication → Users → la cuenta → quitar el segundo factor
   (NO VERIFICADO el menú exacto) y anotar a mano en admin_logs lo hecho.
3. Ese admin entra, da de alta TOTP de nuevo y repite con el segundo
   admin (o con `promote_admin` si hace falta otro).
4. Mientras tanto, los incidentes (SOS) no tienen quién los atienda desde
   el panel: avisar a quien esté de guardia por teléfono (D23).

**Un chófer pierde el teléfono**

1. Central confirma su identidad por el método acordado. Si el teléfono
   puede estar en manos de otra persona, bloquear la cuenta primero
   (panel → usuarios → bloquear): deshabilita la cuenta, revoca sesiones y
   lo saca de disponibles.
2. El responsable ejecuta `reset_mfa` con su correo (como arriba).
3. Si se bloqueó, desbloquearlo desde el panel.
4. El chófer entra en su teléfono nuevo con su contraseña y da de alta
   TOTP de nuevo. Su dispositivo nuevo llegará como alerta «Chófer en un
   dispositivo nuevo»: es lo esperado; resolverla con una nota.
5. Hoy no hay botón en el panel para esto: lo hace el responsable con el
   script. Si los reinicios son frecuentes, una callable de admin con
   auditoría sería el siguiente paso (no hecho).

**Otros casos**

- **Hace falta un admin nuevo**: `node scripts/promote_admin.mjs
  --project <id> --email <correo> --reason "<motivo>" --operator "<quién>"`
  (DRY-RUN), y luego con `--apply`.
- **Sesión de admin vencida** (`reauth_required` tras
  `adminSessionMaxHours`): no es una emergencia; el panel pide confirmar
  la identidad. Atender SOS y alertas no lo pide (C1).
- **Volver atrás con la imposición**: `config/security.mfaEnforced: false`
  en la consola de Firestore (el servidor lo lee en cada llamada y las
  reglas en cada escritura). No quita factores a nadie.

### Apps antiguas

- Una app sin esta versión no sabe mostrar `reauth_required`,
  `mfa_required`, `email_not_verified` ni `terms_required`: verá un
  error genérico. Subir `minAppVersion` / `minDriverAppVersion` cuando las
  apps nuevas estén publicadas (decisión del responsable; no se sube
  ahora).
- Un admin con el panel anterior no puede cambiar roles ni bloquear: las
  reglas ya no le dejan escribir `role` ni `isActive`; necesita el panel
  nuevo (usa setUserRole y setUserBlocked).

### Protección contra la enumeración de correos (B8)

La app ya no dice si un correo tiene cuenta: entrar con un correo que no
existe y con una contraseña incorrecta da el mismo mensaje, recuperar la
contraseña responde igual haya cuenta o no, y el registro no confirma que
el correo esté en uso. Para que la API de Firebase tampoco lo revele, hay
que activar su protección (en cada proyecto: staging y producción):

1. Consola de Firebase → Authentication → Settings → User actions.
2. Activar «Email enumeration protection».
3. Guardar.

NO VERIFICADO: el nombre exacto de la opción en la consola actual, y si
con la protección activa `createUserWithEmailAndPassword` sigue
devolviendo `email-already-in-use` (la app ya lo muestra con un texto
neutro). También NO VERIFICADO si Auth responde `user-disabled` antes de
comprobar la contraseña (una cuenta bloqueada se distinguiría de una
inexistente); la app muestra en ese caso el mensaje de cuenta bloqueada.

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
RECAPTCHA_SITE_KEY      → clave del sitio de reCAPTCHA v3 para App Check en la web (ver «Endurecimiento»)
FIREBASE_ANDROID_APP_ID  → google-services.json → mobilesdk_app_id (ver «Claves de Firebase de las apps nativas»)
FIREBASE_ANDROID_API_KEY → google-services.json → api_key[0].current_key
FIREBASE_IOS_APP_ID      → GoogleService-Info.plist → GOOGLE_APP_ID
FIREBASE_IOS_API_KEY     → GoogleService-Info.plist → API_KEY
GOOGLE_SERVER_CLIENT_ID → OAuth "Web client" del proyecto (Google Sign-In en Android)
GOOGLE_IOS_CLIENT_ID    → GoogleService-Info.plist → CLIENT_ID
ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD,
ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD → ver «Firma de Android»
```
`STRIPE_SECRET_KEY` y `PICKUP_CODE_SECRET` no van en GitHub: viven en
Secret Manager (First-time Setup, pasos 3 y 4).

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
