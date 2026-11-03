/**
 * Siembra los estados del registro de chóferes para las capturas (Parte B
 * del registro), después de seed.cjs. TODO ES FICTICIO: personas,
 * documentos (una tarjeta «DOCUMENTO DE PRUEBA») y requisitos. Los
 * requisitos de config/ops.driverRequirements de aquí son de PRUEBA: los
 * reales los decide el responsable con su abogado.
 *
 * Solo demo-luxelane y solo contra los emuladores de Auth, Firestore y
 * Storage.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const admin = require(path.join(__dirname, '../../functions/node_modules/firebase-admin'));

const PROJECT = 'demo-luxelane';
const BUCKET = `${PROJECT}.appspot.com`;
if ((process.env.GCLOUD_PROJECT || PROJECT) !== PROJECT) throw new Error(`Solo ${PROJECT}.`);
for (const v of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!process.env[v]) throw new Error(`Falta ${v}: solo se siembran los emuladores.`);
}
process.env.FIREBASE_STORAGE_EMULATOR_HOST = process.env.FIREBASE_STORAGE_EMULATOR_HOST || '127.0.0.1:9199';

const PASSWORD = 'prueba-123';
// Requisitos FICTICIOS de prueba.
const REQS = [
  { type: 'profile_photo', required: true, expires: false },
  { type: 'live_photo', required: true, expires: false },
  { type: 'national_id_front', required: true, expires: false },
  { type: 'license_front', required: true, expires: true },
  { type: 'criminal_record', required: true, expires: false },
  { type: 'vehicle_photo_front', required: false, expires: false },
];
// [uid, correo, nombre, rol, estado de la solicitud (null = sin solicitud)]
const PEOPLE = [
  ['aspirante', 'Ada Prueba', 'rider', null],
  ['regdatos', 'Dario Prueba', 'driver', 'draft-empty'],
  ['regdocs', 'Dora Prueba', 'driver', 'needs_changes'],
  ['regrevision', 'Rita Prueba', 'driver', 'submitted'],
  ['regrechazada', 'Ramiro Prueba', 'driver', 'rejected'],
];

async function main() {
  admin.initializeApp({ projectId: PROJECT, storageBucket: BUCKET });
  const db = admin.firestore();
  const auth = admin.auth();
  const bucket = admin.storage().bucket(BUCKET);
  const ts = admin.firestore.Timestamp;
  const now = Date.now();
  const day = 86_400_000;
  const jpeg = fs.readFileSync(path.join(__dirname, 'fixtures/documento_ficticio.jpg'));

  await db.doc('config/ops').set({ driverRequirements: REQS }, { merge: true });

  for (const [uid, name, role, state] of PEOPLE) {
    await auth.deleteUser(uid).catch(() => undefined);
    await auth.createUser({ uid, email: `${uid}@prueba.test`, password: PASSWORD, displayName: name, emailVerified: true });
    await auth.setCustomUserClaims(uid, { role });
    await db.doc(`users/${uid}`).set({
      id: uid, email: `${uid}@prueba.test`, displayName: name, phone: '', role, isActive: true, isVerified: true,
      createdAt: ts.fromMillis(now - 3 * day), fcmTokens: [], _ficticio: true,
    });
    if (!state) continue;
    await db.doc(`driverProfiles/${uid}`).set({ userId: uid, documentsVerified: false, isAvailable: false, online: false });
    if (state === 'draft-empty') {
      await db.doc(`driverApplications/${uid}`).set({ driverId: uid, status: 'draft', step: 'personal',
        createdAt: ts.fromMillis(now - day), updatedAt: ts.fromMillis(now - day) });
      continue;
    }
    const app = { driverId: uid, status: state, step: state === 'needs_changes' ? 'documents' : 'review',
      createdAt: ts.fromMillis(now - 2 * day), updatedAt: ts.fromMillis(now - day) };
    if (state !== 'needs_changes') app.submittedAt = ts.fromMillis(now - day);
    await db.doc(`driverApplications/${uid}`).set(app);
    await db.doc(`driverApplications/${uid}/private/data`).set({
      personal: { fullName: `${name} (ficticio)`, nationalIdNumber: '0000000-FIC', licenseNumber: 'LIC-FICTICIA',
        licenseExpiry: ts.fromMillis(now + 400 * day) },
      vehicle: { make: 'Marca', model: 'Modelo', year: 2022, color: 'black', colorOther: null, plate: `FIC${uid.length}23`,
        bodyType: 'sedan', capacity: 3, class: 'business' },
      vehicleId: `v-${uid}`,
    });
    await db.doc(`vehicles/v-${uid}`).set({ id: `v-${uid}`, driverId: uid, make: 'Marca', model: 'Modelo', year: 2022,
      color: 'black', plate: `FIC${uid.length}23`, bodyType: 'sedan', capacity: 3, class: 'business', isActive: false });
    // Documentos: subidos (y uno rechazado en «necesita cambios»).
    const docs = state === 'needs_changes'
      ? { profile_photo: 'uploaded', national_id_front: 'approved', license_front: 'rejected' }
      : { profile_photo: 'uploaded', live_photo: 'uploaded', national_id_front: 'uploaded', license_front: 'uploaded',
        criminal_record: 'uploaded' };
    for (const [type, status] of Object.entries(docs)) {
      const p = `driverDocs/${uid}/${type}/1`;
      await bucket.file(p).save(jpeg, { contentType: 'image/jpeg', resumable: false,
        metadata: { cacheControl: 'private, no-store, max-age=0' } });
      await db.doc(`driverApplications/${uid}/documents/${type}`).set({
        type, status, version: 1, uploadedAt: ts.fromMillis(now - day),
        expiresAt: type === 'license_front' ? ts.fromMillis(now + 20 * day) : null,
        rejectReason: status === 'rejected' ? 'illegible' : null,
        rejectNote: status === 'rejected' ? 'La foto salió con reflejo (nota de prueba).' : null,
        reviewedAt: status === 'pending_upload' ? null : ts.fromMillis(now - day / 2),
      });
      await db.doc(`driverApplications/${uid}/documentFiles/${type}`).set({
        path: p, size: jpeg.length, contentType: 'image/jpeg', version: 1, uploadedAt: ts.fromMillis(now - day), reviewedBy: null,
      });
    }
  }
  // Bitácora de accesos de prueba y un chófer verificado con un documento
  // que vence pronto y bloqueado (para «Vencimientos próximos»).
  await db.collection('driverDocAccessLogs').add({ adminId: 'admin', adminEmail: 'admin@prueba.test',
    driverId: 'regrevision', type: 'license_front', version: 1, at: ts.fromMillis(now - 3_600_000) });
  await db.doc('driverApplications/chofer').set({ driverId: 'chofer', status: 'approved', step: 'review',
    createdAt: ts.fromMillis(now - 90 * day), updatedAt: ts.fromMillis(now - 30 * day) });
  await db.doc('driverApplications/chofer/documents/license_front').set({ type: 'license_front', status: 'approved',
    version: 1, expiresAt: ts.fromMillis(now + 6 * day) });
  // Chófer verificado aparte (no se toca a los de seed.cjs, que usan otras
  // capturas) con la licencia vencida y bloqueado por blockOnExpiredDocs.
  await auth.deleteUser('regvencido').catch(() => undefined);
  await auth.createUser({ uid: 'regvencido', email: 'regvencido@prueba.test', password: PASSWORD,
    displayName: 'Vito Prueba', emailVerified: true });
  await auth.setCustomUserClaims('regvencido', { role: 'driver' });
  await db.doc('users/regvencido').set({ id: 'regvencido', email: 'regvencido@prueba.test', displayName: 'Vito Prueba',
    phone: '', role: 'driver', isActive: true, isVerified: true, createdAt: ts.fromMillis(now - 90 * day), fcmTokens: [],
    _ficticio: true });
  await db.doc('driverProfiles/regvencido').set({ userId: 'regvencido', documentsVerified: true, isAvailable: false,
    online: false, docsBlocked: true });
  await db.doc('driverApplications/regvencido').set({ driverId: 'regvencido', status: 'approved', step: 'review',
    createdAt: ts.fromMillis(now - 90 * day), updatedAt: ts.fromMillis(now - 30 * day) });
  await db.doc('driverApplications/regvencido/documents/license_front').set({ type: 'license_front', status: 'expired',
    version: 1, expiresAt: ts.fromMillis(now - 2 * day) });
  console.log('Registro de chóferes sembrado (FICTICIO).');
}

main().then(() => process.exit(0), (e) => { console.error(e); process.exit(1); });
