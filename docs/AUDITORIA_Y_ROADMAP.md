# Luxelane: auditoría y hoja de ruta hacia la "super app"

_Fecha: 6 de octubre de 2026 · Rama: `claude/sleepy-cerf-mggmiw`_

## 1. Qué tenemos hoy

| Área | Estado | Comentario |
|---|---|---|
| Landing web (`home_web_page.dart`) | Bien | La reserva está en el hero (como Blacklane), con tipografía editorial (Cormorant + Montserrat), scroll reveals y carrusel de flota. |
| Páginas de servicio (recogida, aeropuerto, por horas) | Bien | El diseño está completo, pero **faltan las fotos** (ver `assets/images/services/*/README.md`). |
| Auth email/contraseña | Funciona | La verificación de teléfono no hace nada. |
| Reserva (cliente) | Funciona | Precio fijo calculado en el cliente (`DefaultPricing`). |
| Pagos Stripe | Parcial | Se autoriza la tarjeta; la captura y la anulación están conectadas en el backend desde este cambio. |
| Ciclo de vida del viaje | Parcial | Los estados los avanza el chófer desde el cliente. La colección `rides` no se crea nunca. |
| App de chófer | Parcial | Onboarding, cola y viaje activo. El `firebase_config.dart` del chófer tiene placeholders. |
| Despacho | Básico | El chófer se auto-asigna; no hay búsqueda por cercanía. |
| Tracking en vivo | Básico | La ubicación se envía cada 10 s solo con la app abierta. |
| Notificaciones push | Rotas | Los tokens FCM solo se registran en la pantalla de viaje; los chóferes no reciben nada. |
| Admin | Parcial | Existen las pantallas CRUD; las reglas bloqueaban logs y config (corregido). |
| Promo codes, B2B, facturas, multi-idioma | No existe | — |

## 2. Hallazgos críticos y qué se corrigió en este cambio

### Seguridad (corregido)
1. **Cualquier usuario podía hacerse admin.** Las reglas permitían escribir `role` en `/users`, y el código auto-promovía `admin@luxelane.com`. Ahora el rol es inmutable para el usuario y el rol admin solo se otorga con `scripts/promote_admin.mjs`.
2. **Un chófer podía auto-verificarse** o inflar su `rating`/`totalRides`. Ahora esos campos solo los escriben los admins o el backend.
3. **Reservas sin validación.** Antes se podía crear una reserva ya asignada, pagada o con precio 0. Además, cualquier usuario (no solo chóferes) podía tomar reservas, y el chófer podía saltar estados. Ahora hay:
   - validación al crear la reserva;
   - solo chóferes **verificados** aceptan reservas;
   - una máquina de estados `confirmed → driver_arriving → driver_arrived → in_progress → completed`;
   - el pasajero cancela solo antes de iniciar el viaje.
4. **Cloud Functions sin control de propiedad (IDOR).** Cualquiera podía reembolsar pagos, usar el `customerId` de otro o capturar con un monto inventado. Ahora:
   - reembolsos y asignación manual: solo admin;
   - tarjetas: siempre las del propio usuario;
   - captura: con el monto **leído de la reserva**, verificando que el PaymentIntent pertenezca al pasajero.
5. **Clave de Stripe mal configurada.** Se leía de `process.env`, que `functions:config` no rellena en v2, así que en producción la clave quedaba vacía. Ahora usa `defineSecret('STRIPE_SECRET_KEY')`.

