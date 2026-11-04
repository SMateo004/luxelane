# Capturas de vuelos (Prompt 15, Parte B): hallazgos

Capturas de `tools/experiencia/capturas_vuelos.cjs` contra los emuladores
(`demo-luxelane`), con los datos FICTICIOS de `seed.cjs` y `seed_vuelos.cjs`.
Pasajero y chófer a 390, 768 y 1280 px en es, en y pt, más 390 px con el
texto al 200 % (`_x2`); el panel, solo en español a los tres anchos. El
manifiesto de cada idioma (`manifiesto_<idioma>.json`) guarda el resultado
de cada captura y, a 390 px, lo que lee el lector de pantalla.

**Resultado: 126 de 126 capturas «ok»** (los fallos de la primera pasada,
del entorno y no de la app, se repitieron en serie; ver al final).

| Estado | Qué muestra |
|---|---|
| v01-paso-vuelo-nacional | Paso «Tu vuelo»: tipo primero, número, aerolínea opcional, fecha, hora del billete, equipaje facturado con su ayuda, punto de recogida nacional y «Hora de recogida en el punto» que devuelve el servidor |
| v02-paso-vuelo-sin-punto | Vuelo internacional en un aeropuerto sin punto internacional: «Punto por confirmar con central» |
| v03-viaje-sin-datos | Viaje confirmado sin datos en vivo: «Sin datos de vuelo en vivo: hora programada HH:MM» |
| v04-viaje-retrasado | Retraso fijado por central: «Nueva hora de recogida: HH:MM» |
| v05-viaje-cancelado | Vuelo cancelado: central revisa la reserva; nada cambia solo |
| v06-chofer-retrasado | Tarjeta «Vuelo» del chófer: estado, llegada estimada, «Debes estar en el punto a las HH:MM», punto e indicaciones |
| v07-chofer-sin-datos | Tarjeta del chófer sin datos en vivo: hora programada |
| v08-chofer-sin-punto | Tarjeta del chófer sin punto definido: «Punto por confirmar con central» |
| v09-chofer-solicitud | Solicitud abierta: «Aeropuerto VVI · Nacional», sin número de vuelo |
| v10–v15 (panel) | Bandeja de vuelos con sus filtros, cancelados o desviados, detalle del vuelo, «Fijar datos del vuelo», aeropuertos y su editor |

## Corregido en esta rama (con test que falla sin el cambio)

1. **La nota del vuelo del pasajero no salía desde 600 px** (diseño ancho del
   viaje): solo estaba en el móvil. 7b4e3c9,
   `test/flights/ride_and_request_flight_test.dart`.
2. **La solicitud abierta no decía que la recogida es en el aeropuerto ni el
   tipo de vuelo**: ahora «Aeropuerto VVI · Nacional» (sin número). 7b4e3c9.
3. **«Nacional» e «Internacional» medían 47 px** en portugués y el lector no
   los leía como botones seleccionables: ahora 48 px como mínimo, botón con
   estado elegido. c2544d9, `test/flights/flight_type_selector_test.dart`.

## Lo que la auditoría de semántica marca y no es de vuelos

- «Cancelar reserva» en el viaje del pasajero mide 27 px de alto (botón de
  texto anterior a esta rama). Pendiente fuera de vuelos.
- Los campos a medio cortar por el borde de la ventana (p. ej. «Fecha del
  vuelo … 350x11») son los que la captura deja a medias: no son objetivos
  pequeños de verdad.
- El detalle del panel (v12) tiene un nodo interactivo sin etiqueta: el
  panel sale siempre en español y queda fuera de la regla de 48 px de las
  apps; NO VERIFICADO cuál es.

## Del entorno de capturas (no de la app)

- Con tres procesos a la vez, el emulador de Auth respondía
  `INVALID_PASSWORD` de forma intermitente: Flutter web perdía pulsaciones al
  teclear la contraseña. El guion ahora inserta el texto de una vez, espera al
  botón real de «Iniciar sesión» y, si sigue en el inicio de sesión, marca la
  captura como fallo con el motivo del emulador (antes salía un «ok» con la
  pantalla de login).
- A 1280 px el resumen de la reserva tiene su propio desplazamiento: la rueda
  va sobre esa columna.
