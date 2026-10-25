// Matriz de acceso de Firestore: colección × rol × operación. Es la única
// fuente: de aquí salen los tests (matrix.rules.ts, uno por celda) y la
// tabla de docs/MATRIZ_ACCESO.md (el test comprueba que coinciden).
import {
  collection, deleteDoc, doc, DocumentData, Firestore, getDoc, getDocs, query,
  Query, serverTimestamp, setDoc, Timestamp, updateDoc, where,
} from 'firebase/firestore';

export const ROLES = ['anon', 'ana', 'beto', 'asig', 'libre', 'nover', 'bloq', 'admin'] as const;
export type Role = (typeof ROLES)[number];

export const ROLE_LABELS: Record<Role, string> = {
  anon: 'anónimo',
  ana: 'pasajero dueño',
  beto: 'otro pasajero',
  asig: 'chófer verif. asignado',
  libre: 'chófer verif. no asignado',
  nover: 'chófer no verificado',
  bloq: 'usuario bloqueado',
  admin: 'admin',
};

export const OPS = ['leer', 'listar', 'crear', 'actualizar', 'borrar'] as const;
export type Op = (typeof OPS)[number];

/** Uid de cada rol (el anónimo no tiene). */
export const uidOf = (r: Role): string | null => (r === 'anon' ? null : r);

export interface Spec {
  /** Nombre en la tabla. */
  name: string;
  /** Ya la cubría algún test de reglas antes de esta matriz. */
  covered: boolean;
  /** Documento objetivo de leer, actualizar y borrar. */
  target: (r: Role) => string;
  /** Consulta de «listar». */
  list: (db: Firestore, r: Role) => Query<DocumentData>;
  /** Documento nuevo y sus datos (los que mandaría quien sí puede crearlo). */
  create: (r: Role) => { path: string; data: DocumentData };
  /** Se ejecuta sin reglas antes de «crear» (p. ej., el alta pendiente). */
  prepareCreate?: (r: Role) => string | null;
  /** Cambio de «actualizar» (el que haría quien sí puede). */
  update: (r: Role) => DocumentData;
  /** S/N por operación, en el orden de OPS, para cada rol. */
  expect: Record<Role, string>;
  /** Qué documento usa cada rol y lo que no se ve en la tabla. */
  note: string;
}

const own = (r: Role, fallback: string) => (r === 'bloq' ? 'bloq' : fallback);
const slot = () => String(Math.floor(Date.now() / 10000));

// Codificación: L = leer, Li = listar, C = crear, A = actualizar, B = borrar.
// Cada cadena tiene 5 letras S (permitido) o N (denegado) en ese orden.
const none = 'NNNNN';
const allRoles = (v: string) =>
  Object.fromEntries(ROLES.map((r) => [r, v])) as Record<Role, string>;

