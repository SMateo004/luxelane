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
D16 ALTO. Teléfono personal del chofer expuesto: publishDriverInfo lo copiaba en driverInfo, legible por el pasajero desde la confirmación y para siempre en el historial. RESUELTO PARCIALMENTE (rama cierre/piloto): el teléfono va en bookings/{id}/driverContact/phone, escrito solo por el servidor y legible por el pasajero solo de driver_arriving a in_progress; el botón «Llamar a tu chófer» solo aparece en esa ventana. PENDIENTE: sustituirlo por llamada enmascarada para que el pasajero nunca vea el número real; migrar reservas existentes (script de migración, modo DRY-RUN por defecto).
D17 ALTO. Notificaciones push de iOS sin entitlements: no existe ios/Runner/*.entitlements ni aps-environment, aunque Info.plist declara UIBackgroundModes remote-notification. Las push no llegarán en iOS.
D18 ALTO. Pasajero y chófer comparten el identificador com.luxelane.app (android/app/build.gradle.kts:57,71; PRODUCT_BUNDLE_IDENTIFIER en el proyecto de iOS) y la app de pasajeros declara ubicación en segundo plano (Info.plist UIBackgroundModes location y NSLocationAlwaysAndWhenInUseUsageDescription; FOREGROUND_SERVICE_LOCATION en AndroidManifest.xml), que solo necesita el chófer: riesgo de rechazo en tiendas y de pedir un permiso que el pasajero no usa.
D19 MEDIO. La clave REST de Maps (Places, Geocoding y Directions desde Android/iOS, --dart-define=GOOGLE_MAPS_KEY) viaja dentro de la app y una clave REST no se puede restringir por aplicación (solo por API); cualquiera puede extraerla y gastar la cuota.
D20 ALTO. Los precios por defecto del código (DefaultPricing en la app, DEFAULT_FARES en functions) no coinciden con el plan de negocio: p. ej. 98 Bs por 16 km en business frente a un ticket ilustrativo de 55 USD del plan [Especulando sobre la cifra del plan]. No deben mostrarse al público.
D21 MEDIO. Desde que bookings tiene allow create: if false y createBooking solo acepta pasajeros, ni el administrador ni un operador pueden crear una reserva en nombre de un cliente (reserva asistida por WhatsApp o teléfono, cuentas corporativas).
D22 ALTO. «Forzar verificación» (adminOverrideVerify, functions/src/trip_flow.ts) deja una reserva verificada sin el código del pasajero con solo el rol admin; hoy el admin no tiene segundo factor (D6). Una cuenta de admin robada puede iniciar viajes sin el pasajero. Mitigación actual: motivo obligatorio, evento en bookings/{id}/events, alerta pickup_override y entrada en admin_logs, todo escrito por el servidor.
D23 ALTO. Respuesta operativa a incidentes: el SOS avisa a central (panel con sonido, push a admins con token, escalada cada 2 minutos), pero no hay definido quién atiende, en qué horario ni con qué protocolo (turnos, tiempo máximo de respuesta, cuándo llamar a las autoridades, a quién avisar si nadie reconoce). Sin eso, un incidente puede quedar sin atender.
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

## J. Datos y privacidad de la verificación en recogida y del SOS

| Dato | Dónde | Quién lo lee | Retención |
|---|---|---|---|
| Sal del código de recogida e intentos fallidos | bookings/{id}/private/pickup | Solo el servidor | Sin borrado (pendiente) |
| Código de recogida | No se guarda: se recalcula con HMAC | El pasajero de la reserva (getPickupCode) | — |
| Pasos del viaje (quién, versión de app, motivo del admin) | bookings/{id}/events | Pasajero, chófer asignado y admin | Sin borrado (pendiente) |
| Ubicación del chófer al llegar, verificar y completar | bookings/{id}/eventLocations | Solo el admin | Sin borrado (pendiente) |
| Incidente SOS (reserva, quién lo disparó y su rol, estado, veces, horas, escaladas, quién reconoció y cerró, nota de cierre) | incidents/{id} | Quien lo disparó y el admin; nunca la contraparte | Nunca se borra |
| Ubicación en vivo de quien disparó el SOS (lat, lng y hora del servidor, como mucho una cada 10 s, solo con el incidente abierto o reconocido) | incidents/{id}/locations | Quien lo disparó y el admin | config/global.incidentLocationRetentionDays; sin el valor no se borra nada y el panel lo indica |
| Registro del incidente | incidents/{id}/events | Solo el admin | Nunca se borra |
| Banderas incidentOpen y activeIncidentId | bookings/{id}/adminOnly/incident (no en la reserva, que lee la contraparte) | Solo el admin | Se actualizan al cerrar |
| Horas de los últimos disparos (límite 5 por hora) | incidentRateLimits/{uid} | Solo el servidor | Se sobrescribe con la última hora |
| Alertas (incident, incident_escalated, incident_cancel_requested, pickup_*, far_from_pickup, arrival_without_location) | adminAlerts | Solo el admin | Sin borrado |
| Notas de reconocer y cerrar | admin_logs | Solo el admin | Inmutable |
| Push a los admin | FCM | Dispositivos de admin con token | Solo «Reserva #ABC123»; sin nombres ni ubicación |

Logs de las funciones: ni el código de recogida ni ninguna coordenada se registran (prueba functions/src/integration/logs_privacy.int.ts, que falla si se añade un log con ellos; test/security/no_sensitive_logs_test.dart para las pantallas y repositorios de la app).

Retención: **no está fijada** (decisión del responsable). Preguntas para el abogado y la aseguradora:
1. ¿Cuánto tiempo debemos conservar las ubicaciones de un SOS cerrado (prueba ante un reclamo o una denuncia) y cuánto como máximo (minimización de datos)?
2. ¿Cuánto tiempo los eventos de la reserva (quién verificó, desde dónde, a qué hora) y la ubicación del chófer en esos eventos?
3. ¿Hay que borrar o anonimizar antes si la persona pide eliminar su cuenta, o prevalece la conservación por un incidente abierto o un reclamo?
4. ¿Qué exige la póliza (si la hay) sobre conservar pruebas de incidentes?
Propuesta [Especulando]: ubicaciones del SOS 90 días tras el cierre (configurable con incidentLocationRetentionDays, ya implementado); eventos de la reserva y eventLocations 12 meses (no implementado: necesita una tarea de borrado). Hasta que se decida no se borra nada. Mencionar en la política de privacidad la ubicación en vivo durante un SOS y quién la ve.

## K. Preferencias del pasajero para su chófer (cierre/preferencias, Parte A)

Son un deseo, no una garantía: no hay emparejamiento por idioma ni por
preferencias (decisión 6). Listas cerradas salvo la nota.

| Dato | Dónde | Quién lo lee | Quién lo escribe | Retención |
|---|---|---|---|---|
| Preferencias del perfil (idiomas del chófer es/en/pt, temperatura, conversación, estilo de música, URL de una lista de música, necesidades prácticas, nota de hasta 200 caracteres) | users/{uid}.tripPreferences | El pasajero y el admin (reglas de users) | Solo updatePreferences (App Check, límite de tasa, sesión de pasajero activo); las reglas lo rechazan desde el cliente | Se borra con el perfil (deleteAccount). Si no, sin borrado: pendiente del abogado |
| Preferencias antiguas (quiet, temperature, music, luggageHelp, openDoor) | users/{uid}.ridePreferences | El pasajero y el admin | Ya no desde el cliente (solo el alta, con los valores por defecto). createBooking solo lee de ahí valores de la lista cerrada | Igual que el perfil |
| Copia saneada por reserva (las mismas claves, más bookingId, riderId, source trip/profile, createdAt) | bookings/{id}/driverView/preferences | Pasajero dueño (siempre), admin (siempre) y chófer asignado y activo solo con la reserva entre confirmed e in_progress | Solo createBooking, en la transacción de la reserva | Se conserva con la reserva; deleteAccount la borra (delete_account.int.ts). Plazo tras el viaje: **pendiente del abogado** |
| Idiomas preferidos (sin datos personales) | bookings/{id}.preferredDriverLanguages y openRequests/{id}.preferredDriverLanguages | Reserva: pasajero, chófer asignado (sin ventana, como el resto de la reserva) y admin. Solicitud abierta: chóferes verificados y admin | createBooking; buildOpenRequest | Como la reserva; la solicitud se borra al asignarse |

- La reserva ya no lleva `riderPreferences` (antes se copiaba sin validar y el
  chófer asignado la leía siempre, también después del viaje).
- Parte B: las apps ya no escriben `ridePreferences` (el perfil guarda con
  updatePreferences) ni leen preferencias de la reserva: el pasajero y el
  chófer leen la copia `driverView`; el chófer, solo en su ventana. Antes de
  aceptar ve únicamente los idiomas. Ninguna preferencia va en un push
  (i18n.test.ts). El panel muestra la copia de cada reserva.
- La URL de la lista solo se acepta https, sin credenciales ni puerto, de un
  host de config/ops.playlistHosts (lo fija el responsable); sin esa lista
  el servidor la rechaza y getPreferenceOptions responde playlistEnabled:
  false. El servidor nunca la abre ni la descarga.
- La nota se guarda sin caracteres de control ni saltos de línea y se
  rechaza si lleva un enlace. Nada impide que el pasajero escriba un dato
  sensible: la app lo advertirá (Parte B).
- Logs: las claves note/notes/playlistUrl/url/*preferences se tachan por
  nombre y cualquier http(s):// por patrón (errors.test.ts y
  logs_privacy.int.ts).

Retención: **no está fijada**; no se inventa un plazo. Preguntas para el abogado:
1. ¿Cuánto conservar la copia por reserva (driverView) y la nota una vez
   terminado el viaje? (Al eliminar la cuenta ya se borra.)
2. Algunas necesidades (asistencia al subir, silla de ruedas plegable)
   pueden revelar datos de salud o discapacidad, y la silla infantil, que
   viaja un menor. ¿Pueden ofrecerse como lista, con qué consentimiento y
   con qué aviso en la política de privacidad?
3. ¿Qué decir en la política de privacidad sobre qué ve el chófer y cuándo?

## L. Idiomas (cierre/idiomas)

Apps del pasajero y del chófer en español, inglés y portugués de Brasil;
panel de admin, páginas legales, alertas del panel y SMS a central en
español.

| Dato | Dónde | Quién lo lee | Quién lo escribe |
|---|---|---|---|
| Idioma de la cuenta (es/en/pt) y su origen (system/user) | users/{uid}.locale, localeSource, localeUpdatedAt | El usuario y el admin (reglas de users) | Solo updatePreferences (las reglas lo rechazan desde el cliente) |
| Idioma de cada aviso guardado | users/{uid}/notifications/{id}.locale | El usuario | El servidor |
| Elección en el dispositivo | shared_preferences (lux.locale) | La app | La app |

- Textos de la app: lib/l10n/src/*.json → .arb (1127 claves). Trinquete de
  textos fijos en cero en lib/features (sin admin ni legal), lib/core y
  lib/app; 108 excepciones `i18n-ignore` con motivo (nombres propios,
  fuentes, datos guardados, solo desarrollo).
- Avisos del servidor: functions/src/i18n.ts, 21 tipos; ningún push ni
  aviso con texto fijo (i18n.test.ts).
- Importes: siempre «Bs» delante; separadores del idioma («Bs 1,234.50»
  en inglés), con tests de que la cifra no cambia de sentido.
- Pendiente del responsable: revisión nativa de en/pt; traducciones
  legales; compromisos «Central te llamará» (SOS cancelado, D23) y «te
  contactamos en menos de un día hábil» (empresas); testimonios de la web
  que parecen inventados y «champán», «Wi-Fi y carga inalámbrica» sin
  respaldo; «Stripe» y «PCI DSS» en la pantalla de tarjeta.

## M. Registro de chóferes y sus documentos (cierre/registro-chofer, Parte A)

Lo que se guarda, dónde y quién lo lee. Todo lo escribe el servidor; nada
lo escribe un cliente salvo el archivo, que el chófer crea una vez en
Storage.

| Dato | Dónde | Quién lo lee | Quién lo escribe |
|---|---|---|---|
| Estado de la solicitud, paso, fechas | driverApplications/{uid} | El chófer dueño y el admin | saveDriverStep, registerDocumentUpload, submitApplication, revisión del admin |
| Nombre, número de cédula, número y vencimiento de licencia, datos del vehículo | driverApplications/{uid}/private/data (y licencia en driverProfiles; vehículo en vehicles) | Solo el admin (el chófer los recupera con getDriverApplication) | saveDriverStep |
| Estado de cada documento: versión, vencimiento, motivo de rechazo y nota | driverApplications/{uid}/documents/{tipo} | El chófer dueño y el admin | El servidor |
| Ruta del archivo, tamaño, tipo real, quién revisó | driverApplications/{uid}/documentFiles/{tipo} | Solo el admin | El servidor |
| Archivos (fotos y documentos) | Cloud Storage, driverDocs/{uid}/{tipo}/{versión} | Nadie con las reglas; el admin con una URL firmada de 5 minutos (adminGetDocumentUrl) | El chófer crea (nunca sobrescribe ni borra) |
| Bitácora de accesos: quién vio qué documento y cuándo (sin la URL) | driverDocAccessLogs | Solo el admin | adminGetDocumentUrl |
| Bloqueo por documentos vencidos y autorización del admin | driverProfiles.docsBlocked, docsBlockOverride | El chófer y el admin | runDocExpiry, adminAllowDriverOnline |
| Revisión, decisión, autorizaciones y purga | admin_logs | Solo el admin | El servidor, en la misma transacción |

- Validación del archivo en el servidor: existe, tamaño máximo técnico de
  10 MB, tipo real por los primeros bytes (JPEG, PNG, WebP; PDF solo en
  antecedentes, propiedad, SOAT, inspección, seguro, permiso y autorización
  del dueño). Un archivo que no cumple queda marcado en Storage y no se
  registra.
- **No hay antivirus ni análisis de contenido** (NO VERIFICADO que un
  archivo con cabecera válida sea inocuo). Las URL firmadas sirven el
  archivo con `Content-Disposition: inline`.
- La foto en vivo se toma con la cámara dentro de la app: reduce el engaño
  pero **no es una prueba de vida ni una comparación de rostro**; la
  interfaz y esta auditoría no lo prometen.
- Logs: cédula, licencia, nombre, placa, rutas, nombres de archivo y URL se
  tachan por nombre y por patrón (driver_registration.int.ts lo comprueba).
  Los avisos al chófer no nombran el documento (pantalla bloqueada).
- Retención: **no se programa ningún borrado**. Hay una purga manual solo
  para admin, con motivo y auditoría, desactivada: solo funciona con
  config/ops.driverDocsPurgeEnabled = true.

Región del bucket: el bucket predeterminado de Firebase usa la ubicación de
recursos del proyecto, que no se puede cambiar una vez fijada. Para Bolivia
la más cercana es `southamerica-east1` (São Paulo, Brasil). NO VERIFICADO:
qué ubicación tiene ya el proyecto, si existe el bucket, el plan de
facturación (Storage pide Blaze para buckets nuevos), App Check en Storage
y que la cuenta de servicio de las functions tenga permiso para firmar URL
(`iam.serviceAccounts.signBlob`, rol «Creador de tokens de cuenta de
servicio» sobre sí misma).

Preguntas para el abogado:
1. ¿Cuánto tiempo hay que conservar las fotos de cédula, licencia,
   antecedentes y del vehículo, de chóferes aprobados y de los rechazados?
   ¿Hay obligación legal de conservarlos (transporte, seguros)?
2. ¿Qué hacer con estos archivos al cerrar la cuenta de un chófer?
   (deleteAccount hoy no los borra.)
3. Si el bucket está fuera de Bolivia (São Paulo u otra región), ¿qué exige
   la transferencia de datos personales al exterior y qué hay que decir en
   la política de privacidad?
4. ¿Qué documentos son obligatorios y cuáles vencen
   (config/ops.driverRequirements)?

### M.A10 Alta del aspirante (startDriverApplication)

- Hasta A10, un aspirante nuevo no podía registrarse solo: las cuentas nuevas son `rider` (firestore.rules, `isValidSelfSignup`) y solo `setUserRole` (admin) daba el rol de chófer [seguro].
- `startDriverApplication`: App Check y límite de tasa (secureCallable, 5 por hora), correo verificado en el token, cuenta `rider` activa, sin ninguna reserva (de cualquier estado), no admin. Cambia `users/{uid}.role` a `driver`, fija el claim y escribe la auditoría (`start_driver_application`, actor con rol `rider`) en la misma transacción que crea `driverApplications/{uid}` en draft y `driverProfiles/{uid}` con `documentsVerified: false`. De un solo sentido. Idempotente. Prueba: driver_start.int.ts.
- Diferencia con setUserRole: no revoca las sesiones; la app debe pedir un token nuevo (`getIdToken(true)`) para que las reglas vean el claim. Se fija el claim después de Firestore; si falla, el reintento lo corrige.
- `users/{uid}.isVerified` es el correo verificado (H6), no la verificación del chófer: no se toca. La del chófer es `driverProfiles/{uid}.documentsVerified`.
- Cerrado para el aspirante sin verificar (reglas y servidor, con test): crear su perfil desde el cliente (ahora nadie), cambiar licencia, vehículo, ubicación o ponerse en línea (solo puede quedar fuera de línea), crear o cambiar vehículos desde el cliente, y usar un perfil de pagos (`ensureStripeCustomer`, `listPaymentMethods` y las demás que comprueban el cliente propio: `driver_account`, para cualquier chófer).
- Consecuencia: la pantalla de alta actual de la app del chófer (escribe `driverProfiles` y `vehicles`) deja de funcionar con estas reglas hasta que la Parte B la cambie por las callables. Las reglas de esta rama no se despliegan antes que la Parte B.
- Versiones por documento: como mucho 20 (storage.rules y `uploadSchema`).
- Índice de grupo de colecciones `documents.expiresAt` en firestore.indexes.json (lo usa `runDocExpiry`; el emulador no lo exige).

### M.B Apps y panel (Parte B)

- **App del chófer** (`lib/features/driver_registration/`): pantalla previa a `startDriverApplication` (la cuenta pasa a ser de chófer, sin vuelta atrás; con reservas, otro correo) y token nuevo (`getIdToken(true)`) tras abrirla; registro por pasos (datos, vehículo, documentos, segundo factor con `mfaEnforced`, resumen y envío) con barra de progreso, reanudable; estado por documento con el motivo de rechazo y «Volver a subir»; «En revisión» sin plazos. Sustituye al alta antigua que escribía `driverProfiles` y `vehicles` desde el cliente.
- **Fotos**: cámara o galería del sistema (`image_picker` 1.2.1); la foto en vivo solo con la cámara frontal y sin galería. **No hay cámara propia** (no se añadió `camera`): la guía de encuadre se muestra antes de abrir la cámara y en la revisión, no dentro de la cámara. Revisión antes de enviar (repetir o usar), resolución mínima local (lado corto ≥ 720 px, valor técnico) y recompresión a JPEG **sin EXIF** (`flutter_image_compress` 2.4.0, `keepExif: false`). Que el EXIF desaparezca de verdad en Android e iOS: NO VERIFICADO (prueba en dispositivo real en DEPLOY.md).
- **PDF**: el servidor los admite en los tipos de papel, pero la app no los ofrece (no hay selector de archivos sin otra dependencia). Hoy todo documento se sube como foto.
- **Web**: no se suben documentos ni la foto en vivo; la compresión web de `flutter_image_compress` necesita un script externo que la CSP no permite. Solo para las capturas contra los emuladores existe `CAPTURE_WEB_UPLOADS` (exige `USE_EMULATORS`; test en build_config_test.dart).
- **Subida**: `driverDocs/{uid}/{tipo}/{versión}` con la versión siguiente; un reintento usa la misma versión y, si el objeto ya existe (no se puede sobrescribir), solo se registra: no se duplica.
- **Segundo factor**: con `mfaEnforced`, el paso aparece antes del resumen, `submitApplication` lo exige en el servidor y la app no deja conectarse sin él (guía al alta o a volver a entrar). La app lo sabe por `getDriverApplication.mfaEnforced` (no lee `config/security`). Ponerse en línea sin TOTP no está cerrado en las reglas (solo en la app); aceptar viajes sí lo exige el servidor (`acceptBooking`).
- **Panel** («Solicitudes de chófer», `lib/features/admin/`): bandeja por estado, detalle con datos y vehículo, requisitos sin configurar, visor con URL firmada de 5 minutos (`Image.network`, sin caché de disco; el objeto lleva `Cache-Control: private, no-store`, que fija el servidor al registrarlo), aprobar o rechazar por documento con motivos cerrados, decisión final con motivo, bitácora de accesos y vencimientos próximos (`adminListDocExpiries`) con «Autorizar en línea». Bandeja y bitácora leen hasta 200 sin índice compuesto (se avisa si se corta).
- **Pasajero** (B3): ve marca, modelo, color y placa del vehículo **aprobado** (`publishDriverInfo` con `driverProfiles.vehicleId` y `isActive`); prueba en driver_registration.int.ts.
- **Textos**: todo en los .arb (es/en/pt), errores del registro en el catálogo del cliente (`registrationErrorMessage`), frases prohibidas ampliadas (verificación de identidad, biometría, prueba de vida). El certificado se llama «Certificado de antecedentes» (en: «Criminal record certificate», pt: «Certidão de antecedentes criminais»): es la única excepción, por su clave (`regDocTypeCriminalRecord`), en las pruebas de promesas, que siguen vetando «antecedentes» en cualquier otro texto.
- **iOS**: `NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription` en es, en y pt (`ios/Runner/<idioma>.lproj/InfoPlist.strings`, en el proyecto de Xcode, y `CFBundleLocalizations`). Los de ubicación siguen solo en español.
- **Pendientes** (no hechos en esta rama):
  1. Ponerse en línea sin TOTP con `mfaEnforced` solo se bloquea en la app, no en las reglas (`driverProfiles` deja `isAvailable`/`online` en true sin mirar el segundo factor). Aceptar viajes sí lo exige el servidor (`acceptBooking`).
  2. Diez capturas con el texto al 200 % (es y pt; vehículo, revisión de la foto, falta de vencimiento, resumen y segundo factor): el guion no desplaza el lienzo de Flutter web con la letra a ese tamaño. Los tests de widget comprueban que no hay desbordes. Las capturas se hicieron con el nombre anterior del certificado («Certificado penal»).
  3. Las pruebas en dispositivo real de DEPLOY.md («Registro de chóferes»): EXIF quitado, cámara frontal en la foto en vivo, URL firmada de 5 minutos sin caché, permisos de cámara y fotos en iOS y web sin subidas.
- **Matriz**: la Parte B no cambia `firestore.rules` ni `storage.rules`.

## N. Vuelos de llegada (cierre/vuelos, Parte A)

Qué se guarda y quién lo lee:

| Dato | Dónde | Quién lo lee | Quién lo escribe |
|---|---|---|---|
| Vuelo (aeropuerto, tipo, aerolínea, número, fecha, hora programada, equipaje facturado, estimada, real, estado, fuente, calidad del dato, bloqueo manual) y `readyAt` | `bookings/{id}.flight`, `bookings/{id}.readyAt` | Pasajero dueño, admin y el chófer asignado (como toda la reserva, también en su historial) | Solo el servidor: `createBooking`, `adminSetFlightInfo`, `adminClearFlightLock` |
| Copia para el chófer (sin fuente ni bloqueo) | `bookings/{id}/driverView/flight` | Chófer asignado y activo entre `confirmed` e `in_progress` (misma regla que `driverView/preferences`), pasajero dueño y admin | Solo el servidor |
| Aeropuertos y puntos de recogida nacional e internacional | `airports/{código}` | Cualquiera con sesión | `adminUpsertAirport` (MFA, sesión reciente, motivo, auditoría) |
| Código, nombre y ciudad del aeropuerto | `airportsPublic/{código}` | Cualquiera (selector sin sesión) | `adminUpsertAirport` |
| Caché de la fuente por aeropuerto y fecha | `flightBoard/{AEROPUERTO_AAAA-MM-DD}` | Nadie desde el cliente | Solo el servidor (planificador, Parte B) |

- **Privacidad (A10)**: el número de vuelo, la aerolínea y el vuelo entero se tachan en los registros (`logger.ts`, prueba en errors.test.ts). En la Parte A no hay notificaciones de vuelo; las de la Parte B no llevarán el número en la pantalla bloqueada.
- **Retención**: cuánto tiempo se guardan el vuelo de la reserva, su copia para el chófer y la caché `flightBoard`: **pendiente del abogado** (no se fija ningún plazo ni se programa borrado). `deleteAccount` no borra `flightBoard` (no tiene datos de la persona, solo vuelos por aeropuerto y fecha).
- **PENDIENTE ANTES DEL PILOTO** (decisión del responsable, 2026-11-03: se trata en un prompt aparte): el chófer asignado lee la reserva entera también después del viaje (regla general de `bookings`), y con ella el número de vuelo en su historial. El vuelo se queda en la reserva; la copia `driverView/flight` tiene ventana (`confirmed` a `in_progress`).
- **No se presentó con vuelo**: solo con el vuelo aterrizado (hora real de la fuente o de un admin) y pasada la espera desde `readyAt`. Retrasado, sin datos, desviado o cancelado: rechazado; solo un admin lo fuerza (`adminForceNoShow`, motivo y auditoría).
- **Precio**: con vuelo se cotiza y reserva con `readyAt` como hora de recogida (incluido el recargo nocturno de `config/pricing`), y no cambia después.
- **Límites de la Parte A, cerrados en la Parte B**: cuando `readyAt` cambia (planificador o admin), `scheduledAt` y `openRequests/{id}.scheduledAt` cambian con él; los seis usos de la hora de recogida (limpieza diaria, chófer ocupado al asignar, retención de la tarjeta, aviso al liberar, reactivación y bandeja de pagos, solicitudes abiertas) lo siguen (`flight_followers.int.ts`). El precio no se recalcula: solo `booking_service.ts` llama a la tarifa (`price_fixed.test.ts`).
- **Lista fija de aeropuertos (decisión 4, DIFERIDA por el responsable, 2026-11-04)**: la detección de «recogida en aeropuerto» sigue en dos listas fijas de 11 aeropuertos, `AIRPORTS` en `functions/src/service_area.ts` y `ServiceArea.airports` en `lib/core/utils/service_area.dart`; además, el aeropuerto debe existir en `airports`. Mientras tanto, `airports_parity.test.ts` falla si las dos listas difieren en código IATA, nombre o coordenadas. Propuesta, sin implementar:
  - `airports/{IATA}` añade `location {lat, lng}`, radio exacto (hoy 1,2 km en el código), radio para lugares con nombre «aeropuerto» (hoy 6 km) y `active`; `airportsPublic` copia ubicación y radios para la app sin sesión.
  - `service_area.ts` se queda con ciudades y distancias; `AIRPORTS` pasa a una función pura `airportFor(lugar, aeropuertos)` con la colección leída con caché por instancia; la app deja de decidir con su lista y sigue el `pickupAirport` de la cotización.
  - Migración solo con aprobación: copiar los 11 aeropuertos y radios que hoy están en el código (nada inventado), una versión calculando con los dos métodos y alertando si no coinciden, y luego borrar la constante.
  - Precio: las claves de `fixedAirportFares` no cambian, pero un aeropuerto desactivado o borrado pasa sus viajes nuevos a tarifa de ciudad sin paso de vuelo, un cambio de radio cambia qué recogidas tienen tarifa fija y un aeropuerto nuevo no la tiene hasta cargar su clave. Las reservas ya creadas no cambian (precio fijo). Riesgo: un error en la colección cambia precios en silencio; mitigación propuesta: alerta cuando una recogida que era aeropuerto deja de serlo.

### N.1 Vuelos, Parte B

- **Planificador `pollFlights`** (cada 5 minutos): solo reservas con `flightActive == true`; puntos de revisión de `config/ops.flightCheckpointsMinutes` y `flightPollMinutes` (sin ellos no hace nada); solo lee la caché `flightBoard` y la fuente configurada, que hoy es la manual (no encuentra nada). Con bloqueo manual no pisa los datos del admin: alerta `flight_source_differs` una vez por dato distinto. Dato viejo (`flightStaleMinutes`): calidad `stale` y alerta `flight_data_stale` una vez por episodio.
- **Avisos** (push y bandeja, es/en/pt del catálogo del servidor): cambio de la hora de recogida igual o mayor que `flightNotifyThresholdMinutes` respecto del último aviso; vuelo cancelado o desviado (una vez por estado, alerta alta a central; la reserva nunca se cancela sola). **No llevan número de vuelo ni aerolínea** (pantalla bloqueada): solo la hora nueva.
- **Chófer**: la tarjeta «Vuelo» lee solo `driverView/flight` y solo en la ventana `confirmed` a `in_progress`; la solicitud abierta lleva solo aeropuerto y tipo de vuelo, sin número.
- **Panel**: detalle del vuelo, formulario manual (motivo obligatorio, bloqueo, quitar bloqueo), bandejas y editor de aeropuertos; todo por callables con MFA y sesión reciente, con auditoría.
- **Textos**: ninguna promesa de hora (`frases_prohibidas_test.dart`: llegar a tiempo, vuelo en tiempo real, espera sin límite, ajuste automático, garantías; es/en/pt).
- **Enlace externo existente**: la tarjeta del chófer conserva el enlace a la página pública de vuelos de la ATT (abre el navegador; la app no lee nada de ella). NO VERIFICADO que esa página siga disponible.
- **PENDIENTE: Prompt 15C (fuente de la ATT)**: la fuente automática de vuelos espera los datos de la página pública de la ATT (qué publica, con qué formato, cada cuánto y si se permite leerla). Hasta entonces `pollFlights` corre con `ManualFlightProvider`, que no encuentra nada: todo dato en vivo lo carga central a mano.
- **PENDIENTE ANTES DEL PILOTO (recordatorio)**: el chófer asignado sigue leyendo la reserva entera después del viaje, con el número de vuelo (ver arriba en N); se trata en un prompt aparte antes del piloto.
- **Fuente**: solo la manual (lo que fija un admin) y la de pruebas. La de la ATT no está implementada; la app y las callables de reserva nunca consultan una fuente externa, solo la caché.

## I. Estado de los hallazgos (rama cierre/identidad, 2026-10-25, con las correcciones C1–C6)

CERRADO = corregido en la rama con prueba automática; nada está desplegado todavía. PARCIAL = lo indicado en «Falta». ABIERTO = sin trabajo.

| Id | Estado | Hecho (commit / prueba) | Falta |
|---|---|---|---|
| D1 | CERRADO (en código) | Verificación en recogida: 39ac9fe…f40606c (ver cierre/verificacion), 965094a el admin solo completa desde in_progress, 53c7138 llegada sin ubicación. SOS: da3c4bc reglas (incidents.rules.ts, 5 de 18 fallan con las reglas anteriores), b450f10 callables y escalada (incidents.int.ts), 9f4fdf7 aviso sin red, 746509d botón en las apps, 5d94f01 panel, 3818119 privacidad (logs_privacy.int.ts), 7410c0c despliegue. | **Sin una persona atendiendo el panel (o recibiendo el push) el botón no protege a nadie**: ver D23. Cierre sospechoso: en el piloto solo se captura el dato (ubicación y hora de inicio y fin en los eventos) y no se retiene el cobro; los umbrales se calibrarán con las dos primeras semanas de datos reales y no se pedirá al pasajero confirmar la llegada por ahora. Push a admins en web no registrado (solo app móvil). Retención de ubicaciones y eventos sin decidir. Desplegar en el orden de DEPLOY.md («Verificación en recogida» y «SOS e incidentes»). |
| D2 | PARCIAL | 697057a createBooking/quoteBooking con precio del servidor; e3109a5 `allow create: if false`; pruebas: functions/src/integration/bookings.int.ts, tools/rules-tests/test/bookings.rules.ts | Idempotencia (requestId), versión mínima de la app, configurar pricingRules/config.pricing y desplegar en el orden de DEPLOY.md. |
| D3 | CERRADO (en código) | Rama cierre/endurecimiento: 84a3526 App Check en las apps (app_check_setup_test.dart, build_config_test.dart); 075129b App Check en las 23 callables con APP_CHECK_ENFORCE en dos fases (callable_security.test.ts: falla si una callable no pasa por secureCallable); 414f643 límites de tasa (rate_limit.int.ts); e2e6734 zod estricto en todas (callable_schemas.test.ts). | Pasos de consola y despliegue en dos fases (DEPLOY.md, «Endurecimiento»); App Check de Firestore en la consola tras subir minAppVersion y minDriverAppVersion. |
| D4 | CERRADO | 364c8b5; tools/rules-tests/test/driverProfiles.rules.ts | Desplegar. |
| D5 | CERRADO | e12d049 openRequests sin PII; 2bc8069 reconciliación; openRequests.rules.ts, reconcile.int.ts | Desplegar y ejecutar la migración (DEPLOY.md). |
| D6 | CERRADO (en código) | Rama cierre/identidad: feb3c03 correo verificado lo marca el servidor y reservar lo exige (identity_email.int.ts, emailVerification.rules.ts); c994394 rol por custom claim fijado solo por setUserRole, backfill en DRY-RUN (identity_roles.int.ts, roleClaims.rules.ts); bd2ac1f bloqueo en el servidor: Auth deshabilitada, sesiones revocadas, isActive (identity_block.int.ts, adminIdentityWrites.rules.ts); 153fdfd TOTP para chóferes y admins con mfaEnforced (mfa_gate.int.ts, adminMfa.rules.ts, mfa_test.dart); d6bca9f reautenticación reciente y sesión máxima de admin (reauth_gate.int.ts, reauth_dialog_test.dart); 38739a7 términos aceptados en el servidor (identity_terms.int.ts, termsAcceptance.rules.ts); 5237aff dispositivos del chófer (driver_devices.int.ts, driverDevices.rules.ts); 134bc5d mensajes sin enumeración de cuentas; 0ec15ff promote_admin con DRY-RUN, guarda y auditoría. Correcciones tras la revisión: 2d346d2 SOS y alertas sin sesión máxima de admin (C1, reauth_gate.int.ts); 4b4685b alerta por el primer dispositivo de un chófer ya verificado (C2, driver_devices.int.ts); e766824 pricingRules sin updatedBy y su migración (C3); 4602ec4 reset_mfa y procedimiento de emergencia completo (C4, reset_mfa.int.ts, probado con los emuladores de Firestore y Auth); 900ef3a orden de legalVersion y pruebas en dispositivos reales (C5, deploy_config.test.ts). | Desplegar en el orden de DEPLOY.md («Identidad»): Identity Platform (coste NO VERIFICADO), activar TOTP, protección contra enumeración, backfill de claims, alta del segundo factor y luego mfaEnforced. Teléfono recogido pero NO verificado (decisión 1: sin proveedor de SMS). Quitar el respaldo del rol en Firestore cuando se confirme el backfill. Sin UI para cambiar correo o contraseña (Firebase ya exige un inicio de sesión reciente para eso; [Probable]). Hacer las pruebas en dispositivos reales de DEPLOY.md antes de mfaEnforced. Decidir cómo se confirma la identidad de quien pide reset_mfa (decisión del responsable). Reiniciar el segundo factor de un chófer solo lo hace el responsable con el script: no hay botón en el panel. |
| D7 | PARCIAL (en código) | e2e6734 capturePayment solo cobra el intent guardado en la reserva (bookings.int.ts). Rama cierre/pagos: interfaz PaymentProvider (A2) con claves de idempotencia en el cobro y en el reembolso (A5, A8); webhook `paymentWebhook` con verificación de firma por la interfaz, probado con un proveedor simulado (payment_card.int.ts); el cobro al pedir chófer es el cargo, sin captura posterior; tarjeta desactivada por `config/ops.paymentMethods` (payment_methods.int.ts). | Elegir el proveedor de tarjeta (decisión del responsable), integrar su `verifyWebhook` con el secreto en Secret Manager y registrar la URL del webhook. Hoy el de Stripe rechaza todo. |
| D8 | PARCIAL | 4724d4f entorno production, concurrencia y acciones por SHA; ccbe8b8 selector FIREBASE_ENV; 3297d33 job de reglas | Crear el proyecto de staging y el entorno de GitHub con revisores. |
| D9 | PARCIAL | 452a5a5 firma de release con key.properties; test/security/build_config_test.dart | Generar el keystore de subida y cargar sus secretos en GitHub; Play App Signing. |
| D10 | CERRADO (en código) | Transiciones del chófer en el servidor (advanceBooking, verifyPickup; 3c5e148, 95f61c2). Roles y bloqueos por setUserRole y setUserBlocked (c994394, bd2ac1f). Parte A (rama cierre/auditoria): todas las escrituras del panel pasan a callables con rol admin, segundo factor con mfaEnforced, zod estricto, motivo y auditoría del servidor en la misma transacción (antes y después de lo cambiado): adminUpdateBooking (e409efc: asignar, cancelar con evento, pasos del panel, importe solo antes de completar y con config/ops.maxPriceAdjustmentPercent), adminRecordPayment (257c266, 047bc28), adminUpdateConfig (fdc9163), adminUpdatePricingRule (1018356), adminVerifyDriver, adminUpdateDriverSensitive y adminSetVehicleActive (c265e4f), adminSetLeadHandled (dba72d6); panel (8970458). Reglas: el admin solo lee; admin_logs solo lo escribe el servidor; 17 celdas cerradas (matriz). Pruebas: admin_*.int.ts, admin_server_writes_test.dart y los tests de reglas (38 fallan con las reglas anteriores). | Desplegar en el orden de DEPLOY.md («Parte A»). Fijar config/ops.maxPriceAdjustmentPercent si se quiere ajustar importes (sin él se rechazan). setUserRole y setUserBlocked siguen con su auditoría anterior (sin antes/después por campo). Fuera del panel siguen refundPayment, backfillSettlements y adminOverrideVerify, que ya auditaban en el servidor. |
| D11 | CERRADO (en código) | 4b58919 STRIPE_SECRET_KEY con defineSecret (stripe_secret.test.ts); 754fae6 traductor central de errores: el cliente solo recibe 7 códigos y un motivo corto, el log tacha claves, correos, teléfonos, tarjetas, códigos y coordenadas (errors.test.ts, bookings.int.ts con una clave sk_test falsa) | Desplegar. |
| D12 | PARCIAL | 130afd2 claves de Maps fuera del código, la release falla sin ellas; build_config_test.dart | Rotar la clave antigua (sigue en el historial de git) y restringir las nuevas. Claves de Firebase de Android/iOS sin valor por defecto desde a446377 (B8). |
| D13 | PARCIAL | 0cbc55f cabeceras y CSP Report-Only (hosting_headers_test.dart); e2e6734 zod estricto en las 23 callables (callable_schemas.test.ts); matriz de acceso de Firestore con un test por celda (58eb92a, [docs/MATRIZ_ACCESO.md](MATRIZ_ACCESO.md)) | CSP obligatoria; deleteAccount: diseño en [docs/DISENO_DELETE_ACCOUNT.md](DISENO_DELETE_ACCOUNT.md); **no se implementa hasta tener las respuestas del contador y del abogado** (propuestas del responsable para N1 y N2 anotadas allí, no implementadas); hallazgos de la matriz: H1–H5 y H7–H10 corregidos y revisión A8 (admin sin crear desde el cliente, IP de confianza, lista blanca del chófer, eventos solo para central, pricingRules acotado, config/ops y config/security) en la rama cierre/identidad, H6 corregido en la Parte B (feb3c03); `updatedBy` retirado del documento público de pricingRules (C3, e766824; ejecutar `npm run migrate:pricing-updated-by` tras desplegar panel y reglas); celdas permitidas para revisión humana en [docs/MATRIZ_ACCESO_PERMITIDOS.md](MATRIZ_ACCESO_PERMITIDOS.md). |
| D14 | ABIERTO | db0553f quitó herramientas de functions (total 58→44). Intento en cierre/endurecimiento: node-forge solo se corrige con firebase-admin ≥ 14.4.0, que exige firebase-functions 7.4.0; firebase-admin 14 retira la API con espacio de nombres (`admin.firestore()`, `admin.firestore.Timestamp`, `admin.messaging()`): 176 errores de compilación en 16 archivos. Revertido. Con la subida, `npm audit --omit=dev` pasaría de 10 (8 moderadas, 2 altas) a 0. | **Aplazado por decisión del responsable (2026-10-24).** Tarea propia: «migrar a la API modular y subir firebase-admin y firebase-functions». Nota: la vulnerabilidad de node-forge solo es alcanzable si la ruta afectada procesa entradas no confiables; NO VERIFICADO. |
| D15 | CERRADO | 4749171; test/security/web_index_test.dart | Desplegar hosting. |
| D16 | PARCIAL | cd2d215 teléfono en driverContact; 6231792 migración; driverContact.rules.ts | Llamada enmascarada; ejecutar la migración. |
| D17 | ABIERTO | — | Entitlements de push (aps-environment) y capacidad Push Notifications en Xcode. |
| D18 | ABIERTO | — | Identificador propio para la app del chófer (flavors) y ubicación en segundo plano solo en ella. |
| D19 | ABIERTO | — | Mover Places/Directions al servidor (como la distancia de createBooking) o a un proxy. |
| D20 | CERRADO (en código) | 840ec6c sin tarifas en el código: sin pricingRules no se muestra cifra («Cotiza al reservar») y no se reserva sin ver el precio del servidor (pricing.test.ts «no hay tarifas en el código del servidor»); tools/pricing para cargarlas. | Cargar las tarifas reales en Firestore (decisión del responsable). |
| D21 | ABIERTO | — | Diseño de reserva asistida (adminCreateBooking). Debe mandar `channel` a `createBooking` (H1: sin él, `app_update_required` y no se crea nada); el valor del panel está por decidir. |
| D22 | CERRADO (en código) | Motivo obligatorio, evento, alerta y admin_logs en el servidor (3c5e148). 153fdfd: las callables de admin (adminOverrideVerify incluida) exigen el segundo factor cuando config/security.mfaEnforced es true (mfa_gate.int.ts); d6bca9f: además, sesión de admin de menos de adminSessionMaxHours (reauth_gate.int.ts). | Activar mfaEnforced tras el alta de al menos dos admins y las pruebas en dispositivos reales (DEPLOY.md, «Identidad»). Hasta entonces el riesgo sigue como antes. C1 (2d346d2): acknowledgeIncident, closeIncident y resolveAlert no tienen sesión máxima; adminOverrideVerify sí la mantiene, además del rol y el segundo factor. |
| #10 (F6) | PARCIAL (en código) | Rama cierre/auditoria, Parte B: 4ba7798 cancelBooking en el servidor, idempotente (cancel_booking.int.ts); 19f422e política en config/ops.cancellationPolicy, recargo anotado y no cobrado, sin política no hay recargo (cancellation.test.ts, cancel_booking.int.ts); f8a9bda no_show tras la espera, con ubicación, evento y alerta, decisión de central con adminUpdateBooking (no_show.int.ts); 59abd0a el chófer libera antes de llegar con motivo y contador (release_booking.int.ts); 88ed7dc pantallas (test/cancellation/); B7 reglas: el pasajero ya no escribe `status: cancelled` (bookingRiderFields.rules.ts, tripFlow.rules.ts y la matriz: 4 fallan con las reglas anteriores). | Decidir la política (plazos, recargo, espera) y si se cobra con el método retenido (DEPLOY.md, «Cancelación»). El texto de legal_page.dart sigue sin cambiar (decisión legal). Modificar una reserva sigue ausente. |
| D23 | ABIERTO | — | Definir quién atiende los incidentes y con qué turnos y protocolo (tiempo de respuesta, cuándo llamar a las autoridades, a quién escalar si nadie reconoce); que los admin de guardia reciban push (hoy solo desde la app móvil). Decisión y operación del responsable. |
| Pagos | PARCIAL (servidor, apps y panel, en código) | Rama cierre/pagos, Parte A: el pago es requisito para pedir chófer (A3: nada se ofrece sin `paid`; regla de auto-aceptación con el estado de pago); estado del pago fuera de la reserva, ilegible para el chófer (A1, matriz); pago manual con confirmación del admin (A4); vencimiento (A6); retención por etapas sobre lo pagado (A7); reembolsos al método original (A8); diferencia final (A9, A10); bandejas (A11); Q2 (adminRecordPayment no cobra dos veces). Parte B: pantalla de pago del pasajero (`/pay/<id>`), pago pendiente y comprobante en el viaje, cancelación con la retención solo si > 0, web solo con pago manual (E38), panel «Pagos» (confirmar, rechazar, devoluciones, saldos) y causa al cancelar; el chófer no lee pagos (B2). G2: saldos pendientes cobrados por central con `adminCollectBalance` (payment_balance.int.ts). H4: el libro `payments` es de solo anexado (asientos creados una vez, nunca borrados ni con otro importe; un pendiente solo se cierra, una vez, como completed o superseded; payment_ledger.int.ts). Los cobros antiguos de antes de pagos (sin `type`) aún los modifican `adminRecordPayment` (corrección) y `refundPayment`: deuda menor, solo reservas antiguas. Tests: payment_*.int.ts, cancel_booking.int.ts, matriz, test/payments, test/admin/admin_payments_test.dart, test/driver/driver_sin_pagos_test.dart. | Decisiones de config/ops (DEPLOY.md, «Pagos»); proveedor de tarjeta (app y webhook); textos legales y de recogida inmediata (DEPLOY.md). Capturas en dispositivo real: NO VERIFICADO. |
| Deuda: campos `*Usd` de `pricingRules` | ABIERTO (deuda, G5: no se renombra) | [seguro] Los importes están en bolivianos (`functions/src/pricing.ts:7`, `fare.ts:64`) aunque los campos se llamen `basePriceUsd`, `pricePerKmUsd`, `pricePerHourUsd` y `minimumPriceUsd`. No hay conversión de moneda en ningún sitio. ~270 usos: servidor (`fare.ts`, `pricing.ts`, esquema estricto de `adminUpdatePricingRule` en `admin_ops.ts`), app (`PricingRule` en `models.dart`, `PricingCatalog`, que lee `/pricingRules` directamente de Firestore, pestaña Tarifas), tests de reglas (`pricingRules.rules.ts`, `matrix.ts`), `tools/pricing` y `seed.cjs`. Riesgo por el que no se hizo: las apps instaladas leen los nombres viejos de Firestore hasta que `minAppVersion` las saque, así que habría un periodo con los dos nombres en cada documento; una edición del panel que escribiera solo uno haría que el precio mostrado y el cobrado se separaran. | Plan si se decide: (1) lectura doble `nuevo ?? viejo` en servidor y app, con tests de paridad; (2) `adminUpdatePricingRule` escribe los dos nombres; (3) script de migración con DRY-RUN por defecto que lista los cambios y solo escribe con `--apply`, contra `demo-luxelane` primero; (4) tras subir `minAppVersion`, dejar de escribir y luego de leer los viejos; (5) reglas al final. Nombres nuevos: decisión del responsable. |
| Preferencias del pasajero | PARCIAL (servidor, reglas, apps y panel, en código) | Rama cierre/preferencias, Parte A: updatePreferences y esquema cerrado (preferences.ts, preferences.test.ts), copia por reserva en driverView/preferences (preferences.int.ts), reglas con ventana (preferences.rules.ts, matriz), idiomas en openRequests (open_requests.test.ts), logs (errors.test.ts, logs_privacy.int.ts). Sección K. | Retención y necesidades sensibles: abogado. Listas de musicStyle y needs: revisión del responsable. config/ops.playlistHosts: lo fija el responsable. Apps y panel: Parte B. |
| Idiomas | PARCIAL (apps y servidor, en código) | Rama cierre/idiomas: es/en/pt en las apps del pasajero y del chófer, idioma de la cuenta en users/{uid}.locale (updatePreferences), avisos del servidor por idioma (i18n.ts), panel y legales en español. Sección L. | Revisión nativa y traducciones legales; decisiones de texto de la sección L. Capturas por idioma en docs/capturas/idiomas. |
| Registro de chóferes | PARCIAL (servidor, reglas, apps y panel, en código) | Rama cierre/registro-chofer, Parte A: alta del aspirante con startDriverApplication (A10, driver_start.int.ts); solicitud por pasos y documentos en Storage (driver_application.ts), storage.rules, revisión con URL firmada y bitácora, vencimientos y bloqueo en línea, reglas y matriz (driverRegistration.rules.ts, storage.rules.ts, driver_registration.int.ts). Sección M. | Requisitos y vencimientos (config/ops), retención y región del bucket: responsable y abogado. Parte B (apps y panel) hecha. Pendiente: bloqueo de conectarse sin TOTP solo en la app (no en las reglas); 10 capturas al 200 % sin hacer; pruebas en dispositivo real de DEPLOY.md (EXIF, cámara frontal, URL de 5 minutos); PDF desde la app y cámara propia, no hechos. |