### Bugs funcionales (corregidos)
- La autorización de tarjeta nunca se vinculaba a la reserva, y la "captura" escribía un pago falso desde el cliente. Ahora la reserva guarda `stripePaymentIntentId`: al completarse, el backend **captura**; al cancelarse, **libera la retención**.
- Pasajeros, equipaje, número de vuelo y horas se pedían en la UI pero no se guardaban. Ahora se guardan.
- Se podía reservar con lugares ficticios ("Recogida"/"Destino" en 0,0). Ahora se exige origen y destino.
- La cola del chófer escuchaba toda la colección `bookings`, y las reglas la rechazaban. Ahora filtra por `status == pending`.
- El cron de limpieza cancelaba **reservas futuras** con más de 30 min de creadas. Ahora usa la hora de recogida y respeta el límite de 500 escrituras por batch.
- El despacho buscaba `vehicleClass`, pero Dart guarda `class`, así que nunca encontraba vehículos.
- Las reglas no cubrían notificaciones, `admin_logs` ni `config`.
- Contraste: texto negro sobre botón zafiro (≈2.5:1) y captions #525252 sobre navy (≈2.4:1). Ahora es blanco sobre zafiro (≈8:1) y captions #7A8699 (≥4.5:1).

### Salud del proyecto (corregido)
- Se eliminó la copia anidada `luxelane/`, un `flutter create` viejo que rompía `flutter analyze`.
- Los tests de Flutter no compilaban. Ahora pasan los **36**.
- **Nuevos tests:**
  - 11 de reglas de negocio en `functions` (`policy.test.ts`);
  - **18 de reglas de seguridad** contra el emulador de Firestore (`rules-tests/`).
- **CI:**
  - Flutter 3.29.3, el mínimo que exige el lockfile (antes 3.24, incompatible);
  - nuevo job de reglas;
  - se agregó `package-lock.json`, sin el cual `npm ci` fallaba;
  - se quitó el job de iOS (no existe `ios/`);
  - el proyecto de deploy ahora coincide con `.firebaserc`.

### Pendiente técnico conocido
- `places_web.dart` y `maps_web_loader.dart` usan `dart:js` / `dart:js_util`, que fueron **eliminados** en Flutter 3.3x+. Hay que migrar a `dart:js_interop` antes de actualizar Flutter.
- La clave de Google Maps está como valor por defecto en `env.dart`. Hay que **restringirla por dominio** (HTTP referrer) en Google Cloud Console y rotarla.
- **Moneda:** el cobro es en `BOB` (configurable con `--dart-define=CURRENCY=usd`). Hay que definir los mercados.
- **Testimonios inventados** (Londres, NY, París) en la landing: dañan la confianza y son un riesgo legal. Hay que reemplazarlos por reales o quitarlos.
- **Videos de fondo de 73 MB y 52 MB:** hay que comprimirlos a menos de 5 MB, con imagen poster primero.

## 3. Diagnóstico de diseño (UI/UX)

- **Hay tres paletas compitiendo:**
  - `LuxColors`: navy oscuro, usado en la app;
  - `LD`: azul claro "editorial", en la landing y la reserva;
  - un gris cálido, en el shell web.
- Hay **141 colores hex sueltos** en el código. El dorado `LuxColors.gold` está definido pero se usa **0 veces**.
- Hay unas 15 clases de botón duplicadas y 4 logos distintos. `booking_screen.dart` y `home_web_page.dart` tienen más de 3.300 líneas cada uno.
- **Accesibilidad:**
  - solo 2 `Semantics` en toda la app;
  - 55 `GestureDetector` frente a 1 `InkWell`, así que no hay foco de teclado ni lector de pantalla;
  - hay tamaños de fuente de 5 a 9 px.
- Faltan estados de **carga (skeletons)**, **éxito** (no hay pantalla de "reserva confirmada"), **vacío** y **error en línea**.
- Mezcla de español e inglés y sin i18n.

### Propuesta de identidad visual: "confianza + hospitalidad"
| Token | Hex | Uso |
|---|---|---|
| Ink | `#0B1220` | Fondo oscuro principal, texto sobre claro |
| Surface / Elevated | `#111A2B` / `#18233A` | Tarjetas y hojas en modo oscuro |
| Paper / Paper-2 | `#FAF8F4` / `#F2EEE7` | Fondo claro (landing, reserva) |
| **Champagne** | `#C6A15B` | **CTA principal**, foco y detalles premium (texto Ink encima, >8:1) |
| Sapphire | `#3B6FB6` | Solo enlaces e información |
| Success / Error | `#3E9C74` / `#D2524E` | Estados |

