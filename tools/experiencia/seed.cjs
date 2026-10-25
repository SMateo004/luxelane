/**
 * Siembra los emuladores de Auth y Firestore para revisar la app en local
 * (Parte A de experiencia). TODO ES FICTICIO: personas, reservas y tarifas
 * llevan la marca `_ficticio: true` y los nombres dicen «Prueba».
 *
 * Se niega a correr si el proyecto no es demo-luxelane o si no apunta a los
 * emuladores (FIRESTORE_EMULATOR_HOST y FIREBASE_AUTH_EMULATOR_HOST).
 */
'use strict';
const path = require('path');
const admin = require(path.join(__dirname, '../../functions/node_modules/firebase-admin'));

const PROJECT = 'demo-luxelane';
const project = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || PROJECT;

function guard() {
  if (project !== PROJECT) throw new Error(`Solo ${PROJECT}; recibido «${project}». No se siembra nada.`);
  for (const v of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
    if (!process.env[v]) throw new Error(`Falta ${v}: solo se siembran los emuladores.`);
  }
}

// Personas de prueba. Contraseña común, solo válida en el emulador.
const PASSWORD = 'prueba-123';
const PEOPLE = [
  { uid: 'pasajera', email: 'pasajera@prueba.test', name: 'Ana Prueba', role: 'rider' },
  { uid: 'chofer', email: 'chofer@prueba.test', name: 'Luis Prueba', role: 'driver', verified: true },
  { uid: 'chofer2', email: 'chofer2@prueba.test', name: 'Raúl Prueba', role: 'driver', verified: true },
  { uid: 'nuevo', email: 'nuevo@prueba.test', name: 'Nora Prueba', role: 'driver', verified: false },
  { uid: 'bloqueado', email: 'bloqueado@prueba.test', name: 'Beto Prueba', role: 'driver', verified: true, blocked: true },
  { uid: 'vacia', email: 'vacia@prueba.test', name: 'Vera Prueba', role: 'rider' },
  // Admin para recorrer el panel (config/security.mfaEnforced es false en el
  // emulador) y otro con un segundo factor inscrito para ver el reto.
  { uid: 'admin', email: 'admin@prueba.test', name: 'Jefa Prueba', role: 'admin' },
  { uid: 'admin2fa', email: 'admin2fa@prueba.test', name: 'Jefa MFA Prueba', role: 'admin', mfa: true },
];

// Santa Cruz de la Sierra (dentro del área de servicio).
const AIRPORT = { name: 'Aeropuerto Viru Viru', address: 'Aeropuerto Internacional Viru Viru (prueba)', lat: -17.6448, lng: -63.1353 };
const CENTRO = { name: 'Plaza principal', address: 'Plaza 24 de Septiembre (prueba)', lat: -17.7834, lng: -63.1821 };
const EQUIPETROL = { name: 'Equipetrol', address: 'Av. San Martín, Equipetrol (prueba)', lat: -17.7655, lng: -63.1966 };

