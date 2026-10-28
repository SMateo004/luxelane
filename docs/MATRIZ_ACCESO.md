# Matriz de acceso de Firestore

Qué puede hacer cada rol en cada colección según `firestore.rules`. La tabla
sale de `tools/rules-tests/test/matrix.ts` y cada celda es un test de
`tools/rules-tests/test/matrix.rules.ts` (1000 celdas: 25 filas × 8 roles × 5
operaciones, más dos casos fuera de la tabla). Si la tabla de aquí y la del código no coinciden, el test falla;
para regenerarla: `UPDATE_MATRIX=1` al correr `npm run test:rules`.

Las funciones del servidor usan el Admin SDK y no pasan por estas reglas.

## Leyenda

- Operaciones: **L** leer (un documento), **Li** listar (una consulta),
  **C** crear, **A** actualizar, **B** borrar. `·` = denegado.
- Roles (personas de `tools/rules-tests/test/setup.ts`):
  - anónimo: sin sesión.
  - pasajero dueño: `ana`, dueña de la reserva `activa`.
  - otro pasajero: `beto`.
  - chófer verificado asignado: `asig`, asignado a `activa`.
  - chófer verificado no asignado: `libre`.
  - chófer no verificado: `nover`.
  - usuario bloqueado: `bloq`, chófer verificado con `isActive == false`.
    Actúa sobre lo suyo (su usuario, sus avisos, su perfil, su vehículo, su
    SOS) y sobre la reserva `activaBloq`, que tiene asignada: así la tabla
    muestra qué conserva una cuenta bloqueada.
  - admin.
- «Cubierta antes»: `sí` si algún test de reglas ya la probaba antes de esta
  matriz; `nueva` si solo la prueba la matriz.
- Debajo de la tabla, el documento y el cambio que usa cada fila.

<!-- matriz:inicio -->
| Colección | Cubierta antes | anónimo | pasajero dueño | otro pasajero | chófer verif. asignado | chófer verif. no asignado | chófer no verificado | usuario bloqueado | admin |
|---|---|---|---|---|---|---|---|---|---|
| `users/{uid}` | sí | · · · · · | L · · A · | · · · · · | · · · · · | · · · · · | · · · · · | L · · · · | L Li · · · |
| `users/{uid}/notifications` | nueva | · · · · · | L Li · A B | · · · · · | · · · · · | · · · · · | · · · · · | L Li · A B | L Li · · · |
| `driverProfiles/{uid}` | sí | · · · · · | · · · · · | · · · · · | L · C A · | · · C · · | · · C · · | L · · A · | L Li · · · |
| `bookings/{id}` | sí | · · · · · | L Li · · · | · · · · · | L · · · · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `bookings/{id}/tracking` | sí | · · · · · | L Li · · · | · · · · · | L Li C A · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `bookings/{id}/driverContact` | sí | · · · · · | L Li · · · | · · · · · | L Li · · · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `bookings/{id}/private` | sí | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · |
| `bookings/{id}/events` | sí | · · · · · | L Li · · · | · · · · · | L Li · · · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `bookings/{id}/eventLocations` | sí | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `bookings/{id}/eventDetails` | nueva | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `bookings/{id}/adminOnly` | sí | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `incidents/{id}` | sí | · · · · · | L Li · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li · · · | L Li · · · |
| `incidents/{id}/locations` | sí | · · · · · | L Li C · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li C · · | L Li · · · |
| `incidents/{id}/events` | sí | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `incidentRateLimits/{uid}` | sí | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · |
| `rateLimits/{id}` | sí | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · |
| `openRequests/{id}` | sí | · · · · · | · · · · · | · · · · · | L Li · · · | L Li · · · | · · · · · | · · · · · | L Li · · · |
| `rides/{id}` | nueva | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `payments/{id}` | nueva | · · · · · | L Li · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `bookings/{id}/payment` | nueva | · · · · · | L Li · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `paymentRefs/{ref}` | nueva | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · |
| `paymentOperations/{key}` | nueva | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · |
| `vehicles/{id}` | sí | · · · · · | · · · · · | · · · · · | L Li C A · | · · C · · | · · C · · | L Li · · · | L Li · · · |
| `pricingRules/{id}` | nueva | L Li · · · | L Li · · · | L Li · · · | L Li · · · | L Li · · · | L Li · · · | L Li · · · | L Li · · · |
| `config/global` | nueva | L · · · · | L · · · · | L · · · · | L · · · · | L · · · · | L · · · · | L · · · · | L · · · · |
| `config/finance` | nueva | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L · · · · |
| `config/ops` | nueva | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L · · · · |
| `config/security` | nueva | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · |
| `businessLeads/{id}` | nueva | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `adminAlerts/{id}` | sí | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `driverDevices/{uid}/devices/{id}` | sí | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `admin_logs/{id}` | nueva | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li · · · |

