# Capturas de preferencias (B5)

Estados nuevos de preferencias en español e inglés a 390, 768 y 1280 px,
contra los emuladores (demo-luxelane) con datos FICTICIOS de seed.cjs
(preferencias de la pasajera, copia por reserva y host de prueba
`musica.ejemplo.test`). Guion: `tools/experiencia/capturas_preferencias.cjs`.
Hojas: `hojas/es.jpg`, `hojas/en.jpg`; resultado de cada una en
`manifiesto.json` (34 de 36).

| Estado | Qué se ve |
|---|---|
| 01-perfil-resumen | Fila «Preferencias para tu chófer» con el resumen corto |
| 02-preferencias | Pantalla de preferencias con chips, lista de música (host permitido), necesidades y nota |
| 03-viaje-pasajero | Panel del viaje: «Tu chófer verá estas preferencias.» y el resumen |
| 04-chofer-viaje | Tarjeta «Preferencias del pasajero» en el viaje del chófer (en la recogida) con la nota completa y «Abrir lista» |
| 05-chofer-solicitud | Solicitud abierta con solo los idiomas |
| 06-panel-detalle | Detalle de la reserva en el panel con sus preferencias (siempre en español) |

## Hallazgos

1. Sin textos cortados ni desbordes a la vista; los textos nuevos salen en
   el idioma del navegador y el panel en español (también con el navegador
   en inglés).
2. El chófer ve la URL de la lista solo como botón «Abrir lista»; el
   pasajero sí ve su propio enlace en su pantalla de preferencias.
3. 06-panel-detalle a 390 px no se capturó (en es ni en en): en el panel
   móvil el guion no llegó a abrir la reserva desde el buscador. El panel es
   de escritorio; el estado se ve a 768 y 1280 px.
4. El paso «Preferencias de este viaje» de la reserva no está en las
   capturas (la reserva por URL vuelve al inicio, como en las capturas de
   idiomas): lo cubren los tests de widget (booking_preferences_test,
   preferencias_accesibilidad_test).
