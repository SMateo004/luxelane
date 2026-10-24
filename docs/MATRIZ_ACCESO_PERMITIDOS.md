# Celdas permitidas de la matriz de acceso

Para revisión humana: todas las celdas de [MATRIZ_ACCESO.md](MATRIZ_ACCESO.md)
cuyo resultado esperado es **permitido**, por colección y por rol, con el
motivo. Las celdas permitidas son las que pueden estar abiertas de más;
**⚠** marca las que parecen más amplias de lo necesario, con la propuesta.

Sale de `tools/rules-tests/test/matrix_allowed.ts`; un test exige una razón
para cada celda permitida y comprueba que este documento coincide (para
regenerarlo: `UPDATE_MATRIX=1` al correr `npm run test:rules`). Los roles y
el documento que usa cada fila están en MATRIZ_ACCESO.md.

<!-- permitidos:inicio -->
148 celdas permitidas, 17 con ⚠.

## `users/{uid}`

**pasajero dueño**

- leer: el usuario lee su propio perfil.
- actualizar: el usuario edita su nombre, teléfono, foto, preferencias y tokens de push (no rol, isActive, stripeCustomerId ni isVerified).

**usuario bloqueado**

- leer: una cuenta bloqueada sigue leyendo su perfil (la app lo usa para detectar el bloqueo y cerrar sesión).
- ⚠ actualizar: la regla del dueño no mira isActive. **un bloqueado aún puede cambiar su nombre, teléfono o tokens de push. Sin efecto en viajes, pero podría exigirse isActive (salvo quitar tokens al cerrar sesión).**

**admin**

- leer: el panel muestra los usuarios.
- listar: el panel lista los usuarios.
- ⚠ crear: la regla deja al admin crear cualquier perfil. **ninguna pantalla crea perfiles de otros; el alta la hace cada persona o promote_admin. Podría cerrarse.**
- ⚠ actualizar: el admin cambia rol e isActive desde el panel. **el panel aún escribe esto directo desde el cliente (D10); pasa a callables con auditoría en el servidor en la Parte B o después.**

## `users/{uid}/notifications`

**pasajero dueño**

- leer: el usuario lee sus avisos.
- listar: la bandeja lista sus avisos.
- actualizar: marca sus avisos como leídos (solo isRead).
- borrar: borra sus avisos.

**usuario bloqueado**

- leer: como cualquier dueño: lee sus avisos.
- listar: como cualquier dueño: lista sus avisos.
- actualizar: como cualquier dueño: marca leídos.
- borrar: como cualquier dueño: borra los suyos.

**admin**

- leer: soporte.
- listar: soporte.
- ⚠ crear: la regla deja al admin crear avisos. **el panel no crea avisos (los crea el servidor); el admin podría escribir avisos con apariencia de sistema en cualquier bandeja. Podría cerrarse.**
- actualizar: soporte.
- borrar: soporte.

## `driverProfiles/{uid}`

**chófer verif. asignado**

- leer: el chófer lee su perfil.
- crear: alta del chófer: crea su propio perfil sin verificación ni valoración.
- actualizar: cambia disponibilidad y ubicación; licencia y vehículo, solo antes de verificar (H4).

**chófer verif. no asignado**

- crear: alta del chófer: crea su propio perfil.

**chófer no verificado**

- crear: alta del chófer: crea su propio perfil.

**usuario bloqueado**

- leer: el chófer lee su perfil.
- crear: la regla de alta no mira isActive (solo alcanzable si nunca tuvo perfil; no queda verificado).
- ⚠ actualizar: la regla del dueño no mira isActive. **un chófer bloqueado puede ponerse isAvailable: true, y assignNearestDriver no comprueba users.isActive [seguro, leído en index.ts]: podría recibir una reserva que ya no puede leer (A1). Propuesta: exigir isActive aquí y filtrar bloqueados en assignNearestDriver.**

**admin**

- leer: el panel muestra los chóferes.
- listar: el panel lista los chóferes.
- ⚠ actualizar: verificar documentos y cambiar licencia a petición del chófer (con registro en admin_logs). **el panel aún escribe esto directo desde el cliente (D10); pasa a callables con auditoría en el servidor en la Parte B o después.**

## `bookings/{id}`

**pasajero dueño**

- leer: el pasajero dueño lee su reserva.
- listar: el pasajero lista sus reservas.
- actualizar: cancela su reserva antes de que empiece el viaje (o la valora al terminar).

**chófer verif. asignado**