- `users/{uid}`: Objetivo users/ana (bloqueado: users/bloq, el suyo). Crear = perfil de otro (users/nuevo); el alta propia está en «Casos fuera de la tabla». Actualizar = displayName.
- `users/{uid}/notifications`: Objetivo users/ana/notifications (bloqueado: las suyas). Las crea el servidor.
- `driverProfiles/{uid}`: Objetivo driverProfiles/asig (bloqueado: el suyo). Crear = el alta propia del chófer (los pasajeros intentan la suya; anónimo y admin, driverProfiles/nuevo).
- `bookings/{id}`: Objetivo bookings/activa (de ana, asignada a asig, en camino); bloqueado: activaBloq, asignada a él. Listar = reservas de ana (bloqueado: las suyas). Actualizar = cancelar, que solo hace el servidor (cancelBooking, B7).
- `bookings/{id}/tracking`: Ubicación del chófer de activa (bloqueado: de activaBloq).
- `bookings/{id}/driverContact`: Teléfono del chófer de activa (bloqueado: de activaBloq). Lo escribe el servidor.
- `bookings/{id}/private`: Sal del código de recogida: nadie desde el cliente, ni el admin.
- `bookings/{id}/events`: Registro de transiciones de activa (bloqueado: de activaBloq). Solo anexa el servidor.
- `bookings/{id}/eventLocations`: Ubicación del chófer en cada evento: solo la lee el admin.
- `bookings/{id}/eventDetails`: Motivo del admin al forzar la verificación y control de llegada (farFromPickup): solo el admin (A8.7).
- `bookings/{id}/adminOnly`: Estado de incidentes de la reserva: solo lo lee el admin.
- `incidents/{id}`: Aviso SOS de ana en activa (bloqueado: el suyo en activaBloq). La contraparte (asig) no lo ve.
- `incidents/{id}/locations`: Ubicación de quien pidió ayuda (tramo de 10 s). Un bloqueado también puede pedir ayuda.
- `incidents/{id}/events`: Registro del incidente: solo el admin lo lee.
- `incidentRateLimits/{uid}`: Contador del SOS: solo el servidor.
- `rateLimits/{id}`: Contadores de límites de las callables: solo el servidor.
- `openRequests/{id}`: Solicitudes sin datos personales: chóferes verificados y activos, y el admin.
- `rides/{id}`: Colección heredada sin uso (H7): solo el admin lee los documentos que queden; nadie escribe. r1: de ana con asig; bloqueado: rBloq.
- `payments/{id}`: Pago de ana (reserva fin). Cobros y reembolsos los hace el servidor; los manuales, adminRecordPayment (Parte A). Desde pagos (A1), también los asientos charge, refund y fee_retained.
- `bookings/{id}/payment`: Estado del pago de activa (A1): lo escribe solo el servidor; lo leen ana y el admin. El chófer asignado (asig) no lo lee: por eso no va en la reserva.
- `paymentRefs/{ref}`: Unicidad de la referencia del pago (A1): solo el servidor.
- `paymentOperations/{key}`: Números de operación ya usados en una confirmación (A4): solo el servidor.
- `vehicles/{id}`: Vehículo de asig (bloqueado: el suyo). Crear = registrar el propio, inactivo; un bloqueado no (H8).
- `pricingRules/{id}`: Tarifas públicas (la web las muestra sin sesión). Las escribe adminUpdatePricingRule (Parte A), sin campos internos ni `updatedBy`: quién la cambió va solo en admin_logs (C3).
- `config/global`: Estado operativo público. Listar la colección incluye config/security: nadie (A8.9). Los ajustes del panel van por adminUpdateConfig (Parte A). Nadie la borra (H9).
- `config/finance`: Comisión y parámetros internos: el admin la lee; la comisión se cambia con adminUpdateConfig (entre 0 y 100, Parte A). Nadie la borra.
- `config/ops`: Tiempos del SOS, retención, radio de llegada y límite de ajuste: el admin la lee; se edita con adminUpdateConfig o en la consola (A8.9, Parte A).
- `config/security`: Segundo factor y sesión máxima de admin: ningún cliente, ni el admin; solo la consola y el servidor (A8.9).
- `businessLeads/{id}`: Formulario de empresas: se envía con la callable submitBusinessLead (H5); ningún cliente escribe directo. El admin lo lee; lo marca atendido con adminSetLeadHandled (Parte A).
- `adminAlerts/{id}`: Avisos del servidor: el admin los marca con resolveAlert, no escribiendo.
- `driverDevices/{uid}/devices/{id}`: Dispositivos del chófer (B7): los anota registerDriverDevice; solo el admin los ve, ni el propio chófer. Alerta baja por dispositivo nuevo, y por el primero si ya está verificado (C2).
- `admin_logs/{id}`: Auditoría inmutable: la escribe solo el servidor, en la transacción de cada cambio (Parte A), y los scripts (promote_admin, reset_mfa, migraciones) con el Admin SDK. Ningún cliente, ni el admin.
<!-- matriz:fin -->

