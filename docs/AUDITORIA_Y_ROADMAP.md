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
| 6 | **Stripe completo**: SetupIntent (3DS), webhook, cargo por cancelación tardía y re-autorización de reservas con más de 6 días | ⏳ Pendiente |
| 7 | **Recibo PDF y correo/SMS** de confirmación | ⏳ Pendiente |
| 8 | **Componentes**: `PriceBreakdown`, skeletons, estados vacío/error, y partir `booking_screen.dart` / `home_web_page.dart` | ⏳ Pendiente |

**Cómo funciona el precio ahora:**
1. La app muestra un **estimado**.
2. Al confirmar, pide la **cotización al servidor**. Si difiere en Bs 1 o más, muestra el precio fijo y pide confirmación.
3. Se autoriza la tarjeta por **exactamente** ese monto.
4. La reserva se crea en el servidor con ese precio.
5. Se **cobra al completar** el viaje y la retención **se libera si se cancela**.

### Fase 2: Experiencia premium diferencial (3–4 semanas)
1. **Seguimiento de vuelos** (AeroDataBox / FlightAware): la recogida se ajusta sola al retraso, con 60 min de espera gratis en aeropuerto y 15 min en ciudad.
2. **Meet & greet**: cartel con el nombre, instrucciones de punto de encuentro y chat o llamada enmascarada con el chófer.
3. **Despacho real**: geohash con ranking por distancia y clase, ofertas con timeout y reasignación, y SLA de confirmación para reservas programadas.
4. **Tracking en vivo** en una hoja inferior con ETA animada, ubicación en segundo plano para el chófer y un documento de tracking por reserva (privacidad: solo el pasajero ve al chófer).
5. **Perfil del chófer**: foto, idiomas, rating real (desde `rides`) y vehículo con matrícula.
6. **i18n (es/en/pt)** con ARB y selector de idioma; multimoneda.

### Fase 3: Super app y B2B (4–6 semanas)
1. **Cuentas corporativas**: centros de costo, reservar para invitados (campo real, no en `notes`), facturación mensual y panel de empresa.
2. **Programa de fidelidad** (niveles, upgrades) y **códigos promocionales**.
3. **Más verticales**: ciudad a ciudad, eventos o roadshows, traslados de hotel y chófer por días.
4. **Verificación de chóferes**: subida de documentos (licencia, seguro, antecedentes), vencimientos, revisión en el admin y pagos con Stripe Connect.
5. **Soporte 24/7** con chat en la app, centro de ayuda y protocolo de incidentes; auditoría completa en `admin_logs`.
6. **Observabilidad**: Crashlytics, Performance, alertas y entornos dev/staging/prod separados.

### Señales de confianza para la landing (rápido, alto impacto)
- Una franja con: **precio fijo garantizado**, **cancelación gratuita hasta 1 h antes**, **chóferes verificados**, **seguro incluido** y **soporte 24/7**.
- Una sección "Cómo funciona" en 3 pasos, ciudades disponibles, badges de App Store y Google Play, y logos de medios de pago.
- Footer con términos, privacidad, contacto real y selector de idioma.

## 5. Cómo probar

```
flutter test                      # 38 tests Dart
(cd functions && npm test)        # 21 tests de reglas de negocio y precios
(cd rules-tests && npm test)      # 18 tests de reglas de seguridad (requiere Java)
```

**Deploy:**
1. `firebase functions:secrets:set STRIPE_SECRET_KEY`
2. `firebase deploy --only functions,firestore`

> ⚠️ **Despliega Functions y reglas juntos, y antes que la app.** La app nueva crea reservas con `quoteBooking`/`createBooking`. Las reglas nuevas impiden crear reservas desde versiones viejas de la app.

> ⚠️ Si ya hay usuarios con `role: admin` creados indebidamente en producción, hay que revisarlos a mano en Firestore.
