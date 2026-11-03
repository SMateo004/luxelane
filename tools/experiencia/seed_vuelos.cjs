/**
 * Siembra los emuladores con vuelos para las capturas de la Parte B de
 * vuelos. TODO ES FICTICIO: el aeropuerto de prueba, su punto de recogida,
 * los minutos de config/ops y los vuelos (aerolínea «Aerolínea de prueba»,
 * números ZZ…). Corre después de seed.cjs.
 *
 * Se niega a correr si el proyecto no es demo-luxelane o si no apunta a los
 * emuladores.
 */
'use strict';
const path = require('path');
const admin = require(path.join(__dirname, '../../functions/node_modules/firebase-admin'));

const PROJECT = 'demo-luxelane';
const project = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || PROJECT;
if (project !== PROJECT) throw new Error(`Solo ${PROJECT}; recibido «${project}». No se siembra nada.`);
for (const v of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!process.env[v]) throw new Error(`Falta ${v}: solo se siembran los emuladores.`);
}

// Minutos FICTICIOS (los reales los fija el responsable en config/ops).
const OPS = {
  flightExitMinutes: { domestic: { noCheckedBag: 15, checkedBag: 30 }, international: { noCheckedBag: 35, checkedBag: 55 } },
  flightNotifyThresholdMinutes: 15,
  flightCheckpointsMinutes: [180, 60],
  flightPollMinutes: 15,
  flightStaleMinutes: 45,
};
// Aeropuerto de prueba con punto nacional y SIN punto internacional (para
// ver «Punto por confirmar con central»).
const VVI = {
  code: 'VVI', name: 'Aeropuerto de prueba Viru Viru (ficticio)', city: 'Santa Cruz de la Sierra', timeZone: 'America/La_Paz',
  pickupPoints: {
    domestic: { name: 'Puerta de llegadas nacionales (punto ficticio)',
      instructions: 'Frente a la salida, junto al cartel de prueba. Dato ficticio.', lat: -17.6449, lng: -63.1352 },
    international: null,
  },
};