El navy transmite seguridad corporativa y el champagne transmite hospitalidad de lujo. Es la combinación que usan las marcas de chófer premium. La idea es un solo `ThemeExtension` con modo claro y oscuro, y una regla de lint que prohíba `Color(0x…)` fuera de los tokens.

## 4. Hoja de ruta hacia una super app tipo Blacklane

### Fase 1: Confianza y núcleo de negocio — en curso
Decisiones: **paleta marino + champagne** y **cobro en bolivianos (Bs)**.

| # | Entregable | Estado |
|---|---|---|
| 1 | **Cotización en servidor** (`quoteBooking`): precio fijo en Bs desde `pricingRules` (o valores por defecto), distancia validada en el servidor y cotización válida 15 min | ✅ Hecho |
| 2 | **Reserva solo vía Cloud Function** (`createBooking`): precio, ruta y vehículo salen de la cotización; la autorización de tarjeta debe coincidir con el monto cotizado; las reglas bloquean la escritura directa | ✅ Hecho |
| 3 | **Notificaciones**: registro del token FCM al iniciar sesión (pasajeros y chóferes; web con `FCM_VAPID_KEY`) | ✅ Hecho |
| 4 | **Identidad visual**: tokens en `lib/app/theme/lux_tokens.dart`, acento champagne con texto tinta (8,6:1), papel cálido en superficies claras y formato `LuxMoney` (`Bs 1.250`) | ✅ Hecho (base) |
| 5 | **Pantalla "Reserva confirmada"**: check animado, precio fijo, resumen, cuenta regresiva y garantías | ✅ Hecho |
| 6 | **Pagos con tarjeta (Stripe)** | ⏸️ Fuera de alcance por ahora. Las reservas sin tarjeta quedan como *pago al chófer* (efectivo o QR) y la app lo explica al confirmar |
| 7 | **Recibo** en la app (viajes completados y cancelados, copiable); correo/SMS pendiente | ✅ Recibo · ⏳ correo |
| 8 | **Componentes** en `lib/core/widgets/lux_states.dart`: `PriceBreakdown`, `LuxSkeleton`, `LuxSkeletonList` y `LuxErrorState`. Se partieron los archivos grandes: `home_web_page.dart` pasó de 3.393 a ~200 líneas (secciones en `web/`) y `booking_screen.dart` de 3.481 a ~1.800 (`booking/`). Se borraron unas 1.300 líneas de código muerto | ✅ Hecho |
| 9 | **Landing confiable**: los testimonios inventados se reemplazaron por "La promesa Luxelane" (solo compromisos que el producto cumple) y "Cómo funciona". Se corrigieron afirmaciones falsas ("En todo el mundo", "+50 ciudades", "24/7") y se unificaron los CTA en champagne | ✅ Hecho |
| 10 | **Mis viajes**: secciones Próximos y Anteriores, skeleton de carga, error con reintento, tarjetas tocables (viaje en curso o recibo) | ✅ Hecho |

**Cómo funciona el precio ahora:**
1. La app muestra un **estimado**.
2. Al confirmar, pide la **cotización al servidor**. Si difiere en Bs 1 o más, muestra el precio fijo y pide confirmación.
3. Se autoriza la tarjeta por **exactamente** ese monto.
4. La reserva se crea en el servidor con ese precio.
5. Se **cobra al completar** el viaje y la retención **se libera si se cancela**.

### Fase 2: Experiencia premium diferencial — en curso

