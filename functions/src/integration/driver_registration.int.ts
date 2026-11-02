/**
 * Registro de chóferes (A9) contra los emuladores de Firestore y Storage:
 * solicitud completa, requisitos sin configurar, obligatorio faltante,
 * archivo falso, ruta ajena, rechazo y nueva versión, vencimientos con reloj
 * simulado, bloqueo en línea, cambio de vehículo, aprobación incompleta,
 * usuario ajeno, admin sin MFA y nada sensible en los logs.
 *
 * Requisitos, días y datos: FICTICIOS de prueba (los reales los decide el
 * responsable con su abogado en config/ops).
 */
import { describe, it, expect, beforeAll, beforeEach, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import {
  acceptBooking as acceptBookingFn, adminDecideApplication as decideFn, saveDriverStep as saveStepFn,
  submitApplication as submitFn,
} from '../index';
import {
  adminAllowDriverOnline, adminDecideApplication, adminGetDocumentUrl, adminListDocExpiries, adminPurgeDriverDocuments, NO_STORE,
  adminReviewDocument, DocStore, gcsDocStore, getDriverApplication, recomputeDocsBlock, RegDeps,
  registerDocumentUpload, runDocExpiry, saveDriverStep, storagePath, submitApplication,
} from '../driver_application';

const db = admin.firestore();
const bucket = admin.storage().bucket('demo-luxelane.appspot.com');
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const DAY = 24 * 60 * 60 * 1000;
const T0 = Date.UTC(2026, 10, 1, 12);
let clock = T0;

// El emulador no firma URLs: la firma se simula (en producción, getSignedUrl).
const real = gcsDocStore(bucket);
const store: DocStore = { ...real, signedReadUrl: async (p, ttl) => `https://firma.ficticia.test/${p.length}?ttl=${ttl}` };
const pushes: string[] = [];
const deps: RegDeps = { db, store, now: () => clock, push: async (_t, title) => { pushes.push(title); } };
const ADMIN = { adminId: 'jefa', adminEmail: null };

// Bytes de prueba (no son documentos reales).
const JPEG = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0x10, 0x4a, 0x46, 0x49, 0x46, 0, 1, 2, 3, 4, 5]);
const PDF = Buffer.from('%PDF-1.4 ficticio de prueba');
const FAKE = Buffer.from('esto no es una imagen, es texto');

// Requisitos FICTICIOS de prueba.
const REQS = [
  { type: 'profile_photo', required: true, expires: false },
  { type: 'license_front', required: true, expires: true },
  { type: 'criminal_record', required: true, expires: false },
  { type: 'vehicle_photo_front', required: false, expires: false },
];
const PERSONAL = { step: 'personal', fullName: 'Chófer De Prueba', nationalIdNumber: '9999999-FIC',
  licenseNumber: 'LIC-FICTICIA-1', licenseExpiry: T0 + 400 * DAY };
const VEHICLE = { step: 'vehicle', make: 'Marca', model: 'Modelo', year: 2022, color: 'black', plate: 'prb-123',
  bodyType: 'sedan', passengers: 3, vehicleClass: 'business' };

async function reason(p: Promise<unknown>): Promise<{ reason?: string; fields?: string[] }> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string; fields?: string[] }) ?? {}; }
  throw new Error('se esperaba un error');
}

async function upload(uid: string, type: string, version: number, data = JPEG, contentType = 'image/jpeg') {
  await bucket.file(storagePath(uid, type, version)).save(data, { contentType, resumable: false });
}

async function uploadAndRegister(uid: string, type: string, version = 1, extra: Record<string, unknown> = {}) {
  await upload(uid, type, version, type === 'criminal_record' ? PDF : JPEG,
    type === 'criminal_record' ? 'application/pdf' : 'image/jpeg');
  return registerDocumentUpload(deps, uid, { type, version, ...extra });
}

async function clear(): Promise<void> {
  for (const col of ['driverApplications', 'driverProfiles', 'vehicles', 'users', 'adminAlerts', 'admin_logs',
    'driverDocAccessLogs', 'config', 'bookings', 'rateLimits']) {
    await db.recursiveDelete(db.collection(col));
  }
  await bucket.deleteFiles({ prefix: 'driverDocs/' }).catch(() => undefined);
}

