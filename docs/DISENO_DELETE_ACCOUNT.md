# deleteAccount: diseño (sin implementar)

Este documento es solo una propuesta. **No se ha cambiado código.** Lo que
falta lo deciden el responsable del proyecto, el contador y el abogado (ver
las preguntas al final). Las afirmaciones van etiquetadas según CLAUDE.md.

## 1. Qué hace hoy (`functions/src/index.ts`, `deleteAccount`) [seguro]

1. Rechaza las cuentas de administración (`admin_account`) y las que tienen
   reservas activas como pasajero o como chófer (`active-bookings`).
2. Borra el cliente de Stripe, si lo hay (un fallo no detiene el borrado).
3. Borra `users/{uid}/notifications`, `driverProfiles/{uid}` y `users/{uid}`.
4. Desactiva los vehículos del chófer (no los borra).
5. Escribe en `admin_logs` una entrada `delete_account` **con el correo de
   la persona** (`adminEmail`).
6. Borra el usuario de Firebase Auth.

Lo que **no** toca hoy [seguro]: las reservas (direcciones y coordenadas,
notas, datos del invitado, preferencias, valoraciones, `driverInfo`), sus
subcolecciones (`tracking`, `driverContact`, `events`, `eventLocations`,
`private`, `adminOnly`), `payments`, `incidents` y sus ubicaciones,
`incidentRateLimits/{uid}`, `rateLimits/*__{uid}` y los `admin_logs`
anteriores en los que aparece la persona.

## 2. Inventario y propuesta por dato

Propuesta [Especulando] hasta que respondan contador y abogado.
«Seudónimo» significa sustituir el uid por un identificador sin vínculo con
la persona (por ejemplo `deleted_<aleatorio>`), sin guardar en ningún sitio la
correspondencia con el uid.

| Dónde | Datos personales | Propuesta | Motivo |
|---|---|---|---|
| Firebase Auth | correo, teléfono, proveedor | Borrar (ya se hace) | Sin uso tras el cierre |
| `users/{uid}` | nombre, correo, teléfono, foto, tokens FCM, preferencias | Borrar (ya se hace) | — |
| `users/{uid}/notifications` | textos de avisos | Borrar (ya se hace) | — |
| `driverProfiles/{uid}` | licencia, vencimiento, última ubicación | Borrar (ya se hace) | Ver pregunta C3 si hay que guardar la licencia |
| `vehicles` del chófer | placa, marca, modelo | Desactivar (ya se hace); ¿quitar `driverId`? | La placa identifica al chófer; ver A4 |
| `bookings` terminadas o canceladas | `riderId`/`driverId`, direcciones, coordenadas, notas, invitado (nombre, teléfono, correo), preferencias, comentarios, `driverInfo` | Conservar importe, fechas, clase, servicio, km, ciudad, estado y `settlement`; **seudónimo** en `riderId`/`driverId`; borrar notas, invitado, preferencias, comentarios y `driverInfo`; reducir direcciones a la zona (como `pickupArea`) | Contabilidad sin identificar a la persona; ver C1 y A1 |
| `bookings/*/tracking`, `driverContact` | ubicación y teléfono del chófer | Borrar | Ya no son visibles fuera del viaje |
| `bookings/*/events`, `eventLocations` | quién y dónde en cada paso | Conservar el evento con seudónimo; borrar ubicaciones | Ver A2 (prueba ante reclamos) |
| `bookings/*/private` | sal del código | Borrar | Sin uso tras el viaje |
| `payments` | `riderId`, importes, IDs de Stripe | Conservar con seudónimo | Registro contable; ver C1 y C2 |
| Stripe | cliente, métodos de pago, cargos | Borrar el cliente (ya se hace); los cargos los conserva Stripe | [Probable] Stripe guarda sus propios registros de pagos; NO VERIFICADO |
| `incidents` y `locations` | quién pidió ayuda, ubicaciones | Si hay incidente abierto o en plazo de retención: **impedir el borrado** (nuevo motivo `incident_hold`); después, seudónimo y ubicaciones borradas según la retención acordada | Ver A3 y la pregunta de retención ya abierta en la auditoría |
| `admin_logs` | correo en `delete_account`, uid en `targetId` | No guardar el correo; `targetId` con seudónimo | Hoy el registro del borrado conserva el correo [seguro] |
| `incidentRateLimits/{uid}`, `rateLimits/*__{uid}` | uid y contadores | Borrar (o dejar que caduquen por TTL) | Sin valor tras el cierre |
| `openRequests` | sin datos personales | Nada | — |
| `businessLeads` | contacto de empresas, sin uid | Fuera de este flujo | No se vincula a una cuenta |

### Chóferes

- Antes de borrar: ¿hay liquidaciones pendientes (`settlement`) con el
  chófer? Si las hay, borrar la cuenta dejaría pagos sin destinatario. Ver C4.

### Orden propuesto [Especulando]

1. Comprobaciones: admin, reservas activas, incidente abierto o en
   retención, liquidaciones pendientes del chófer.
2. Marcar `users/{uid}.deletionRequestedAt` y cerrar sesión en todos los
   dispositivos (`revokeRefreshTokens`).
3. Seudonimizar y limpiar reservas, pagos, eventos y registros en lotes
   (idempotente: si se corta, al reintentar continúa).
4. Borrar Stripe, documentos del usuario y Auth.
5. Registrar `delete_account` en `admin_logs` sin correo.

Si se decide un plazo de gracia (pregunta N1), los pasos 3–5 los haría una
función programada al vencer el plazo.

## 3. Preguntas

### Para el contador

- **C1.** ¿Cuánto tiempo hay que conservar los registros de cada viaje y
  cobro, y qué campos exige la normativa (importe, fecha, concepto, datos
  del cliente)? NO VERIFICADO: no hay cifra en el repositorio y no se
  inventa aquí.
- **C2.** ¿Los comprobantes o facturas emitidos deben conservar nombre o
  NIT del cliente aunque borre su cuenta? Si sí, ¿dónde deben guardarse?
- **C3.** ¿Hay que conservar algún dato del chófer (licencia, documento)
  por obligaciones con él (pagos, retenciones)?
- **C4.** Liquidaciones pendientes con un chófer que borra su cuenta:
  ¿se paga antes, se retiene el borrado o se guarda el dato bancario
  aparte?

### Para el abogado

- **A1.** ¿Qué normativa de datos personales aplica a la operación y qué
  plazo hay para atender una solicitud de borrado?
- **A2.** ¿Se pueden conservar, con seudónimo, los registros de viaje y
  eventos como prueba ante reclamos? ¿Por cuánto tiempo?
- **A3.** Incidentes de seguridad (SOS): ¿se puede negar o aplazar el
  borrado mientras haya un incidente abierto o en plazo de retención?
- **A4.** Datos de terceros: el invitado de una reserva (nombre, teléfono,
  correo) y la placa del vehículo. ¿Se borran con la cuenta de quien
  reservó?
- **A5.** ¿Qué texto de la política de privacidad debe describir este
  proceso?

### Para el responsable del proyecto

- **N1.** ¿Borrado inmediato o con plazo de gracia para arrepentirse?
- **N2.** ¿El admin puede borrar cuentas a petición (por correo o
  teléfono), con el mismo proceso?

## 4. Propuestas del responsable (2026-10-24, no implementadas)

No se implementa nada hasta tener las respuestas del contador y del abogado.

- **N1** [Especulando]: periodo de gracia de 14 días durante el cual la
  cuenta queda deshabilitada y se puede revertir.
- **N2**: sí, el admin puede borrar a petición de la persona, con auditoría
  en el servidor y verificación de identidad.
