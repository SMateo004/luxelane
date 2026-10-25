<!-- Inventario generado leyendo el código (agente de apoyo, revisado). Verificado con tests de widget (tools/experiencia/pruebas/a5_movimiento_test.dart, salida en docs/experiencia/a5_pruebas_salida.txt): SOS a 200 ms con «quitar animaciones», deslizador sin reintento, puntos de carga, pulso de la barra y esqueleto que siguen con reducir movimiento. Las referencias al SDK se leyeron en /opt/flutter (3.47.6); las builds y tests de este repo usan Flutter 3.29, donde el test del SOS reproduce el mismo comportamiento. -->
# A5 — Inventario de animaciones de `lib/` (rama `cierre/experiencia`)

Repositorio: rama `cierre/experiencia` (lectura de código, sin cambios).
Fecha: 2026-10-25.

## Método

- grep en todo `lib/` de: `AnimationController`, `Animated*(`, `TweenAnimationBuilder`, `Hero(`, `PageRouteBuilder`, `CustomTransitionPage`, `.repeat(`, `animateTo(`, `animateCamera`, `transitionDuration`, `showGeneralDialog`, `showModalBottomSheet`, `showDialog`, `*Transition`, `AnimatedBuilder`, `.forward(`, `ensureVisible`, `Lottie`, `VideoPlayer`, `Shimmer/Skeleton`, `LuxLoadingDots`, `LuxSlideToConfirm`, `LuxMotion.`, `CircularProgressIndicator`, `LinearProgressIndicator`, `ExpansionTile`, `RefreshIndicator`, `Switch.adaptive`, `SnackBar`. Después se leyó cada sitio. **[seguro]**
- No hay `Hero(` real (solo una clase llamada `_Hero` en `service_page_template.dart:235`), ni `PageRouteBuilder`, ni Lottie. **[seguro]**
- Sí hay vídeo (`video_player`, `home_web_page.dart:2452-2516`, assets `assets/videos/business_bg.mp4` y `cta_bg.mp4`). **[seguro]**

### Valores de `LuxMotion` (`lib/app/theme/lux_motion.dart`) **[seguro]**

| Token | Valor |
|---|---|
| `fast` | 120 ms |
| `base` | 220 ms |
| `slow` | 360 ms |
| `page` | 320 ms |
| `stagger` | 45 ms |
| `emphasized` | `Cubic(0.2, 0, 0, 1)` |
| `decelerate` | `Cubic(0.05, 0.7, 0.1, 1)` |
| `accelerate` | `Cubic(0.3, 0, 0.8, 0.15)` |
| `pressedScale` | 0.97 |
| `reduced(ctx)` | `MediaQuery.maybeDisableAnimationsOf(ctx) ?? false` |
| `of(ctx, d)` | `Duration.zero` si `reduced`, si no `d` |

### Lo que hace el propio Flutter con «reducir movimiento» (importante para leer la columna «Respeta»)

Se comprobó en el SDK local (`/opt/flutter`, Flutter 3.47.6):

- `AnimationController` con `AnimationBehavior.normal` (el valor por defecto) acorta `forward/reverse/animateTo/animateBack` al **5 %** de su duración cuando `SemanticsBinding.instance.disableAnimations` está activo (`animation_controller.dart:651`). **[seguro]** Esa bandera viene de la **plataforma** (accesibilidad del sistema), no del `MediaQuery` que se sobreescribe en los tests.
- `repeat()` no se acorta (`animation_controller.dart:714-741`, `_RepeatingSimulation` sin escala). **[seguro]**
- El scroll animado (`ScrollPosition.animateTo`, `ensureVisible`) usa `AnimationController.unbounded` (`scroll_activity.dart:597/708/730`), que es `preserve`: **no se acorta**. **[seguro]**
- Las animaciones implícitas (`AnimatedContainer`, `AnimatedSwitcher`, `AnimatedSize`, `TweenAnimationBuilder`…), las transiciones de ruta y las de hojas/diálogos usan `AnimationController` normal: se acortan al 5 % solo con la bandera de plataforma. **[seguro]** (`implicit_animations.dart:362`, `animated_switcher.dart:312`, `rendering/animated_size.dart:89`, `bottom_sheet.dart:248`).
- Si Flutter web traduce `prefers-reduced-motion` del navegador a `disableAnimations`: **NO VERIFICADO** (el engine web no está en la caché local). Es relevante porque la home web y las páginas de servicio solo existen en web.

Leyenda de la columna «Respeta»:

- **Sí**: consulta `LuxMotion.of` / `LuxMotion.reduced` (o sea `MediaQuery.disableAnimations`).
- **Sí (parcial)**: la consulta, pero algo sigue moviéndose o el temporizador sigue corriendo.
- **No·SDK**: duración fija, no consulta `MediaQuery.disableAnimations`; solo la acorta el SDK al 5 % si la bandera viene de la plataforma.
- **No**: ni el código ni el SDK la reducen (repeat infinito, scroll animado, vídeo, animación ligada al scroll, cámara del mapa).

Las duraciones son las del código; «/0» = cero con reducir movimiento vía `LuxMotion.of`.

---

## Tabla de animaciones