export const SPECS: Spec[] = [
  {
    name: 'users/{uid}',
    covered: true,
    target: (r) => `users/${own(r, 'ana')}`,
    list: (db) => query(collection(db, 'users')),
    create: () => ({ path: 'users/nuevo', data: { id: 'nuevo', role: 'rider', isActive: true } }),
    update: () => ({ displayName: 'Nombre nuevo' }),
    expect: { ...allRoles(none), ana: 'SNNSN', bloq: 'SNNSN', admin: 'SSNNN' },
    note: 'Objetivo users/ana (bloqueado: users/bloq, el suyo). Crear = perfil de otro (users/nuevo); ' +
      'el alta propia está en «Casos fuera de la tabla». Actualizar = displayName.',
  },
  {
    name: 'users/{uid}/notifications',
    covered: false,
    target: (r) => `users/${own(r, 'ana')}/notifications/n1`,
    list: (db, r) => query(collection(db, 'users', own(r, 'ana'), 'notifications')),
    create: (r) => ({
      path: `users/${own(r, 'ana')}/notifications/nueva`,
      data: { userId: own(r, 'ana'), title: 'Aviso', body: 'Texto', isRead: false },
    }),
    update: () => ({ isRead: true }),
    expect: { ...allRoles(none), ana: 'SSNSS', bloq: 'SSNSS', admin: 'SSNNN' },
    note: 'Objetivo users/ana/notifications (bloqueado: las suyas). Las crea el servidor.',
  },
  {
    name: 'driverProfiles/{uid}',
    covered: true,
    target: (r) => `driverProfiles/${own(r, 'asig')}`,
    list: (db) => query(collection(db, 'driverProfiles')),
    // Alta del chófer: crea el suyo (se borra antes, como antes del alta).
    prepareCreate: (r) => (['asig', 'libre', 'nover', 'bloq'].includes(r) ? `driverProfiles/${r}` : null),
    create: (r) => ({
      path: `driverProfiles/${uidOf(r) && r !== 'admin' ? r : 'nuevo'}`,
      data: { userId: uidOf(r) ?? 'nuevo', licenseNumber: 'LIC-NUEVA', isAvailable: false },
    }),
    update: () => ({ isAvailable: false }),
    expect: {
      ...allRoles(none), asig: 'SNSSN', libre: 'NNSNN', nover: 'NNSNN', bloq: 'SNNSN', admin: 'SSNNN',
    },
    note: 'Objetivo driverProfiles/asig (bloqueado: el suyo). Crear = el alta propia del chófer ' +
      '(los pasajeros intentan la suya; anónimo y admin, driverProfiles/nuevo).',
  },
  {
    name: 'bookings/{id}',
    covered: true,
    target: (r) => `bookings/${r === 'bloq' ? 'activaBloq' : 'activa'}`,
    list: (db, r) => (r === 'bloq'
      ? query(collection(db, 'bookings'), where('driverId', '==', 'bloq'))
      : query(collection(db, 'bookings'), where('riderId', '==', 'ana'))),
    create: () => ({ path: 'bookings/nueva', data: { riderId: 'ana', status: 'pending', estimatedPrice: 1 } }),
    update: () => ({ status: 'cancelled', updatedAt: Timestamp.now() }),
    expect: { ...allRoles(none), ana: 'SSNSN', asig: 'SNNNN', admin: 'SSNNN' },
    note: 'Objetivo bookings/activa (de ana, asignada a asig, en camino); bloqueado: activaBloq, ' +
      'asignada a él. Listar = reservas de ana (bloqueado: las suyas). Actualizar = cancelar.',
  },
  {
    name: 'bookings/{id}/tracking',
    covered: true,
    target: (r) => `bookings/${r === 'bloq' ? 'activaBloq' : 'activa'}/tracking/driver`,
    list: (db, r) => query(collection(db, 'bookings', r === 'bloq' ? 'activaBloq' : 'activa', 'tracking')),
    prepareCreate: (r) => `bookings/${r === 'bloq' ? 'activaBloq' : 'activa'}/tracking/driver`,
    create: (r) => ({
      path: `bookings/${r === 'bloq' ? 'activaBloq' : 'activa'}/tracking/driver`,
      data: { lat: -17.7, lng: -63.1, updatedAt: serverTimestamp() },
    }),
    update: () => ({ lat: -17.71, lng: -63.11, updatedAt: serverTimestamp() }),
    expect: { ...allRoles(none), ana: 'SSNNN', asig: 'SSSSN', admin: 'SSNNN' },
    note: 'Ubicación del chófer de activa (bloqueado: de activaBloq).',
  },
  {
    name: 'bookings/{id}/driverContact',
    covered: true,
    target: (r) => `bookings/${r === 'bloq' ? 'activaBloq' : 'activa'}/driverContact/phone`,
    list: (db, r) => query(collection(db, 'bookings', r === 'bloq' ? 'activaBloq' : 'activa', 'driverContact')),
    create: (r) => ({
      path: `bookings/${r === 'bloq' ? 'activaBloq' : 'activa'}/driverContact/otro`,
      data: { phone: '+59170000999' },
    }),
    update: () => ({ phone: '+59170000999' }),
    expect: { ...allRoles(none), ana: 'SSNNN', asig: 'SSNNN', admin: 'SSNNN' },
    note: 'Teléfono del chófer de activa (bloqueado: de activaBloq). Lo escribe el servidor.',
  },
  {
    name: 'bookings/{id}/private',
    covered: true,
    target: () => 'bookings/activa/private/pickup',
    list: (db) => query(collection(db, 'bookings', 'activa', 'private')),
    create: () => ({ path: 'bookings/activa/private/otro', data: { salt: 'x' } }),
    update: () => ({ attempts: 0 }),
    expect: allRoles(none),
    note: 'Sal del código de recogida: nadie desde el cliente, ni el admin.',
  },
  {
    name: 'bookings/{id}/events',
    covered: true,
    target: (r) => `bookings/${r === 'bloq' ? 'activaBloq' : 'activa'}/events/e1`,
    list: (db, r) => query(collection(db, 'bookings', r === 'bloq' ? 'activaBloq' : 'activa', 'events')),
    create: (r) => ({
      path: `bookings/${r === 'bloq' ? 'activaBloq' : 'activa'}/events/nuevo`,
      data: { from: 'confirmed', to: 'driver_arriving' },
    }),
    update: () => ({ to: 'completed' }),
    expect: { ...allRoles(none), ana: 'SSNNN', asig: 'SSNNN', admin: 'SSNNN' },
    note: 'Registro de transiciones de activa (bloqueado: de activaBloq). Solo anexa el servidor.',
  },
  {
    name: 'bookings/{id}/eventLocations',
    covered: true,
    target: () => 'bookings/activa/eventLocations/e1',
    list: (db) => query(collection(db, 'bookings', 'activa', 'eventLocations')),
    create: () => ({ path: 'bookings/activa/eventLocations/nuevo', data: { lat: 0, lng: 0 } }),
    update: () => ({ lat: 1 }),
    expect: { ...allRoles(none), admin: 'SSNNN' },
    note: 'Ubicación del chófer en cada evento: solo la lee el admin.',
  },
  {
    name: 'bookings/{id}/eventDetails',
    covered: false,
    target: () => 'bookings/activa/eventDetails/e1',
    list: (db) => query(collection(db, 'bookings', 'activa', 'eventDetails')),
    create: () => ({ path: 'bookings/activa/eventDetails/nuevo', data: { reason: 'x' } }),
    update: () => ({ reason: 'y' }),
    expect: { ...allRoles(none), admin: 'SSNNN' },
    note: 'Motivo del admin al forzar la verificación y control de llegada (farFromPickup): solo el admin (A8.7).',
  },
  {
    name: 'bookings/{id}/adminOnly',
    covered: true,
    target: () => 'bookings/activa/adminOnly/incidents',
    list: (db) => query(collection(db, 'bookings', 'activa', 'adminOnly')),
    create: () => ({ path: 'bookings/activa/adminOnly/otro', data: { incidentOpen: false } }),
    update: () => ({ incidentOpen: false }),
    expect: { ...allRoles(none), admin: 'SSNNN' },
    note: 'Estado de incidentes de la reserva: solo lo lee el admin.',
  },
  {
    name: 'incidents/{id}',
    covered: true,
    target: (r) => `incidents/${r === 'bloq' ? 'incBloq' : 'inc1'}`,
    list: (db, r) => query(collection(db, 'incidents'), where('reporterId', '==', own(r, 'ana'))),
    create: () => ({ path: 'incidents/nuevo', data: { reporterId: 'ana', status: 'open', bookingId: 'activa' } }),
    update: () => ({ status: 'closed' }),
    expect: { ...allRoles(none), ana: 'SSNNN', bloq: 'SSNNN', admin: 'SSNNN' },
    note: 'Aviso SOS de ana en activa (bloqueado: el suyo en activaBloq). La contraparte (asig) no lo ve.',
  },
  {
    name: 'incidents/{id}/locations',
    covered: true,
    target: (r) => `incidents/${r === 'bloq' ? 'incBloq' : 'inc1'}/locations/1`,
    list: (db, r) => query(collection(db, 'incidents', r === 'bloq' ? 'incBloq' : 'inc1', 'locations')),
    create: (r) => ({
      path: `incidents/${r === 'bloq' ? 'incBloq' : 'inc1'}/locations/${slot()}`,
      data: { lat: -17.7, lng: -63.1, at: serverTimestamp() },
    }),
    update: () => ({ lat: -17.71 }),
    expect: { ...allRoles(none), ana: 'SSSNN', bloq: 'SSSNN', admin: 'SSNNN' },
    note: 'Ubicación de quien pidió ayuda (tramo de 10 s). Un bloqueado también puede pedir ayuda.',
  },
  {
    name: 'incidents/{id}/events',
    covered: true,
    target: () => 'incidents/inc1/events/e1',
    list: (db) => query(collection(db, 'incidents', 'inc1', 'events')),
    create: () => ({ path: 'incidents/inc1/events/nuevo', data: { type: 'raised' } }),
    update: () => ({ type: 'closed' }),
    expect: { ...allRoles(none), admin: 'SSNNN' },
    note: 'Registro del incidente: solo el admin lo lee.',
  },
  {
    name: 'incidentRateLimits/{uid}',
    covered: true,
    target: (r) => `incidentRateLimits/${own(r, 'ana')}`,
    list: (db) => query(collection(db, 'incidentRateLimits')),
    create: (r) => ({ path: `incidentRateLimits/nuevo-${r}`, data: { count: 0 } }),
    update: () => ({ count: 0 }),
    expect: allRoles(none),
    note: 'Contador del SOS: solo el servidor.',
  },
  {
    name: 'rateLimits/{id}',
    covered: true,
    target: () => 'rateLimits/createBooking__ana',
    list: (db) => query(collection(db, 'rateLimits')),
    create: (r) => ({ path: `rateLimits/createBooking__nuevo-${r}`, data: { count: 0 } }),
    update: () => ({ count: 0 }),
    expect: allRoles(none),
    note: 'Contadores de límites de las callables: solo el servidor.',
  },
  {
    name: 'openRequests/{id}',
    covered: true,
    target: () => 'openRequests/pend',
    list: (db) => query(collection(db, 'openRequests')),
    create: () => ({ path: 'openRequests/nueva', data: { vehicleClass: 'business' } }),
    update: () => ({ estimatedPrice: 1 }),
    expect: { ...allRoles(none), asig: 'SSNNN', libre: 'SSNNN', admin: 'SSNNN' },
    note: 'Solicitudes sin datos personales: chóferes verificados y activos, y el admin.',
  },
  {
    name: 'rides/{id}',
    covered: false,
    target: (r) => `rides/${r === 'bloq' ? 'rBloq' : 'r1'}`,
    list: (db, r) => (r === 'bloq'
      ? query(collection(db, 'rides'), where('driverId', '==', 'bloq'))
      : query(collection(db, 'rides'), where('riderId', '==', 'ana'))),
    create: () => ({ path: 'rides/nuevo', data: { riderId: 'ana', driverId: 'asig', bookingId: 'activa' } }),
    update: () => ({ distanceKm: 5 }),
    expect: { ...allRoles(none), admin: 'SSNNN' },
    note: 'Colección heredada sin uso (H7): solo el admin lee los documentos que queden; nadie escribe. ' +
      'r1: de ana con asig; bloqueado: rBloq.',
  },
  {
    name: 'payments/{id}',
    covered: false,
    target: () => 'payments/p1',
    list: (db) => query(collection(db, 'payments'), where('riderId', '==', 'ana')),
    create: () => ({ path: 'payments/nuevo', data: { riderId: 'ana', bookingId: 'fin', status: 'captured' } }),
    update: () => ({ status: 'refunded' }),
    expect: { ...allRoles(none), ana: 'SSNNN', admin: 'SSNNN' },
    note: 'Pago de ana (reserva fin). Cobros y reembolsos los hace el servidor; los manuales, adminRecordPayment (Parte A).',
  },
  {
    name: 'vehicles/{id}',
    covered: true,
    target: (r) => `vehicles/${r === 'bloq' ? 'v-bloq' : 'v-asig'}`,
    list: (db, r) => query(collection(db, 'vehicles'), where('driverId', '==', own(r, 'asig'))),
    create: (r) => ({
      path: `vehicles/nuevo-${r}`,
      data: { driverId: uidOf(r) ?? 'nadie', make: 'Kia', model: 'Rio', plate: 'NUEVA', isActive: false },
    }),
    update: () => ({ color: 'Negro' }),
    expect: {
      ...allRoles(none), asig: 'SSSSN', libre: 'NNSNN', nover: 'NNSNN', bloq: 'SSNSN', admin: 'SSNNN',
    },
    note: 'Vehículo de asig (bloqueado: el suyo). Crear = registrar el propio, inactivo; un bloqueado no (H8).',
  },
  {
    name: 'pricingRules/{id}',
    covered: false,
    target: () => 'pricingRules/business_oneWay',
    list: (db) => query(collection(db, 'pricingRules')),
    create: () => ({
      path: 'pricingRules/electric_oneWay',
      data: { basePriceUsd: 1, pricePerKmUsd: 1, pricePerHourUsd: 0, minimumPriceUsd: 1, isActive: true },
    }),
    update: () => ({ basePriceUsd: 2 }),
    expect: { ...allRoles('SSNNN'), admin: 'SSNNN' },
    note: 'Tarifas públicas (la web las muestra sin sesión). Las escribe adminUpdatePricingRule (Parte A), sin ' +
      'campos internos ni `updatedBy`: quién la cambió va solo en admin_logs (C3).',
  },
  {
    name: 'config/global',
    covered: false,
    target: () => 'config/global',
    list: (db) => query(collection(db, 'config')),
    create: () => ({ path: 'config/nuevo', data: { x: 1 } }),
    update: () => ({ isMaintenanceMode: false }),
    expect: { ...allRoles('SNNNN'), admin: 'SNNNN' },
    note: 'Estado operativo público. Listar la colección incluye config/security: nadie (A8.9). Los ajustes del ' +
      'panel van por adminUpdateConfig (Parte A). Nadie la borra (H9).',
  },
  {
    name: 'config/finance',
    covered: false,
    target: () => 'config/finance',
    list: (db) => query(collection(db, 'config')),
    create: () => ({ path: 'config/otro', data: { platformCommissionPct: 10 } }),
    update: () => ({ platformCommissionPct: 12 }),
    expect: { ...allRoles(none), admin: 'SNNNN' },
    note: 'Comisión y parámetros internos: el admin la lee; la comisión se cambia con adminUpdateConfig ' +
      '(entre 0 y 100, Parte A). Nadie la borra.',
  },
  {
    name: 'config/ops',
    covered: false,
    target: () => 'config/ops',
    list: (db) => query(collection(db, 'config')),
    create: () => ({ path: 'config/ops', data: { arrivalRadiusMeters: 1 } }),
    update: () => ({ arrivalRadiusMeters: 1 }),
    expect: { ...allRoles(none), admin: 'SNNNN' },
    note: 'Tiempos del SOS, retención, radio de llegada y límite de ajuste: el admin la lee; se edita con ' +
      'adminUpdateConfig o en la consola (A8.9, Parte A).',
  },
  {
    name: 'config/security',
    covered: false,
    target: () => 'config/security',
    list: (db) => query(collection(db, 'config')),
    create: () => ({ path: 'config/security', data: { mfaEnforced: false } }),
    update: () => ({ mfaEnforced: false }),
    expect: allRoles(none),
    note: 'Segundo factor y sesión máxima de admin: ningún cliente, ni el admin; solo la consola y el servidor (A8.9).',
  },
  {
    name: 'businessLeads/{id}',
    covered: false,
    target: () => 'businessLeads/l1',
    list: (db) => query(collection(db, 'businessLeads')),
    create: (r) => ({
      path: `businessLeads/nuevo-${r}`,
      data: {
        company: 'Empresa', contactName: 'Nombre', email: 'contacto@example.com', phone: '1',
        travellers: '2', message: 'Hola', handled: false, createdAt: serverTimestamp(),
      },
    }),
    update: () => ({ handled: true }),
    expect: { ...allRoles(none), admin: 'SSNNN' },
    note: 'Formulario de empresas: se envía con la callable submitBusinessLead (H5); ningún cliente ' +
      'escribe directo. El admin lo lee; lo marca atendido con adminSetLeadHandled (Parte A).',
  },
  {
    name: 'adminAlerts/{id}',
    covered: true,
    target: () => 'adminAlerts/a1',
    list: (db) => query(collection(db, 'adminAlerts')),
    create: () => ({ path: 'adminAlerts/nueva', data: { type: 'x', resolved: false } }),
    update: () => ({ resolved: true }),
    expect: { ...allRoles(none), admin: 'SSNNN' },
    note: 'Avisos del servidor: el admin los marca con resolveAlert, no escribiendo.',
  },
  {
    name: 'driverDevices/{uid}/devices/{id}',
    covered: true,
    target: () => 'driverDevices/asig/devices/d1',
    list: (db) => query(collection(db, 'driverDevices/asig/devices')),
    create: () => ({ path: 'driverDevices/asig/devices/nuevo', data: { platform: 'android' } }),
    update: () => ({ platform: 'ios' }),
    expect: { ...allRoles(none), admin: 'SSNNN' },
    note: 'Dispositivos del chófer (B7): los anota registerDriverDevice; solo el admin los ve, ' +
      'ni el propio chófer. Alerta baja por dispositivo nuevo, y por el primero si ya está verificado (C2).',
  },
  {
    name: 'admin_logs/{id}',
    covered: false,
    target: () => 'admin_logs/log1',
    list: (db) => query(collection(db, 'admin_logs')),
    create: (r) => ({ path: `admin_logs/nuevo-${r}`, data: { adminId: uidOf(r) ?? 'nadie', action: 'x' } }),
    update: () => ({ action: 'y' }),
    expect: { ...allRoles(none), admin: 'SSNNN' },
    note: 'Auditoría inmutable: la escribe solo el servidor, en la transacción de cada cambio (Parte A), y los ' +
      'scripts (promote_admin, reset_mfa, migraciones) con el Admin SDK. Ningún cliente, ni el admin.',
  },
];

