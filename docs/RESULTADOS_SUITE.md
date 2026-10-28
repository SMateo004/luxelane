# Resultados de la suite

Tablas en texto plano (bloque de código) para que se lean igual en un
adjunto. Cada fila es la salida real del comando; nada resumido a mano.
Todo contra los emuladores con el proyecto ficticio `demo-luxelane`.

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