| # | Entregable | Estado |
|---|---|---|
| 1 | **Chófer real en el viaje.** Antes todos los pasajeros veían un chófer inventado ("James Whitmore"). Ahora, al asignarse la reserva, el backend copia en ella una ficha del chófer: nombre corto, foto, rating real, viajes, vehículo, color y placa. El teléfono solo se ve mientras el viaje está activo, con botones Llamar y WhatsApp | ✅ Hecho |
| 2 | **Seguimiento en vivo privado.** El chófer escribe su posición en `bookings/{id}/tracking/live`, que solo leen ese pasajero y ese chófer, y solo mientras el viaje está activo. Se borra al terminar. `driverProfiles` dejó de ser legible para cualquier usuario: antes exponía la ubicación de todos los chóferes | ✅ Hecho |
| 3 | **ETA en vivo** ("Tu chófer llega en 6 min" / "Llegas en 18 min") con indicador EN VIVO; el pasajero ya no ve el botón de desarrollo "Siguiente (dev)" | ✅ Hecho |
| 4 | **Seguimiento de vuelos** (`trackFlights`, cada 15 min, AeroDataBox). Si el vuelo se retrasa 10 min o más, la recogida se corre lo mismo que el retraso (nunca se adelanta) y se avisa al pasajero y al chófer. La tarjeta del vuelo en la app muestra estado, terminal y nueva hora | ✅ Hecho (requiere `FLIGHT_API_KEY`) |
| 5 | **Calificaciones reales** (`rateBooking`): 1–5 estrellas y comentario, una sola vez por viaje; actualiza el promedio del chófer. Antes se enviaban a un documento que nunca existía | ✅ Hecho |
| 6 | **Despacho por cercanía.** Las recogidas de los próximos 90 min se ofrecen primero al chófer verificado más cercano con la clase correcta, dentro de 25 km y con ubicación de menos de 10 min. Tiene 1 minuto para aceptar (lo ve como "Solicitud exclusiva" con cuenta regresiva). Si la rechaza o no responde, pasa al siguiente (hasta 5) y luego se abre a todos. Las reservas anticipadas se abren a todos desde el inicio. Las reglas impiden que otro chófer tome una oferta exclusiva | ✅ Hecho |
| 7 | **Meet & greet.** La reserva guarda el nombre y teléfono reales del pasajero (o del invitado). El chófer tiene llamar, WhatsApp y **"Mostrar cartel"**, que pone el nombre a pantalla completa en horizontal. El pasajero ve en el viaje cómo y dónde lo esperan | ✅ Hecho |
| 7b | **Espera gratuita: 60 min en aeropuerto** desde el aterrizaje y **15 min en ciudad** desde la recogida o la llegada del chófer. Cuenta regresiva para pasajero y chófer, aviso push con la hora límite, y se muestra en la confirmación y en la landing | ✅ Hecho |
| 8 | **Idiomas es / en / pt.** La app sigue el idioma del dispositivo o navegador y cambia en vivo, sin reiniciar; si el idioma no está soportado usa inglés. Hay 1068 textos en ARB, con fechas, horas y montos según el idioma. Las push salen en el idioma del usuario, y en Android 13+ se puede elegir el idioma por app. Los tests impiden textos fijos y traducciones incompletas (ver `lib/l10n/README.md`) | ✅ Hecho |
| 9 | **Reportes de operaciones** (admin → Reportes). Se calculan sobre las reservas reales, por fecha de recogida y en hora local, para los últimos 7, 30 o 90 días. Incluyen viajes completados e ingresos (con variación contra el período anterior), ticket promedio, tasa de cancelación, cancelaciones tardías, reservas que nadie tomó y calificación promedio. Gráficos: viajes por día, ingresos por día, demanda por hora de recogida, mezcla por categoría y servicio, y origen de las cancelaciones. Tabla de rendimiento por chófer. Los datos diarios y los de chóferes se exportan a CSV (descarga en web; en móvil se copian) | ✅ Hecho |

### Fase 3: Super app y B2B (4–6 semanas) — en curso

