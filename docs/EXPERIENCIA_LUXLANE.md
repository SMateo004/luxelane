# Experiencia Luxelane — revisión de la app funcionando

Rama `cierre/experiencia` · 2026-10-25 · Parte A (A1–A9). No se cambió código
de la app salvo el entorno de A1 (modo emuladores). Las correcciones son la
Parte B y solo las que apruebe el responsable.

Etiquetas: **[seguro]** lo leí o lo ejecuté · **[Probable]** · **[Especulando]**
· **NO VERIFICADO**.

## Índice

1. [Entorno reproducible (A1)](#a1-entorno-reproducible)
2. [Capturas y hojas de contacto (A2, A3)](#a2-a3-capturas-y-hojas-de-contacto)
3. [Hallazgos por severidad (A9)](#a9-hallazgos)
4. [Revisión de lujo con criterios medibles (A4)](#a4-revisión-de-lujo)
5. [Animaciones (A5)](#a5-animaciones)
6. [Accesibilidad (A6)](#a6-accesibilidad)
7. [Rendimiento y peso (A7)](#a7-rendimiento-y-peso)
8. [Errores (A8)](#a8-errores)
9. [Límites de esta revisión](#límites-de-esta-revisión)

---

## A1. Entorno reproducible

Un comando: `tools/experiencia/levantar.sh` (o `--sin-build` si ya están las
builds). Se niega a correr con otro proyecto que no sea `demo-luxelane`.

| Pieza | Qué hace |
|---|---|
| `lib/core/config/emulator_setup.dart` | Modo emuladores solo con `--dart-define=USE_EMULATORS=true`: opciones ficticias con `demo-luxelane` y Auth, Firestore y Functions en localhost. Sin la variable, la app usa sus opciones de siempre. Rechaza cualquier otro proyecto (test `test/core/config/emulator_setup_test.dart`). `lib/firebase_options.dart` no se tocó. |
| `tools/experiencia/seed.cjs` | Siembra Auth y Firestore: pasajera, pasajera sin viajes, chófer verificado (con viajes), chófer verificado libre, chófer no verificado, chófer bloqueado, admin y admin con un segundo factor inscrito; una reserva por estado del grafo (pendiente, liberada, confirmada, en camino, llegó, verificada, en curso, completada, no se presentó, cancelada, cancelada con recargo), un SOS abierto, alertas, un cobro, tarifas y política **ficticias** (`_ficticio: true`). Contraseña común `prueba-123`. Se niega sin `FIRESTORE_EMULATOR_HOST`/`FIREBASE_AUTH_EMULATOR_HOST` o con otro proyecto. |
| `tools/experiencia/callables.cjs` | Ejecuta las 31 callables y 8 triggers de Firestore con el código compilado real (`functions/lib`). Sustituye al emulador de Functions de firebase-tools, que en este entorno manda por el proxy hasta las llamadas a 127.0.0.1 (`request blocked: no rule allows host "127.0.0.1"`) [seguro]. Lo que llama a Stripe no se ejecuta (clave ficticia). |
| `tools/experiencia/serve.cjs` | Sirve las builds: pasajero y panel en :5050, chófer en :5051. |
| `tools/experiencia/capturas.cjs`, `hojas.sh`, `accesibilidad.cjs`, `rendimiento.cjs`, `analisis_tema.py`, `pruebas/a5_movimiento_test.dart` | A2–A7 (ver cada sección). |

Notas del entorno [seguro]: las builds del modo emuladores llevan CanvasKit
local (`--no-web-resources-cdn`) porque `www.gstatic.com` está bloqueado en
esta sesión; el SDK JS de Firebase (también en gstatic) lo sirven los
scripts desde `tools/experiencia/node_modules/firebase@11.9.1`. La app no
cambia por ello. Rutas web con «#» (estrategia por omisión de Flutter):
`http://localhost:5050/#/trips`.

## A2, A3. Capturas y hojas de contacto

`node tools/experiencia/capturas.cjs` recorre 103 escenarios por ancho (390,
768 y 1280 px) y guarda `docs/capturas/<flujo>/<estado>_<ancho>.png` y
`docs/capturas/manifiesto.json` (qué se capturó, qué falló y por qué).
**La app no tiene tema oscuro** (`theme: luxTheme` sin `darkTheme`) [seguro]:
todas las capturas son en claro.

Hojas de contacto: `docs/capturas/hojas/<flujo>.jpg` (una fila por ancho) y
`docs/capturas/hojas/00-global.jpg` (pantallas principales). Se regeneran con
`tools/experiencia/hojas.sh`.

Flujos (de la sección C de la auditoría): F1 acceso y seguridad, F2 reserva,
F3 por horas, F5 día del servicio (una reserva por estado), F6 cancelación,
F7 viajes y pagos, F8 valoración, F9 SOS, F10 empresas, F13 alta de chófer,
F14 jornada del chófer, F17 panel, A8 errores.

Resultado [seguro, `manifiesto.json`]: **309 capturas, 301 correctas, 8
fallidas, 0 errores de JavaScript**. Las 8 fallidas son los estados de F2
«sin permiso de ubicación», «con ubicación», «sin direcciones» y «fecha y
hora» a 768 y 1280 px: en esos anchos el inicio es la home web, que no tiene
esos botones (no aplica). Las capturas pesan 47 MB: **no se suben** (límite
25 MB); quedan el script que las genera, el manifiesto y las hojas de
contacto (6,6 MB).

## A9. Hallazgos

Ordenados por severidad. «Evidencia» apunta a una captura (en
`docs/capturas/`, regenerable) o a una medida. Ninguno está corregido.

### Bloquea piloto

| Id | Hallazgo | Evidencia | Pantalla | Propuesta |
|---|---|---|---|---|
| E1 | **El SOS se envía con 200 ms de pulsación si el teléfono tiene «quitar animaciones»** (accesibilidad del sistema): el temporizador de 2 s es un `AnimationController` que Flutter acorta al 5 %. Riesgo de avisos falsos a central. [seguro] | Test `tools/experiencia/pruebas/a5_movimiento_test.dart` → «Expected: <0> Actual: <1>» (`docs/experiencia/a5_pruebas_salida.txt`). El test del repo no lo ve porque solo cambia `MediaQuery`. | Viaje (pasajero y chófer) | Que la duración de la pulsación no dependa de la animación (`AnimationBehavior.preserve` o temporizador propio), con test que use `FakeAccessibilityFeatures`. |
| E2 | **Promesas de servicio que el sistema no cumple o que contradicen la política configurable** (`lib/core/design/lux_promise.dart`): «Cancelación gratuita hasta 1 h antes», «Cancela o modifica sin coste», «60/15 min de espera gratuita», «Seguimiento de vuelo en tiempo real», «Atención al cliente 24/7», «propina incluida», «verificación de antecedentes, inspección y formación». Hoy: el recargo sale de `config/ops.cancellationPolicy`, modificar no existe, no hay seguimiento de vuelo, D23 (quién atiende) está abierto. [seguro] | `F2-reserva/inicio_390`, `F2-reserva/vehiculos_390`, `F6-cancelacion/con-recargo_390` (promete gratis y la app cobra Bs 50 de la política de prueba). | Inicio, reserva, servicios | **Decisión del responsable** (textos de negocio y legales): qué promesas quedan; las que dependen de la política, leerlas de `config/ops`. |
| E3 | **El deslizador del chófer queda en «hecho» si el paso falla** (sin red, error del servidor): no puede reintentar «Salir hacia la recogida», «He llegado» ni «Iniciar viaje» sin salir de la pantalla, aunque el aviso dice «Vuelve a intentarlo». `_done` solo se reinicia si cambia la etiqueta (`lux_feedback.dart:488-494`). [seguro] | Test anterior → «Expected: <2> Actual: <1>»; captura `A8-errores/chofer-deslizar-sin-red_390`. | Viaje del chófer | Reiniciar el control cuando el paso no se aplica (resultado del bloc o clave por intento). |
| E4 | **La web tarda 55 s en mostrar algo con «4G lenta»** y la pantalla queda en blanco todo ese tiempo (`web/index.html` no tiene indicador de carga). Sin límite de red: 1,9 s. [seguro, medido en la build del modo emuladores sin compresión; en hosting comprimido se estima menos, ver A7] | `A7-rendimiento/resultado.json`; `F1-acceso/carga_390` (blanca). | Toda la web | Indicador de carga en `index.html` (sin script en línea, por la CSP) y bajar el peso (E5). |
| E5 | **Peso de la app: 201 MB en la build web**; 122 MB son dos vídeos de fondo que además se empaquetan en las apps nativas (`pubspec.yaml: assets/videos/`); `hero_bg.png` de 6000×4000 (3 MB); 48 imágenes suman 50,7 MB, 33 pesan más de 500 KB. [seguro] | `A7-rendimiento/resultado.json` (`peso`). | Home web, reserva | Sacar los vídeos de las apps nativas, redimensionar y comprimir (WebP/AVIF), cargar diferido. Cambiar recursos de marca puede requerir decisión. |

### Molesta

| Id | Hallazgo | Evidencia | Pantalla | Propuesta |
|---|---|---|---|---|
| E6 | Textos técnicos a la persona: 31 sitios devuelven `Failure(e.toString())`. Visto: «HttpException: Invalid HTTP date Invalid Date» al entrar un admin con segundo factor de teléfono. [seguro] | `F1-acceso/admin-reto-segundo-factor_390` | Login y repositorios | Mapear a mensajes humanos (ya existe `functionErrorMessage`). |
| E7 | Accesibilidad con teclado y lector: con Tab no se llega a «Iniciar sesión» ni a «Crear cuenta»; la casilla de términos no tiene etiqueta; el botón atrás del viaje no tiene etiqueta; SOS, código y «Cancelar reserva» quedan fuera del orden de foco; los interruptores «Bloquear» del panel no dicen de quién son. [seguro] | `A6-accesibilidad/resultado.json` | Login, registro, viaje, panel | Semántica y orden de foco (ver A6). |
| E8 | Con texto al 200 % se recortan los dígitos del código de recogida, «SOS» queda «SO», «Bienveni / do», la hora del próximo trayecto se parte, las acciones del chófer se truncan y el diálogo de cancelar recorta opciones. [seguro] | `A6-accesibilidad/*_x2.png` | Varias | Diseños que crezcan con el texto. |
| E9 | 47 objetivos táctiles de menos de 48 px en las 10 pantallas principales (iconos 36–40 px, pestañas 36–39, enlaces de 16–17 px de alto). [seguro] | `A6-accesibilidad/resultado.json` | Varias | Áreas táctiles de 48 px. |
| E10 | Reducir movimiento: 78 de 118 animaciones no consultan `LuxMotion`; los puntos de carga, el pulso de la barra del viaje y el brillo del esqueleto siguen moviéndose (3 tests fallan); vídeos y marquesina en bucle en la web. [seguro] | `docs/experiencia/A5_animaciones.md`, `a5_pruebas_salida.txt` | Varias | Pasar por `LuxMotion` y parar repeticiones. |
| E11 | Calendario en inglés: «Sun, Oct 25», «October 2026», «S M T W T F S» (falta la localización de Material). [seguro] | `F2-reserva/fecha-hora_390` | Reserva | Delegados de localización `es`. |
| E12 | Sin aviso de «sin conexión»: al perder la red, viajes, perfil, panel y chófer siguen mostrando datos en caché sin indicarlo. [seguro] | `A8-errores/*-sin-red_390` | Varias | Aviso de conexión global. |
| E13 | Mensajes que culpan a la conexión cuando no es la red: reserva inexistente → «No pudimos cargar tu reserva. Revisa tu conexión» (y además «Asignando a tu chófer»); error 500 al cancelar → «Revisa tu conexión». [seguro] | `F5-viaje/reserva-inexistente_390`, `F6-cancelacion/error-servidor_390` | Viaje, cancelar | Distinguir «no existe», «servidor» y «red». |
| E14 | Panel en móvil: la tarjeta del SOS y el aviso de dos pasos ocupan más de media pantalla en todas las pestañas. [seguro] | `F17-panel/*_390` | Panel | Compactar o fijar solo un resumen. |
| E15 | El panel se suscribe al abrir a hasta 1000 reservas, 2000 pagos y a todos los usuarios, chóferes y vehículos: 102 documentos con la semilla mínima; con datos reales, miles de lecturas por apertura. [seguro] | `A7-rendimiento/resultado.json`, `admin_repository_impl.dart:55-105` | Panel | Paginación y consultas por pestaña. |
| E16 | Inicio y Mis viajes vuelven a leer las 11 reservas cada uno (la misma consulta se abre por pantalla). [seguro] | `A7-rendimiento/resultado.json` | Pasajero | Compartir el stream de reservas. |
| E17 | Chófer con viaje: el título «Pide al pasajero su código…» se solapa con «SOS» y la campana. [seguro] | `F14-chofer/inicio_390` | Chófer | Reservar espacio a la cabecera. |
| E18 | El chófer que liberó un viaje lo sigue viendo en «Solicitudes» (no puede aceptarlo: 0.3). [seguro] | `F14-chofer/solicitudes_390` (chofer2 ve r-released) | Chófer | Ocultarlo también al volver a entrar. |
| E19 | Reserva liberada sin teléfono de central: el texto pide «llama a central» pero, sin `config/global.dispatchPhone`, no hay botón (introducido en 0.5). [seguro] | `F5-viaje/liberada_390` | Viaje | Texto según haya número o no. |
| E20 | Contraste por debajo de AA (4,5:1) en texto normal: `warning` 3,45–4,05 sobre los fondos claros y 3,70 sobre su tinte; `inkTertiary` 4,04–4,34 sobre `surfaceMuted`, `surfaceDeep` y `sapphireTint`; blanco sobre `warning` 4,05. Se usa en «No se presentó», chips y avisos. [seguro, calculado] | `tools/experiencia/analisis_tema.py` | Tema | Oscurecer `warning` e `inkTertiary`. |
| E21 | Importes con formatos distintos: «Bs96.00», «Bs 120», «Bs120.00», «Bs 50.00», «Bs 120,00». [seguro] | `F14-chofer/ganancias_390`, `F14-chofer/en-recogida_390`, `F5-viaje/cancelada-con-recargo_390`, `F17-panel/operaciones_390` | Varias | Un formateador de moneda. |
| E22 | Sin permiso de ubicación se muestran coordenadas en crudo («-17.78330, -63.18210») y no se explica el permiso. [seguro] | `F2-reserva/sin-permiso-ubicacion_390` | Reserva | Mensaje y dirección legible. |
| E23 | `/booking` abierto directamente muestra «PRECIO FINAL Bs 20» sin ruta. [seguro] | `F2-reserva/confirmar_390` | Reserva | Volver al inicio si falta el viaje. |
| E24 | Ayuda del SOS: «Te contactarán en breve» (y en «No se presentó»: «te contactará», texto que añadí en B6) sin que exista aún quién atiende (D23). [seguro] | `F9-sos/ayuda_390`, `F5-viaje/no-se-presento_390` | SOS, viaje | **Decisión del responsable** (compromiso operativo). |
| E25 | Cabecera oscura de «Mis viajes» en 768+ px con el logo casi invisible. [seguro] | `F7-viajes/lista_768` | Mis viajes | Logo claro sobre fondo oscuro. |

### Menor

| Id | Hallazgo | Evidencia | Pantalla | Propuesta |
|---|---|---|---|---|
| E26 | `web/manifest.json`: «A new Flutter project.» y nombre «luxelane»; título de la app del chófer «Luxelane Driver» (inglés). [seguro] | Archivos | PWA | Textos en español (el nombre de marca lo decide el responsable). |
| E27 | Sin clave de Maps el mapa muestra «Esta versión se compiló sin la clave de Google Maps (GOOGLE_MAPS_KEY)». Solo en builds sin clave. [seguro] | `F5-viaje/en-curso_390` | Viaje | Texto neutro. |
| E28 | Valores fuera del tema en 141 archivos: 153 colores literales y 145 `Colors.*`, 226 `fontSize`, 164 `TextStyle` propios, 278 espaciados fuera de la rejilla de 4; 723 textos fijos sin capa de textos. La peor: `booking_screen.dart` (65/65/65). [seguro, recuento por patrones] | `tools/experiencia/analisis_tema.py` | Varias | Pasar a `LuxTypography`/`LuxSpacing`/`LuxColors`. |
| E29 | Mientras el diálogo de cancelar está abierto, el botón de fondo ya dice «Cancelando…». [seguro] | `F6-cancelacion/con-recargo_390` | Viaje | Marcarlo al confirmar. |
| E30 | `Booking.fromJson` lanza si un lugar no trae coordenadas (visto al escribir un test). [seguro] | `place_model.dart:23` | Modelo | Valor por defecto. |
| E31 | Momentos clave sin confirmación: el pasajero no ve «código verificado» (la tarjeta desaparece), fin del viaje sin momento de éxito, llegada sin háptica. [seguro, leído] | `docs/experiencia/A5_animaciones.md` | Viaje | Ver propuestas en A5 (sin añadir). |
| E32 | Rutas web con «#» (estrategia por omisión). [seguro] | URLs | Web | `usePathUrlStrategy` si se quiere. |
| E33 | Texto legal: «Puedes cancelar sin costo hasta 1 hora antes» contradice la política configurable. [seguro] | `F1-acceso/terminos_390` | Legal | **No se toca** (texto legal): decisión del responsable y el abogado. |

## A4. Revisión de lujo

Criterios por pantalla. Cifras por archivo con
`tools/experiencia/analisis_tema.py` (colores = literales + `Colors.*`;
espaciado fuera de rejilla = valores que no son múltiplo de 4). AA calculado
en E20. Overflow visto en las capturas a 390/768/1280 y a escala 1,3/2,0.

| Pantalla (archivo) | Jerarquía | Espaciado (fuera de rejilla / usos de `LuxSpacing`) | Tipografía (`fontSize` / `TextStyle` sueltos / usos del tema) | Colores (sueltos / `LuxColors`) | Textos | Componentes | Vacío / error | Overflow |
|---|---|---|---|---|---|---|---|---|
| Inicio app (`home_screen`) | Clara: saludo, formulario, CTA | 10 / 25 | 9 / 1 / 14 | 2 / 38 | Promesas sin respaldo (E2) | Consistentes | Validación «Ingresa un lugar de recogida» | A 2,0 la tarjeta del próximo trayecto se parte |
| Inicio web (`home_web_page`) | Hero con foto | 56 / 0 | 35 / 26 / 0 | 95 / 0 | «En todo el mundo» (promesa) | Sistema propio (LD) | — | — |
| Login (`login_page`) | Clara | 9 / 0 | 13 / 13 / 1 | 1 / 20 | Error en crudo (E6) | Botón Google distinto | Validación correcta | A 2,0 «recuerdas / .» |
| Registro (`register_page`) | Clara | 3 / 9 | 3 / 1 / 10 | 0 / 9 | Bien | Casilla sin etiqueta (E7) | Validación por campo | «Bienveni / do» a 2,0 |
| Reserva (`booking_screen`) | Pasos 1–3 claros | **65 / 11** | **65 / 65 / 3** | 20 / 11 | Calendario en inglés (E11); promesas | Muchos estilos propios | Precio sin ruta (E23) | — |
| Viaje pasajero (`ride_screen`) | Estado + código + chófer | 1 / 24 | 2 / 0 / 8 | 0 / 14 | «Revisa tu conexión» equivocado (E13) | Consistentes | «Asignando…» en reserva inexistente | Código recortado a 2,0 |
| Mis viajes (`trips_screen`) | Lista clara | 1 / 13 | 3 / 0 / 6 | 0 / 8 | Bien | Tarjetas consistentes | Vacío bueno («Tu primer trayecto…») | Truncados a 1,3 |
| Perfil (`profile_screen`) | Clara | 2 / 25 | 4 / 1 / 7 | 1 / 9 | Bien | Interruptores y chips | — | — |
| Pagos (`payment_screen`) | Mínima | 0 / 5 | 2 / 0 / 3 | 1 / 10 | «Paga sin pensarlo» sin explicación | — | Stripe no probado | — |
| Chófer inicio (`driver_home_screen`) | Título enorme con viaje | 7 / 31 | 11 / 0 / 20 | 0 / 35 | Bien | — | Banner «documentos en revisión» bien | Solapa con SOS (E17) |
| Chófer viaje (`driver_active_ride_screen`) | Acción principal clara | 0 / 21 | 0 / 0 / 5 | 0 / 10 | «Bs120.00» (E21) | Deslizador bloqueable (E3) | — | Truncados a 2,0 |
| Chófer solicitudes (`driver_queue_screen`) | Clara | 2 / 16 | 6 / 0 / 8 | 0 / 0 | Bien | — | — | — |
| Chófer ganancias (`driver_earnings_screen`) | Cifra grande clara | 2 / 12 | 8 / 0 / 10 | 0 / 3 | «Bs96.00» (E21) | — | — | — |
| Panel (`admin_sections`, `admin_finance_tab`) | SOS arriba, luego datos | 3+2 / 90+48 | 0+2 / 2+3 / 55+33 | 0 / 70+34 | Interruptores sin nombre (E7) | Consistentes | Vacíos buenos | Móvil saturado (E14); pestañas cortadas a 2,0 |
| Legal (`legal_page`) | Clara | 3 / 0 | 0 / 0 / 0 | 0 / 0 | Contradicción (E33) | — | — | — |

Textos: no hay «A new Flutter project» en pantallas (sí en el manifiesto,
E26), ni marcadores ni «??». Los textos en inglés vistos: calendario (E11),
«Luxelane Driver», «HttpException…» (E6). Textos fijos que no pasan por una
capa de textos: **723** en 65 archivos (no existe capa de textos ni l10n).

## A5. Animaciones

Inventario completo (118 filas, archivo:línea, duración, curva, si respeta
reducir movimiento, si bloquea, riesgo al interrumpirse):
[`docs/experiencia/A5_animaciones.md`](experiencia/A5_animaciones.md).
Resumen:

- **38 de 118** respetan «reducir movimiento» (pasan por `LuxMotion`); 7 solo en parte. **78 no lo consultan**: en 62 la duración es fija (solo el SDK la acorta al 5 % si la opción viene del sistema) y 16 no las reduce nada (bucles, scroll animado, vídeo, cámara del mapa). [seguro, leído]
- Tests de widget (`tools/experiencia/pruebas/a5_movimiento_test.dart`, 7 tests: **2 pasan, 5 fallan**, salida literal en `docs/experiencia/a5_pruebas_salida.txt`): SOS a 200 ms (E1), deslizador sin reintento (E3), puntos de carga, pulso de la barra del viaje y brillo del esqueleto siguen con reducir movimiento (E10).
- Pueden dejar la pantalla inutilizable si se interrumpen: el deslizador (E3) [seguro]; la hoja de solicitud entrante del chófer no se cierra arrastrando y hace un `pop()` a ciegas al desaparecer la solicitud (`driver_home_screen.dart:53-124`) [Probable]; pagos sin límite de tiempo en la carga (`payment_screen.dart:141`) [Probable]. Todos los `AnimationController` tienen `dispose` [seguro].
- Bloquean la interacción: el éxito de reserva (barrera modal 1,8 s antes de navegar, `lux_feedback.dart:298-356`) y las rutas mientras salen (SDK).

Momentos clave sin animación ni confirmación (propuestas, **sin añadir**):

| Momento | Hoy | Propuesta |
|---|---|---|
| Confirmar reserva | Visto de 900 ms, háptica y cierre a 1,8 s; con tarjeta y viaje lejano se salta y navega directo | Mismo momento en todos los caminos, respetando reducir movimiento |
| Llegada del chófer | Fundido del texto y la barra avanza (móvil); en web cambia de golpe; sin háptica | Háptica + cambio de estado destacado; en web igual que en móvil |
| Código de recogida | Chófer: visto, háptica, sacudida si falla. Pasajero: la tarjeta desaparece sin confirmar | Confirmación breve «Código verificado» al pasajero |
| Fin del viaje | Fundido del texto y diálogo de valoración; el chófer navega antes de que confirme el servidor | Momento de llegada antes de valorar; el chófer espera la confirmación |

## A6. Accesibilidad

`node tools/experiencia/accesibilidad.cjs` (Chromium, 390 px; la escala de
texto de Flutter web se toma del tamaño de letra del navegador: 16 → 20,8 →
32 px). Resultado completo: `docs/capturas/A6-accesibilidad/resultado.json`.

| Pantalla | Escala 1,3 | Escala 2,0 | Sin etiqueta | < 48 px | Orden de foco (Tab) |
|---|---|---|---|---|---|
| Inicio | Bien | Tarjeta del próximo trayecto rota («14:5 / 0») | 0 | 10 (iconos 36–40, chips 36–38) | Recorre campos y barra inferior; salta «Ver vehículos y precios» |
| Login | Bien | «recuerdas / .» | 0 (imagen decorativa sin etiqueta) | 3 (enlaces de 17 px) | **Solo Google → correo → contraseña: nunca llega a «Iniciar sesión»** |
| Registro | Bien | «Bienveni / do» | **1: casilla de términos** | 5 | Llega a la casilla; **no a «Crear cuenta»** |
| Mis viajes | Truncados («Busine…») | Títulos truncados | 0 | 0 | Toda la lista es un solo grupo |
| Viaje con código | Bien | **Dígitos del código recortados**; «SO» | **1: botón atrás** | 1 | **Solo la barra inferior**: ni SOS, ni código, ni cancelar |
| Viaje con SOS | Bien | «SO» recortado | **1: botón atrás** | 1 | Igual: el SOS no es alcanzable con teclado |
| Cancelar (diálogo) | Bien | Opciones recortadas | 0 | 6 (radios de 40, botones de 32) | Correcto |
| Chófer inicio | Solapa con SOS | Acciones truncadas | 0 | 2 | Campana → «El pasajero no aparece» → pestañas (no llega a «Ingresar código») |
| Chófer viaje | Bien | «Ingresar código del…» | **1: botón atrás** | 2 | **Solo «El pasajero no aparece»** |
| Panel | Bien | Pestañas cortadas | 0 (pero «Bloquear» sin nombre) | 17 (pestañas de 39, botones de 30–32) | Correcto en lo visible |

Lector de pantalla en el SOS [seguro]: el botón expone «Ayuda SOS» con la
pista «Mantén pulsado dos segundos para avisar a central. Con lector de
pantalla, toca dos veces y confirma», y con el lector activo un toque pide
confirmación (`sos_button.dart`, test `incident_ui_test.dart` del repo). Pero
el SOS no está en el orden de foco con teclado (tabla). **NO VERIFICADO** con
TalkBack/VoiceOver reales.

## A7. Rendimiento y peso

`node tools/experiencia/rendimiento.cjs` (Chromium; «4G lenta» de DevTools:
1,6 Mbps bajada, 0,75 Mbps subida, 562,5 ms de latencia). Resultado:
`docs/capturas/A7-rendimiento/resultado.json`.

**Carga en frío de la build del modo emuladores** (CanvasKit local y sin
compresión: el servidor local no comprime) [seguro, medido]:

| Ruta | Red | Primera pintura | Primer fotograma Flutter | Interactivo | Transferido | Peticiones |
|---|---|---|---|---|---|---|
| `/` | sin límite | 1 508 ms | 1 914 ms | 2 896 ms | 11 537 KB | 30 |
| `/` | 4G lenta | 54 772 ms | 55 186 ms | 56 171 ms | 11 537 KB | 30 |
| `/legal/terminos` | 4G lenta | 54 700 ms | 54 949 ms | 55 533 ms | 11 469 KB | 29 |

En hosting los archivos van comprimidos y CanvasKit viene del CDN:
`main.dart.js` 4 170 KB → 916 KB brotli; `canvaskit.wasm` (chromium) 5 437 KB
→ 1 543 KB brotli. Con eso, unos 2,5–3 MB → **15–20 s en 4G lenta**
[Especulando: estimación, no medida en hosting].

**Peso** [seguro]: 201 MB, 111 archivos. Mayores: `business_bg.mp4` 71,6 MB,
`cta_bg.mp4` 51,0 MB, `canvaskit.wasm` 6,8 MB, `main.dart.js` 4,2 MB,
`hero_bg.png` 3,1 MB (6000×4000), seis imágenes de asientos de 2,1–2,2 MB.

**Documentos de Firestore al abrir cada pantalla** (contados en el canal
Listen del emulador; con la semilla de prueba) [seguro]:

| Pantalla | Desde | Documentos | Callables |
|---|---|---|---|
| Inicio | navegación | 11 | — |
| Mis viajes | navegación | 11 (las mismas 11 reservas otra vez) | — |
| Viaje | navegación | 13 | `getPickupCode` |
| Perfil | inicio de sesión | 49 | — |
| Chófer inicio | inicio de sesión | 17 | `registerDriverDevice` |
| Chófer solicitudes | inicio de sesión | 7 | — |
| Chófer ganancias | inicio de sesión | 17 | — |
| Panel | inicio de sesión | **102** | — |

**Los 5 mayores problemas**: (1) 55 s en blanco con 4G lenta (E4); (2) 122 MB
de vídeo, también en las apps nativas (E5); (3) 50,7 MB de imágenes, `hero_bg`
de 6000×4000 (E5); (4) el panel abre suscripciones a colecciones enteras: 102
documentos con una semilla mínima (E15); (5) cada pantalla del pasajero abre
otra vez la consulta de sus reservas (E16).

**Llamadas repetidas sin necesidad**: ninguna callable se repitió en estos
recorridos [seguro]; lo que se repite es la consulta de reservas del pasajero
entre pantallas (E16).

## A8. Errores

Con la sesión iniciada se cortó la red (`setOffline`), se «apagó» el backend
(Auth, Firestore y Functions sin respuesta) o las callables devolvieron 500 o
sin red. Capturas en `docs/capturas/A8-errores/` y en F5/F6.

| Pantalla | Sin red | Backend caído (recarga) | Error del servidor | Hallazgo |
|---|---|---|---|---|
| Inicio | Sigue igual, sin aviso | Login, sin decir que el servidor no responde | — | E12 |
| Mis viajes | Datos en caché, sin aviso | Login sin aviso | — | E12 |
| Viaje | Código en caché, sin aviso | Login sin aviso | Código: «No se pudo completar. Inténtalo de nuevo.» + Reintentar (bien) | E12 |
| Cancelar | «No se pudo cancelar. Revisa tu conexión…» (bien) | — | Mismo texto de conexión con un 500 | E13 |
| Perfil | Sin aviso | Login sin aviso | — | E12 |
| Chófer inicio | Sin aviso | Login sin aviso | — | E12 |
| Chófer solicitudes | «Conéctate para aceptar» sin aviso de red | Login sin aviso | — | E12 |
| Chófer viaje | Sin aviso | Login sin aviso | Deslizador bloqueado | E3 |
| Panel | Datos sin aviso | Login sin aviso | — | E12 |
| Login (backend caído) | — | «Sin conexión con el servidor. Revisa tu red e inténtalo de nuevo.» (bien) | — | — |
| Reto de segundo factor | — | — | «HttpException: Invalid HTTP date Invalid Date» | E6 |

Ninguna pantalla en blanco tras cargar y **0 errores de JavaScript** en las
309 capturas [seguro]. La única pantalla en blanco es la carga inicial (E4).
«Backend caído» con recarga lleva al login también porque en el modo
emuladores la sesión no sobrevive a una recarga (ver Límites).

## Límites de esta revisión

- **Modo emuladores, no producción.** Firebase JS y CanvasKit se sirven en local porque `www.gstatic.com` está bloqueado en esta sesión; los tiempos de A7 son de esa build sin comprimir (la estimación comprimida es [Especulando]).
- **La sesión no sobrevive a recargar la página en el modo emuladores** [seguro: la clave `firebase:authUser` desaparece de IndexedDB al recargar]; causa [Probable]: el SDK intenta refrescar el token contra el servidor real antes de que se aplique `useAuthEmulator`. La app no cierra la sesión de una cuenta activa al arrancar [seguro, leído]. En producción: **NO VERIFICADO**. Por eso cada captura inicia sesión y A8 «backend caído» acaba en el login.
- **Sin Google Maps** (no hay clave): no se ven el mapa, las direcciones con autocompletado ni la ruta; las pantallas de reserva con direcciones y vehículos con precio no se pudieron recorrer.
- **Sin Stripe**: pagos con tarjeta, retenciones y cobros no se probaron (callables de Stripe desactivadas en el ejecutor local).
- **Sin dispositivos reales**: háptica, notificaciones push, permisos nativos, TalkBack/VoiceOver, «quitar animaciones» del sistema en un teléfono real y apps Android/iOS: **NO VERIFICADO** (el SOS se comprobó con el binding de test de Flutter).
- **TOTP en el emulador**: el reto de segundo factor se vio con un factor de teléfono simulado; el alta de TOTP (pantalla del chófer) se capturó, pero el emulador de Auth no permite completarla [Probable].
- **Triggers**: corren en el ejecutor local escuchando Firestore; los programados (`scheduledCleanup`, escalado de SOS, reconciliación) no corren.
