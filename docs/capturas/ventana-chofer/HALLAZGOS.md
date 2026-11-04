# Capturas de la ventana del chófer (Prompt 17, Parte B)

`tools/experiencia/capturas_ventana.cjs` contra los emuladores (`demo-luxelane`),
con las reglas de esta rama y los datos FICTICIOS de `seed.cjs` y
`seed_ventana.cjs`. App del chófer a 390, 768 y 1280 px en es, en y pt, más
390 px con el texto al 200 % (`_x2`). El manifiesto guarda el resultado de
cada captura y, a 390 px, lo que lee el lector de pantalla.

**Resultado: 60 de 60 capturas «ok».** Auditoría de semántica: ningún botón
sin etiqueta y ningún objetivo de menos de 48 px en las 15 pantallas a 390 px.

| Estado | Qué muestra |
|---|---|
| w01-ganancias | Ganancias leídas de `driverHistory`: neto, tarifas, comisión, un viaje provisional, uno por horas y uno reembolsado; cada viaje con su **zona**, no la dirección |
| w02-ganancias-vacio | Chófer sin historial: estado vacío |
| w03-inicio-hoy | «Ganancias de hoy» del inicio desde el historial (neto y viajes de hoy) |
| w04-cierre-terminado | La reserva en curso se completa con el chófer mirando: «Viaje terminado» (estado leído del resumen) |
| w05-cierre-cancelado | El pasajero cancela con el chófer mirando: «El viaje se canceló» |

w04 y w05 son de punta a punta: el guion crea una reserva en curso, el chófer
la abre, el guion la cierra con el Admin SDK sobre el emulador, el disparador
`writeDriverHistoryOnBooking` (emulado por `callables.cjs`) escribe el
resumen, la reserva sale de la consulta del chófer y la app muestra el cierre
sin errores.

## No capturado

- **Estado de error** del historial: con las reglas de esta rama no se puede
  provocar sin romper la sesión; está cubierto por pruebas de widget
  (`test/driver/driver_earnings_screen_test.dart`,
  `test/driver/driver_history_test.dart`). NO VERIFICADO en la app web.
- **Estado de carga**: dura menos de lo que tarda la captura; cubierto por
  las mismas pruebas.

## Del entorno de capturas

- El chófer de prueba `chofer` tiene viajes en curso y su inicio abre el
  viaje activo: «Ganancias de hoy» se captura con `chofer2`, que tiene el
  historial sembrado y ningún viaje en curso.