- leer: el chófer asignado y activo lee la reserva que atiende.

**admin**

- leer: operación.
- listar: operación.
- ⚠ actualizar: cancelar, asignar, ajustar precio desde el panel (no verificar ni completar fuera de in_progress). **el panel aún escribe esto directo desde el cliente (D10); pasa a callables con auditoría en el servidor en la Parte B o después.**

## `bookings/{id}/tracking`

**pasajero dueño**

- leer: el pasajero ve dónde está su chófer mientras va, espera o lo lleva.
- listar: igual que leer.

**chófer verif. asignado**

- leer: el chófer asignado ve su propia ubicación publicada.
- listar: igual que leer.
- crear: publica su ubicación (solo lat, lng y hora del servidor) mientras el viaje está vivo.
- actualizar: actualiza su ubicación en las mismas condiciones.

**admin**

- leer: seguimiento desde el panel.
- listar: seguimiento desde el panel.

## `bookings/{id}/driverContact`

**pasajero dueño**

- leer: el pasajero llama a su chófer mientras el viaje está vivo.
- listar: igual que leer.

**chófer verif. asignado**

- leer: el chófer ve su propio teléfono.
- listar: igual que leer.

**admin**

- leer: soporte.
- listar: soporte.

## `bookings/{id}/private`

Ninguna celda permitida.

## `bookings/{id}/events`

**pasajero dueño**

- leer: el pasajero ve el historial de su viaje.
- listar: igual que leer.

**chófer verif. asignado**

- leer: el chófer asignado ve el historial del viaje.
- listar: igual que leer.

**admin**

- leer: auditoría.
- listar: auditoría.

## `bookings/{id}/eventLocations`

**admin**

- leer: ubicación del chófer en cada paso, para reclamos.
- listar: igual que leer.

## `bookings/{id}/adminOnly`

**admin**

- leer: estado de incidentes de la reserva.
- listar: igual que leer.

## `incidents/{id}`

**pasajero dueño**

- leer: quien pidió ayuda ve el estado de su aviso.
- listar: igual que leer.

**usuario bloqueado**

- leer: un bloqueado también ve el aviso que disparó.
- listar: igual que leer.

**admin**

- leer: central atiende el aviso.
- listar: franja de incidentes del panel.

## `incidents/{id}/locations`

**pasajero dueño**

- leer: quien pidió ayuda ve las ubicaciones que compartió.
- listar: igual que leer.
- crear: publica su ubicación mientras el aviso está abierto (una por tramo de 10 s).

**usuario bloqueado**

- leer: igual que el pasajero.
- listar: igual que el pasajero.
- crear: pedir ayuda no depende de la cuenta: un bloqueado en un viaje también puede.

**admin**

- leer: central sigue a quien pidió ayuda.
- listar: igual que leer.

## `incidents/{id}/events`

**admin**

- leer: registro del incidente.
- listar: igual que leer.

## `incidentRateLimits/{uid}`

Ninguna celda permitida.

## `rateLimits/{id}`

Ninguna celda permitida.

## `openRequests/{id}`

**chófer verif. asignado**

- leer: un chófer verificado y activo ve solicitudes sin datos personales.
- listar: igual que leer.

**chófer verif. no asignado**

- leer: un chófer verificado y activo ve solicitudes sin datos personales.
- listar: igual que leer.

**admin**

- leer: operación.
- listar: operación.

## `rides/{id}`

**admin**

- leer: consultar los documentos heredados que queden.
- listar: igual que leer.

## `payments/{id}`

**pasajero dueño**

- leer: el pasajero ve sus pagos.
- listar: historial de pagos.

**admin**

- leer: finanzas.
- listar: finanzas.
- ⚠ crear: registrar un cobro manual (efectivo, QR). **el panel aún escribe esto directo desde el cliente (D10); pasa a callables con auditoría en el servidor en la Parte B o después.**
- ⚠ actualizar: corregir un cobro manual. **el panel aún escribe esto directo desde el cliente (D10); pasa a callables con auditoría en el servidor en la Parte B o después.**

## `vehicles/{id}`

**chófer verif. asignado**

- leer: el chófer ve su vehículo.
- listar: su vehículo por consulta.
- ⚠ crear: registra un vehículo propio, inactivo. **un chófer ya verificado puede registrar más vehículos inactivos (solo el admin los activa). Sin efecto hasta que se activen.**
- actualizar: cambia color y foto.

**chófer verif. no asignado**

- crear: registra su vehículo, inactivo.

**chófer no verificado**

