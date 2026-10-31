# Capturas por idioma (B5)

14 pantallas de las apps del pasajero y del chófer × 3 anchos (390, 768,
1280 px) × 3 idiomas (es, en, pt): 126 capturas contra los emuladores
(demo-luxelane), con el build web de 9a5dc22 (después de los arreglos de
texto grande). Hojas de contacto: `hojas/es.jpg`, `hojas/en.jpg`,
`hojas/pt.jpg`. Guion: `tools/experiencia/capturas_idiomas.cjs` y
`hojas_idiomas.sh`; resultado de cada captura en `manifiesto.json`.

## Hallazgos

1. Sin textos de la interfaz en español en inglés ni en portugués en las 14
   pantallas, salvo los datos (abajo) y las páginas legales, que muestran
   el aviso traducido y el texto en español (decisión 3).
2. Datos de prueba en español que se ven tal cual en los tres idiomas: el
   color del vehículo («Negro»), lugares («Plaza principal», «Centro»,
   «Aeropuerto») y la zona de la solicitud del chófer («from Aeropuerto»).
   Son datos, no textos de la app; el color lo escribe el chófer y la zona
   el servidor (`areaLabel`), en español. Decidir si la zona se traduce.
3. Ningún texto cortado ni desbordado a la vista en los tres anchos. Los
   títulos más largos (pt «Seu motorista chegou e está esperando por você.
   Sem pressa.», en «Ask the passenger for their pickup code.») caben.
4. «05-reserva» (ruta /booking sin datos) vuelve al inicio en los tres
   idiomas: la reserva se cubre con los tests de widget
   (bloque_reserva_test, texto_grande_idiomas_test), no con esta captura.
5. En «13-chofer-solicitudes» se ve el tooltip «Earnings»/«Ganancias» de la
   barra inferior: lo provoca el puntero del navegador de pruebas, no la app.
6. La primera pasada de pt a 1280 px dejó «14-chofer-recogida» en el inicio
   de sesión (el login tardó); se repitió pt a 1280 px y está bien.
7. El perfil sigue mostrando las preferencias antiguas (silencio, música,
   temperatura…): la pantalla nueva de preferencias es la Parte B del
   prompt de preferencias, pendiente.