| # | archivo:línea | Widget / clase | Qué anima (propiedad · elemento visible) | Duración | Curva | ∞ | Respeta reducir mov. | Bloquea interacción | Riesgo al interrumpirse |
|---|---|---|---|---|---|---|---|---|---|
| **Rutas y diálogos globales** |
| 1 | app/router/lux_transitions.dart:10-37 | `luxFadeThroughPage` (rutas `_fade` de router.dart:356 y driver_router.dart:150) | opacidad 0→1 + translateY 12→0 px · página nueva | 320 entrada / 220 salida (`page`/`base`) | `decelerate` | no | Sí (parcial): `if (LuxMotion.reduced(context)) return child;` (l.20), pero `transitionDuration` sigue en 320 ms y la ruta sigue en transición sin moverse [seguro] | La ruta que sale ignora punteros mientras va en reverse (SDK routes.dart:1154-1157) [seguro]; la que entra acepta toques [seguro] | Ninguno: la ruta la gestiona el Navigator [Probable] |
| 2 | app/router/lux_transitions.dart:41-76 | `luxPushPage` (`_slide` de router.dart:359: verify-email, booking, ride-type, pago, añadir tarjeta, viaje activo del chófer en app pasajero) | entrada: slide X 100 %→0; la anterior se desplaza −25 % y baja a opacidad 0.6 | 320 / 260 (`base`+40) | `emphasized` / reverse `accelerate` | no | Sí (parcial), mismo motivo (l.49) [seguro] | Igual que #1 [seguro] | Ninguno [Probable] |
| 3 | app/router/lux_transitions.dart:79-100 | `luxModalPage` (`_slide` de driver_router.dart:153: viaje activo del chófer) | slide Y 100 %→0 · página | 360 / 220 (`slow`/`base`) | `emphasized` / `accelerate` | no | Sí (parcial) (l.86) [seguro] | Igual que #1 | Ninguno [Probable] |
| 4 | app/router/router.dart:370-381 | `_SplashPage` `TweenAnimationBuilder` | opacidad 0→1 + translateY 8 px · logotipo y barra | 900 ms | `easeOutCubic` | no | No·SDK [seguro] | No | Ninguno |
| 5 | app/router/router.dart:388 | `LinearProgressIndicator` indeterminado (splash) | barra que recorre · bajo el logotipo | 1800 ms (SDK) | SDK | **sí** | No [seguro] | No | Ninguno |
| 6 | core/widgets/lux_feedback.dart:298-356 | `showLuxSuccess` (`showGeneralDialog`) | fundido de la barrera + contenido | 220 / 0 (`LuxMotion.of(base)`) | `decelerate` | no | Sí (l.309) [seguro] | **Sí**: barrera modal hasta el cierre automático a 1800 ms (`Future.delayed`, l.311-313) o toque en la barrera; `booking_screen.dart:502-507` espera al cierre para navegar a `/ride/:id` [seguro] | `Future.delayed` no cancelable que hace `Navigator.pop`: si `pageBuilder` se reconstruye se programan varios pops, y uno que llegue con `ctx` aún montado durante la salida podría quitar la ruta de debajo [Especulando] |
| 7 | core/widgets/lux_site_chrome.dart:463-486 | `_MenuButton` (menú móvil web, `showGeneralDialog`) | opacidad + slide Y −3 %→0 · menú a pantalla completa | 320 ms fija | `easeOut` / `easeOutCubic` | no | No·SDK [seguro] | Barrera modal (descartable) | Ninguno |
| 8 | (varios) `showModalBottomSheet` con transición por defecto: driver_home_screen.dart:53 y :615, pickup_code_entry.dart:24, sos_entry.dart:24, profile_screen.dart:45, notification_bell.dart:83 | hojas inferiores | slide Y · hoja | 250 entrada / 200 salida (SDK bottom_sheet.dart:27-28) | SDK | no | No·SDK [seguro] | Modal. La de solicitud entrante es `isDismissible:false, enableDrag:false` (driver_home_screen.dart:58-59) [seguro] | Ver riesgo R3 (solicitud entrante) |
| 9 | (varios) `showDialog` por defecto: ride_screen.dart:160 (valoración), booking_screen.dart:239/397 y `_showAddGuestDialog`, driver_step_action.dart (liberar/no aparece), sos_button.dart:69, admin_dashboard_page.dart:140, admin_sections.dart:469/1319, etc. | diálogos Material | fundido+escala | 150 ms (SDK dialog.dart:1853) | SDK | no | No·SDK [seguro] | Modal | Ninguno |
| 10 | core/widgets/components.dart:1037-1070 | `showLuxSnackbar` (`SnackBar`) | entrada/salida del aviso | 250 ms (SDK snack_bar.dart:28) | SDK | no | No·SDK [seguro] | No | Ninguno |
| **Componentes core** |
| 11 | core/widgets/lux_feedback.dart:15-79 | `LuxFadeIn` | opacidad 0→1 + translateY 10→0 px; cascada `delay + 45 ms × min(index, 8)` | 360 (`slow`) + retraso | `decelerate` | no | Sí: `_c.value = 1` si `reduced` (l.49-51) [seguro] | No. El contenido es tocable mientras está a opacidad 0 [seguro: no hay IgnorePointer] | No: `Timer` cancelado y controller liberado en `dispose` (l.61-64) [seguro]. Usos: home_screen.dart:522-582 (7), trips_screen.dart:102/111, driver_home_screen.dart:255/1010/1040/1056, driver_queue_screen.dart:55/68, driver_earnings_screen.dart:32/39, profile_screen.dart:155, pickup_code_card.dart:83, components.dart:630 (EmptyState), admin_shared_widgets.dart:525, lux_feedback.dart:325/335 |
| 12 | core/widgets/lux_feedback.dart:86-132 | `LuxShimmer` (dentro de `LuxSkeletonList` :159-203) | brillo `ShaderMask` que barre en X · tarjetas esqueleto | 1400 ms | lineal | **sí** | Sí (parcial): con `reduced` devuelve el hijo sin brillo (l.109), pero el controller sigue en `repeat()` desde que se crea (l.96-99) [seguro] | No | No: `dispose` (l.102-104). Usos de `LuxSkeletonList`: admin_sections.dart:35/288/846/1018/1130/1421/1975, admin_finance_tab.dart:45, admin_alerts_tab.dart:35, trips_screen.dart:57, driver_home_screen.dart:150, driver_active_ride_screen.dart:22, driver_queue_screen.dart:22, driver_earnings_screen.dart:24, profile_screen.dart:90, payment_screen.dart:136 |
| 13 | core/widgets/lux_feedback.dart:210-294 | `LuxSuccessMark` (CustomPainter) | círculo que se rellena (0–55 %) + trazo del visto (45–100 %) | 900 ms | `decelerate` y `emphasized` por tramos | no | Sí: `_c.value = 1` si `reduced` (l.229-230) [seguro] | No | No |
| 14 | core/widgets/lux_feedback.dart:418-434 | `RideProgressBar` `AnimatedFractionallySizedBox` | ancho 0→1 de cada tramo · barra de etapas del viaje | 360 / 0 | `emphasized` | no | Sí (l.419) [seguro] | No | No |
| 15 | core/widgets/lux_feedback.dart:374-377, 423-432 | `RideProgressBar` pulso | opacidad 0.45↔1 del tramo actual | 1600 ms ida y vuelta | lineal | **sí** | Sí (parcial): con `calm` no se pinta el `FadeTransition` (l.402, 423), pero el controller repite siempre, también en `completed`/`cancelled` [seguro] | No | No: `dispose` (l.393-395) |
| 16 | core/widgets/lux_feedback.dart:547-565 | `LuxSlideToConfirm` arrastre | posición X del botón (sigue al dedo) + opacidad del texto `1-t` | gesto | — | no | n/a (lo controla el dedo) | Tras confirmar, `_done=true` anula gestos y `Semantics.onTap` (l.513, 550, 556) [seguro] | **Sí, R1**: `_done` solo se reinicia si cambia `label` (l.491-494). Si el paso falla en el servidor el estado no cambia y el control queda en «hecho» para siempre [Probable] |
| 17 | core/widgets/lux_feedback.dart:483-484, 566-568 | `LuxSlideToConfirm` regreso | X del botón vuelve a 0 al soltar antes del 85 % | 220 ms (`LuxMotion.base`, no `.of`) | lineal | no | No·SDK [seguro] | No | No: controller creado en `initState` y liberado en `dispose` (l.481-501) |
| 18 | core/widgets/lux_raised.dart:176-179 | `LuxRaisedButton` `AnimatedScale` | escala 1→0.97 al presionar | 120 / 0 | `emphasized` | no | Sí (l.118) [seguro] | No | No |
| 19 | core/widgets/lux_raised.dart:180-197 | `LuxRaisedButton` `AnimatedContainer` | relieve (decoración) + translateY −1 px al pasar el ratón | 120 / 0 | `emphasized` | no | Sí [seguro] | No | No |
| 20 | core/widgets/lux_raised.dart:199-210 | `LuxRaisedButton` `AnimatedSwitcher` | texto ↔ `LuxLoadingDots` | 220 / 0 | `decelerate`/`accelerate` | no | Sí (l.200) [seguro] | **Sí**: `_enabled = onPressed != null && !loading` (l.108) desactiva el botón mientras carga [seguro] | No |
| 21 | core/widgets/lux_raised.dart:221-266 | `LuxLoadingDots` | opacidad en onda de 3 puntos | 1100 ms | `easeInOut` por punto | **sí** | **No**: nunca consulta `MediaQuery` y `repeat()` no lo acorta el SDK [seguro] | No | No: `dispose` (l.237-240). Usos: LuxRaisedButton, components.dart:597 (LoadingOverlay), ride_screen.dart:574 (`_AssigningCard`), pickup_code_entry.dart:264 |
| 22 | core/widgets/components.dart:173-178 | `LuxPressable` `AnimatedScale` | escala al presionar (0.97 o la dada) | 120 / 0 | `emphasized` | no | Sí [seguro] | No | No. Usos: LuxCard, SectionChip, AdminFilterChip, `_GoControl`, home_screen.dart:669/926/1037/1144, profile_screen.dart:567 |
| 23 | core/widgets/components.dart:273-286 | `LuxCard` `AnimatedContainer` | color, borde y sombra al seleccionar | 220 / 0 | `emphasized` | no | Sí [seguro] | No | No |
| 24 | core/widgets/components.dart:458-477 | `LuxSegmented` `AnimatedPositioned` | posición X de la píldora seleccionada | 220 / 0 | `emphasized` | no | Sí (l.445) [seguro] | No | No |
| 25 | core/widgets/components.dart:494-506 | `LuxSegmented` `AnimatedDefaultTextStyle` | color y grosor de la etiqueta | 220 / 0 | lineal | no | Sí [seguro] | No | No |
| 26 | app/theme/app_theme.dart:281-289 | `ElevatedButton` `backgroundBuilder` | relieve al presionar | 140 ms fija | lineal | no | No·SDK [seguro] | No | No |
| 27 | app/shell/app_shell.dart:110-117 | `_MobileTabItem` | ancho 0↔18 px del indicador de pestaña | 250 ms fija | `easeOutCubic` | no | No·SDK [seguro] | No | No |
| 28 | app/shell/app_shell.dart:261-266 | `_ShellLink` (nav web) | ancho del subrayado | 250 ms fija | lineal | no | No·SDK [seguro] | No | No |
| 29 | app/driver_shell/driver_shell.dart:46 | `NavigationBar.animationDuration` | indicador de destino | 220 ms (`LuxMotion.base`, no `.of`) | SDK | no | No·SDK [seguro] | No | No |
| 30 | core/widgets/lux_site_chrome.dart:54-56 | `LuxSiteNav` | fondo transparente→sólido + borde | 400 ms fija | `easeOutCubic` | no | No·SDK [seguro] | No | No |
| 31 | core/widgets/lux_site_chrome.dart:179-185 | `LuxNavLink` | ancho del subrayado al pasar el ratón | 250 ms | `easeOutCubic` | no | No·SDK | No | No |
| 32 | core/widgets/lux_site_chrome.dart:288-296 | `LuxServicesMenu` `AnimatedRotation` | giro 180° del chevrón | 200 ms | lineal | no | No·SDK | No | Menú `OverlayPortal` solo por hover (l.205-216): en táctil no hay `onExit` y el desplegable puede quedarse abierto hasta tocar una opción [Especulando] |
| 33 | core/widgets/lux_site_chrome.dart:327-329 | `_DropItem` `AnimatedContainer` | fondo al pasar el ratón | 150 ms | lineal | no | No·SDK | No | No |
| 34 | core/widgets/lux_site_chrome.dart:353-361 | `_DropItem` `AnimatedOpacity` | flecha 0↔1 | 150 ms | lineal | no | No·SDK | No | No |
| 35 | core/widgets/lux_site_chrome.dart:389-395 | `LuxNavCta` | color + translateY −1 px al pasar el ratón | 200 ms | lineal | no | No·SDK | No | No |
| 36 | core/widgets/lux_map.dart:224-248 | `LuxMap._fitBounds` `animateCamera(newLatLngBounds)` | cámara del mapa encuadra recogida, destino y ruta | la del plugin nativo (NO VERIFICADO) | plugin | no | **No** [seguro: no consulta] | No | Reintentos con `mounted` (l.231-236) [seguro]; sin riesgo |
| 37 | core/widgets/lux_map.dart:250-253, 267-270 | `LuxMap._animateToDriver` | cámara sigue al chófer | plugin | plugin | no | **No** | No | Solo actúa si `origin` y `destination` son null (l.268-269), así que nunca en `RideScreen` [seguro]. Callback post-frame sin `mounted` y `_controller` liberado sin ponerse a null (l.299-301): posible excepción no capturada tras desmontar [Probable], sin bloquear la pantalla |
| 38 | core/widgets/lux_service_booking_card.dart:316-318 | `AnimatedSize` del error | alto del mensaje de error | 200 ms | lineal | no | No·SDK | No | No |
| 39 | core/widgets/lux_service_booking_card.dart:433-436 | `_Segmented` | fondo de la opción | 220 ms | `easeOutCubic` | no | No·SDK | No | No |
| **Home web (`home_web_page.dart`, `home_design.dart`, `drive_canvas_painter.dart`)** — ningún archivo usa `LuxMotion` [seguro] |
| 40 | home_web_page.dart:105-122 | `_scrollToKey` `animateTo` | scroll vertical hasta flota / empresas | 700 ms | `Cubic(0.16,1,0.3,1)` | no | **No** (scroll = `preserve`) [seguro] | No | No: callback post-frame que comprueba `currentContext` |
| 41 | home_web_page.dart:125-129 | `_scrollToTop` | scroll a 0 | 900 ms | `Cubic(0.16,1,0.3,1)` | no | **No** | No | No |
| 42 | home_web_page.dart:284-287, 324-327, 386 | `_HeroSection._intro` `FadeTransition(Interval .35–1)` | opacidad del titular + **barra de reserva** + paneles | 1600 ms (visible de 560 a 1600 ms) | `easeOut` | no | No·SDK | No: la barra se puede tocar mientras es invisible (0–560 ms) [seguro: FadeTransition no bloquea] | No: `dispose` (l.316-319) |
| 43 | home_web_page.dart:742-780 (uso :401) | `_ClipReveal` | slide Y 100 %→0 recortado · titular «Tu chófer te espera.» | 950 ms + 300 ms de retraso | `Cubic(0.16,1,0.3,1)` | no | No·SDK | No | `Future.delayed` no cancelable, comprueba `mounted` (l.766-768); sin riesgo |
| 44 | home_web_page.dart:605/627/649 | 3× `AnimatedSize` | alto de los paneles en línea (mapa recogida, mapa destino, fecha) | 420 ms | `easeInOut` | no | No·SDK | No | No |
| 45 | home_web_page.dart:839-844 | `_InlineMapPanel` `animateCamera(newLatLng)` | cámara al cambiar el lugar | plugin | plugin | no | **No** | No | No |
| 46 | home_web_page.dart:994-1000 | `_Pill` | fondo de la píldora de servicio | 200 ms | lineal | no | No·SDK | No | No |
| 47 | home_web_page.dart:1095-1110 | `_BarCta` | degradado al pasar el ratón | 200 ms | lineal | no | No·SDK | No | No |
| 48 | home_web_page.dart:1157-1162 | `_SolidBtn` | color al pasar el ratón | 200 ms | lineal | no | No·SDK | No | No |
| 49 | home_web_page.dart:1203-1215 | `_GhostBtn` | borde y fondo al pasar el ratón | 200 ms | lineal | no | No·SDK | No | No |
| 50 | home_web_page.dart:1268-1275 | `_DateDisplayTrigger` `AnimatedRotation` | giro del chevrón | 250 ms | lineal | no | No·SDK | No | No |
| 51 | home_web_page.dart:1454-1458 | `_InlineDatePanel` celda de día | fondo del día seleccionado | 180 ms | lineal | no | No·SDK | No | No |
| 52 | home_web_page.dart:1665-1760 (uso :169) | `_MarqueeBar` | translateX continuo del texto «Precios Fijos · Chóferes…» | 36 s por vuelta | lineal | **sí** | **No** [seguro] | No | No: `dispose` (l.1699-1702) |
| 53 | home_web_page.dart:1902-1906 | `_FleetCard` | borde y degradado al pasar el ratón | 280 ms | lineal | no | No·SDK | No | No |
| 54 | home_web_page.dart:2096-2112 | `_TestimonialsSection` `AnimatedSwitcher` cita | fundido cruzado de la cita (solo al tocar un punto; no hay autoplay) | 500 ms | lineal | no | No·SDK | No | No |
| 55 | home_web_page.dart:2115-2140 | `_TestimonialsSection` `AnimatedSwitcher` autor | fundido del autor | 400 ms | lineal | no | No·SDK | No | No |
| 56 | home_web_page.dart:2151-2157 | puntos de testimonios | ancho 6↔28 px | 250 ms | lineal | no | No·SDK | No | No |
| 57 | home_web_page.dart:2452-2516 (usos :2193, :2344) | `_VideoBackground` ×2 | vídeo de fondo en bucle, silenciado, reproducción automática | duración del vídeo | — | **sí** | **No** [seguro: `setLooping(true)` + `play()` sin consultar nada] | No | No: `dispose` y `!mounted` tras `initialize` (l.2473-2477) |
| 58 | home_web_page.dart:2617-2955 (uso :172) | `_BookSection` | ligado al scroll: sección fija + giro 3D `rotateY` de páginas (l.2921, 2950) | sin duración (sigue el scroll) | cúbica de salida sobre el progreso | — | **No** [seguro] | No | No |
| 59 | home_web_page.dart:2748-2757 | puntos del libro | tamaño 5↔7.5 px | 350 ms | lineal | no | No·SDK | No | No |
| 60 | home_web_page.dart:2768-2771 | indicador «SCROLL» | opacidad 0.4→0 | 600 ms | lineal | no | No·SDK | No | No |
| 61 | home_design.dart:142-257 + 14 usos en home_web_page.dart (1812, 1814, 1828, 2081, 2212 en lista, 2272, 2274, 2283, 2292, 2357, 2373, 2382, 2396, 2413) | `RevealOnScroll` (home) | opacidad 0→1 + slide (dx o dy hasta 160 px) + escala 0.94→1 al entrar en pantalla | 1100 ms + 0–220 ms | `Cubic(0.16,1,0.3,1)` | no | No·SDK | No: el contenido invisible sigue siendo tocable (p. ej. `_GhostBtn` en l.2292, fila CTA en l.2413) [seguro] | El contenido se queda a opacidad 0 hasta que un evento de scroll lo dispare (l.209-226); sin scroll no aparece [seguro]. `Future.delayed` con `mounted` [seguro] |
| 62 | home_design.dart:142-257 + 7 usos en service_page_template.dart (329, 331, 390 en lista, 486 en lista, 578, 705 en lista, 1084) | `RevealOnScroll` (páginas de servicio) | igual que #61 (dy 32–40 px) | 1100 ms + 0–300 ms | igual | no | No·SDK | Igual que #61 | Igual que #61 |
| 63 | home_design.dart:306-361 | `AnimatedCounter` | número que cuenta hasta el objetivo | 1800 ms | cuártica de salida | no | No·SDK | — | **Código muerto**: no se usa en `lib/` [seguro, grep] |
| 64 | home/presentation/pages/drive_canvas_painter.dart:12-74 | `DriveCanvasAnim` (CustomPainter de partículas) | partículas y trazos en canvas + parallax con el ratón | 10 s por vuelta | lineal | **sí** | **No** | — | **Código muerto**: el archivo no se importa en ningún sitio [seguro, grep] |
| **Páginas de servicio (`service_page_template.dart`)** — sin `LuxMotion` [seguro] |
| 65 | service_page_template.dart:122-126 | `_toTop` `animateTo` | scroll a 0 (al elegir clase o al pulsar «Reservar») | 900 ms | `Cubic(0.16,1,0.3,1)` | no | **No** | No | No |
| 66 | service_page_template.dart:128-135 | `_toFleet` `Scrollable.ensureVisible` | scroll hasta la flota | 800 ms | igual | no | **No** | No | No |
| 67 | service_page_template.dart:804-821 | `_ClassCard` | translateY −6 px + borde + sombra al pasar el ratón | 300 ms | `easeOutCubic` | no | No·SDK | No | No |
| 68 | service_page_template.dart:911-919 | `AnimatedSlide` flecha | X 0→10 % | 250 ms | lineal | no | No·SDK | No | No |
| 69 | service_page_template.dart:1027-1035 | `_FaqTile` `AnimatedRotation` | «+» gira 45° | 250 ms | lineal | no | No·SDK | No | No |
| 70 | service_page_template.dart:1041-1055 | `_FaqTile` `AnimatedSize` | alto de la respuesta | 280 ms | `easeOutCubic` | no | No·SDK | No | No |
| **Reserva (`booking_screen.dart`, `vehicle_details.dart`)** — sin `LuxMotion` [seguro] |
| 71 | booking_screen.dart:630-645 | `_revealCard` (`Future.delayed` 500 ms + `animateTo`) | scroll horizontal de las tarjetas de vehículo | 500 ms de espera + 420 ms | `easeOutCubic` | no | **No** | No | Comprueba `mounted` y `hasClients` (l.637) [seguro]; sin riesgo |
| 72 | booking_screen.dart:824-828 | héroe web | color de fondo según la clase | 600 ms | `easeInOut` | no | No·SDK | No | No |
| 73 | booking_screen.dart:833-848 | `AnimatedSwitcher` nombre de clase | fundido cruzado | 350 ms | lineal | no | No·SDK | No | No |
| 74 | booking_screen.dart:981-990 | icono de comodidad | fondo según la clase | 500 ms | lineal | no | No·SDK | No | No |
| 75 | booking_screen.dart:1232-1245 | `AnimatedSize` mapa de ruta | alto del mapa (oculto si es por horas) | 320 ms | `easeInOut` | no | No·SDK | No | No |
| 76 | booking_screen.dart:1420-1423 | `_mobileLayout` | color de fondo del paso de vehículo | 600 ms | `easeInOut` | no | No·SDK | No | No |
| 77 | booking_screen.dart:1788-1800 | tarjeta guardada | borde al seleccionar | 160 ms | lineal | no | No·SDK | No | No |
| 78 | booking_screen.dart:1935-1938 | selector fijo de vehículo `AnimatedSize` | alto del selector al pasar las tarjetas | 220 ms | `easeInOut` | no | No·SDK | No | No |
| 79 | booking_screen.dart:1941-1943 | `AnimatedOpacity` del selector | opacidad. **Nunca anima**: está dentro de la rama que exige la misma condición (`showStickySelector`, l.1938 y l.1943), así que siempre vale 1 [seguro] | 200 ms | lineal | no | No·SDK | No | No |
| 80 | booking_screen.dart:1963-1967 | chip del selector fijo | fondo y borde | 180 ms | lineal | no | No·SDK | No | No |
| 81 | booking_screen.dart:2172-2176 | `_VehicleCard` | ancho (crece al seleccionar) + translateY −4 px al pasar el ratón | 480 ms | `easeInOutCubic` | no | No·SDK | No | No |
| 82 | booking_screen.dart:2240-2243 | `_VehicleCard` visto | opacidad 0↔1 | 300 ms | lineal | no | No·SDK | No | No |
| 83 | booking_screen.dart:2410-2413 | `_BookOptionCard` | borde | 160 ms | lineal | no | No·SDK | No | No |
| 84 | booking_screen.dart:2639-2642 | `_LightServiceTypeTab` | fondo y sombra de la pestaña | 160 ms | lineal | no | No·SDK | No | No |
| 85 | vehicle_details.dart:267-268 | pie de foto `AnimatedSwitcher` | fundido cruzado del texto | 250 ms | lineal | no | No·SDK | No | No |
| 86 | vehicle_details.dart:447-450 | `_Carousel` `AnimatedSwitcher` | fundido cruzado de la foto | 350 ms | lineal | no | No·SDK | No | No |
| 87 | vehicle_details.dart:461-464 | puntos del carrusel | ancho 7↔22 px | 200 ms | lineal | no | No·SDK | No | No |
| 88 | vehicle_details.dart:562-564 | `_RoundedStage` | degradado de fondo | 500 ms | lineal | no | No·SDK | No | No |
| 89 | vehicle_details.dart:614-619 | `_UnderlineTab` | ancho del subrayado | 180 ms | lineal | no | No·SDK | No | No |
| 90 | vehicle_details.dart:658-664 | `_RoundNav` | relieve al presionar | 120 ms | lineal | no | No·SDK | No | No |
| **Home móvil (`home_screen.dart`)** |
| 91 | home_screen.dart:568-581 | `AnimatedSize` insignia de ruta | alto de la insignia | 220 / 0 | `emphasized` | no | Sí [seguro] | No | No |
| 92 | home_screen.dart:1117-1128 | `_HourSelector` `AnimatedSwitcher` | fundido del número de horas | 120 / 0 | lineal | no | Sí [seguro] | No | No |
| **App del chófer** |
| 93 | driver_home_screen.dart:158-170 | `AnimatedSwitcher` panel inactivo ↔ viaje activo | fundido cruzado del panel completo | 360 / 0 | `decelerate`/`accelerate` | no | Sí [seguro] | No: durante el cruce el panel saliente sigue en el árbol y se puede tocar (el SDK no lo envuelve en IgnorePointer, animated_switcher.dart) [Probable] | No |
| 94 | driver_home_screen.dart:207-217 | `_Header` título | fundido cruzado | 220 / 0 | lineal | no | Sí | No | No |
| 95 | driver_home_screen.dart:375-399, 429-453 | `_GoControl` ondas | 2 anillos que crecen ×1.7 y se desvanecen | 2400 ms | lineal | **sí** | Sí: `_sync` para y pone a 0 si `reduced` (l.393-398), y se reevalúa en `didChangeDependencies` [seguro] | No | No: `dispose` (l.402-404) |
| 96 | driver_home_screen.dart:461-467 | `_GoControl` círculo | color del botón conectar/en línea | 360 / 0 | `emphasized` | no | Sí | No | No |
| 97 | driver_home_screen.dart:702-712 | `_ActiveRidePanel` mensaje | fundido cruzado del texto del paso | 220 / 0 | lineal | no | Sí | No | No |
| 98 | driver_home_screen.dart:895-931 (uso :843) | `_PulseIndicator` | escala 1→1.9 + opacidad 0.45→0 del punto de la parada actual | 2000 ms | lineal | **sí** | **No** [seguro] | No | No: `dispose` (l.909-912) |
| 99 | driver_step_action.dart:115-119 | uso de `LuxSlideToConfirm` («Salir hacia la recogida», «He llegado», «Iniciar viaje», «Completar viaje») | ver #16/#17 | — | — | — | — | — | Ver R1. Clave `ValueKey('slide-${status.label}')` constante mientras no cambie el estado [seguro] |
| 100 | pickup_code_entry.dart:110-117, 183-185, 234-243 | `_shake` | translateX `sin(4πt)·8·(1−t)` de las casillas al fallar el código | 360 ms | lineal (atenuación propia) | no | Sí: no se lanza si `reduced` (l.183) [seguro] | No | No: creado en `initState`, `dispose` (l.115-123) |
| 101 | pickup_code_entry.dart:198-212 | `AnimatedSwitcher` teclado ↔ verificado ↔ bloqueado | fundido cruzado | 220 / 0 | `decelerate`/`accelerate` | no | Sí (l.190) | Teclado desactivado mientras `_busy` (l.284) y tras `_verified` (l.135) [seguro] | No |
| 102 | pickup_code_entry.dart:153-161 | pausa tras verificar | la hoja se queda con el visto antes de cerrarse | 1100 ms (400 ms con `reduced`) | — | no | Sí (parcial): la espera se acorta pero no se elimina [seguro] | Sí, la hoja no se puede usar durante la pausa (ya está verificada) | `Timer` sin guardar ni cancelar, comprueba `mounted` (l.159) [seguro]; si el chófer cierra la hoja antes, no pasa nada |
| 103 | pickup_code_entry.dart:298-317 | `_Slot` | borde y color de cada casilla | 120 / 0 | lineal | no | Sí | No | No |
| **Viaje del pasajero** |
| 104 | ride_screen.dart:493-497 | `_BottomPanel` `AnimatedSize` | alto del panel inferior (solo móvil) | 360 / 0 | `emphasized` | no | Sí (l.469) [seguro] | No | No |
| 105 | ride_screen.dart:506-528 | `_BottomPanel` `AnimatedSwitcher` | fundido cruzado de chip de estado + mensaje (solo móvil) | 360 / 0 | `decelerate`/`accelerate` | no | Sí | No | No |
| 106 | pickup_code_card.dart:83-108 | `PickupCodeCard` (`LuxFadeIn` + `AnimatedSwitcher`) | entrada de la tarjeta + cargando ↔ código ↔ error | 360 + 220 / 0 | `decelerate`/`accelerate` | no | Sí (l.82) [seguro] | No | No |
| **Incidencias** |
| 107 | incidents/presentation/widgets/sos_button.dart:35-66, 131-138 | `SosButton` pulsación mantenida | anillo `CircularProgressIndicator(value)` que se llena; al soltar vuelve a 0 | llenado 2000 ms (`holdDuration`); vaciado 220 ms (`LuxMotion.base`) o instantáneo con `reduced` | lineal | no | Sí (parcial): el vaciado consulta `reduced` (l.63), pero el llenado es un `forward()` normal → con la bandera de plataforma **el SDK lo acorta a 100 ms** [seguro, prueba aislada] | Es el propio mecanismo de seguridad | Ver R2 (crítico) |
| 108 | incident_help_sheet.dart:123-142 | `AnimatedSwitcher` título/estado del aviso | fundido cruzado | 220 / 0 | lineal | no | Sí | No | No |
| **Pagos** |
| 109 | payment_screen.dart:141-146 | `AnimatedOpacity` + `IgnorePointer` | lista de tarjetas atenuada a 0.55 mientras guarda | 220 / 0 | lineal | no | Sí | **Sí**: `IgnorePointer(ignoring: busy)` mientras `PaymentLoading` [seguro] | Si el estado se queda en `PaymentLoading` (sin error ni timeout), la lista queda bloqueada [Probable] |
| 110 | payment_screen.dart:282-294 | `AnimatedSwitcher` predeterminada | aparece/desaparece el visto | 220 / 0 | lineal | no | Sí | No | No |
| **Panel admin** |
| 111 | admin_dashboard_page.dart:310-317 | `AnimatedSwitcher` de sección | fundido cruzado de la sección completa | 220 / 0 | `decelerate` | no | Sí | No (el contenido saliente sigue siendo tocable durante el cruce) [Probable] | No |
| 112 | admin_shared_widgets.dart:74-77 | `SectionChip` | fondo y borde | 220 / 0 | `emphasized` | no | Sí | No | No |
| 113 | admin_shared_widgets.dart:122-125 | `AdminNavItem` | fondo seleccionado | 220 / 0 | `emphasized` | no | Sí | No | No |
| 114 | admin_shared_widgets.dart:261-263 | `AdminFilterChip` | fondo y borde | 220 / 0 | lineal | no | Sí | No | No |
| 115 | admin_incidents_strip.dart:353 | `ExpansionTile` «Registro» | despliegue | 200 ms (SDK expansion_tile.dart:26) | SDK | no | No·SDK | No | No |
| **Indicadores Material indeterminados y otros por defecto** |
| 116 | admin_sections.dart:1906, profile_screen.dart:427, notification_bell.dart:168, map_picker_dialog.dart:200, place_autocomplete_field.dart:380, lux_service_booking_card.dart:354 | `CircularProgressIndicator` indeterminado | giro | ~1333 ms por ciclo (SDK) | SDK | **sí** | **No** | No | No |
| 117 | trips_screen.dart:86 | `RefreshIndicator` | indicador de tirar para actualizar | SDK | SDK | no | No·SDK | No | No |
| 118 | admin_sections.dart:1084/1273/1947, components.dart:839 | `Switch.adaptive` | desplazamiento del interruptor | SDK | SDK | no | No·SDK | No | No |