/** Documentos que la matriz necesita además de seed(). */
export async function seedMatrix(db: Firestore): Promise<void> {
  const put = (path: string, data: DocumentData) => setDoc(doc(db, path), data);
  await put('users/ana/notifications/n1', { userId: 'ana', title: 'Aviso', isRead: false });
  await put('users/bloq/notifications/n1', { userId: 'bloq', title: 'Aviso', isRead: false });
  for (const b of ['activa', 'activaBloq']) {
    await put(`bookings/${b}/events/e1`, { from: 'confirmed', to: 'driver_arriving' });
  }
  await put('bookings/activaBloq/tracking/driver', { lat: -17.7, lng: -63.1, updatedAt: Timestamp.now() });
  await put('bookings/activaBloq/driverContact/phone', { phone: '+59170000556' });
  await put('bookings/activa/private/pickup', { salt: 'sal', attempts: 0 });
  await put('bookings/activa/eventLocations/e1', { lat: -17.7, lng: -63.1 });
  await put('bookings/activa/eventDetails/e1', { reason: 'Motivo del admin', farFromPickup: true });
  await put('bookings/activa/adminOnly/incidents', { incidentOpen: true });
  const inc = { status: 'open', cancelledByReporter: false, createdAt: Timestamp.now() };
  await put('incidents/inc1', { ...inc, reporterId: 'ana', bookingId: 'activa' });
  await put('incidents/incBloq', { ...inc, reporterId: 'bloq', bookingId: 'activaBloq' });
  for (const i of ['inc1', 'incBloq']) await put(`incidents/${i}/locations/1`, { lat: -17.7, lng: -63.1 });
  await put('incidents/inc1/events/e1', { type: 'raised' });
  await put('incidentRateLimits/ana', { count: 1 });
  await put('incidentRateLimits/bloq', { count: 1 });
  await put('rateLimits/createBooking__ana', { count: 1 });
  await put('rides/r1', { riderId: 'ana', driverId: 'asig', bookingId: 'activa' });
  await put('rides/rBloq', { riderId: 'beto', driverId: 'bloq', bookingId: 'activaBloq' });
  await put('payments/p1', { riderId: 'ana', bookingId: 'fin', status: 'captured' });
  for (const uid of ['asig', 'bloq']) {
    await put(`vehicles/v-${uid}`, { driverId: uid, make: 'Toyota', model: 'Camry', plate: `P-${uid}`, isActive: true });
  }
  await put('pricingRules/business_oneWay', {
    basePriceUsd: 50, pricePerKmUsd: 3, pricePerHourUsd: 0, minimumPriceUsd: 60, isActive: true,
  });
  await put('config/global', { isMaintenanceMode: false });
  await put('config/finance', { platformCommissionPct: 10 });
  await put('config/ops', { arrivalRadiusMeters: 300 });
  await put('config/security', { mfaEnforced: false });
  await put('businessLeads/l1', { company: 'Empresa', email: 'contacto@example.com', handled: false });
  await put('adminAlerts/a1', { type: 'x', resolved: false });
  await put('admin_logs/log1', { adminId: 'admin', action: 'x' });
  await put('driverDevices/asig/devices/d1', { platform: 'android' });
}