async function main() {
  guard();
  admin.initializeApp({ projectId: PROJECT });
  const db = admin.firestore();
  const auth = admin.auth();
  const ts = admin.firestore.Timestamp;
  const now = Date.now();
  const at = (min) => ts.fromMillis(now + min * 60_000);
  const geo = (p) => ({ name: p.name, address: p.address, coordinates: new admin.firestore.GeoPoint(p.lat, p.lng) });

  // Auth: borra y vuelve a crear las cuentas de prueba.
  for (const p of PEOPLE) {
    await auth.deleteUser(p.uid).catch(() => undefined);
    await auth.createUser({
      uid: p.uid, email: p.email, password: PASSWORD, displayName: p.name, emailVerified: true,
      disabled: p.blocked === true,
      // Segundo factor simulado: un teléfono ficticio inscrito (el emulador
      // muestra el código en su consola; no se envía SMS).
      ...(p.mfa ? { multiFactor: { enrolledFactors: [{ phoneNumber: '+15555550100', displayName: 'Prueba', factorId: 'phone' }] } } : {}),
    });
    await auth.setCustomUserClaims(p.uid, { role: p.role });
  }

  const batch = db.batch();
  const set = (p, d) => batch.set(db.doc(p), { ...d, _ficticio: true });

  for (const p of PEOPLE) {
    set(`users/${p.uid}`, {
      id: p.uid, email: p.email, phone: '', displayName: p.name, role: p.role,
      isActive: p.blocked !== true, isVerified: true, phoneVerified: false,
      emailVerifiedAt: at(-60 * 24), createdAt: at(-60 * 24 * 30), fcmTokens: [],
    });
    if (p.role === 'driver') {
      set(`driverProfiles/${p.uid}`, {
        userId: p.uid, licenseNumber: `PRUEBA-${p.uid.toUpperCase()}`, licenseExpiry: at(60 * 24 * 365),
        vehicleId: `v-${p.uid}`, documentsVerified: p.verified === true, rating: 4.9, totalRides: 12,
        isAvailable: p.uid === 'chofer2', online: p.uid === 'chofer2',
        currentLocation: new admin.firestore.GeoPoint(-17.77, -63.18),
      });
      set(`vehicles/v-${p.uid}`, {
        id: `v-${p.uid}`, driverId: p.uid, make: 'Marca de prueba', model: 'Modelo de prueba', year: 2024,
        plate: `PRB-${p.uid.slice(0, 3).toUpperCase()}`, class: 'business', color: 'Negro', capacity: 3,
        isActive: p.verified === true,
      });
    }
  }

  // Configuración de prueba. Valores FICTICIOS para poder ver las pantallas:
  // no son tarifas ni políticas de negocio.
  set('config/global', { isMaintenanceMode: false, firstClassEnabled: true });
  set('config/pricing', { routeFactor: 1.3 });
  set('config/finance', { commissionPct: 20 });
  set('config/security', { mfaEnforced: false });
  set('config/ops', {
    cancellationPolicy: {
      freeWithinMinutesOfBooking: 5, freeBeforePickupMinutes: 120, chargeWhenNoDriver: false,
      feeType: 'fixed', feeValue: 50, noShowWaitMinutes: 10,
    },
    maxPriceAdjustmentPercent: 20,
  });
  for (const vc of ['business', 'businessSuv', 'firstClass', 'businessVan', 'electric']) {
    for (const st of ['oneWay', 'byTheHour']) {
      set(`pricingRules/${vc}_${st}`, {
        id: `${vc}_${st}`, vehicleClass: vc, serviceType: st, isActive: true,
        basePriceUsd: 10, pricePerKmUsd: 2, pricePerHourUsd: 30, minimumPriceUsd: 20, updatedAt: at(0),
      });
    }
  }

  // Una reserva por estado del grafo, más cancelaciones con y sin recargo.
  const base = (id, extra) => ({
    id, riderId: 'pasajera', origin: geo(AIRPORT), destination: geo(CENTRO), class: 'business',
    vehicleClass: 'business', serviceType: 'oneWay', estimatedPrice: 120, passengerCount: 1, luggageCount: 1,
    createdAt: at(-120), updatedAt: at(-5), scheduledAt: at(30), ...extra,
  });
  const driverInfo = { name: 'Luis Prueba', photoUrl: null, rating: 4.9,
    vehicle: { make: 'Marca de prueba', model: 'Modelo de prueba', plate: 'PRB-CHO', color: 'Negro' } };
  const assigned = { driverId: 'chofer', driverInfo };
  const bookings = {
    'r-pending': base('r-pending', { status: 'pending', scheduledAt: at(180) }),
    'r-released': base('r-released', { status: 'pending', scheduledAt: at(45),
      lastRelease: { driverId: 'chofer2', reason: 'vehicle_issue', at: at(-3), from: 'confirmed' }, releasedBy: ['chofer2'] }),
    'r-confirmed': base('r-confirmed', { status: 'confirmed', scheduledAt: at(240), ...assigned }),
    'r-arriving': base('r-arriving', { status: 'driver_arriving', ...assigned }),
    'r-arrived': base('r-arrived', { status: 'driver_arrived', arrivedAt: at(-12), noShowAvailableAt: at(-2), ...assigned }),
    'r-verified': base('r-verified', { status: 'verified', ...assigned }),
    'r-progress': base('r-progress', { status: 'in_progress', destination: geo(EQUIPETROL), ...assigned }),
    'r-completed': base('r-completed', { status: 'completed', scheduledAt: at(-60 * 24), finalPrice: 120, ...assigned,
      settlement: { amount: 120, commissionPct: 20, platformCommission: 24, driverPayout: 96 } }),
    'r-cancelled': base('r-cancelled', { status: 'cancelled', cancelledBy: 'rider', cancellationReason: 'changed_plans',
      cancellationFee: 0, cancellationFeeBasis: 'early', cancellationFeeCharged: false, scheduledAt: at(60 * 24) }),
    'r-cancelled-fee': base('r-cancelled-fee', { status: 'cancelled', cancelledBy: 'rider', cancellationReason: 'other',
      cancellationFee: 50, cancellationFeeBasis: 'late', cancellationFeeCharged: false, scheduledAt: at(-30) }),
    'r-noshow': base('r-noshow', { status: 'no_show', arrivedAt: at(-25), noShowAt: at(-10), ...assigned }),
  };
  for (const [id, b] of Object.entries(bookings)) set(`bookings/${id}`, b);
  set('openRequests/r-pending', { vehicleClass: 'business', serviceType: 'oneWay', scheduledAt: at(180), estimatedPrice: 120,
    hours: null, passengerCount: 1, luggageCount: 1, pickupAirport: 'VVI', flightType: null, pickupArea: 'Aeropuerto',
    dropoffArea: 'Centro', pickupApprox: { lat: -17.64, lng: -63.14 }, dropoffApprox: { lat: -17.78, lng: -63.18 }, tripKm: 16 });
  set('openRequests/r-released', { vehicleClass: 'business', serviceType: 'oneWay', scheduledAt: at(45), estimatedPrice: 120,
    hours: null, passengerCount: 1, luggageCount: 1, pickupAirport: 'VVI', flightType: null, pickupArea: 'Aeropuerto',
    dropoffArea: 'Centro', pickupApprox: { lat: -17.64, lng: -63.14 }, dropoffApprox: { lat: -17.78, lng: -63.18 }, tripKm: 16 });

  // SOS abierto en el viaje en curso y una alerta para central.
  set('incidents/inc-prueba', { bookingId: 'r-progress', bookingShortId: 'R-PROGRE', bookingStatusAtRaise: 'in_progress',
    reporterId: 'pasajera', reporterRole: 'rider', status: 'open', count: 1, createdAt: at(-2), lastRaisedAt: at(-2),
    updatedAt: at(-2), escalation: { count: 0, lastAt: null }, appVersion: null, cancelledByReporter: false });
  set('bookings/r-progress/adminOnly/incident', { openByReporter: { pasajera: 'inc-prueba' }, incidentOpen: true });
  set('adminAlerts/alerta-prueba', { type: 'driver_released_booking', severity: 'high', bookingId: 'r-released',
    driverId: 'chofer2', reason: 'vehicle_issue', minutesToPickup: 45, resolved: false, createdAt: at(-3),
    message: 'El chófer liberó la reserva y faltan 45 min para la recogida. (dato de prueba)' });
  set('adminAlerts/alerta-noshow', { type: 'rider_no_show', severity: 'medium', bookingId: 'r-noshow', driverId: 'chofer',
    resolved: false, createdAt: at(-10), message: 'El chófer marcó que el pasajero no apareció. (dato de prueba)' });
  set('payments/p-prueba', { id: 'p-prueba', bookingId: 'r-completed', riderId: 'pasajera', driverId: 'chofer',
    amount: 120, amountBs: 120, currency: 'BOB', status: 'captured', method: 'cash', manual: true, createdAt: at(-60 * 23) });

  await batch.commit();
  console.log(`Sembrado ${PROJECT}: ${PEOPLE.length} cuentas (contraseña «${PASSWORD}»), ${Object.keys(bookings).length} reservas.`);
}

main().catch((e) => { console.error(String(e.message || e)); process.exit(1); });
