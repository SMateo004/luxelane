# Auditoría técnica — Luxelane (repo SMateo004/luxelane)
Fecha: 18 de octubre de 2026. Base: commit d2b7d72. Lectura de código, tests y auditoría de dependencias de Cloud Functions. Etiquetas: [seguro] lo leí o ejecuté; [Leído por revisor] lo leyó un revisor con ruta:línea; [Probable] inferencia; NO VERIFICADO no se pudo comprobar.

## A. Veredicto
NO está lista para un piloto con clientes reales. Incumple el criterio de piloto: F5 (verificación por código) y F9 (SOS) no existen, y hay hallazgos críticos de seguridad abiertos.
Hay base seria: app Flutter + Firebase, cobro con Stripe conectado, roles que no se pueden auto-asignar, despacho manual con auditoría de admin, tests que pasan. Es un MVP de reserva y cobro, no todavía un servicio de chofer ejecutivo con la seguridad prometida.

Bloqueos principales, por gravedad:
1. No existe verificación pasajero-chofer ni botón SOS; el chofer completa el viaje deslizando y eso dispara el cobro.
2. El precio de la reserva lo fija el cliente.
3. Exposición de datos personales: driverProfiles legible por cualquier usuario autenticado; reservas pending legibles por cualquier chofer, incluso no verificado, con datos de terceros en notes.
4. Pagos y despliegue frágiles: sin webhook de Stripe ni idempotencia; un solo entorno (producción); CI despliega a producción en cada push a main sin aprobación; release Android firmado con claves de debug.
5. Verificación de cuentas falsa (isVerified true desde el cliente), sin 2FA, sin App Check en ningún callable.

## B. Inventario técnico
Flutter (BLoC, get_it, go_router), web+Android+iOS. Backend Firebase: Auth, Firestore, Cloud Functions TypeScript (Node 22), Messaging, Crashlytics, Performance. Pagos: Stripe con captura manual. Mapas: Google Maps con clave por defecto embebida. Dos apps: pasajero (lib/main.dart) y chofer (lib/main_driver.dart). Estados de reserva existentes (7): pending, confirmed, driver_arriving, driver_arrived, in_progress, completed, cancelled (lib/core/enums/enums.dart:8-16). Un solo proyecto Firebase: luxelane-4e7ae. Código muerto: Ride/RideBloc/RideRepository, DriveCanvasAnim, ErrorBoundary (no captura nada), FeatureFlags estáticos, RideTypePage, router de chofer duplicado, luxModalPage.

## C. Cobertura de flujos (sección 12 del plan de negocio)
F1 registro/verificación: PARCIAL (verificación real, 2FA y aceptación de términos faltan).
F2 traslado aeropuerto: PARCIAL (sin estado real de vuelo ni hora de recogida por vuelo; tarifa no validada en servidor).
F3 por hora: FUNCIONAL con huecos.
F4 reserva para tercero: SOLO UI/PARCIAL (el tercero va como texto concatenado en notes; sin enlace de seguimiento).
F5 día del servicio: PARCIAL (sin verificación por código; estado Verificada no existe).
F6 modificar/cancelar: PARCIAL (modificar ausente; política de cancelación contradictoria entre legal_page.dart:65-69 y reglas/UI; sin cargo ni no-show).
F7 pago/factura/recibo: PARCIAL (cobro sí; factura NIT, recibo, historial de pagos y webhooks no).
F8 post-servicio: PARCIAL (calificación de un solo número; sin comentario, propina ni prepago).
F9 SOS/incidente: AUSENTE.
F10 alta de empresa: SOLO UI (formulario de lead en businessLeads).
F11 reserva corporativa: AUSENTE. F12 facturación corporativa: AUSENTE.
F13 alta de chofer: PARCIAL (sin postulación pública ni subida de documentos; el admin verifica a mano).
F14 jornada del chofer: PARCIAL (sin timeout de aceptación; rechazo solo en memoria; sin checklist).
F15 despacho: PARCIAL (manual; assignNearestDriver en index.ts:884 y acceptBooking no se llaman desde ningún cliente; sin mapa ni alertas).
F16 contingencia: AUSENTE (solo flag de mantenimiento).
F17 administración: PARCIAL (tarifas, roles, bloqueo y auditoría sí; faltan zonas, cupones, roles de operador, 2FA).
Aerotaxi: AUSENTE (correcto, es fase diferida).
Matriz de estados: faltan Borrador, Pendiente de pago, Verificada, Cerrada, Modificada, No-show, Incidente; Confirmada y Asignada son un solo estado. Las acciones de pasajero y chofer no generan auditoría (solo el admin escribe admin_logs, desde el cliente). La reasignación no avisa a nadie. El chofer no recibe aviso in-app.

