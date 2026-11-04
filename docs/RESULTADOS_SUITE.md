# Resultados de la suite

Tablas en texto plano (bloque de código) para que se lean igual en un
adjunto. Cada fila es la salida real del comando; nada resumido a mano.
Todo contra los emuladores con el proyecto ficticio `demo-luxelane`.

## cierre/ventana-chofer, Parte B (B1–B4, commit fa7ef65, 2026-11-04)

Sobre la Parte A (2fc95a1). Emuladores de Firestore, Storage y Auth con
`demo-luxelane`; reglas e integración sin las variables de proxy de la sesión.
Historial, importes y reservas de las pruebas: FICTICIOS. Trinquete de textos
fijos: 0 (trinquete y vigilados).

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           108 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           337 archivos, 0 cambiados       0
flutter test                                  pasa           1076/1076                       0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           756/756 (35 de 35 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (Firestore+Storage)        pasa           3832/3832 (29 de 29 suites)     0
npm run test:integration (demo-luxelane)      pasa           503/503 (53 de 53 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
Capturas de la ventana del chófer             pasa           60/60                           —
```

### Reglas anteriores con los tests nuevos

La Parte B no cambia las reglas. `firestore.rules` de c3854f8 con los tests
de fa7ef65, código de salida 1: los mismos 38 fallos que en la Parte A (lista
literal arriba, en la Parte A).

```
Test Suites: 2 failed, 27 passed, 29 total
Tests:       38 failed, 3794 passed, 3832 total
```

### Tests nuevos sin el cambio de su tarea

```
Tarea                                      Test                                                Sin el cambio
B1 ganancias desde driverHistory           driver_earnings_screen_test, driver_history_test    no compilan (history)
B2 X del detalle de la reserva             booking_detail_close_test                           2 fallan
B4 DEPLOY.md de la ventana del chófer      deploy_config.test.ts (sección «Ventana»)           falla
Enlace node_modules fuera del repositorio  deploy_config.test.ts («repositorio limpio»)        falla (en 2fc95a1)
```

## cierre/ventana-chofer, Parte A (A1–A6, commit a973dfb, 2026-11-04)

Desde cierre/integracion c3854f8. Emuladores de Firestore, Storage y Auth con
`demo-luxelane`; reglas e integración sin las variables de proxy de la sesión.
Reservas, chóferes, importes y política de las pruebas: FICTICIOS.

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           108 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           335 archivos, 0 cambiados       0
flutter test                                  pasa           1060/1060                       0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           753/753 (35 de 35 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (Firestore+Storage)        pasa           3832/3832 (29 de 29 suites)     0
npm run test:integration (demo-luxelane)      pasa           503/503 (53 de 53 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
```

### Reglas anteriores con los tests nuevos

`firestore.rules` de c3854f8 con los tests de a973dfb, `RULES_PATH=<reglas
anteriores> firebase emulators:exec --only firestore,storage --project
demo-luxelane "jest --runInBand --verbose"`, código de salida 1. Fallan
exactamente las celdas que cambian: el chófer asignado deja de leer las
reservas terminadas, canceladas o «no se presentó» y sus subcolecciones, la
consulta sin filtro de estado se rechaza, y `driverHistory` se abre al chófer
dueño y al admin.

```
Test Suites: 2 failed, 27 passed, 29 total
Tests:       38 failed, 3794 passed, 3832 total

● bookings/{id} · cancelled › asig › leer
● bookings/{id} · cancelled › asig › listar
● bookings/{id} · completed › asig › leer
● bookings/{id} · completed › asig › listar
● bookings/{id} · liberada › asig › listar
● bookings/{id} · no_show › asig › leer
● bookings/{id} · no_show › asig › listar
● bookings/{id}/driverContact · cancelled › asig › leer
● bookings/{id}/driverContact · cancelled › asig › listar
● bookings/{id}/driverContact · completed › asig › leer
● bookings/{id}/driverContact · completed › asig › listar
● bookings/{id}/driverContact · no_show › asig › leer
● bookings/{id}/driverContact · no_show › asig › listar
● bookings/{id}/events · cancelled › asig › leer
● bookings/{id}/events · cancelled › asig › listar
● bookings/{id}/events · completed › asig › leer
● bookings/{id}/events · completed › asig › listar
● bookings/{id}/events · no_show › asig › leer
● bookings/{id}/events · no_show › asig › listar
● bookings/{id}/tracking · cancelled › asig › leer
● bookings/{id}/tracking · cancelled › asig › listar
● bookings/{id}/tracking · completed › asig › leer
● bookings/{id}/tracking · completed › asig › listar
● bookings/{id}/tracking · no_show › asig › leer
● bookings/{id}/tracking · no_show › asig › listar
● consultas del chófer sobre sus reservas › la consulta antigua (solo driverId, sin estado) se rechaza entera: la app anterior deja de ver sus viajes
● consultas del chófer sobre sus reservas › pedir sus reservas terminadas por consulta se rechaza
● driverHistory/{uid}/trips › admin › leer
● driverHistory/{uid}/trips › admin › listar
● driverHistory/{uid}/trips › asig › leer
● driverHistory/{uid}/trips › asig › listar
● driverHistory/{uid}/trips › bloq › leer
● driverHistory/{uid}/trips › bloq › listar
● driverHistory/{uid}/trips › el admin lo lee
● driverHistory/{uid}/trips › el chófer dueño lee y lista su historial, del más reciente al más antiguo
● fuera de la ventana › asignado y activo: no lee la reserva cancelled ni sus eventos
● fuera de la ventana › asignado y activo: no lee la reserva completed ni sus eventos
● fuera de la ventana › asignado y activo: no lee la reserva no_show ni sus eventos
```

## cierre/integracion tras fusionar cierre/vuelos (commit 44bbb52, 2026-11-04)

`git merge --no-ff cierre/vuelos` sobre c0b38fe con el worktree limpio, sin
conflictos (cierre/vuelos salía de c0b38fe). Incluye la revisión de la
Parte B: test de paridad de aeropuertos servidor/app (5920b08), auditoría
con la decisión 4 diferida y los pendientes (e05a094), «Cancelar reserva» a
48 px con test (c53fdbd: ya medía 48; los 27 px eran la captura cortada) y
la auditoría de capturas (5892e8d). Emuladores con `demo-luxelane`; reglas e
integración sin las variables de proxy de la sesión. Datos de prueba
FICTICIOS.

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           108 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           331 archivos, 0 cambiados       0
flutter test                                  pasa           1047/1047                       0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           746/746 (34 de 34 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (Firestore+Storage)        pasa           1976/1976 (28 de 28 suites)     0
npm run test:integration (demo-luxelane)      pasa           488/488 (52 de 52 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
```

actionlint no está instalado en la sesión.

## cierre/vuelos, Parte B (B1–B7, commit 7b4e3c9; app final c2544d9, 2026-11-04)

Desde la Parte A (961531f) con el panel de vuelos (a168f85, traído con
cherry-pick). Emuladores de Firestore, Storage y Auth con `demo-luxelane`;
reglas e integración sin las variables de proxy de la sesión. Aeropuerto,
punto de recogida, minutos de config/ops y vuelos de las pruebas: FICTICIOS.

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           107 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           329 archivos, 0 cambiados       0
flutter test                                  pasa           1042/1042                       0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           743/743 (33 de 33 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (Firestore+Storage)        pasa           1976/1976 (28 de 28 suites)     0
npm run test:integration (demo-luxelane)      pasa           488/488 (52 de 52 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
```

Después, c2544d9 (selector de tipo de vuelo a 48 px, hallazgo de las
capturas) solo toca la app; repetido sobre c2544d9:

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           108 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           330 archivos, 0 cambiados       0
flutter test                                  pasa           1044/1044                       0
```

Capturas (`tools/experiencia/capturas_vuelos.cjs`): 126 de 126 «ok»
(docs/capturas/vuelos/HALLAZGOS.md).

### Reglas anteriores con los tests nuevos

La Parte B no cambia `firestore.rules` ni `storage.rules`. `firestore.rules`
de c0b38fe (antes de vuelos) con los tests de 7b4e3c9, código de salida 1:
los mismos 32 fallos que en la Parte A (las reglas de `airports` y
`airportsPublic` no existían).

```
Test Suites: 2 failed, 26 passed, 28 total
Tests:       32 failed, 1944 passed, 1976 total
```

### Tests nuevos sin el cambio de su tarea

```
Tarea                                   Test                                               Sin el cambio
B4 nota del vuelo en el diseño ancho    ride_and_request_flight_test (768 y 1280 px)       2 fallan
B5 solicitud con aeropuerto y tipo      ride_and_request_flight_test (es, en, pt)          3 fallan
B4 selector de vuelo a 48 px            flight_type_selector_test (texto x1 y x2)          2 fallan
B6 frases prohibidas de vuelos          frases_prohibidas_test («on time» en inglés)       falla
B7 DEPLOY.md de vuelos                  deploy_config.test.ts (sección «Vuelos»)           falla
```

## cierre/vuelos, Parte A (A1–A10, commit 46bb704, 2026-11-03)

Desde cierre/integracion c0b38fe. Emuladores de Firestore, Storage y Auth con
`demo-luxelane`; reglas e integración sin las variables de proxy de la sesión.
Minutos de salida, espera, tarifas, recargo nocturno, aeropuertos y vuelos de
las pruebas: FICTICIOS.

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           108 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           312 archivos, 0 cambiados       0
flutter test                                  pasa           944/944                         0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           729/729 (32 de 32 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (Firestore+Storage)        pasa           1976/1976 (28 de 28 suites)     0
npm run test:integration (demo-luxelane)      pasa           468/468 (50 de 50 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
```

### Reglas anteriores con los tests nuevos

`firestore.rules` de c0b38fe con los tests de 46bb704, código de salida 1:

```
Test Suites: 2 failed, 26 passed, 28 total
Tests:       32 failed, 1944 passed, 1976 total

● aeropuertos y caché › airports: con sesión se lee; sin sesión, no; nadie escribe desde el cliente
● aeropuertos y caché › airportsPublic: lo lee cualquiera, nadie lo escribe
● airports/{code} › admin|ana|asig|beto|bloq|libre|nover › leer y listar (14)
● airportsPublic/{code} › admin|ana|anon|asig|beto|bloq|libre|nover › leer y listar (16)
```

## cierre/integracion tras fusionar cierre/registro-chofer (commit 005f5a9, 2026-11-03)

Fusión `git merge --no-ff cierre/registro-chofer` (hasta ad7110b: Partes A,
A10 y B, con los tres cambios de la aprobación) en un worktree limpio, sin
conflictos. Emuladores de Firestore, Storage y Auth con `demo-luxelane`.

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           108 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           312 archivos, 0 cambiados       0
flutter test                                  pasa           944/944                         0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           652/652 (30 de 30 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (Firestore+Storage)        pasa           1851/1851 (27 de 27 suites)     0
npm run test:integration (demo-luxelane)      pasa           440/440 (48 de 48 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
```

Las reglas de esta rama (Firestore y Storage) no se despliegan hasta publicar
las apps (DEPLOY.md, «Registro de chóferes»).

## cierre/registro-chofer, Parte B (B0–B5, commit 42ed8c2, 2026-11-03)

Sobre A10 (a0d596b). Flutter 3.29.3, Node 22, emuladores de Firestore, Storage
y Auth con `demo-luxelane`; reglas e integración sin las variables de proxy de
la sesión. Dependencias nuevas con versión fija: firebase_storage 12.4.10,
image_picker 1.2.1, flutter_image_compress 2.4.0.

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           108 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           312 archivos, 0 cambiados       0
flutter test                                  pasa           939/939                         0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           652/652 (30 de 30 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (Firestore+Storage)        pasa           1851/1851 (27 de 27 suites)     0
npm run test:integration (demo-luxelane)      pasa           440/440 (48 de 48 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
capturas del registro (B4)                    170 de 180     10 al 200 % no capturadas       —
```

`flutter test` en la suite completa (commit c751f83) dio `+938 -1: Some tests
failed`: `mapas_ficticios_test.dart` («ningún archivo de lib/ importa ni nombra
el MapsService ficticio») por un comentario de `image_prep.dart` que nombraba
el entorno de capturas. Corregido en 42ed8c2; repetido: `01:50 +939: All tests
passed!`. analyze y format, repetidos tras la corrección: 108 issues, 0
cambiados. El resto de filas son de c751f83 (la corrección solo cambia un
comentario).

La Parte B no cambia `firestore.rules` ni `storage.rules` (sin celdas nuevas en
la matriz): las reglas anteriores son las mismas y dan el mismo resultado que
arriba.

## cierre/registro-chofer, A10 (alta del aspirante, commit 67ad375, 2026-10-31)

Sobre la Parte A (796b748). Emuladores de Firestore, Storage y Auth con
`demo-luxelane`; reglas e integración sin las variables de proxy de la sesión.

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           109 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           290 archivos, 0 cambiados       0
flutter test                                  pasa           854/854                         0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           633/633 (30 de 30 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (Firestore+Storage)        pasa           1851/1851 (27 de 27 suites)     0
npm run test:integration (demo-luxelane)      pasa           436/436 (48 de 48 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
```

### Los tests nuevos fallan sin el cambio

Reglas de 796b748 (Firestore y Storage) con los tests de 67ad375, código de
salida 1:

```
Test Suites: 5 failed, 22 passed, 27 total
Tests:       13 failed, 1838 passed, 1851 total

● alta y activación de /vehicles › el aspirante sin verificar no crea su vehículo desde el cliente; el verificado sí, inactivo
● aspirante sin verificar (A10) › no crea su perfil de chófer desde el cliente (lo crea el servidor)
● aspirante sin verificar (A10) › no registra ni cambia vehículos desde el cliente; el chófer verificado sí cambia color y foto
● aspirante sin verificar (A10) › no se pone en línea ni cambia licencia, vehículo o ubicación; sí puede quedar fuera de línea
● campos del perfil del chófer (A8.5) › el alta no se hace desde el cliente
● chófer verificado con isActive == false › su perfil (H10) › no crea un perfil nuevo
● driverProfiles/{uid} › asig › crear
● driverProfiles/{uid} › libre › crear
● driverProfiles/{uid} › nover › crear
● licencia tras la verificación (H4) › antes de verificar, el aspirante no corrige licenseExpiry desde el cliente
● licencia tras la verificación (H4) › antes de verificar, el aspirante no corrige licenseNumber desde el cliente
● licencia tras la verificación (H4) › antes de verificar, el aspirante no corrige vehicleId desde el cliente
● vehicles/{id} › nover › crear
```

storage.rules de 796b748 con test/storage.rules.ts de 67ad375, código de salida 1:

```
✕ versión máxima 20: la 20 entra, la 21 no
Tests:       1 failed, 10 passed, 11 total
```

Servidor sin el rechazo `driver_account` (función vaciada a mano, restaurada
después), driver_start.int.ts, código de salida 1:

```
✕ ensureStripeCustomer y listPaymentMethods rechazan a un chófer, aunque tuviera cliente de cuando era pasajero
Expected: "driver_account"
Received: "ok"
Tests:       1 failed, 9 passed, 10 total
```

Los demás tests de driver_start.int.ts no compilan sin `startDriverApplication`;
el de índices (deploy_config.test.ts) y el caso `version: 21` de
callable_schemas.test.ts fallan sin sus cambios (la entrada no existía y el
esquema admitía hasta 999 999). cancel_booking.int.ts: arreglo de un test
intermitente, sin test que falle de forma determinista.

## cierre/registro-chofer, Parte A (A1–A9, commit 1821d5b, 2026-10-31)

Desde cierre/integracion 0c8d1c8 (con idiomas y preferencias). Flutter
3.29.3, Node 22, emuladores de Firestore, Storage y Auth con `demo-luxelane`.
Reglas e integración se ejecutan sin las variables de proxy de la sesión
(`env -u HTTPS_PROXY ...`): con ellas, las reglas de Storage no llegan al
emulador de Firestore (`firestore.get` devuelve null).

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           109 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           290 archivos, 0 cambiados       0
flutter test                                  pasa           854/854                         0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           624/624 (30 de 30 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (Firestore+Storage)        pasa           1847/1847 (27 de 27 suites)     0
npm run test:integration (demo-luxelane)      pasa           426/426 (47 de 47 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
```

La Parte A no toca Flutter (el número de tests de Flutter no cambia). En una
ejecución anterior de integración en esta rama falló una vez
`cancel_booking.int.ts` (test preexistente, intermitente: depende de que la
marca de tiempo contenga «7299»); en esta ejecución pasa. No se ha corregido.

### Reglas anteriores con los tests nuevos

`firestore.rules` de 0c8d1c8 y Storage cerrado (`allow read, write: if
false`, lo que equivale a no tener reglas) con los tests de 1821d5b, código
de salida 1:

```
Test Suites: 3 failed, 24 passed, 27 total
Tests:       23 failed, 1824 passed, 1847 total

● bloqueo en línea por documentos vencidos (docsBlocked) › bloqueado no acepta una reserva pagada
● bloqueo en línea por documentos vencidos (docsBlocked) › sin bloqueo se pone en línea; con bloqueo, no
● driverApplications › el chófer lee su estado y el motivo de rechazo, no sus datos personales ni las rutas
● driverApplications › otro chófer o un pasajero no la leen; el admin sí
● driverApplications/{uid} › admin › leer
● driverApplications/{uid} › admin › listar
● driverApplications/{uid} › bloq › leer
● driverApplications/{uid} › nover › leer
● driverApplications/{uid}/documentFiles › admin › leer
● driverApplications/{uid}/documentFiles › admin › listar
● driverApplications/{uid}/documents › admin › leer
● driverApplications/{uid}/documents › admin › listar
● driverApplications/{uid}/documents › bloq › leer
● driverApplications/{uid}/documents › bloq › listar
● driverApplications/{uid}/documents › nover › leer
● driverApplications/{uid}/documents › nover › listar
● driverApplications/{uid}/private › admin › leer
● driverApplications/{uid}/private › admin › listar
● driverDocAccessLogs/{id} › admin › leer
● driverDocAccessLogs/{id} › admin › listar
● driverDocs/{uid}/{tipo}/{versión} › el chófer dueño sube su documento
● driverDocs/{uid}/{tipo}/{versión} › el dueño no sobrescribe, no lee y no borra
● driverDocs/{uid}/{tipo}/{versión} › tipo de archivo no permitido
```

## cierre/integracion tras fusionar cierre/preferencias, Parte B (commit 43f0e67, 2026-10-31)

Fusión `git merge --no-ff cierre/preferencias` (hasta c74300d) en un
worktree limpio, sin conflictos.

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           109 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           290 archivos, 0 cambiados       0
flutter test                                  pasa           854/854                         0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           557/557 (30 de 30 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (demo-luxelane)            pasa           1631/1631 (25 de 25 suites)     0
npm run test:integration (demo-luxelane)      pasa           402/402 (46 de 46 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
```

actionlint: la descarga del binario no se permitió en este entorno; ci.yml
no cambia.

## cierre/preferencias, Parte B (B0–B6, commit ca6aa15, 2026-10-31)

Desde cierre/integracion 4e3000a (con idiomas). Flutter 3.29.3, Node 22,
emuladores con `demo-luxelane`.

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           109 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           290 archivos, 0 cambiados       0
flutter test                                  pasa           854/854                         0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           557/557 (30 de 30 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (demo-luxelane)            pasa           1631/1631 (25 de 25 suites)     0
npm run test:integration (demo-luxelane)      pasa           402/402 (46 de 46 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
capturas de preferencias (B5)                 34 de 36       panel a 390 px sin capturar     —
```

La Parte B no cambia `firestore.rules`. Trinquete de textos fijos en 0.

### Reglas anteriores con los tests nuevos

`firestore.rules` de 5443ec1 (antes de preferencias) con los tests de
ca6aa15, código de salida 1:

```
Test Suites: 3 failed, 22 passed, 25 total
Tests:       19 failed, 1612 passed, 1631 total

● bookings/{id}/driverView › admin › leer
● bookings/{id}/driverView › admin › listar
● bookings/{id}/driverView › ana › leer
● bookings/{id}/driverView › ana › listar
● bookings/{id}/driverView › asig › leer
● bookings/{id}/driverView › asig › listar
● copia por reserva: … › chófer asignado y activo, etapa confirmed: la lee
● copia por reserva: … › chófer asignado y activo, etapa driver_arrived: la lee
● copia por reserva: … › chófer asignado y activo, etapa driver_arriving: la lee
● copia por reserva: … › chófer asignado y activo, etapa in_progress: la lee
● copia por reserva: … › chófer asignado y activo, etapa verified: la lee
● copia por reserva: … › el admin la lee
● copia por reserva: … › el pasajero dueño la lee en cualquier etapa; otro pasajero, nunca
● perfil: tripPreferences no se escribe desde el cliente › el alta no trae tripPreferences
● perfil: tripPreferences no se escribe desde el cliente › el dueño no cambia las ridePreferences antiguas
● perfil: tripPreferences no se escribe desde el cliente › el dueño no las cambia
● users/{uid}.locale no se escribe desde el cliente › el alta no trae idioma
● users/{uid}.locale no se escribe desde el cliente › el chófer tampoco
● users/{uid}.locale no se escribe desde el cliente › el pasajero no cambia su idioma directo
```

### Tests nuevos sin el cambio de su tarea

```
Tarea                     Archivo de tests                          Sin el cambio
B0a deleteAccount         delete_account.int.ts                     1 de 2 falla
B0b modelo y perfil       trip_preferences_test, profile_prefs_bloc no compilan sin el modelo
B0c tarjeta del chófer    driver_preferences_card_test.dart         no compila sin el widget
B1 perfil                 preferences_screen_test.dart              2 fallan (fila del perfil); resto no compila
B1 reserva y viaje        booking_preferences_test, ride_prefs      5 fallan; el de viaje no compila
B1 limpieza               auth_state_preferences_test.dart          no compila sin el campo
B2 idiomas en solicitud   open_request_languages_test.dart          no compila sin el campo
B2 nada en push           i18n.test.ts (2)                          prueba nueva (guarda)
B3 panel                  admin_booking_preferences_test.dart       1 de 6 falla; sin el widget no compila
Panel en español          locale_test.dart, idioma_test.dart        no compila / 1 falla
B4 frases prohibidas      frases_prohibidas_test.dart               prueba nueva (casos sintéticos)
B5 200 % y lector         preferencias_accesibilidad_test.dart      9 de 18 fallan
```

## cierre/integracion tras fusionar cierre/idiomas (commit 98f464d, 2026-10-31)

Fusión `git merge --no-ff cierre/idiomas` (hasta 4eefcf0, con la corrección
de textos en inglés en la versión en español) en un worktree limpio, sin
conflictos.

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           109 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           273 archivos, 0 cambiados       0
flutter test                                  pasa           783/783                         0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           555/555 (30 de 30 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (demo-luxelane)            pasa           1631/1631 (25 de 25 suites)     0
npm run test:integration (demo-luxelane)      pasa           400/400 (45 de 45 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
```

actionlint: la descarga del binario no se permitió en este entorno; ci.yml
no cambia.

### Corrección 4eefcf0 sin el cambio

```
Tarea                     Archivo de tests                          Sin el cambio
Inglés en el español      sin_ingles_en_espanol_test.dart           2 de 3 fallan
```

## cierre/idiomas, Parte B (B1–B7, commit 5d01638, 2026-10-31)

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           109 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           272 archivos, 0 cambiados       0
flutter test                                  pasa           780/780                         0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           555/555 (30 de 30 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (demo-luxelane)            pasa           1631/1631 (25 de 25 suites)     0
npm run test:integration (demo-luxelane)      pasa           400/400 (45 de 45 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
capturas por idioma (B5)                      pasa           126/126                         0
```

analyze baja de 121 a 109 avisos informativos: desaparecen `prefer_const`
de widgets que tenían textos fijos; ninguno nuevo (listas comparadas).
La Parte B no cambia `firestore.rules` ni functions: la salida de las
reglas anteriores con los tests nuevos es la de la Parte A (abajo).

Trinquete de textos fijos: 1180 → 0 (apps del pasajero y del chófer) y
278 → 0 (vigilados: core y app); 108 `i18n-ignore` con motivo.

### Tests nuevos sin el cambio de su tarea

```
Tarea                     Archivo de tests                          Sin el cambio
B1 autenticación          bloque_auth_test.dart                     12 de 12 fallan
B1 inicio y servicios     bloque_inicio_test.dart                   falla (6 de 6 en su versión de 6)
B1 reserva                bloque_reserva_test.dart                  3 de 3 fallan
B1 pago y comprobante     bloque_pagos_test.dart                    6 de 6 fallan
B1 viaje / incidentes     bloque_viaje_test.dart                    fallan en los dos bloques
B1 Mis viajes/perfil/av.  bloque_perfil_test.dart                   4 / 6 / 4 fallan
B1 chófer                 bloque_chofer_test.dart                   6 de 6 fallan
B1 comunes y errores      bloque_comunes_test.dart                  6 fallan
B1 textos compartidos     textos_compartidos_test.dart              falla (const en español)
B1.0 formato              formato_test.dart                         no compila sin el cambio
B2 aviso legal            legal_aviso_test.dart                     2 de 3 fallan
B4 texto grande           texto_grande_idiomas_test.dart            falla sin cada arreglo
B4 frases prohibidas      frases_prohibidas_test.dart               prueba nueva (casos sintéticos)
```

## cierre/idiomas, Parte A (A1–A7, commit c9e8a1c, 2026-10-30)

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           121 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           257 archivos, 0 cambiados       0
flutter test                                  pasa           639/639                         0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           555/555 (30 de 30 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (demo-luxelane)            pasa           1631/1631 (25 de 25 suites)     0
npm run test:integration (demo-luxelane)      pasa           400/400 (45 de 45 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
```

actionlint: la descarga del binario no se permitió en este entorno; ci.yml
no cambia. Los 121 avisos de analyze son los mismos que en cierre/integracion.

### Reglas anteriores con los tests nuevos

`firestore.rules` de c585305 con los tests de c9e8a1c, código de salida 1:

```
Test Suites: 1 failed, 24 passed, 25 total
Tests:       3 failed, 1628 passed, 1631 total

● users/{uid}.locale no se escribe desde el cliente › el alta no trae idioma
● users/{uid}.locale no se escribe desde el cliente › el chófer tampoco
● users/{uid}.locale no se escribe desde el cliente › el pasajero no cambia su idioma directo
```

### Tests nuevos sin el cambio de su tarea

```
Tarea                     Archivo de tests                          Sin el cambio
A1 resolución y panel     locale_test.dart                          no compila sin el módulo
A1 apps con la elección   idioma_test.dart                          1 de 2 falla (app.dart anterior)
A2 reglas                 locale.rules.ts                           3 de 5 fallan
A2 callable               preferences.int.ts (idioma)               2 de 4 fallan
A3 selector               locale_test.dart (selector)               no compila sin el widget
A4 catálogo               i18n.test.ts                              no compila sin el módulo
A4 avisos por idioma      i18n.int.ts                               no compila con el servidor anterior
A5 trinquete              textos_fijos_trinquete_test.dart          prueba nueva (línea base)
A7 paridad .arb           arb_parity_test.dart                      prueba nueva (casos sintéticos)
```

## cierre/integracion tras fusionar cierre/preferencias, Parte A (commit 195ac70, 2026-10-30)

Fusión `git merge --no-ff cierre/preferencias` en un worktree limpio, sin
conflictos.

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           121 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           245 archivos, 0 cambiados       0
flutter test                                  pasa           617/617                         0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           542/542 (29 de 29 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (demo-luxelane)            pasa           1626/1626 (24 de 24 suites)     0
npm run test:integration (demo-luxelane)      pasa           390/390 (44 de 44 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
```

actionlint: la descarga del binario no se permitió en este entorno; ci.yml
no cambia.

## cierre/preferencias, Parte A (A1–A6, commit 5d71ea1, 2026-10-30)

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           121 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           245 archivos, 0 cambiados       0
flutter test                                  pasa           617/617                         0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           542/542 (29 de 29 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (demo-luxelane)            pasa           1626/1626 (24 de 24 suites)     0
npm run test:integration (demo-luxelane)      pasa           390/390 (44 de 44 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
```

La Parte A no toca la app (lib/, test/): flutter da lo mismo que en la fusión.

### Reglas anteriores con los tests nuevos

`firestore.rules` de 5443ec1 (cierre/integracion) con los tests de 5d71ea1,
`RULES_PATH=<reglas anteriores> firebase emulators:exec --only firestore
--project demo-luxelane "jest --runInBand --verbose"`, código de salida 1:

```
Test Suites: 2 failed, 22 passed, 24 total
Tests:       16 failed, 1610 passed, 1626 total

● bookings/{id}/driverView › admin › leer
● bookings/{id}/driverView › admin › listar
● bookings/{id}/driverView › ana › leer
● bookings/{id}/driverView › ana › listar
● bookings/{id}/driverView › asig › leer
● bookings/{id}/driverView › asig › listar
● copia por reserva: bookings/{id}/driverView/preferences › chófer asignado y activo, etapa confirmed: la lee
● copia por reserva: bookings/{id}/driverView/preferences › chófer asignado y activo, etapa driver_arrived: la lee
● copia por reserva: bookings/{id}/driverView/preferences › chófer asignado y activo, etapa driver_arriving: la lee
● copia por reserva: bookings/{id}/driverView/preferences › chófer asignado y activo, etapa in_progress: la lee
● copia por reserva: bookings/{id}/driverView/preferences › chófer asignado y activo, etapa verified: la lee
● copia por reserva: bookings/{id}/driverView/preferences › el admin la lee
● copia por reserva: bookings/{id}/driverView/preferences › el pasajero dueño la lee en cualquier etapa; otro pasajero, nunca
● perfil: tripPreferences no se escribe desde el cliente › el alta no trae tripPreferences
● perfil: tripPreferences no se escribe desde el cliente › el dueño no cambia las ridePreferences antiguas
● perfil: tripPreferences no se escribe desde el cliente › el dueño no las cambia
```

### Tests nuevos sin el cambio de su tarea

```
Tarea                     Archivo de tests                          Sin el cambio
A1 esquema                preferences.test.ts                       no compila sin el módulo
A1 reglas del perfil      preferences.rules.ts                      3 de 5 fallan
A2 copia por reserva      preferences.int.ts (createBooking, 7)     7 de 7 fallan
A2 sin riderPreferences   bookings.int.ts                           1 falla
A3 driverView             matriz (6 celdas) y preferences.rules.ts  13 fallan (6 + 7)
A4 openRequests           open_requests.test.ts                     no compila sin el cambio
A5 logs (unitario)        errors.test.ts                            1 de 16 falla
A5 logs (integración)     logs_privacy.int.ts                       falla (con logger y createBooking anteriores)
```

## cierre/integracion tras fusionar cierre/ajustes (commit 2725b7c, 2026-10-30)

Fusión `git merge --no-ff origin/cierre/ajustes` en un worktree limpio, sin
conflictos. Flutter 3.29.3 (el de ci.yml), Node 22, emuladores con
`demo-luxelane`.

```
Comando                                       Resultado      Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa           121 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa           245 archivos, 0 cambiados       0
flutter test                                  pasa           617/617                         0
functions: npm run build                      pasa           —                               0
functions: npm test                           pasa           508/508 (28 de 28 suites)       0
functions: jest fare.test.ts pickup_code      pasa           33/33                           0
npm run test:rules (demo-luxelane)            pasa           1567/1567 (23 de 23 suites)     0
npm run test:integration (demo-luxelane)      pasa           378/378 (43 de 43 suites)       0
tools/pricing: npm test                       pasa           pass 10, fail 0                 0
actionlint ci.yml                             NO EJECUTADO   —                               —
```

actionlint no se ejecutó: la descarga del binario no se permitió en este
entorno. ci.yml no cambia en esta fusión.

## cierre/pagos-g, G1–G5 (commit 9b72fc8, 2026-10-28)

```
Comando                                       Resultado  Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa       121 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa       243 archivos, 0 cambiados       0
flutter test                                  pasa       607/607                         0
functions: npm run build                      pasa       —                               0
functions: npm test                           pasa       508/508                         0
functions: jest fare.test.ts pickup_code      pasa       33/33                           0
npm run test:rules (demo-luxelane)            pasa       1567/1567                       0
npm run test:integration (demo-luxelane)      pasa       374/374                         0
tools/pricing: npm test                       pasa       pass 10, fail 0                 0
actionlint ci.yml                             pasa       —                               0
```

Sin cambios en `firestore.rules` ni en sus tests.

### Tests nuevos sin el cambio de su tarea

```
Tarea                     Archivo de tests                          Sin el cambio
G1 chófer inmediato       promesas_test.dart                        2 de 23 fallan (6 líneas)
G2 cobrar saldo           payment_balance.int.ts (8)                no compila sin el módulo
G2 panel                  admin_payments_test.dart                  no compila sin el método
G4 importe en auditoría   payment_manual.int.ts                     1 de 17 falla
G3, G5                    capturas y documentación                  —
```

## cierre/pagos, Parte B y E34–E39 (commit f38b5e7, 2026-10-26)

```
Comando                                       Resultado  Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa       121 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa       243 archivos, 0 cambiados       0
flutter test                                  pasa       604/604                         0
functions: npm run build                      pasa       —                               0
functions: npm test                           pasa       502/502                         0
functions: jest fare.test.ts pickup_code      pasa       33/33                           0
npm run test:rules (demo-luxelane)            pasa       1567/1567                       0
npm run test:integration (demo-luxelane)      pasa       366/366                         0
tools/pricing: npm test                       pasa       pass 10, fail 0                 0
actionlint ci.yml                             pasa       —                               0
```

La Parte B no cambia `firestore.rules` ni los tests de reglas: la salida
de las reglas anteriores con los tests nuevos es la de la Parte A (abajo).
Las 121 «issues» son avisos informativos (info); en 90f969b eran 117.

### Tests nuevos sin el cambio de su tarea

```
Tarea                     Archivo de tests                          Sin el cambio
E34 sugerencias a11y      place_autocomplete_a11y_test.dart         1 de 1 falla
E35/E36 precio            booking_price_test.dart                   2 de 2 fallan
E37 error del servidor    booking_request_data_test.dart            falla
E39 invitado en móvil     booking_price_test.dart                   1 de 3 falla
E38 servidor (web)        payment_dispatch.int.ts                   1 de 16 falla
B1 reservar → pagar       booking_price_test.dart                   1 de 4 falla
B3 asientos pendientes    payment_inbox.int.ts                      1 de 6 falla
B3 causa al cancelar      panel_no_show_test.dart                   no compila sin el cambio
B2 chófer sin pagos       driver_sin_pagos_test.dart                falla al añadir un campo de pago
B4 textos                 textos_pagos_test.dart                    falla con el diálogo anterior
B1/B3 pantallas nuevas    booking_payment_test, payment_receipt,    no compilan sin el módulo
                          admin_payments_test
```

## cierre/pagos, Parte A (commit 90f969b, 2026-10-26)

```
Comando                                       Resultado  Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa       117 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa       226 archivos, 0 cambiados       0
flutter test                                  pasa       557/557                         0
functions: npm run build                      pasa       —                               0
functions: npm test                           pasa       502/502                         0
functions: jest fare.test.ts pickup_code      pasa       33/33                           0
npm run test:rules (demo-luxelane)            pasa       1567/1567                       0
npm run test:integration (demo-luxelane)      pasa       361/361                         0
tools/pricing: npm test                       pasa       pass 10, fail 0                 0
actionlint ci.yml                             pasa       —                               0
```

### Reglas anteriores con los tests nuevos

`firestore.rules` de 80674ed (antes de pagos) con los tests de b51f8a8
(salida literal de `npm run test:rules`, código de salida 1):

```
Test Suites: 2 failed, 21 passed, 23 total
Tests:       5 failed, 1562 passed, 1567 total
```

Fallan las celdas nuevas que permiten algo (`bookings/{id}/payment` ×
pasajero dueño y admin × leer y listar: 4) y «sin pago confirmado nadie la
acepta desde el cliente (pagos, A3)» (1).

### Tests nuevos sin el cambio de su tarea

```
Tarea                     Archivo de tests                          Sin el cambio
A2 método desactivado     payment_methods.int.ts                    3 de 3 fallan
A3 sin pago, sin chófer   payment_dispatch.int.ts                   10 de 11 fallan
A7 retención por etapas   cancel_booking.int.ts + payment_settle    15 de 28 fallan
A12 causa por defecto     payment_settle.int.ts                     1 de 7 falla
Q2 segundo cobro          admin_payment.int.ts                      2 de 14 fallan
A4, A5, A6, A8, A9, A11   payment_*.int.ts (módulos nuevos)         no compilan sin el módulo
```

## cierre/experiencia, F1–F6 (commit 973390f, 2026-10-26)

```
Comando                                       Resultado  Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa       117 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa       226 archivos, 0 cambiados       0
flutter test                                  pasa       557/557                         0
functions: npm run build                      pasa       —                               0
functions: npm test                           pasa       443/443                         0
functions: jest fare.test.ts pickup_code      pasa       33/33                           0
npm run test:rules (demo-luxelane)            pasa       1446/1446                       0
npm run test:integration (demo-luxelane)      pasa       272/272                         0
tools/pricing: npm test                       pasa       pass 10, fail 0                 0
actionlint ci.yml                             pasa       —                               0
```

## cierre/integracion tras fusionar cierre/pagos-g (commit a37c6a6, 2026-10-28)

```
Comando                                       Resultado  Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa       121 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa       243 archivos, 0 cambiados       0
flutter test                                  pasa       607/607                         0
functions: npm run build                      pasa       —                               0
functions: npm test                           pasa       508/508                         0
functions: jest fare.test.ts pickup_code      pasa       33/33                           0
npm run test:rules (demo-luxelane)            pasa       1567/1567                       0
npm run test:integration (demo-luxelane)      pasa       374/374                         0
tools/pricing: npm test                       pasa       pass 10, fail 0                 0
actionlint ci.yml                             pasa       —                               0
```

## cierre/ajustes, H1–H4 (commit eabd29c, 2026-10-28)

```
Comando                                       Resultado  Tests pasados/total             Código de salida
flutter analyze --no-fatal-infos              pasa       121 issues (0 errores/avisos)   0
dart format --set-exit-if-changed lib/ test/  pasa       245 archivos, 0 cambiados       0
flutter test                                  pasa       617/617                         0
functions: npm run build                      pasa       —                               0
functions: npm test                           pasa       508/508 (28 de 28 suites)       0
functions: jest fare.test.ts pickup_code      pasa       33/33                           0
npm run test:rules (demo-luxelane)            pasa       1567/1567 (23 de 23 suites)     0
npm run test:integration (demo-luxelane)      pasa       378/378 (43 de 43 suites)       0
tools/pricing: npm test                       pasa       pass 10, fail 0                 0
actionlint ci.yml                             pasa       —                               0
```

Sin cambios en `firestore.rules` ni en sus tests.

### Tests nuevos sin el cambio de su tarea

```
Tarea                     Archivo de tests                          Sin el cambio
H1 channel obligatorio    payment_dispatch.int.ts                   1 de 17 falla
H2/E40 comprobante        payment_receipt_test.dart                 no compila sin el cambio
H2/E41 Mis viajes         trip_payment_status_test.dart             no compila sin el cambio
H2/E42 tarjetas           payment_methods_screen_test.dart          no compila sin el cambio
H2/E43 titular            payment_receipt_test.dart                 no compila sin el cambio
H3 saldo neutro           payment_receipt_test.dart                 1 de 12 falla
H4 solo anexado           payment_ledger.int.ts                     2 de 2 fallan
```
