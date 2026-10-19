# Luxelane

App de chófer privado: Flutter (pasajeros, chóferes y panel de
administración) sobre Firebase (Auth, Firestore, Cloud Functions y Hosting),
con pagos de captura manual.

## Ejecutar en local con emuladores

Todo usa el proyecto ficticio `demo-luxelane`; no toca ningún proyecto real.

```
(cd functions && npm ci && npm run build && npm test)   # funciones
(cd tools/rules-tests && npm ci)                         # herramientas de reglas
npm run emulators     # Firestore (8080) y Auth (9099) locales
npm run test:rules    # tests de las reglas de Firestore en el emulador
npm run test:integration   # triggers de reservas contra el emulador de Firestore
```

Se ejecutan desde la raíz o desde `tools/rules-tests`. Las pruebas de
integración invocan los handlers reales (`onBookingCreated`,
`closeOpenRequest`) contra el emulador de Firestore; no usan el emulador de
Functions, que detrás de un proxy HTTPS no logra registrar los triggers.

App:

```
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run --dart-define=FIREBASE_ENV=staging
```

Sin `FIREBASE_ENV` la app compila para staging, nunca para producción.

Claves (Google Maps y demás `--dart-define`): copia `env.example.json` a
`env.local.json` (ignorado por git), complétalo y usa
`flutter run --dart-define-from-file=env.local.json`. No hay claves en el
repositorio; sin la de Maps los mapas muestran un aviso. Detalle por
plataforma en DEPLOY.md, «Claves de Google Maps».

## Desplegar

- **Staging:** manual, con `--project staging`, después de pasar los tests.
- **Producción:** CI al hacer push a `main`, con aprobación del entorno
  `production` de GitHub.

Pasos y secretos en [DEPLOY.md](DEPLOY.md).

## Plan de trabajo

[docs/AUDITORIA_LUXLANE.md](docs/AUDITORIA_LUXLANE.md): hallazgos D1–D15 y
tareas #1–#17. Reglas de trabajo en [CLAUDE.md](CLAUDE.md).