async function main() {
  admin.initializeApp({ projectId: PROJECT });
  const db = admin.firestore();
  const ts = admin.firestore.Timestamp;
  const now = Date.now();
  const at = (min) => ts.fromMillis(now + min * 60_000);
  // Fecha local de La Paz (UTC−4) de una hora dada.
  const localDate = (ms) => new Date(ms - 4 * 3_600_000).toISOString().slice(0, 10);
  const geo = (name, address, lat, lng) => ({ name, address, coordinates: new admin.firestore.GeoPoint(lat, lng) });
  const ORIGIN = geo('Aeropuerto Viru Viru', 'Aeropuerto Internacional Viru Viru (prueba)', -17.6448, -63.1353);
  const DEST = geo('Plaza principal', 'Plaza 24 de Septiembre (prueba)', -17.7834, -63.1821);
  const driverInfo = { name: 'Luis Prueba', photoUrl: null, rating: 4.9,
    vehicle: { make: 'Marca de prueba', model: 'Modelo de prueba', plate: 'PRB-CHO', color: 'Negro' } };

  const batch = db.batch();
  batch.set(db.doc('config/ops'), OPS, { merge: true });
  batch.set(db.doc('airports/VVI'), { ...VVI, updatedAt: at(-60 * 24) });
  batch.set(db.doc('airportsPublic/VVI'), { code: VVI.code, name: VVI.name, city: VVI.city });

  /** Reserva con vuelo; [arrMin] es la llegada programada en minutos desde ahora. */
  const flightBooking = (id, { status, arrMin, flightStatus = 'scheduled', estMin = null, type = 'domestic', bag = true,
    source = 'passenger', quality = 'none', lock = false, assigned = true, number = 'ZZ123', extra = {} }) => {
    const exit = OPS.flightExitMinutes[type][bag ? 'checkedBag' : 'noCheckedBag'];
    const effective = estMin ?? arrMin;
    const readyAt = at(effective + exit);
    const flight = {
      airportCode: 'VVI', flightType: type, airline: 'Aerolínea de prueba', flightNumber: number,
      flightDate: localDate(now + arrMin * 60_000), scheduledArrival: at(arrMin), hasCheckedBag: bag,
      estimatedArrival: estMin === null ? null : at(estMin), actualArrival: null, status: flightStatus, source,
      lastObservedAt: quality === 'none' ? null : at(-5), lastChangeAt: at(-5), dataQuality: quality, manualLock: lock,
      notifiedReadyAt: readyAt, ...(lock ? { manualSetBy: 'admin', manualSetAt: at(-5) } : {}),
    };
    const active = ['pending', 'confirmed', 'driver_arriving', 'driver_arrived'].includes(status)
      && !['landed', 'cancelled', 'diverted'].includes(flightStatus);
    batch.set(db.doc(`bookings/${id}`), {
      _ficticio: true, id, riderId: 'pasajera', origin: ORIGIN, destination: DEST, class: 'business', vehicleClass: 'business',
      serviceType: 'oneWay', estimatedPrice: 120, passengerCount: 1, luggageCount: 1, createdAt: at(-120), updatedAt: at(-5),
      status, scheduledAt: readyAt, readyAt, flightActive: active, flight, flightNumber: number, flightType: type,
      pickupAirport: 'VVI', ...(assigned ? { driverId: 'chofer', driverInfo } : { driverId: null }), ...extra,
    });
    if (assigned) {
      const { source: _s, manualLock: _l, notifiedReadyAt: _n, lastObservedAt: _o, lastChangeAt: _c, manualSetBy: _b,
        manualSetAt: _a, ...view } = flight;
      batch.set(db.doc(`bookings/${id}/driverView/flight`), { ...view, readyAt, updatedAt: at(-5) });
    }
    batch.set(db.doc(`bookings/${id}/payment/state`), { bookingId: id, riderId: 'pasajera', paymentStatus: 'paid',
      paymentMethod: 'manual_qr', amountDue: 12000, amountPaid: 12000, paidAt: at(-100), createdAt: at(-120), updatedAt: at(-100) });
    return readyAt;
  };

  // Sin datos en vivo (lo dijo el pasajero): por verificar.
  flightBooking('v-sindatos', { status: 'confirmed', arrMin: 90, number: 'ZZ101' });
  batch.set(db.doc('adminAlerts/vuelo-por-verificar'), { type: 'flight_unverified', severity: 'low', bookingId: 'v-sindatos',
    resolved: false, createdAt: at(-30), message: 'Vuelo indicado por el pasajero, sin verificar. (dato de prueba)' });
  // Retrasado, fijado por central con bloqueo manual.
  flightBooking('v-retrasado', { status: 'confirmed', arrMin: 60, estMin: 140, flightStatus: 'delayed', source: 'admin',
    quality: 'fresh', lock: true, number: 'ZZ202' });
  batch.set(db.doc('admin_logs/vuelo-fijado'), { action: 'set_flight_info', targetId: 'v-retrasado', targetType: 'booking',
    adminId: 'admin', adminEmail: 'admin@prueba.test', actorRole: 'admin', reason: 'Confirmado con la aerolínea (dato de prueba)',
    timestamp: at(-5), createdAt: at(-5) });
  // Cancelado: alerta alta, la reserva no se cancela sola.
  flightBooking('v-cancelado', { status: 'confirmed', arrMin: 120, flightStatus: 'cancelled', source: 'admin', quality: 'fresh',
    lock: true, number: 'ZZ303' });
  batch.set(db.doc('adminAlerts/vuelo-cancelado'), { type: 'flight_disrupted', severity: 'high', bookingId: 'v-cancelado',
    resolved: false, createdAt: at(-4), message: 'El vuelo figura como cancelado. Revisa la reserva. (dato de prueba)' });
  // Internacional sin punto definido.
  flightBooking('v-sinpunto', { status: 'confirmed', arrMin: 200, type: 'international', bag: false, number: 'ZZ404' });
  batch.set(db.doc('adminAlerts/vuelo-sin-punto'), { type: 'pickup_point_missing', severity: 'medium', bookingId: 'v-sinpunto',
    resolved: false, createdAt: at(-20), message: 'El aeropuerto VVI no tiene punto de recogida internacional. (dato de prueba)' });
  // Solicitud abierta con vuelo: solo aeropuerto y tipo, sin número.
  const openReady = flightBooking('v-abierta', { status: 'pending', arrMin: 150, assigned: false, number: 'ZZ505' });
  batch.set(db.doc('openRequests/v-abierta'), { vehicleClass: 'business', serviceType: 'oneWay', scheduledAt: openReady,
    estimatedPrice: 120, hours: null, passengerCount: 1, luggageCount: 1, pickupAirport: 'VVI', flightType: 'domestic',
    pickupArea: 'Aeropuerto', dropoffArea: 'Centro', pickupApprox: { lat: -17.64, lng: -63.14 },
    dropoffApprox: { lat: -17.78, lng: -63.18 }, tripKm: 16 });

  await batch.commit();
  console.log(`Sembrados en ${PROJECT}: aeropuerto VVI (ficticio), config/ops de vuelos (ficticia) y 5 reservas con vuelo.`);
}

main().catch((e) => { console.error(String(e.message || e)); process.exit(1); });