| # | Entregable | Estado |
|---|---|---|
| 1 | **Cuentas corporativas.** Luxelane crea la empresa (razón social, NIT, correo de facturación) desde admin → Empresas y puede suspenderla. El administrador de la empresa entra desde su perfil a un portal con tres secciones. **Estado de cuenta** mensual: total a facturar, desglose por centro de costo y por persona, lista de viajes y exportación CSV. **Miembros**: agregar por correo; si la persona aún no tiene cuenta, se une al registrarse. También cambiar permisos y quitar miembros. **Ajustes**: datos de facturación y centros de costo, que puede exigir. Al reservar, el miembro elige "Facturar a la empresa" o "Personal" y puede indicar centro de costo y referencia. El servidor valida la membresía, el centro de costo y que la cuenta esté activa. Un viaje corporativo no pasa por tarjeta, y el chófer ve "no cobres al pasajero". La confirmación y el recibo muestran "Facturado a {empresa}". Las reglas permiten al administrador de la empresa leer solo los viajes de su empresa; nadie puede unirse ni darse permisos a sí mismo. Los datos del invitado ya se guardaban en campos propios (Fase 2) | ✅ Hecho (desplegar reglas e índices: `firebase deploy --only firestore,functions`) |

| 2 | **Verificación de chóferes.** El chófer sube 5 documentos (licencia, cédula, antecedentes, SOAT y RUAT) como foto o PDF desde "Documentos", e indica el vencimiento de los que vencen. El admin los revisa desde Chóferes → Revisar documentos: abre el archivo, aprueba confirmando la fecha o rechaza con un motivo, y el chófer recibe un aviso en su idioma. `documentsVerified` ya no se marca a mano: el servidor lo recalcula cada vez que cambia un documento, y un chófer sin verificar queda desconectado y fuera del despacho. Cada día se vencen los documentos caducados y se avisa 30 y 7 días antes. Los archivos están en Storage y solo los ven el chófer y los admins. Se borran al eliminar la cuenta. Los chóferes verificados antes de este cambio siguen verificados hasta que suban o cambien un documento | ✅ Hecho (activar Storage y desplegar: `firebase deploy --only functions,firestore,storage`) |

| 3 | **Códigos promocionales.** El admin crea códigos desde Promociones. Pueden ser de porcentaje con tope o de monto fijo, con monto mínimo del viaje y fechas de vigencia. También se limitan los usos totales y por pasajero, y se pueden reservar al primer viaje o a ciertas categorías. Cada código se pausa con un clic y muestra cuántas veces se usó. El pasajero escribe el código al reservar y ve el descuento al instante. El servidor lo valida al cotizar y deja el precio con descuento fijado en la cotización. El uso se registra al crear la reserva, en una transacción que vuelve a revisar los límites, y se libera si la reserva se cancela. Si el código deja de valer entre la vista previa y la confirmación, se explica el motivo y se pide confirmar el precio completo. La confirmación y el recibo muestran el descuento. Los pasajeros no pueden listar códigos ni tocar contadores | ✅ Hecho (desplegar: `firebase deploy --only functions,firestore`) |

Pendiente de la Fase 3:
2. **Programa de fidelidad** (niveles y beneficios reales).
3. **Más verticales**: ciudad a ciudad, eventos o roadshows, traslados de hotel y chófer por días.
4. **Pagos a chóferes** (liquidaciones; sin Stripe Connect).
5. **Soporte 24/7** con chat en la app, centro de ayuda y protocolo de incidentes; auditoría completa en `admin_logs`.
6. **Observabilidad**: Crashlytics, Performance, alertas y entornos dev/staging/prod separados.

### Señales de confianza para la landing (rápido, alto impacto)
- Una franja con: **precio fijo garantizado**, **cancelación gratuita hasta 1 h antes**, **chóferes verificados**, **seguro incluido** y **soporte 24/7**.
- Una sección "Cómo funciona" en 3 pasos, ciudades disponibles, badges de App Store y Google Play, y logos de medios de pago.
- Footer con términos, privacidad, contacto real y selector de idioma.

## 4b. Preparación para lanzar

