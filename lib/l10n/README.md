# Idiomas (es · en · pt)

La app sigue **el idioma del dispositivo** (o del navegador en web) y cambia
**en vivo** si el usuario lo cambia en Ajustes, sin reiniciar. Si el idioma
del dispositivo no está soportado, se usa **inglés**. Fechas, horas y montos
en Bs se formatean según el idioma activo. Android 13+ también ofrece el
selector "Idioma de la app" (`android/app/src/main/res/xml/locales_config.xml`).

Las notificaciones push del servidor usan el idioma guardado en
`users/{uid}.locale`, que la app actualiza automáticamente
(`functions/src/messages.ts`).

## Agregar o cambiar un texto

1. Edita el archivo del área en `lib/l10n/parts/*.json`. Cada clave lleva las
   tres traducciones:
   ```json
   "tripPickupIn": {
     "es": "Recogida en {minutes} min",
     "en": "Pickup in {minutes} min",
     "pt": "Embarque em {minutes} min",
     "placeholders": { "minutes": { "type": "int" } }
   }
   ```
   Usa placeholders y plurales ICU (`{count, plural, =1{…} other{…}}`). No
   construyas frases concatenando fragmentos traducidos.
2. Regenera:
   ```
   dart run tool/build_l10n.dart && flutter gen-l10n
   ```
3. Úsalo en la UI con `context.l10n.tripPickupIn(5)`.

Nombres de vehículo, servicio y estado: `vehicleClass.localizedLabel(context.l10n)`,
`serviceType.localizedLabel(…)`, `status.localizedLabel(…)`.
Duraciones: `localizedDuration(context.l10n, d)`. Montos: `LuxMoney.format`.
Fechas: `DateFormat.yMMMd()`, `DateFormat.jm()`… **sin** locale fijo.

## Garantías automáticas (tests y CI)

- `test/l10n_test.dart`: cambio de idioma en vivo, respaldo en inglés, y que
  los tres ARB tengan las mismas claves y placeholders.
- `test/no_hardcoded_strings_test.dart`: falla si alguien escribe texto visible
  fijo en una pantalla.
- CI ejecuta `dart run tool/build_l10n.dart --check` y verifica que
  `lib/l10n/gen` esté generado.

Los textos legales largos (Términos, Privacidad) están en
`lib/features/legal/presentation/pages/legal_content.dart`, una versión por
idioma; prevalece la versión en español.