Pagos, Parte B: sin cambios de reglas. Las apps leen
`bookings/{id}/payment/state` (pasajero dueño) y escriben solo por
callables; el panel usa `adminPaymentInbox`, `adminConfirmPayment`,
`adminRejectPayment`, `adminRecordRefund` y `adminCollectBalance` (G2). La app del chófer no lee pagos
(`test/driver/driver_sin_pagos_test.dart`).


## Hallazgos

Celdas más abiertas de lo necesario. Severidad: Alta, Media, Baja,
Informativa.

| # | Celdas | Severidad | Estado |
|---|---|---|---|
| H1 | `bookings`, `tracking`, `driverContact`, `events`, `rides` × usuario bloqueado × leer/listar | Media | **Corregido** (a32305f). La lectura del chófer asignado exige `isActiveUser()`. La app del chófer muestra «Cuenta suspendida. Contacta con central.»; el panel avisa al bloquear a un chófer con viajes activos y permite reasignarlos. Tests: `blockedDriver.rules.ts` (bloqueado no lee, reactivado sí), matriz, `auth_bloc_test`, `block_driver_test`. |
| H2 | `users` × dueño (y bloqueado) × actualizar `isVerified` | Baja | **Corregido** (58eb92a). `isVerified` es campo privilegiado. |
| H3 | `users/{uid}/notifications` × dueño (y bloqueado) × crear | Baja | **Corregido** (58eb92a). Los avisos los crea el servidor. |
| H4 | `driverProfiles` × chófer verificado × actualizar | Media | **Corregido** (140bac6). Tras verificar, el chófer no cambia `licenseNumber`, `licenseExpiry` ni `vehicleId`; del vehículo ya solo editaba `color` y `photoUrl` (`plate`, `class`, `make`, `model`, `year`: solo admin). El perfil del chófer muestra los campos bloqueados; el admin los cambia desde el panel con motivo en `admin_logs`. Tests: `driverDocuments.rules.ts`, `driver_documents_test.dart`. |
| H5 | `businessLeads` × cualquiera (también anónimo) × crear | Media | **Corregido** (100d36c). El formulario usa la callable `submitBusinessLead` (esquema estricto, campo trampa, límite por IP seudonimizada con HMAC y por correo, App Check); las reglas niegan crear desde el cliente. Tests: `business_leads.int.ts`, matriz. |
| H6 | `users` × alta propia con `isVerified: true` y campos arbitrarios | Baja | **Pendiente: Parte B (B1).** |
| H7 | `rides` × chófer (también bloqueado) × actualizar | Baja | **Corregido** (e926aec). Sin usos vivos: se eliminó el código (modelo, repositorio, bloc, trigger). Lectura solo admin, escritura denegada; los documentos existentes no se tocan. |
| H8 | `vehicles` × usuario bloqueado × crear | Informativa | **Corregido** (a37d7b2). Crear un vehículo exige `isActive`. Cambiar color o foto del propio sigue permitido (⚠ en MATRIZ_ACCESO_PERMITIDOS.md). |
| H9 | `config/*` × admin × borrar | Informativa | **Corregido** (a37d7b2). Ningún cliente borra `config/*`; se actualiza. |
| H10 | `driverProfiles` × usuario bloqueado × crear/actualizar, y `assignNearestDriver` | Media | **Corregido** (A8.1). El dueño escribe su perfil solo con la cuenta activa (dejar de estar disponible siempre se permite); `assignNearestDriver` descarta a los chóferes con `users.isActive == false`, también dentro de la transacción. Tests: `blockedDriver.rules.ts`, `assignment.int.ts`, `assignment.test.ts`. |