| Bloqueante | Estado |
|---|---|
| La **app del chófer no conectaba a Firebase** (configuración con valores de relleno) | ✅ Corregido: usa la configuración real |
| `deploy_web.sh` compilaba con `GOOGLE_MAPS_KEY=placeholder`, lo que rompía los mapas en producción; además no desplegaba la app del chófer | ✅ Corregido: exige la clave y despliega ambas apps |
| **Eliminar cuenta** (obligatorio en Google Play y App Store) | ✅ En Perfil y en `/eliminar-cuenta` (sirve como URL para la tienda). No se puede con un viaje en curso; las reservas pendientes se cancelan y los viajes pasados se conservan sin datos de contacto |
| **Términos, Privacidad y Contacto** | ✅ Páginas públicas en `/terminos`, `/privacidad` y `/contacto`, enlazadas desde el footer, el perfil y el registro. El registro exige aceptar los términos y guarda la fecha y versión aceptadas. ⚠ Son borradores: completa `lib/core/config/legal.dart` y hazlos revisar por un abogado. Se muestra un aviso de "borrador" hasta completarlos |
| Controles falsos en el perfil ("Millas", idiomas que no cambiaban nada, preferencias de notificaciones sin efecto, métodos de pago de Stripe) | ✅ Reemplazados por Ayuda y legal |
| **Ubicación del chófer en segundo plano** | ✅ Android: servicio en primer plano con notificación visible, sin pedir el permiso de ubicación "siempre". iOS: actualizaciones en segundo plano. Web: sigue funcionando solo con la pestaña abierta |
| **Android listo para la tienda**: permisos de Internet, ubicación y notificaciones; dos apps (`com.luxelane.rider` y `com.luxelane.driver`); firma de release con `key.properties`; clave de Maps para Android | ✅ Configurado. ⚠ No se pudo compilar aquí (sin Android SDK); hay que verificarlo con `flutter build appbundle` |
| **Firebase para Android/iOS**: hoy solo está configurado para web, así que las apps móviles se caen al iniciar | ⏳ Requiere `flutterfire configure` con tu cuenta (pasos en `DEPLOY.md`) |
| Proyecto iOS | ⏳ No existe la carpeta `ios/` (pasos en `DEPLOY.md`) |
| **Cancelación por el pasajero.** No existía en la app aunque se prometía | ✅ "Cancelar reserva" en el viaje, con aviso de si es gratuita. El servidor libera al chófer, le avisa en su idioma y marca `lateCancellation` cuando faltaba menos de 1 h, para la futura política |
| **Panel de operaciones** | ✅ Alerta de reservas sin chófer con recogida en menos de 2 h, filtro "Sin chófer", y por reserva: asignar al chófer más cercano (mismo ranking que el despacho automático), cancelar (con aviso al pasajero y al chófer, auditado) o eliminar |
| Textos de marketing no respaldados (gerente de cuenta, facturación centralizada, champán, Wi-Fi, "todo el mundo", clase Eléctrico no reservable, 4 asientos) | ✅ Reemplazados por funciones reales |

## 5. Cómo probar

```
flutter test                      # 187 tests Dart
(cd functions && npm test)        # 69 tests de negocio, precios, vuelos, chófer, espera, despacho, cancelación, mensajes, cuentas corporativas, documentos y promociones
(cd rules-tests && npm test)      # 30 tests de reglas de Firestore y Storage (requiere Java)
```

**Deploy:**
1. `firebase functions:secrets:set STRIPE_SECRET_KEY` (aunque no se use Stripe, el secreto tiene que existir para poder desplegar; sirve cualquier valor de relleno)
2. `firebase functions:secrets:set FLIGHT_API_KEY` (clave de AeroDataBox en RapidAPI; con el valor `none` el seguimiento de vuelos queda apagado)
3. `firebase deploy --only functions,firestore`

> ⚠️ **Despliega Functions y reglas juntos, y antes que la app.** La app nueva crea reservas con `quoteBooking`/`createBooking`. Las reglas nuevas impiden crear reservas desde versiones viejas de la app.

> ⚠️ Si ya hay usuarios con `role: admin` creados indebidamente en producción, hay que revisarlos a mano en Firestore.