- crear: alta: registra su vehículo, inactivo.

**usuario bloqueado**

- leer: ve su vehículo.
- listar: su vehículo por consulta.
- ⚠ actualizar: la regla de color y foto no mira isActive. **un bloqueado aún cambia color o foto. Sin efecto en viajes.**

**admin**

- leer: flota.
- listar: flota.
- ⚠ crear: la regla deja al admin dar de alta vehículos. **ninguna pantalla del panel crea vehículos (los registra el chófer); podría cerrarse.**
- ⚠ actualizar: activar, desactivar y corregir datos a petición del chófer. **el panel aún escribe esto directo desde el cliente (D10); pasa a callables con auditoría en el servidor en la Parte B o después.**

## `pricingRules/{id}`

**anónimo**

- leer: tarifas públicas: la web las muestra sin sesión.
- listar: tarifas públicas: la web las lista sin sesión.

**pasajero dueño**

- leer: tarifas públicas: la web las muestra sin sesión.
- listar: tarifas públicas: la web las lista sin sesión.

**otro pasajero**

- leer: tarifas públicas: la web las muestra sin sesión.
- listar: tarifas públicas: la web las lista sin sesión.

**chófer verif. asignado**

- leer: tarifas públicas: la web las muestra sin sesión.
- listar: tarifas públicas: la web las lista sin sesión.

**chófer verif. no asignado**

- leer: tarifas públicas: la web las muestra sin sesión.
- listar: tarifas públicas: la web las lista sin sesión.

**chófer no verificado**

- leer: tarifas públicas: la web las muestra sin sesión.
- listar: tarifas públicas: la web las lista sin sesión.

**usuario bloqueado**

- leer: tarifas públicas: la web las muestra sin sesión.
- listar: tarifas públicas: la web las lista sin sesión.

**admin**

- leer: editar tarifas.
- listar: editar tarifas.
- crear: nueva tarifa con importes válidos.
- actualizar: cambiar una tarifa con importes válidos.
- borrar: quitar una tarifa (la clase deja de reservarse).

## `config/global`

**anónimo**

- ⚠ leer: estado operativo que la app lee antes de iniciar sesión (mantenimiento, versión mínima, teléfonos de central). **todo lo que se guarde en config/global es público, también sin sesión: no guardar ahí nada interno (hoy también lleva los tiempos de escalada del SOS y la retención).**

**pasajero dueño**

- leer: estado operativo que la app lee antes de iniciar sesión (mantenimiento, versión mínima, teléfonos de central).

**otro pasajero**

- leer: estado operativo que la app lee antes de iniciar sesión (mantenimiento, versión mínima, teléfonos de central).

**chófer verif. asignado**

- leer: estado operativo que la app lee antes de iniciar sesión (mantenimiento, versión mínima, teléfonos de central).

**chófer verif. no asignado**

- leer: estado operativo que la app lee antes de iniciar sesión (mantenimiento, versión mínima, teléfonos de central).

**chófer no verificado**

- leer: estado operativo que la app lee antes de iniciar sesión (mantenimiento, versión mínima, teléfonos de central).

**usuario bloqueado**

- leer: estado operativo que la app lee antes de iniciar sesión (mantenimiento, versión mínima, teléfonos de central).

**admin**

- leer: ajustes del panel.
- listar: ajustes del panel.
- crear: crear un documento de configuración.
- ⚠ actualizar: cambiar ajustes. **el panel aún escribe esto directo desde el cliente (D10); pasa a callables con auditoría en el servidor en la Parte B o después.**

## `config/finance`

**admin**

- leer: comisión de la plataforma.
- listar: ajustes del panel.
- crear: crear un documento de configuración (comisión entre 0 y 100).
- ⚠ actualizar: cambiar la comisión (entre 0 y 100). **el panel aún escribe esto directo desde el cliente (D10); pasa a callables con auditoría en el servidor en la Parte B o después.**

## `businessLeads/{id}`

**admin**

- leer: atender solicitudes de empresas.
- listar: bandeja de empresas.
- actualizar: marcar como atendida (solo handled).

## `adminAlerts/{id}`

**admin**

- leer: avisos del servidor.
- listar: avisos del servidor.

## `admin_logs/{id}`

**admin**

- leer: auditoría.
- listar: auditoría.
- ⚠ crear: el panel anexa su propia auditoría (adminId = quien escribe). **una auditoría escrita por el cliente se puede omitir o falsear en el detalle; la definitiva debe escribirla el servidor (D10).**
<!-- permitidos:fin -->