Revisión A8 (rama cierre/identidad):

| # | Qué | Estado |
|---|---|---|
| A8.2 | `users`, `users/{uid}/notifications`, `vehicles` × admin × crear | **Cerrado.** Ninguna pantalla ni script lo usaba (los scripts usan el Admin SDK). |
| A8.3 | `submitBusinessLead`: IP de `x-forwarded-for` | **Corregido.** Usaba el primer elemento (lo puede inventar el cliente); ahora el último, más un tope global de 100/h. Que el último sea siempre el cliente: NO VERIFICADO. |
| A8.5 | `driverProfiles` × dueño × campos nuevos | **Cerrado.** Lista blanca de campos del dueño (tabla abajo). |
| A8.6 | `bookings` × dueño × cancelar/valorar | Campo por campo ya cerrado; se acotan `updatedAt` (hora cercana a la del servidor) y `riderComment` (texto ≤ 1000). |
| A8.7 | `bookings/{id}/events` × pasajero y chófer × leer | **Corregido.** El motivo del admin y `farFromPickup`/`arrivalCheck` pasan a `eventDetails` (solo admin); migración para los eventos ya escritos. |
| A8.8 | `pricingRules` × público × leer | **Cerrado (C3).** Sin campos internos; lista blanca de campos. `updatedBy` (uid del admin, público) retirado en C3: las reglas lo rechazan, el panel ya no lo escribe ni lo muestra (quién cambió la tarifa está en admin_logs) y `npm run migrate:pricing-updated-by` lo borra de los documentos existentes. Tests: `pricingRules.rules.ts`, `pricing_updated_by.int.ts`. |
| A8.9 | `config/global` × público × leer | **Corregido.** Las claves de operación pasan a `config/ops` (solo admin lee) y la seguridad irá en `config/security` (nadie). |

Parte A de la auditoría (rama cierre/auditoria): el admin solo lee. Cada
escritura suya pasa a una callable con rol admin, segundo factor (con
`mfaEnforced`), esquema estricto, motivo y auditoría en la misma
transacción. Se cierran 17 celdas (de 147 permitidas a 130; de 13 ⚠ a 4).
Con las reglas anteriores, los tests nuevos dan `38 failed, 1397 passed,
1435 total`.

| Celda cerrada (admin) | ⚠ antes | La sustituye |
|---|---|---|
| `users/{uid}` × actualizar | sí | `setUserRole`, `setUserBlocked` (B2, B3) |
| `users/{uid}/notifications` × actualizar, borrar | no | — (el panel no los usaba) |
| `driverProfiles/{uid}` × actualizar | sí | `adminVerifyDriver`, `adminUpdateDriverSensitive` |
| `bookings/{id}` × actualizar | sí | `adminUpdateBooking` |
| `payments/{id}` × crear, actualizar | sí (las dos) | `adminRecordPayment` |
| `vehicles/{id}` × actualizar | sí | `adminSetVehicleActive`, `adminUpdateDriverSensitive` |
| `pricingRules/{id}` × crear, actualizar, borrar | no | `adminUpdatePricingRule` (borrar = desactivar) |
| `config/global` × crear, actualizar | actualizar | `adminUpdateConfig` (lista blanca) |
| `config/finance` × crear, actualizar | actualizar | `adminUpdateConfig` |
| `businessLeads/{id}` × actualizar | no | `adminSetLeadHandled` |
| `admin_logs/{id}` × crear | sí | el servidor, en la transacción de cada cambio |

Correcciones tras la revisión de la Parte B (rama cierre/identidad):

