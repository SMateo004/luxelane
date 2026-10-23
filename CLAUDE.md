# Reglas de trabajo — Luxelane

Estas reglas valen para todas las sesiones de trabajo en este repositorio.

**Plan de trabajo:** `docs/AUDITORIA_LUXLANE.md`. Los hallazgos D1–D15 y las
tareas #1–#17 que se mencionan en las sesiones salen de ese archivo.

## Ramas y despliegues

- Se trabaja solo en ramas. Nada se mezcla a `main` sin autorización
  explícita del responsable del proyecto.
- Nunca hacer push a `main`.
- Nunca desplegar a Firebase (functions, reglas de Firestore, hosting)
  desde esta máquina. Todo se prueba con los emuladores locales.

## Antes y después de cada cambio

- Antes de cualquier cambio, explicar en 3 líneas qué se va a tocar y por qué.
- Después de cada tarea, ejecutar análisis y tests y mostrar el resultado
  real (no un resumen inventado):
  - App: `flutter analyze`, `dart format --output=none --set-exit-if-changed lib/ test/`, `flutter test`.
  - Functions: `npm run build` y `npm test` dentro de `functions/`.
- En la ENTREGA FINAL incluir siempre, en texto plano dentro del mensaje,
  una tabla con una fila por comando: comando, resultado (pasa/falla),
  número de tests pasados/total y código de salida. Además de las salidas
  literales (los adjuntos pierden las salidas de los comandos).

## Seguridad

- Cada cambio de seguridad debe llevar un test que falle sin el cambio y
  pase con él.

## Decisiones de negocio

- Si una decisión es de negocio (precios, políticas, textos legales,
  proveedores, nombre de marca, números de contacto), detenerse y
  preguntar. No inventar valores.

## Textos

- No mencionar marcas de terceros del sector en textos de producto ni de
  documentación.

## Afirmaciones

- Etiquetar las afirmaciones con:
  - **[seguro]**: lo leí o lo ejecuté.
  - **[Probable]**
  - **[Especulando]**
- Si algo no se pudo verificar, escribir **NO VERIFICADO**.

## Commits

- Commits pequeños, uno por tarea, con un mensaje claro en español.
