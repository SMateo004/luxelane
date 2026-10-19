# Luxelane

App de chófer privado: Flutter (pasajeros, chóferes y panel de
administración) sobre Firebase (Auth, Firestore, Cloud Functions y Hosting),
con pagos de captura manual.

## Ejecutar en local con emuladores

Todo usa el proyecto ficticio `demo-luxelane`; no toca ningún proyecto real.

```
cd functions
npm ci
npm run build && npm test   # tests unitarios de las funciones
npm run emulators           # Firestore (8080) y Auth (9099) locales
npm run test:rules          # tests de las reglas de Firestore en el emulador
```

App:

```
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run --dart-define=FIREBASE_ENV=staging
```

Sin `FIREBASE_ENV` la app compila para staging, nunca para producción.

## Desplegar

- **Staging:** manual, con `--project staging`, después de pasar los tests.
- **Producción:** CI al hacer push a `main`, con aprobación del entorno
  `production` de GitHub.

Pasos y secretos en [DEPLOY.md](DEPLOY.md).

## Plan de trabajo

[docs/AUDITORIA_LUXLANE.md](docs/AUDITORIA_LUXLANE.md): hallazgos D1–D15 y
tareas #1–#17. Reglas de trabajo en [CLAUDE.md](CLAUDE.md).