| # | Qué | Estado |
|---|---|---|
| C2 | `driverDevices` y `adminAlerts` | Sin cambio de acceso (solo el admin lee, nadie escribe desde el cliente). El primer dispositivo de un chófer ya verificado también deja una alerta baja. Test: `driver_devices.int.ts`. |
| C3 | `pricingRules` × admin × crear/actualizar | Las reglas rechazan `updatedBy`; el uid de quien cambió la tarifa queda solo en `admin_logs`. Test: `pricingRules.rules.ts`. |
| C4 | `admin_logs` | Sin cambio de acceso. `reset_mfa`, `promote_admin` y las migraciones escriben con el Admin SDK y `source: 'script'`. |

Pagos (rama cierre/pagos, Parte A). Celdas nuevas, 120 (3 filas × 8 roles
× 5 operaciones), de las que solo 4 permiten algo:

| Fila | Permitido | Lo escribe |
|---|---|---|
| `bookings/{id}/payment` | pasajero dueño y admin × leer, listar | solo el servidor: `createBooking`, `startPayment`, `markPaymentSent`, `adminConfirmPayment`, `adminRejectPayment`, webhook, vencimiento, cancelaciones, `adminRecordRefund`, diferencia final, `adminCollectBalance` |
| `paymentRefs/{ref}` | nadie | `createBooking` (unicidad de la referencia) |
| `paymentOperations/{key}` | nadie | `adminConfirmPayment` (un número de operación, una vez) |

El chófer (asignado o no) no lee ninguna: el estado del pago va fuera de
la reserva porque el chófer lee la reserva entera. `payments/{id}` no
cambia de acceso (pasajero dueño y admin leen; nadie escribe); ahora
también guarda los asientos charge, refund y fee_retained.

Además (fuera de la tabla), la auto-aceptación del chófer en
`bookings/{id}` exige el pago confirmado (`get` del estado de pago); sin
estado de pago (reservas anteriores) se deniega. Test:
`bookings.rules.ts` («sin pago confirmado nadie la acepta desde el
cliente»). Sin las reglas nuevas, los tests de la matriz dan `6 failed,
1279 passed, 1285 total` (4 celdas y las 2 comprobaciones del documento).

La revisión de todas las celdas permitidas, con ⚠ en las que parecen más
amplias de lo necesario, está en
[MATRIZ_ACCESO_PERMITIDOS.md](MATRIZ_ACCESO_PERMITIDOS.md).

Sin hallazgos de la primera revisión: `payments` (solo el pasajero dueño
lee; escribe el servidor), `pricingRules` (lectura pública a propósito),
`config/finance`, `openRequests`, `incidents` y sus subcolecciones,
`private`, `eventLocations`, `adminOnly`, `incidentRateLimits`,
`rateLimits`, `adminAlerts`, `admin_logs`.

## Campos de `driverProfiles/{uid}` (A8.5)

Quién escribe cada campo [seguro: modelo `DriverProfile`, alta del chófer,
repositorios de la app, panel y `functions/src/index.ts`]. «Dueño» exige
cuenta activa salvo apagar la disponibilidad. Ningún otro campo lo escribe
el dueño (lista blanca `driverOwnerFields`): un campo nuevo de documentos,
fotos de identidad o datos de pago queda bloqueado para él desde el primer
día. Hoy no existe ninguno de esos tres tipos de campo.

| Campo | Antes de verificar | Después de verificar |
|---|---|---|
| `userId` | dueño (solo al crear, igual a su uid), admin | admin |
| `licenseNumber`, `licenseExpiry`, `vehicleId` | dueño, admin | admin (a petición del chófer, con `admin_logs`) |
| `isAvailable` | dueño, servidor (asignar, aceptar, liberar), chófer al aceptar (transacción en la app) | igual |
| `online` | dueño, servidor (lo lee al liberar) | igual |
| `currentLocation` | dueño | dueño |
| `documentsVerified` | admin | admin |
| `rating`, `ratingCount` | servidor (valoración del viaje) | servidor |
| `totalRides` | servidor (al completar) | servidor |
| cualquier otro | admin, servidor | admin, servidor |

## Casos fuera de la tabla

- Alta propia: un usuario nuevo crea su perfil como pasajero activo; como
  chófer, no.
- H2: el dueño (y el bloqueado) no cambian `isVerified`; el admin sí.