/** La operación de una celda contra el Firestore de ese rol. */
export function operation(spec: Spec, op: Op, db: Firestore, r: Role): () => Promise<unknown> {
  switch (op) {
    case 'leer': return () => getDoc(doc(db, spec.target(r)));
    case 'listar': return () => getDocs(spec.list(db, r));
    case 'crear': {
      const { path, data } = spec.create(r);
      return () => setDoc(doc(db, path), data);
    }
    case 'actualizar': return () => updateDoc(doc(db, spec.target(r)), spec.update(r));
    case 'borrar': return () => deleteDoc(doc(db, spec.target(r)));
  }
}

export const allowed = (spec: Spec, r: Role, op: Op) => spec.expect[r][OPS.indexOf(op)] === 'S';

/** Tabla en Markdown para docs/MATRIZ_ACCESO.md. */
export function renderMatrix(): string {
  const head = `| Colección | Cubierta antes | ${ROLES.map((r) => ROLE_LABELS[r]).join(' | ')} |`;
  const sep = `|---|---|${ROLES.map(() => '---').join('|')}|`;
  const cell = (s: string) => OPS.map((o, i) => (s[i] === 'S' ? o[0].toUpperCase() + (o === 'listar' ? 'i' : '') : '·'))
    .join(' ');
  const rows = SPECS.map((s) =>
    `| \`${s.name}\` | ${s.covered ? 'sí' : 'nueva'} | ${ROLES.map((r) => cell(s.expect[r])).join(' | ')} |`);
  const notes = SPECS.map((s) => `- \`${s.name}\`: ${s.note}`);
  return [head, sep, ...rows, '', ...notes].join('\n');
}