## D. Seguridad
D1 CRÍTICO. Sin verificación por código ni SOS; el chofer completa y cobra solo. firestore.rules:110-116; lib/features/driver/presentation/pages/driver_active_ride_screen.dart:210-216.
D2 CRÍTICO. Precio controlado por el cliente. firestore.rules:130-144 (acepta cualquier estimatedPrice > 0); functions/src/index.ts:586-611 solo marca pricingReview; Stripe cobra ese precio (index.ts:164, 234).
D3 ALTO. Sin App Check ni límites de tasa en los 12 callables (index.ts líneas 132, 188, 323, 386, 413, 429, 446, 475, 577, 806, 884, 967); firebase_app_check ausente en pubspec.yaml.
D4 ALTO. driverProfiles legible por cualquier autenticado (ubicación en vivo y licencia). firestore.rules:95.
D5 ALTO. Reservas pending legibles por cualquier chofer, también no verificado, con PII en notes y las preferencias del pasajero (riderPreferences). firestore.rules:121-122.
D6 ALTO. Identidad: isVerified true desde cliente (lib/features/auth/data/repositories/auth_repository_impl.dart:120); sendPhoneVerification no hace nada (:334); sin 2FA; sin vinculación de dispositivo del chofer; rol solo en Firestore sin custom claims; bloquear a un usuario no revoca sus tokens ni deshabilita la cuenta.
D7 ALTO. Sin webhook de Stripe (no hay onRequest ni constructEvent); sin idempotency keys (functions/src/stripe_service.ts:18, 42, 89); capturePayment (index.ts:188) acepta el stripePaymentIntentId del cliente sin compararlo con el de la reserva.
D8 ALTO. Un solo entorno; CI despliega a producción en cada push a main sin aprobación (.github/workflows/ci.yml:247, 277) con w9jds/firebase-action@master; .firebaserc y firebase_options.dart apuntan a luxelane-4e7ae; DEPLOY.md:24-25 menciona luxelane-prod y luxelane-dev, que no existen en la configuración.
D9 ALTO. Release Android firmado con claves de debug. android/app/build.gradle.kts:50-52.
D10 MEDIO. Admin escribe directo a Firestore pagos, finalPrice, roles (lib/features/admin/data/repositories/admin_repository_impl.dart:332-349, 387-436, 518-528) y comisión (updateFinanceSettings, admin_repository_impl.dart:439); los logs de auditoría salen del cliente, omitibles o falsificables (firestore.rules:310-315); en servidor solo escriben log refundPayment (index.ts:356), deleteAccount (index.ts:516) y backfillSettlements (index.ts:843).
D11 MEDIO. Errores de Stripe llegan crudos al cliente (functions/src/errors.ts:27-29, index.ts:180, 215, 370); STRIPE_SECRET_KEY se lee con process.env ?? '' (stripe_service.ts:4) y el CI no la inyecta; DEPLOY.md documenta functions:config:set, obsoleto.
D12 MEDIO. Claves de Maps por defecto embebidas en lib/core/config/env.dart:7, android/app/build.gradle.kts:21 e ios Luxelane.xcconfig:5; restricciones no documentadas; clave de Firebase web en firebase_options.dart:64 y web/firebase-messaging-sw.js:6.
D13 MEDIO. Faltan cabeceras de seguridad en firebase.json (CSP, frame-ancestors); validación de entradas de callables solo "truthy"; deleteAccount conserva en las reservas direcciones exactas y driverInfo (nombre y teléfono del chofer).
D14 MEDIO. npm audit de producción en functions: 10 vulnerabilidades (8 moderadas, 2 altas: firebase-admin y node-forge).
D15 MEDIO. web/index.html:7 con maximum-scale=1.0 (bloquea el zoom); Stripe.js bloqueante; importa firebase-app.js sin usarlo.
Positivos: los roles no se pueden auto-asignar; el importe de Stripe se calcula en servidor al crear el PaymentIntent; el reembolso es solo admin con log en servidor; no se guardan números de tarjeta; no hay secretos privados en el árbol actual (solo placeholders sk_live_XXX, pk_live_XXX).
No verificado: historial git previo (un solo commit), restricciones de las claves en Google Cloud, copias de seguridad en la consola, enumeración de correos, campos que serializa Booking.toJson.