### Recuento

- **118 filas** en la tabla. Algunas agrupan varios sitios (hojas, diálogos, spinners, `RevealOnScroll`). 2 son código muerto (#63, #64). Si se cuenta cada instancia de `RevealOnScroll` por separado, son 21 usos (14 en la home y 7 en servicios).
- **Respetan reducir movimiento consultando `MediaQuery` (`LuxMotion`): 38 filas** (sí o sí parcial): #1–3, 6, 11–15, 18–20, 22–25, 91–97, 100–110 y 111–114.
  - Sí (parcial), 7 de ellas: #1, 2, 3 (la ruta conserva la duración), #12 y #15 (el ticker sigue corriendo), #102 (pausa de 400 ms) y #107 (SOS).
- **No consultan nada: 78 filas.** De ellas:
  - **No·SDK: 62** (duración fija; solo se acortan al 5 % si la bandera viene del sistema; en web NO VERIFICADO).
  - **No: 16**, que ni el SDK reduce: #5, 21, 36, 37, 40, 41, 45, 52, 57, 58, 64, 65, 66, 71, 98 y 116.
- **n/a: 2** (#16 y #99, controlados por el gesto).
- Repeticiones infinitas: #5, 12, 15, 21, 52, 57, 64, 95, 98 y 116. Solo #12, #15 y #95 miran «reducir movimiento».

---

## (1) Animaciones que NO respetan reducir movimiento, por impacto

1. **SOS (#107), el caso al revés y crítico.** Con la bandera de accesibilidad del sistema activa («Quitar animaciones» en Android, y en iOS probablemente «Reducir movimiento» [Probable]), el SDK acorta el `forward()` de 2 s a **100 ms**. El mecanismo anti-toque-accidental desaparece.
   - Verificado con una copia aislada del widget y `accessibilityFeaturesTestValue(disableAnimations: true)`: 200 ms de pulsación disparan el aviso (`hits = 1`). **[seguro]**
   - El test del repo (`test/incidents/incident_ui_test.dart:296-313`) solo sobreescribe `MediaQuery` y comprueba 2100 ms, así que no lo detecta. **[seguro]**
   - Causa: `sos_button.dart:35` crea el controller sin `animationBehavior: AnimationBehavior.preserve`.
2. **Vídeos de fondo en bucle con autoplay** (#57, `home_web_page.dart:2452-2516`, dos secciones). Movimiento a pantalla grande e indefinido, sin pausa. **[seguro]**
3. **Libro 3D ligado al scroll** (#58, `home_web_page.dart:2617-2955`): `rotateY` de páginas a pantalla completa y sección fija. Es un detonante vestibular típico. **[seguro]**
4. **Marquesina infinita** (#52, `home_web_page.dart:1665-1760`): texto que se mueve sin fin, sin control de pausa. **[seguro]**
5. **Entradas de la home web y de las páginas de servicio**: `RevealOnScroll` (#61, #62: 21 usos, desplazamientos de hasta 160 px y escala), `_ClipReveal` (#43) e intro del héroe (#42, 1,6 s). No consultan `MediaQuery`; en web, que es donde viven, la mitigación del SDK es NO VERIFICADO. **[seguro]**
6. **Scroll animado largo** (#40, 41, 65, 66, 71: 700–900 ms y 420 ms). El SDK nunca lo acorta (controller `unbounded` = `preserve`). **[seguro]**
7. **`_PulseIndicator` del chófer** (#98): pulso infinito en la pantalla que se usa conduciendo. **[seguro]**
8. **`LuxLoadingDots`** (#21): onda infinita en todos los botones con `loading`, en `LoadingOverlay` y en «Asignando a tu chófer» (que puede durar minutos). **[seguro]**
9. **Spinners Material indeterminados** (#5, #116). **[seguro]**
10. **Reserva** (#71–#90): colores de 500–600 ms, ancho de tarjeta de 480 ms, fundidos de 250–350 ms. Todo No·SDK. **[seguro]**
11. **Cámara del mapa** (#36, #37, #45): `animateCamera` siempre animado. **[seguro]**
12. **Detalles pequeños**: hovers y subrayados de `lux_site_chrome` (#30–35), `app_shell` (#27, 28), `app_theme` (#26), `NavigationBar` (#29), regreso del deslizador (#17, usa `LuxMotion.base` y no `.of`), splash (#4), menú móvil web (#7), hojas, diálogos, snackbar, `ExpansionTile` y `Switch`. **[seguro]**

---

## (2) Riesgos de interrupción concretos

- **R1. `LuxSlideToConfirm` queda en «hecho» para siempre si falla el paso (alto) [Probable].**
  - `lux_feedback.dart:559-565` pone `_done = true` y llama a `onConfirmed`; a partir de ahí los gestos son null (l.550, 556) y `Semantics.onTap` también (l.513).
  - Solo se reinicia si cambia `label` (l.491-494).
  - Cuando `_advance` falla (`driver_bloc.dart`, `_onArrived/_onStartTrip/_onCompleteTrip` → `_advance`; si falla emite solo `notice`), el estado del viaje no cambia, la clave `ValueKey('slide-${status.label}')` (`driver_step_action.dart:116`) tampoco y el `State` se conserva.
  - Resultado: el chófer ve el visto y no puede repetir «Salir hacia la recogida», «He llegado» o «Iniciar viaje» sin reiniciar la app. Aplica en `driver_home_screen.dart:809` y `driver_queue_screen.dart:269`.
  - En la pantalla de viaje activo, «Completar» navega a `/driver` antes de confirmar (`driver_active_ride_screen.dart:211`).
  - No hay test que lo cubra [seguro: grep en `test/`].
- **R2. El SOS se activa con 100 ms de pulsación si el sistema tiene las animaciones desactivadas (crítico) [seguro].** Ver (1).1. Puntos: `sos_button.dart:35` (controller), `:55` (`forward`) y `:37` (`completed` → `_activate`).
- **R3. Hoja de solicitud entrante sin salida si se desmonta `DriverHomeScreen` (medio) [Probable].**
  - `driver_home_screen.dart:53-84`: `isDismissible:false, enableDrag:false`, en el navegador raíz.
  - `onAccept`/`onDecline` usan el `context` de la pantalla (`context.read`) y cierran solo `if (mounted)`.
  - Si la pantalla se desmonta con la hoja abierta (`context.go('/driver/onboarding')` en l.117, cierre de sesión), los botones lanzan al leer un contexto desactivado y no cierran la hoja: queda un modal que cubre la app.
  - Además, «la solicitud desapareció» (l.122-125) hace `Navigator.of(context, rootNavigator: true).pop()` a ciegas: si encima hay otra ruta (un diálogo), cierra esa y no la hoja [Probable].
- **R4. `showLuxSuccess`: `pop` programado sin cancelar (bajo) [Especulando].**
  - `lux_feedback.dart:311-313` programa `Navigator.pop` a 1800 ms dentro de `pageBuilder`.
  - Si el diálogo se reconstruye se programan varios. Si el usuario lo cierra tocando la barrera y el temporizador cae mientras `ctx` sigue montado (salida de 220 ms), el `pop` quitaría la ruta de debajo.
  - En la práctica `booking_screen.dart:507` hace `context.go` justo después, lo que lo mitiga.
- **R5. `LuxMap._animateToDriver` tras desmontar (bajo) [Probable].**
  - `lux_map.dart:267-270` añade un callback post-frame sin `mounted`.
  - `dispose` libera `_controller` sin ponerlo a null (l.299-301), así que puede saltar una excepción asíncrona sin capturar.
  - No deja la pantalla inutilizable.
- **R6. Contenido invisible pero tocable / que no aparece sin scroll (bajo) [seguro].**
  - `home_web_page.dart:386`: barra de reserva a opacidad 0 durante 560 ms, tocable.
  - `RevealOnScroll` (`home_design.dart:209-226`) solo se dispara con eventos de scroll o de dependencias: un bloque bajo el pliegue queda a opacidad 0 hasta que haya scroll, y sus botones (`home_web_page.dart:2292`, `:2413`) se pueden pulsar sin verse.
  - `LuxFadeIn` igual, durante su retraso.
- **R7. Pagos bloqueados si `PaymentLoading` no termina (medio) [Probable].** `payment_screen.dart:141-146`: `IgnorePointer(ignoring: busy)` sin timeout.
- **R8. Paneles salientes tocables durante los `AnimatedSwitcher` grandes (bajo) [Probable].** `driver_home_screen.dart:158` (360 ms) y `admin_dashboard_page.dart:310`: el SDK no bloquea los hijos que salen.
- **Sin riesgo [seguro]:** todos los `AnimationController` del repo tienen `dispose`. `LuxFadeIn` cancela su `Timer`. `_ClipReveal`, `RevealOnScroll`, `_revealCard` y la pausa de `pickup_code_entry.dart:158` usan `Future.delayed`/`Timer` sin cancelar, pero comprueban `mounted`. `_VideoBackground` libera el controller si se desmonta durante `initialize`.

---

## (3) Momentos clave: qué pasa hoy en pantalla

### Confirmar reserva (`booking_screen.dart`)

Sí hay animación y feedback, con huecos. [seguro]

- Al pulsar «Reservar», `LuxRaisedButton` hace háptica `confirm` (solo móvil, `lux_raised.dart:168-169`). El texto pasa a `LuxLoadingDots` y el botón se desactiva (#20).
- Si falta precio del servidor, solo aparece un snackbar con el precio (l.441-455).
- Con `BookingCreated` (efectivo, l.663-670) o tras `confirmPayment` de Stripe (l.528-529) se llama a `showLuxSuccess`:
  - háptica de éxito;
  - barrera a opacidad 0.88;
  - visto animado de 900 ms;
  - título «Reserva confirmada» con `LuxFadeIn` a 380 ms y mensaje a 460 ms;
  - cierre solo a 1,8 s;
  - después `context.go('/ride/:id')` con fundido de 320 ms.
- **Hueco:** con tarjeta y «viaje lejano» (`PaymentIntentCreated` sin `clientSecret`, l.716-722) se navega directo a `/ride/:id`: no hay visto, ni háptica, ni mensaje.
- En web, las hápticas no hacen nada (`lux_motion.dart:49-63`).

### Llegada del chófer (`ride_screen.dart`, `driverArriving` → `driverArrived`)

[seguro]

- **Móvil:**
  - el chip y el texto cambian con fundido de 360 ms a «Tu chófer ha llegado y te espera. Tómate tu tiempo.» (l.506-528, 143-144);
  - el tercer tramo de `RideProgressBar` se rellena (360 ms) y el pulso pasa a él;
  - el panel crece con `AnimatedSize`;
  - aparece `PickupCodeCard` con `LuxFadeIn`, primero en esqueleto y luego el código (fundido de 220 ms).
- **No hay** háptica, sonido ni ningún cambio en el mapa: `LuxMap` no dibuja marcador del chófer (`lux_map.dart:168-192`, solo recogida y destino) y la cámara no lo sigue porque hay origen y destino (l.267-270). La ubicación del chófer se lee (`ride_screen.dart:216-230`) pero no se ve.
- **Web:** el texto de estado cambia de golpe (sin `AnimatedSwitcher`, l.365-382), no hay barra de progreso y solo la tarjeta del código entra con `LuxFadeIn`.
- Si llega una notificación push en ese momento: NO VERIFICADO.

### Código de recogida

[seguro]

- **Chófer (`pickup_code_entry.dart`):**
  - cada tecla da háptica `tap` y anima el borde de la casilla (120 ms);
  - al cuarto dígito aparecen los puntos de carga y el teclado se desactiva;
  - **éxito:** háptica de éxito y fundido a `_Verified` con `LuxSuccessMark` (900 ms), «Pasajero verificado» y «Desliza «Iniciar viaje»…»; a los 1100 ms (400 ms con reducir movimiento) se cierra la hoja (salida de 200 ms);
  - **código erróneo:** háptica de aviso, sacudida de 360 ms (sin ella con reducir movimiento), casillas en rojo, dígitos borrados y mensaje;
  - **error de red:** conserva los dígitos y muestra «Reintentar»;
  - **bloqueado:** fundido a la vista de bloqueo.
- **Pasajero (`pickup_code_card.dart` dentro de `ride_screen`):** la tarjeta no reacciona a la verificación. Cuando el estado pasa a `verified`, `_pickupSection` devuelve `SizedBox.shrink()` (`ride_screen.dart:322-326`):
  - en móvil la tarjeta desaparece mientras el panel encoge (360 ms) y el texto cambia con fundido a «Código verificado. Tu viaje empieza en un momento.»;
  - en web desaparece de golpe;
  - no hay visto, ni háptica, ni confirmación de que el código «funcionó».

### Fin del viaje (`ride_screen.dart`, `inProgress` → `completed`)

[seguro]

- **Pasajero móvil:**
  - el chip y el texto cambian con fundido a «Has llegado. Gracias por viajar con Luxelane.»;
  - la barra se completa y el pulso se apaga (`step < 5` falso; el controller sigue en marcha);
  - el botón principal pasa a «Calificar viaje»;
  - en el siguiente fotograma se abre `showDialog` de valoración (fundido y escala de 150 ms) si no hay valoración (l.76-84).
  - No hay visto de éxito, háptica, resumen ni importe animado.
- **Pasajero web:** el texto cambia de golpe y se abre el mismo diálogo.
- **Chófer:**
  - al deslizar «Completar viaje» el botón muestra el visto y, en la pantalla de viaje activo, navega en seguida a `/driver` (`driver_active_ride_screen.dart:211`) antes de que el servidor confirme;
  - en la home el panel cambia a inactivo con fundido de 360 ms cuando desaparece el viaje activo;
  - no hay momento de éxito;
  - si falla, solo sale un snackbar con el aviso y, fuera de la pantalla de viaje activo, el deslizador queda bloqueado (R1).
