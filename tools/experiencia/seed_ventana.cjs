/**
 * Siembra el historial del chófer (driverHistory, ventana del chófer) para
 * las capturas de la Parte B. TODO ES FICTICIO: zonas, importes y estrellas.
 * Corre después de seed.cjs. Solo demo-luxelane y solo los emuladores.
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

async function main() {
  admin.initializeApp({ projectId: PROJECT });
  const db = admin.firestore();
  const ts = admin.firestore.Timestamp;
  const now = Date.now();
  const at = (min) => ts.fromMillis(now + min * 60_000);
  // Como lo escribe writeDriverHistoryOnBooking: solo la lista cerrada.
  const trip = (id, endedMin, extra = {}) => ({
    bookingId: id, status: 'completed', endedAt: at(endedMin), serviceType: 'oneWay', vehicleClass: 'business',
    pickupArea: 'Aeropuerto', dropoffArea: 'Santa Cruz de la Sierra', pickupApprox: { lat: -17.64, lng: -63.14 },
    dropoffApprox: { lat: -17.78, lng: -63.18 }, distanceKm: 16.4, durationMinutes: 28, riderRating: 5,
    estimatedPrice: 120, finalPrice: 120, refunded: false,
    settlement: { amount: 120, commissionPct: 20, platformCommission: 24, driverPayout: 96 }, ...extra,
  });
  const batch = db.batch();
  const put = (id, data) => batch.set(db.doc(`driverHistory/chofer/trips/${id}`), data);
  put('h-hoy-1', trip('h-hoy-1', -90));
  put('h-hoy-2', trip('h-hoy-2', -30, { settlement: null, finalPrice: null, estimatedPrice: 95, riderRating: null }));
  put('h-ayer', trip('h-ayer', -26 * 60, { serviceType: 'byTheHour', dropoffArea: null, dropoffApprox: null,
    distanceKm: null, durationMinutes: 180, estimatedPrice: 300, finalPrice: 300,
    settlement: { amount: 300, commissionPct: 20, platformCommission: 60, driverPayout: 240 } }));
  put('h-reembolsado', trip('h-reembolsado', -3 * 24 * 60, { refunded: true, riderRating: 3 }));
  await batch.commit();
  console.log(`Sembrado ${PROJECT}: historial FICTICIO de chofer (4 viajes); chofer2 sin historial.`);
}

main().catch((e) => { console.error(String(e.message || e)); process.exit(1); });
