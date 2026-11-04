# Página pública del viaje compartido (/t) — Prompt 18, C5

`tools/experiencia/capturas_compartir.cjs` contra el emulador de Firestore
(`demo-luxelane`), con `sharedTrip` servido en local desde el código
compilado de functions y enlaces FICTICIOS creados con `createTripShare`.

**Resultado: 72 de 72 capturas «ok»** (6 estados × es/en/pt × 390, 768 y
1280 px, más 390 px con el texto al 200 %, `_x2`).

## Red lenta simulada (latencia 400 ms, 400 kbit/s)

| Idioma | Peso transferido (página + consulta) | Hasta ver el estado |
|---|---|---|
| es | 5561 bytes | 1333 ms |
| en | 5507 bytes | 1339 ms |
| pt | 5573 bytes | 1316 ms |

Sin el framework de la app, sin fuentes externas ni imágenes: una página y una
consulta. Cada actualización posterior (cada 15 s) es solo la consulta.

## Estados

| Estado | Qué muestra |
|---|---|
| activo | Estado («El chófer va hacia la recogida»), hora de recogida prevista, nombre de pila del chófer, vehículo, zonas y la última posición con su hora y «Ver en el mapa» |
| sin-posicion | Chófer asignado, aún sin ir hacia la recogida: «Sin posición todavía» |
| terminado | «Viaje terminado» y la nota de que el seguimiento se cierra (dentro del margen de `tripShareGraceMinutes`, FICTICIO en la prueba) |
| revocado / invalido | La misma página: «Enlace no disponible» (sin pistas de por qué) |
| sin-javascript | El título y el aviso de activar JavaScript, en el idioma del navegador; nada más |

## Lector de pantalla y tamaño táctil

El manifiesto guarda el árbol de accesibilidad a 390 px: encabezado de nivel
1, el estado en una región `status` (se anuncia al cambiar), datos como lista
de definiciones y el enlace «Ver en el mapa». Objetivos de menos de 48 px:
ninguno.

- NO VERIFICADO con un lector de pantalla real (VoiceOver, TalkBack). El árbol
  de Playwright no incluye el contenido de `<noscript>` aunque se vea en
  pantalla (captura `sin-javascript`).
- NO VERIFICADO en un teléfono con una red lenta real; la simulación es de
  Chromium (CDP).
- «Ver en el mapa» usa `geo:`: abre la app de mapas en Android; en iOS Safari
  NO VERIFICADO (puede no hacer nada).