async function readyApplication(uid = 'carlos') {
  await saveDriverStep(deps, uid, PERSONAL);
  await saveDriverStep(deps, uid, VEHICLE);
  await uploadAndRegister(uid, 'profile_photo');
  await uploadAndRegister(uid, 'license_front', 1, { expiresAt: clock + 30 * DAY });
  await uploadAndRegister(uid, 'criminal_record');
}

async function approveAll(uid = 'carlos') {
  for (const type of ['profile_photo', 'license_front', 'criminal_record']) {
    const v = (await db.doc(`driverApplications/${uid}/documents/${type}`).get()).data()!.version;
    await adminReviewDocument(deps, ADMIN, { driverId: uid, type, version: v, decision: 'approve' });
  }
}

const app = async (uid = 'carlos') => (await db.doc(`driverApplications/${uid}`).get()).data();
const docOf = async (type: string, uid = 'carlos') =>
  (await db.doc(`driverApplications/${uid}/documents/${type}`).get()).data();

beforeAll(async () => { await clear(); });
beforeEach(async () => {
  await clear();
  clock = T0;
  pushes.length = 0;
  await db.doc('users/carlos').set({ role: 'driver', isActive: true, fcmTokens: ['t-carlos'], locale: 'en' });
  await db.doc('users/otro').set({ role: 'driver', isActive: true });
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('users/jefa').set({ role: 'admin', isActive: true });
  await db.doc('config/ops').set({ driverRequirements: REQS });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('solicitud completa', () => {
  it('pasos, documentos, envío, revisión y aprobación por los caminos de siempre', async () => {
    await readyApplication();
    expect(await submitApplication(deps, 'carlos')).toEqual({ status: 'submitted' });
    expect((await db.collection('adminAlerts').where('type', '==', 'driver_application_submitted').get()).size).toBe(1);
    await approveAll();
    expect((await app())!.status).toBe('in_review');
    const res = await adminDecideApplication(deps, ADMIN, { driverId: 'carlos', decision: 'approve',
      reason: 'Todos los documentos revisados (prueba)' });
    expect(res.status).toBe('approved');
    const profile = (await db.doc('driverProfiles/carlos').get()).data()!;
    expect(profile.documentsVerified).toBe(true);
    const vehicle = (await db.doc(`vehicles/${profile.vehicleId}`).get()).data()!;
    expect(vehicle).toMatchObject({ isActive: true, plate: 'PRB123', color: 'black', bodyType: 'sedan', capacity: 3 });
    // Caminos de siempre: verify_driver y enable_vehicle en la auditoría.
    const ops = (await db.collection('admin_logs').get()).docs.map((d) => d.data().operation);
    expect(ops).toEqual(expect.arrayContaining(['verify_driver', 'enable_vehicle', 'driver_application_approve',
      'approve_driver_document']));
    // Aviso en su idioma, sin nombre de documento.
    const inbox = (await db.collection('users/carlos/notifications').get()).docs.map((d) => d.data());
    expect(inbox).toEqual([expect.objectContaining({ title: 'Application approved', type: 'driver_application_approved' })]);
    expect(pushes).toEqual(['Application approved']);
  });

  it('reanudable: getDriverApplication devuelve lo guardado y el estado', async () => {
    await saveDriverStep(deps, 'carlos', PERSONAL);
    const a = await getDriverApplication(deps, 'carlos');
    expect(a).toMatchObject({ status: 'draft', step: 'vehicle', requirementsConfigured: true, mfaEnforced: false,
      personal: { fullName: 'Chófer De Prueba', licenseExpiry: PERSONAL.licenseExpiry } });
  });
});

describe('requisitos y faltantes', () => {
  it('sin config/ops.driverRequirements: avanza pero no envía', async () => {
    await db.doc('config/ops').set({});
    await saveDriverStep(deps, 'carlos', PERSONAL);
    expect((await getDriverApplication(deps, 'carlos')).requirementsConfigured).toBe(false);
    expect((await reason(submitApplication(deps, 'carlos'))).reason).toBe('requirements_not_configured');
  });

  it('obligatorio faltante: documents_missing con el tipo', async () => {
    await saveDriverStep(deps, 'carlos', PERSONAL);
    await saveDriverStep(deps, 'carlos', VEHICLE);
    await uploadAndRegister('carlos', 'profile_photo');
    expect(await reason(submitApplication(deps, 'carlos')))
      .toEqual(expect.objectContaining({ reason: 'documents_missing', fields: ['license_front', 'criminal_record'] }));
  });

  it('documento que vence sin fecha: rechazado', async () => {
    await upload('carlos', 'license_front', 1);
    expect(await reason(registerDocumentUpload(deps, 'carlos', { type: 'license_front', version: 1 })))
      .toEqual(expect.objectContaining({ fields: ['expiresAt'] }));
  });

  it('aprobar sin todos los obligatorios aprobados: no', async () => {
    await readyApplication();
    await submitApplication(deps, 'carlos');
    await adminReviewDocument(deps, ADMIN, { driverId: 'carlos', type: 'profile_photo', version: 1, decision: 'approve' });
    expect(await reason(adminDecideApplication(deps, ADMIN, { driverId: 'carlos', decision: 'approve',
      reason: 'Intento de aprobar incompleto' }))).toEqual(expect.objectContaining({
      reason: 'documents_not_approved', fields: ['license_front', 'criminal_record'] }));
    expect((await db.doc('driverProfiles/carlos').get()).data()!.documentsVerified).toBe(false);
  });
});

describe('archivos', () => {
  it('archivo falso con extensión de imagen: invalid_file y el objeto queda marcado', async () => {
    await upload('carlos', 'profile_photo', 1, FAKE, 'image/jpeg');
    expect((await reason(registerDocumentUpload(deps, 'carlos', { type: 'profile_photo', version: 1 }))).reason)
      .toBe('invalid_file');
    const [md] = await bucket.file('driverDocs/carlos/profile_photo/1').getMetadata();
    expect(md.metadata?.luxelaneInvalid).toBe('type');
    expect(await docOf('profile_photo')).toBeUndefined();
  });

  it('PDF en un documento que solo admite imagen: invalid_file', async () => {
    await upload('carlos', 'profile_photo', 1, PDF, 'application/pdf');
    expect((await reason(registerDocumentUpload(deps, 'carlos', { type: 'profile_photo', version: 1 }))).reason)
      .toBe('invalid_file');
  });

  it('ruta ajena: registrar el archivo de otro no es posible', async () => {
    await upload('otro', 'profile_photo', 1);
    // La ruta sale del uid de la sesión: para carlos no hay archivo.
    expect((await reason(registerDocumentUpload(deps, 'carlos', { type: 'profile_photo', version: 1 }))).reason)
      .toBe('file_missing');
  });

  it('rechazo y nueva versión: la v2 vuelve a revisión y limpia el motivo', async () => {
    await readyApplication();
    await submitApplication(deps, 'carlos');
    await adminReviewDocument(deps, ADMIN, { driverId: 'carlos', type: 'profile_photo', version: 1, decision: 'reject',
      rejectReason: 'illegible', note: 'Foto borrosa' });
    expect(await docOf('profile_photo')).toMatchObject({ status: 'rejected', rejectReason: 'illegible', rejectNote: 'Foto borrosa' });
    expect((await reason(uploadAndRegister('carlos', 'profile_photo', 3))).reason).toBe('unexpected_version');
    await uploadAndRegister('carlos', 'profile_photo', 2);
    expect(await docOf('profile_photo')).toMatchObject({ status: 'uploaded', version: 2, rejectReason: null });
  });
});

describe('vehículo', () => {
  it('año fuera de rango y mínimo por clase (config/ops.vehicleMinYear)', async () => {
    expect((await reason(saveDriverStep(deps, 'carlos', { ...VEHICLE, year: 1989 }))).fields).toEqual(['year']);
    expect((await reason(saveDriverStep(deps, 'carlos', { ...VEHICLE, year: 2028 }))).fields).toEqual(['year']);
    await db.doc('config/ops').set({ driverRequirements: REQS, vehicleMinYear: { business: 2023 } });
    expect((await reason(saveDriverStep(deps, 'carlos', { ...VEHICLE, year: 2022 }))).fields).toEqual(['year']);
  });

  it('placa en uso por otro vehículo activo: plate_in_use', async () => {
    await db.doc('vehicles/v-otro').set({ driverId: 'otro', plate: 'PRB123', isActive: true });
    expect((await reason(saveDriverStep(deps, 'carlos', VEHICLE))).reason).toBe('plate_in_use');
  });

  it('cambio de vehículo tras aprobar: el nuevo queda inactivo y en revisión hasta aprobarlo', async () => {
    await readyApplication();
    await submitApplication(deps, 'carlos');
    await approveAll();
    await adminDecideApplication(deps, ADMIN, { driverId: 'carlos', decision: 'approve', reason: 'Aprobado (prueba)' });
    const oldId = (await db.doc('driverProfiles/carlos').get()).data()!.vehicleId;
    await saveDriverStep(deps, 'carlos', { ...VEHICLE, plate: 'NUE-456', color: 'other', colorOther: 'Vino' });
    const a = (await app())!;
    expect(a.status).toBe('in_review');
    const newId = a.pendingVehicleId;
    expect(newId).not.toBe(oldId);
    expect((await db.doc(`vehicles/${newId}`).get()).data()!.isActive).toBe(false);
    expect((await db.doc(`vehicles/${oldId}`).get()).data()!.isActive).toBe(true);
    expect((await db.doc('driverProfiles/carlos').get()).data()!.vehicleId).toBe(oldId);
    await adminDecideApplication(deps, ADMIN, { driverId: 'carlos', decision: 'approve', reason: 'Vehículo nuevo revisado' });
    expect((await db.doc(`vehicles/${newId}`).get()).data()!.isActive).toBe(true);
    expect((await db.doc(`vehicles/${oldId}`).get()).data()!.isActive).toBe(false);
    expect((await db.doc('driverProfiles/carlos').get()).data()!.vehicleId).toBe(newId);
  });

  it('datos personales tras aprobar: los cambia el admin', async () => {
    await readyApplication();
    await submitApplication(deps, 'carlos');
    await approveAll();
    await adminDecideApplication(deps, ADMIN, { driverId: 'carlos', decision: 'approve', reason: 'Aprobado (prueba)' });
    expect((await reason(saveDriverStep(deps, 'carlos', PERSONAL))).reason).toBe('locked_after_approval');
  });
});

describe('vencimientos y bloqueo en línea (reloj simulado)', () => {
  async function approvedDriver() {
    await readyApplication();
    await submitApplication(deps, 'carlos');
    await approveAll();
    await adminDecideApplication(deps, ADMIN, { driverId: 'carlos', decision: 'approve', reason: 'Aprobado (prueba)' });
    await db.doc('driverProfiles/carlos').update({ isAvailable: true, online: true });
  }

  it('avisos a los días configurados, una vez; al vencer, una alerta por documento y versión', async () => {
    await approvedDriver();
    await db.doc('config/ops').update({ docExpiryReminderDays: [7, 1] });
    clock = T0 + 24 * DAY; // vence en 6 días
    expect((await runDocExpiry(deps)).reminders).toBe(1);
    expect((await runDocExpiry(deps)).reminders).toBe(0);
    clock = T0 + 29.5 * DAY; // vence en menos de 1 día
    expect((await runDocExpiry(deps)).reminders).toBe(1);
    clock = T0 + 31 * DAY;
    expect((await runDocExpiry(deps)).expired).toBe(1);
    await runDocExpiry(deps);
    expect((await docOf('license_front'))!.status).toBe('expired');
    expect((await db.collection('adminAlerts').where('type', '==', 'driver_document_expired').get()).size).toBe(1);
    // blockOnExpiredDocs ausente (false): alerta sin bloqueo.
    const p = (await db.doc('driverProfiles/carlos').get()).data()!;
    expect(p.docsBlocked ?? false).toBe(false);
    expect(p.isAvailable).toBe(true);
  });

  it('sin docExpiryReminderDays: sin avisos, solo marca vencidos y alerta', async () => {
    await approvedDriver();
    clock = T0 + 25 * DAY;
    expect(await runDocExpiry(deps)).toMatchObject({ reminders: 0, expired: 0 });
    clock = T0 + 31 * DAY;
    expect(await runDocExpiry(deps)).toMatchObject({ expired: 1 });
  });

  it('blockOnExpiredDocs true: bloquea y saca de línea; el servidor no le asigna ni deja aceptar', async () => {
    await approvedDriver();
    await db.doc('config/ops').update({ blockOnExpiredDocs: true });
    clock = T0 + 31 * DAY;
    await runDocExpiry(deps);
    expect((await db.doc('driverProfiles/carlos').get()).data()).toMatchObject({ docsBlocked: true, isAvailable: false, online: false });
    await db.doc('bookings/b1').set({ riderId: 'ana', status: 'pending', driverId: null });
    await db.doc('bookings/b1/payment/state').set({ riderId: 'ana', paymentStatus: 'paid' });
    await db.doc('driverProfiles/carlos').update({ isAvailable: true }); // aunque lo forzara
    const r = await reason((acceptBookingFn as unknown as Runnable).run({
      auth: { uid: 'carlos', token: { role: 'driver' } }, data: { bookingId: 'b1' } }));
    expect(r.reason).toBe('driver_docs_blocked');
  });

  it('con un viaje en curso no lo saca de línea', async () => {
    await approvedDriver();
    await db.doc('config/ops').update({ blockOnExpiredDocs: true });
    await db.doc('bookings/viaje').set({ riderId: 'ana', driverId: 'carlos', status: 'in_progress' });
    clock = T0 + 31 * DAY;
    await runDocExpiry(deps);
    expect((await db.doc('driverProfiles/carlos').get()).data()).toMatchObject({ docsBlocked: true, isAvailable: true, online: true });
  });

  it('el admin autoriza con motivo y auditoría; sigue autorizado al volver a pasar la tarea', async () => {
    await approvedDriver();
    await db.doc('config/ops').update({ blockOnExpiredDocs: true });
    clock = T0 + 31 * DAY;
    await runDocExpiry(deps);
    await adminAllowDriverOnline(deps, ADMIN, { driverId: 'carlos', reason: 'Renovación en trámite (prueba)' });
    await runDocExpiry(deps);
    expect(await recomputeDocsBlock(deps, 'carlos')).toBe(false);
    expect((await db.collection('admin_logs').where('operation', '==', 'allow_driver_online_expired_docs').get()).size).toBe(1);
  });
});

describe('acceso y permisos', () => {
  it('URL firmada: cada llamada queda en la bitácora, sin la URL ni la ruta', async () => {
    await readyApplication();
    const r = await adminGetDocumentUrl(deps, ADMIN, { driverId: 'carlos', type: 'license_front' });
    expect(r.url).toContain('firma.ficticia.test');
    const logs = (await db.collection('driverDocAccessLogs').get()).docs.map((d) => d.data());
    expect(logs).toEqual([expect.objectContaining({ adminId: 'jefa', driverId: 'carlos', type: 'license_front', version: 1 })]);
    expect(JSON.stringify(logs)).not.toMatch(/https?:|driverDocs\//);
  });

  it('usuario ajeno (pasajero) no guarda pasos ni registra documentos', async () => {
    expect((await reason(saveDriverStep(deps, 'ana', PERSONAL))).reason).toBe('not_a_driver');
    expect((await reason(registerDocumentUpload(deps, 'ana', { type: 'profile_photo', version: 1 }))).reason)
      .toBe('not_a_driver');
    // Y la callable exige el rol de chófer.
    expect((await reason((saveStepFn as unknown as Runnable).run({ auth: { uid: 'ana', token: { role: 'rider' } },
      data: PERSONAL }))).reason).toBeDefined();
  });

  it('admin sin segundo factor (mfaEnforced): mfa_required', async () => {
    await db.doc('config/security').set({ mfaEnforced: true });
    const now = Math.floor(Date.now() / 1000);
    const r = await reason((decideFn as unknown as Runnable).run({ app: {},
      auth: { uid: 'jefa', token: { role: 'admin', auth_time: now, firebase: { sign_in_provider: 'password' } } },
      data: { driverId: 'carlos', decision: 'reject', reason: 'Prueba sin segundo factor' } }));
    expect(r.reason).toBe('mfa_required');
    await db.doc('config/security').delete();
  });

  it('con mfaEnforced, el chófer da de alta el TOTP antes de enviar (A10.3)', async () => {
    await readyApplication();
    await db.doc('config/security').set({ mfaEnforced: true });
    const now = Math.floor(Date.now() / 1000);
    const base = { app: {}, data: null };
    const noFactor = await reason((submitFn as unknown as Runnable).run({ ...base,
      auth: { uid: 'carlos', token: { role: 'driver', auth_time: now, firebase: { sign_in_provider: 'password' } } } }));
    expect(noFactor.reason).toBe('mfa_required');
    expect((await app())?.status).toBe('draft');
    expect((await getDriverApplication(deps, 'carlos')).mfaEnforced).toBe(true);
    const ok = await (submitFn as unknown as Runnable).run({ ...base, auth: { uid: 'carlos',
      token: { role: 'driver', auth_time: now, firebase: { sign_in_provider: 'password', sign_in_second_factor: 'totp' } } } });
    expect(ok).toEqual({ status: 'submitted' });
    await db.doc('config/security').delete();
  });

  it('el archivo aceptado queda sin caché (Cache-Control no-store) para el visor del panel', async () => {
    await saveDriverStep(deps, 'carlos', PERSONAL);
    await uploadAndRegister('carlos', 'profile_photo');
    const [md] = await bucket.file(storagePath('carlos', 'profile_photo', 1)).getMetadata();
    expect(md.cacheControl).toBe(NO_STORE);
  });

  it('vencimientos para el panel: vencidos y próximos, sin rutas ni datos personales', async () => {
    await readyApplication();
    await db.doc('driverApplications/otro').set({ driverId: 'otro', status: 'draft' });
    await db.doc('driverApplications/otro/documents/license_front')
      .set({ status: 'approved', version: 1, expiresAt: admin.firestore.Timestamp.fromMillis(clock - DAY) });
    // Otra subcolección llamada documents fuera del registro: no cuenta.
    await db.doc('otraCosa/x/documents/y').set({ expiresAt: admin.firestore.Timestamp.fromMillis(clock) });
    const r = await adminListDocExpiries(deps, ADMIN, { days: 60 });
    expect(r).toEqual({ truncated: false, items: [
      { driverId: 'otro', type: 'license_front', status: 'approved', expiresAt: clock - DAY },
      { driverId: 'carlos', type: 'license_front', status: 'uploaded', expiresAt: clock + 30 * DAY },
    ] });
    expect((await adminListDocExpiries(deps, ADMIN, { days: 10 })).items.map((i) => i.driverId)).toEqual(['otro']);
    await db.recursiveDelete(db.collection('otraCosa'));
  });

  it('purga manual: desactivada sin config/ops.driverDocsPurgeEnabled', async () => {
    await readyApplication();
    expect((await reason(adminPurgeDriverDocuments(deps, ADMIN, { driverId: 'carlos', reason: 'Prueba de purga desactivada' })))
      .reason).toBe('purge_disabled');
    const [exists] = await bucket.file('driverDocs/carlos/profile_photo/1').exists();
    expect(exists).toBe(true);
  });
});

describe('logs sin cédula, licencia, rutas, URLs ni nombres de archivo', () => {
  it('flujo completo y errores: nada sensible en lo que se registra', async () => {
    const captured: string[] = [];
    const spies = (['log', 'info', 'warn', 'error'] as const).map((m) =>
      jest.spyOn(console, m).mockImplementation((...a: unknown[]) => {
        captured.push(a.map((x) => (typeof x === 'string' ? x : JSON.stringify(x))).join(' '));
      }));
    try {
      await readyApplication();
      await upload('carlos', 'vehicle_photo_front', 1, FAKE, 'image/jpeg');
      await registerDocumentUpload(deps, 'carlos', { type: 'vehicle_photo_front', version: 1 }).catch(() => undefined);
      await submitApplication(deps, 'carlos');
      await adminGetDocumentUrl(deps, ADMIN, { driverId: 'carlos', type: 'license_front' });
      await db.doc('config/ops').update({ docExpiryReminderDays: [30], driverRequirements: [...REQS, { type: 'raro' }] });
      await runDocExpiry(deps);
    } finally {
      spies.forEach((s) => s.mockRestore());
    }
    const all = captured.join('\n');
    expect(captured.length).toBeGreaterThan(0);
    for (const s of ['9999999', 'LIC-FICTICIA', 'driverDocs/', 'firma.ficticia', 'PRB123', 'Chófer De Prueba']) {
      expect(all).not.toContain(s);
    }
  });
});
