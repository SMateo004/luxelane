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
| `users/{uid}` | sí | · · · · · | L · · A · | · · · · · | · · · · · | · · · · · | · · · · · | L · · A · | L Li · A · |
| `users/{uid}/notifications` | nueva | · · · · · | L Li · A B | · · · · · | · · · · · | · · · · · | · · · · · | L Li · A B | L Li · A B |
| `driverProfiles/{uid}` | sí | · · · · · | · · · · · | · · · · · | L · C A · | · · C · · | · · C · · | L · · A · | L Li · A · |
| `bookings/{id}` | sí | · · · · · | L Li · A · | · · · · · | L · · · · | · · · · · | · · · · · | · · · · · | L Li · A · |
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
| `payments/{id}` | nueva | · · · · · | L Li · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li C A · |
| `vehicles/{id}` | sí | · · · · · | · · · · · | · · · · · | L Li C A · | · · C · · | · · C · · | L Li · A · | L Li · A · |
| `pricingRules/{id}` | nueva | L Li · · · | L Li · · · | L Li · · · | L Li · · · | L Li · · · | L Li · · · | L Li · · · | L Li C A B |
| `config/global` | nueva | L · · · · | L · · · · | L · · · · | L · · · · | L · · · · | L · · · · | L · · · · | L · C A · |
| `config/finance` | nueva | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L · C A · |
| `config/ops` | nueva | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L · · · · |
| `config/security` | nueva | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · |
| `businessLeads/{id}` | nueva | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li · A · |
| `adminAlerts/{id}` | sí | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li · · · |
| `admin_logs/{id}` | nueva | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | · · · · · | L Li C · · |

- `users/{uid}`: Objetivo users/ana (bloqueado: users/bloq, el suyo). Crear = perfil de otro (users/nuevo); el alta propia está en «Casos fuera de la tabla». Actualizar = displayName.
- `users/{uid}/notifications`: Objetivo users/ana/notifications (bloqueado: las suyas). Las crea el servidor.
- `driverProfiles/{uid}`: Objetivo driverProfiles/asig (bloqueado: el suyo). Crear = el alta propia del chófer (los pasajeros intentan la suya; anónimo y admin, driverProfiles/nuevo).
- `bookings/{id}`: Objetivo bookings/activa (de ana, asignada a asig, en camino); bloqueado: activaBloq, asignada a él. Listar = reservas de ana (bloqueado: las suyas). Actualizar = cancelar.
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
- `payments/{id}`: Pago de ana (reserva fin). Cobros y reembolsos los hace el servidor; el admin registra cobros manuales.
- `vehicles/{id}`: Vehículo de asig (bloqueado: el suyo). Crear = registrar el propio, inactivo; un bloqueado no (H8).
- `pricingRules/{id}`: Tarifas públicas (la web las muestra sin sesión); solo el admin las edita.
- `config/global`: Estado operativo público. Listar la colección incluye config/security: nadie (A8.9). Nadie la borra (H9).
- `config/finance`: Comisión y parámetros internos: solo el admin. Borrarla se deniega también al admin (la regla valida el documento resultante).
- `config/ops`: Tiempos del SOS, retención y radio de llegada: el admin la lee; se edita en la consola (A8.9).
- `config/security`: Segundo factor y sesión máxima de admin: ningún cliente, ni el admin; solo la consola y el servidor (A8.9).
- `businessLeads/{id}`: Formulario de empresas: se envía con la callable submitBusinessLead (H5); ningún cliente escribe directo. El admin lo lee y lo marca atendido.
- `adminAlerts/{id}`: Avisos del servidor: el admin los marca con resolveAlert, no escribiendo.
- `admin_logs/{id}`: Auditoría inmutable: el admin anexa a su nombre.
<!-- matriz:fin -->


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
| A8.8 | `pricingRules` × público × leer | Sin campos internos; lista blanca de campos. Queda `updatedBy` (uid del admin, público): **pendiente de decisión** porque el panel lo muestra. |
| A8.9 | `config/global` × público × leer | **Corregido.** Las claves de operación pasan a `config/ops` (solo admin lee) y la seguridad irá en `config/security` (nadie). |

La revisión de todas las celdas permitidas, con ⚠ en las que parecen más
amplias de lo necesario, está en
[MATRIZ_ACCESO_PERMITIDOS.md](MATRIZ_ACCESO_PERMITIDOS.md).

Sin hallazgos de la primera revisión: `payments` (solo el pasajero dueño
lee; escribe el admin), `pricingRules` (lectura pública a propósito),
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
