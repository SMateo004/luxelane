# Resultados de la suite

Tablas en texto plano (bloque de código) para que se lean igual en un
adjunto. Cada fila es la salida real del comando; nada resumido a mano.
Todo contra los emuladores con el proyecto ficticio `demo-luxelane`.

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