## E. UX/UI
Bueno: paleta marfil + zafiro con tokens (lib/app/theme/app_theme.dart:12-40), Cormorant Garamond + Montserrat, catálogo de movimiento (lux_motion.dart), tres transiciones de ruta, barra de progreso de viaje, slide-to-confirm con háptica, estados vacíos y de éxito bien cuidados.
Problemas: main.dart:27-41 espera 10 variantes de Google Fonts por red antes de runApp y assets/fonts está vacío; 120 MB de video y 51 MB de imágenes en el bundle; setState por scroll en toda la home web (home_web_page.dart:91); dos sistemas visuales (LD.* en web pública y LuxColors en app) con 140 Color(0x…) y 160 TextStyle( fuera del tema; se viola la regla "sin negro"; reducir movimiento no se respeta en web pública, reserva ni servicios; ErrorBoundary no hace nada y LuxErrorScreen no se usa, sin detección de conexión, un booking inexistente deja "Cargando" para siempre; 21 Semantics frente a 56 GestureDetector, tapas de 38 y 46 dp, etiquetas de 9 px, contrastes de 4,34:1 y 3,92:1 que fallan AA, solo tema claro; sin l10n, <title> y description en inglés, manifest con valores por defecto de Flutter; la web afirma "Cobertura Mundial", "más de 50 ciudades" y "Puntualidad Garantizada" (no verificable y contradice el plan de una sola ciudad); aparecen nombres de marcas de terceros en docs/DESIGN_SYSTEM.md:6 y un comentario en lib/features/booking/presentation/pages/booking_screen.dart:2015; nombre de marca en el código "Luxelane"/"LUXELANE" frente a "LuxLane" en el plan de negocio.

## F. Calidad
functions: tsc compila sin errores; jest 20/20 en 4 suites. No hay tests de reglas de Firestore ni de autorización por objeto. Sin webhooks, sin monitoreo de alertas, sin backups en el repo, sin staging.

## G. Banderas legales (requieren abogado)
Clasificación del servicio (aplicación de transporte con registro ATP, DS 5199, o servicio privado/turístico); facturación fiscal NIT/razón social ausente; política de cancelación contradictoria; protección de datos (D4, D5) y sin aceptación de términos registrada; afirmaciones publicitarias sin sustento.

## H. Plan de cierre
Bloqueantes: #1 código de verificación + estado verified; #2 botón SOS e incidentes; #3 precio calculado en servidor (callable createBooking, reglas niegan precio del cliente); #4 cerrar lecturas (driverProfiles, pending, tercero estructurado); #5 App Check + límites de tasa + errores sin detalle + validación de esquema; #6 pagos (webhook con firma, idempotencia, validar PaymentIntent contra la reserva); #7 staging separado + deploy a producción con aprobación + secretos; #8 firma de release Android y restricciones de claves; #9 verificación real de correo/teléfono, 2FA para chofer y admin, custom claims, revocar sesión al bloquear.
Importantes: #10 política de cancelación y no-show coherente; #11 auditoría de transiciones en servidor y aviso al reasignar; #12 estado real de vuelo y hora de recogida por vuelo; #13 fuentes empaquetadas, splash, comprimir videos y PNG, quitar setState por scroll; #14 manejo de errores y aviso sin conexión; #15 factura, recibo e historial de pagos; #16 npm audit fix y cabeceras de seguridad; #17 quitar afirmaciones no verificables, copy en español, manifest y title.
Deseables: reducir movimiento en web pública, accesibilidad (48 dp, Semantics, contraste, texto escalable), unificar LD y LuxColors, tema oscuro, limpiar código muerto, quitar nombres de terceros de docs, calificación multicriterio, corporativo (F10–F12) y contingencia (F16) para la Fase 2.
Orden sugerido: #4, #3, #1, #2, #5, #6, #7, #8, #9, #10, #11, en paralelo con #13 y #14.

Criterio estricto de "lista para piloto": F2, F5 (con código), F7 (pago real) y F9 (SOS) funcionan de punta a punta; cero hallazgos CRÍTICOS abiertos; autorización por objeto probada con tests; build y tests pasan; despliegue a producción protegido por aprobación.
