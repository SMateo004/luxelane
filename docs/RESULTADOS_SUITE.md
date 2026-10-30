# Resultados de la suite

Tablas en texto plano (bloque de código) para que se lean igual en un
adjunto. Cada fila es la salida real del comando; nada resumido a mano.
Todo contra los emuladores con el proyecto ficticio `demo-luxelane`.

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
