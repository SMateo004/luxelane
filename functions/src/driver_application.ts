/**
 * Registro de chóferes (prompt de registro, Parte A): solicitud por pasos,
 * documentos en Cloud Storage (driverDocs/{uid}/{tipo}/{versión}), revisión
 * por un admin, vencimientos y bloqueo para ponerse en línea.
 *
 * Datos:
 * - driverApplications/{uid}: estado, paso y marcas de tiempo (lo lee el
 *   chófer dueño y el admin).
 * - driverApplications/{uid}/private/data: datos personales y del vehículo
 *   (solo el admin; el chófer los recupera con getDriverApplication).
 * - driverApplications/{uid}/documents/{tipo}: estado, versión, vencimiento y
 *   motivo de rechazo (chófer dueño y admin).
 * - driverApplications/{uid}/documentFiles/{tipo}: ruta, tamaño, tipo real y
 *   quién revisó (solo el admin).
 * - driverDocAccessLogs/{id}: quién vio qué documento y cuándo (solo admin,
 *   sin la URL).
 * Todo lo escribe el servidor. Qué documentos son obligatorios y cuáles
 * vencen sale de config/ops.driverRequirements (decisión del responsable).
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { AdminActor, reasonSchema, writeAudit } from './admin_audit';
import { adminSetVehicleActive, adminVerifyDriver } from './admin_ops';
import { VEHICLE_CLASSES } from './fare';
import { SNIFF_BYTES, sniffType, SniffedType } from './file_sniff';
import { AppLocale, localeOf, notice, NoticeType } from './i18n';
import { AuthAdmin, requireVerifiedEmail } from './identity';
import { logger } from './logger';
import { opsConfig } from './ops_config';
import { docId, parseInput } from './schemas';

// ---------------------------------------------------------------------------
// Listas fijas (código; los textos van por i18n)
// ---------------------------------------------------------------------------

export const DOC_TYPES = [
  'profile_photo', 'live_photo', 'national_id_front', 'national_id_back', 'license_front', 'license_back',
  'criminal_record', 'vehicle_ownership', 'vehicle_soat', 'vehicle_inspection', 'vehicle_insurance',
  'vehicle_permit', 'owner_authorization',
  'vehicle_photo_front', 'vehicle_photo_back', 'vehicle_photo_left', 'vehicle_photo_right',
  'vehicle_photo_interior_front', 'vehicle_photo_interior_back', 'vehicle_photo_plate',
] as const;
export type DocType = (typeof DOC_TYPES)[number];

/**
 * Documentos que admiten PDF (papeles); el resto solo imagen (fotos y
 * tarjetas). Decisión técnica, no legal: la misma lista está en
 * storage.rules.
 */
export const PDF_TYPES: readonly DocType[] = [
  'criminal_record', 'vehicle_ownership', 'vehicle_soat', 'vehicle_inspection', 'vehicle_insurance',
  'vehicle_permit', 'owner_authorization',
];

/** Tamaño máximo técnico por archivo (igual que storage.rules). */
export const MAX_FILE_BYTES = 10 * 1024 * 1024;

export const APP_STATUSES = ['draft', 'submitted', 'in_review', 'needs_changes', 'approved', 'rejected'] as const;
export type AppStatus = (typeof APP_STATUSES)[number];
export const DOC_STATUSES = ['pending_upload', 'uploaded', 'approved', 'rejected', 'expired'] as const;
export type DocStatus = (typeof DOC_STATUSES)[number];
export const STEPS = ['personal', 'vehicle', 'documents', 'review'] as const;
export const REJECT_REASONS = [
  'illegible', 'expired', 'wrong_document', 'incomplete', 'data_mismatch', 'low_quality', 'other',
] as const;
export const VEHICLE_COLORS = [
  'black', 'white', 'silver', 'gray', 'blue', 'red', 'green', 'beige', 'brown', 'other',
] as const;
export const BODY_TYPES = ['sedan', 'suv', 'van'] as const;
export const MIN_VEHICLE_YEAR = 1990;

const DAY_MS = 24 * 60 * 60 * 1000;
const URL_TTL_MS = 5 * 60 * 1000;

// ---------------------------------------------------------------------------
// Dependencias
// ---------------------------------------------------------------------------

/** Lo que el registro necesita del almacenamiento (sustituible en tests). */
export interface DocStore {
  /** null si no existe. */
  metadata(path: string): Promise<{ size: number; contentType: string | null } | null>;
  head(path: string, bytes: number): Promise<Uint8Array>;
  /** URL de lectura firmada que caduca en [ttlMs]. */
  signedReadUrl(path: string, ttlMs: number): Promise<string>;
  markInvalid(path: string, reason: string): Promise<void>;
  deletePrefix(prefix: string): Promise<number>;
}

export function gcsDocStore(bucket: { file: (p: string) => any; deleteFiles: (o: { prefix: string }) => Promise<unknown>;
  getFiles: (o: { prefix: string }) => Promise<unknown[]> }): DocStore {
  return {
    async metadata(path) {
      const f = bucket.file(path);
      const [exists] = await f.exists();
      if (!exists) return null;
      const [md] = await f.getMetadata();
      return { size: Number(md.size ?? 0), contentType: (md.contentType as string | undefined) ?? null };
    },
    async head(path, bytes) {
      const [buf] = await bucket.file(path).download({ start: 0, end: bytes - 1 });
      return new Uint8Array(buf);
    },
    async signedReadUrl(path, ttlMs) {
      // Requiere que la cuenta de servicio de las functions pueda firmar
      // (iam.serviceAccounts.signBlob): ver DEPLOY.md. NO VERIFICADO.
      const [url] = await bucket.file(path).getSignedUrl({
        version: 'v4', action: 'read', expires: Date.now() + ttlMs,
        responseDisposition: 'inline', extensionHeaders: {},
      });
      return url;
    },
    async markInvalid(path, reason) {
      await bucket.file(path).setMetadata({ metadata: { luxelaneInvalid: reason } });
    },
    async deletePrefix(prefix) {
      const [files] = (await bucket.getFiles({ prefix })) as [unknown[]];
      await bucket.deleteFiles({ prefix });
      return files.length;
    },
  };
}

export interface RegDeps {
  db: admin.firestore.Firestore;
  store: DocStore;
  now?: () => number;
  /** Push al chófer; sin él, solo la bandeja. */
  push?: (tokens: string[], title: string, body: string, data: Record<string, string>) => Promise<void>;
}

const nowMs = (d: RegDeps) => d.now?.() ?? Date.now();
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const regError = (code: 'failed-precondition' | 'not-found' | 'invalid-argument' | 'permission-denied',
  reason: string, extra: Record<string, unknown> = {}) => new HttpsError(code, reason, { reason, ...extra });

export const appRef = (db: admin.firestore.Firestore, uid: string) => db.collection('driverApplications').doc(uid);
const privateRef = (db: admin.firestore.Firestore, uid: string) => appRef(db, uid).collection('private').doc('data');
const docRef = (db: admin.firestore.Firestore, uid: string, type: string) => appRef(db, uid).collection('documents').doc(type);
const fileRef = (db: admin.firestore.Firestore, uid: string, type: string) =>
  appRef(db, uid).collection('documentFiles').doc(type);
export const storagePath = (uid: string, type: string, version: number) => `driverDocs/${uid}/${type}/${version}`;

// ---------------------------------------------------------------------------
// Requisitos (config/ops)
// ---------------------------------------------------------------------------

export interface Requirement { type: DocType; required: boolean; expires: boolean }

const requirementSchema = z.strictObject({ type: z.enum(DOC_TYPES), required: z.boolean(), expires: z.boolean() });

/**
 * config/ops.driverRequirements. null si no existe o no es una lista: el
 * chófer puede avanzar pero no enviar, y el admin ve «requisitos sin
 * configurar». Las entradas mal formadas se ignoran (y se avisa en el log
 * solo con el índice).
 */
export function readRequirements(ops: Record<string, unknown>): Requirement[] | null {
  const raw = ops.driverRequirements;
  if (!Array.isArray(raw)) return null;
  const out: Requirement[] = [];
  raw.forEach((r, i) => {
    const p = requirementSchema.safeParse(r);
    if (p.success && !out.some((o) => o.type === p.data.type)) out.push(p.data);
    else logger.warn('driverRequirements', 'invalid entry ignored', { index: i });
  });
  return out;
}

/** config/ops.vehicleMinYear: { clase: año }. Sin el valor, no se comprueba. */
export function minYearFor(ops: Record<string, unknown>, vehicleClass: string): number | null {
  const m = ops.vehicleMinYear;
  if (!m || typeof m !== 'object') return null;
  const v = (m as Record<string, unknown>)[vehicleClass];
  return typeof v === 'number' && Number.isInteger(v) ? v : null;
}

/** config/ops.docExpiryReminderDays: días antes del vencimiento (enteros > 0). */
export function reminderDays(ops: Record<string, unknown>): number[] {
  const r = ops.docExpiryReminderDays;
  return Array.isArray(r) ? [...new Set(r.filter((d): d is number => Number.isInteger(d) && d > 0))].sort((a, b) => b - a) : [];
}

// ---------------------------------------------------------------------------
// Pasos (saveDriverStep)
// ---------------------------------------------------------------------------

// Controles y saltos de línea fuera; espacios simples.
const CONTROL = new RegExp('[\\u0000-\\u001F\\u007F-\\u009F\\u2028\\u2029\\u200B-\\u200F\\u202A-\\u202E\\u2060-\\u2069\\uFEFF]', 'g');
export const cleanText = (s: string) => s.replace(CONTROL, ' ').replace(/\s+/g, ' ').trim();
const text = (min: number, max: number) => z.string().max(max * 2).transform(cleanText)
  .refine((s) => s.length >= min && s.length <= max, { message: 'length' });

/** Placa: mayúsculas, solo letras y números (sin formato nacional concreto). */
export const normalizePlate = (s: string) => s.toUpperCase().replace(/[\s.-]/g, '');
const plateSchema = z.string().max(30).transform(normalizePlate)
  .refine((p) => /^[A-Z0-9]{4,10}$/.test(p), { message: 'plate' });
const idNumber = z.string().max(40).transform((s) => s.toUpperCase().replace(/\s+/g, ''))
  .refine((s) => /^[A-Z0-9-]{4,20}$/.test(s), { message: 'format' });

export const personalStepSchema = z.strictObject({
  step: z.literal('personal'),
  fullName: text(2, 120),
  nationalIdNumber: idNumber,
  licenseNumber: idNumber,
  /** Vencimiento de la licencia, ms UTC. */
  licenseExpiry: z.number().int().positive().max(4_102_444_800_000),
});

export const vehicleStepSchema = z.strictObject({
  step: z.literal('vehicle'),
  make: text(1, 40),
  model: text(1, 40),
  year: z.number().int(),
  color: z.enum(VEHICLE_COLORS),
  colorOther: text(1, 20).optional(),
  plate: plateSchema,
  bodyType: z.enum(BODY_TYPES),
  passengers: z.number().int().min(1).max(8),
  vehicleClass: z.enum(VEHICLE_CLASSES),
}).refine((v) => (v.color === 'other') === (v.colorOther !== undefined), { message: 'colorOther', path: ['colorOther'] });

export const stepSchema = z.union([personalStepSchema, vehicleStepSchema]);

async function requireDriver(db: admin.firestore.Firestore, uid: string | undefined): Promise<string> {
  if (!uid) throw new HttpsError('unauthenticated', 'unauthenticated', { reason: 'unauthenticated' });
  const u = (await db.collection('users').doc(uid).get()).data();
  if (!u || u.role !== 'driver' || u.isActive === false) throw regError('permission-denied', 'not_a_driver');
  return uid;
}

export interface StartDeps {
  db: admin.firestore.Firestore;
  auth: AuthAdmin;
  now?: () => number;
}

/**
 * El aspirante abre su solicitud (A10): una cuenta de pasajero activa, con
 * el correo verificado y sin reservas, pasa a role=driver por el mismo
 * camino que setUserRole (users/{uid}.role, claim y auditoría) y queda con
 * driverApplications/{uid} en draft y un perfil sin verificar
 * (documentsVerified false). Es de un solo sentido: la cuenta de chófer no
 * es la de pasajero. Idempotente: si ya es chófer, devuelve su solicitud
 * (y la crea si el admin le dio el rol sin solicitud).
 *
 * No revoca las sesiones (setUserRole sí): la app pide un token nuevo
 * (getIdToken(true)) para llevar el claim nuevo.
 */
export async function startDriverApplication(deps: StartDeps, uid: string | undefined,
  token: Record<string, unknown> | undefined) {
  if (!uid) throw new HttpsError('unauthenticated', 'unauthenticated', { reason: 'unauthenticated' });
  requireVerifiedEmail(token);
  const db = deps.db;
  const now = ts(deps.now?.() ?? Date.now());
  const uRef = db.collection('users').doc(uid);
  const aRef = appRef(db, uid);
  const profileRef = db.collection('driverProfiles').doc(uid);

  const result = await db.runTransaction(async (tx) => {
    const [u, app, profile] = await Promise.all([tx.get(uRef), tx.get(aRef), tx.get(profileRef)]);
    const user = u.data();
    if (!user) throw regError('not-found', 'profile_not_found');
    if (user.isActive === false) throw regError('permission-denied', 'inactive_user');
    if (user.role === 'admin') throw regError('permission-denied', 'admin_account');
    if (user.role !== 'rider' && user.role !== 'driver') throw regError('permission-denied', 'not_a_rider');
    if (user.role === 'driver' && app.exists) {
      return { status: app.data()?.status as AppStatus, created: false, roleChanged: false };
    }
    if (user.role === 'rider') {
      // Sin reservas, de ningún estado: el historial de pasajero no pasa a
      // una cuenta de chófer.
      const booked = await tx.get(db.collection('bookings').where('riderId', '==', uid).limit(1));
      if (!booked.empty) throw regError('failed-precondition', 'has_bookings');
      tx.update(uRef, { role: 'driver', roleUpdatedAt: now });
    }
    tx.create(aRef, { driverId: uid, status: 'draft', step: 'personal', createdAt: now, updatedAt: now });
    if (!profile.exists) {
      tx.create(profileRef, { userId: uid, documentsVerified: false, isAvailable: false, online: false });
    }
    writeAudit(tx, db, {
      actor: { adminId: uid, adminEmail: null }, actorRole: user.role as string,
      operation: 'start_driver_application', collection: 'users', docId: uid, targetType: 'user',
      changes: user.role === 'rider' ? { role: { before: 'rider', after: 'driver' } } : {},
      reason: null, details: user.role === 'rider' ? 'rider → driver (solicitud de chófer)' : 'Solicitud de chófer abierta',
    });
    return { status: 'draft' as AppStatus, created: true, roleChanged: user.role === 'rider' };
  });

  // Claim después de Firestore: si falla, al reintentar se vuelve a fijar.
  const authUser = await deps.auth.getUser(uid);
  if (authUser.customClaims?.role !== 'driver') {
    await deps.auth.setCustomUserClaims(uid, { ...(authUser.customClaims ?? {}), role: 'driver' });
  }
  return { status: result.status, created: result.created, roleChanged: result.roleChanged, refreshToken: true };
}

/** Guarda un paso; reanudable: cada paso se puede volver a enviar. */
export async function saveDriverStep(deps: RegDeps, uid: string | undefined, data: unknown) {
  const id = await requireDriver(deps.db, uid);
  const input = parseInput(stepSchema, data);
  const db = deps.db;
  const now = ts(nowMs(deps));
  const ops = await opsConfig(db, nowMs(deps));

  if (input.step === 'vehicle') {
    const thisYear = new Date(nowMs(deps)).getUTCFullYear();
    const min = Math.max(MIN_VEHICLE_YEAR, minYearFor(ops, input.vehicleClass) ?? MIN_VEHICLE_YEAR);
    if (input.year < min || input.year > thisYear + 1) {
      throw regError('invalid-argument', 'invalid_request', { fields: ['year'] });
    }
  }

  return db.runTransaction(async (tx) => {
    const aRef = appRef(db, id);
    const pRef = privateRef(db, id);
    const profileRef = db.collection('driverProfiles').doc(id);
    const [app, priv, profile] = await Promise.all([tx.get(aRef), tx.get(pRef), tx.get(profileRef)]);
    const status = (app.data()?.status as AppStatus | undefined) ?? 'draft';
    if (status === 'rejected') throw regError('failed-precondition', 'application_closed');
    const approved = status === 'approved' || profile.data()?.documentsVerified === true;

    if (input.step === 'personal') {
      // Tras aprobar, licencia y datos personales los cambia el admin (H4).
      if (approved) throw regError('failed-precondition', 'locked_after_approval');
      const { step: _s, ...personal } = input;
      tx.set(pRef, { personal: { ...personal, licenseExpiry: ts(personal.licenseExpiry) }, updatedAt: now }, { merge: true });
      tx.set(profileRef, {
        userId: id, licenseNumber: personal.licenseNumber, licenseExpiry: ts(personal.licenseExpiry),
        ...(profile.exists ? {} : { documentsVerified: false, isAvailable: false, online: false }),
      }, { merge: true });
    } else {
      // Placa única entre vehículos activos (de otros chóferes o los suyos).
      const dup = await tx.get(db.collection('vehicles').where('plate', '==', input.plate).where('isActive', '==', true));
      if (dup.docs.some((d) => d.data().driverId !== id)) {
        throw regError('failed-precondition', 'plate_in_use', { fields: ['plate'] });
      }
      const prev = priv.data()?.vehicleId as string | undefined;
      const prevSnap = prev ? await tx.get(db.collection('vehicles').doc(prev)) : null;
      // Antes de aprobar se corrige el borrador; tras aprobar, un vehículo
      // nuevo inactivo que queda en revisión.
      const reuse = prevSnap?.exists && prevSnap.data()?.isActive !== true;
      const vRef = reuse ? prevSnap!.ref : db.collection('vehicles').doc();
      const vehicle = {
        id: vRef.id, driverId: id, make: input.make, model: input.model, year: input.year, color: input.color,
        colorOther: input.colorOther ?? null, plate: input.plate, bodyType: input.bodyType, capacity: input.passengers,
        class: input.vehicleClass, isActive: false, updatedAt: now,
      };
      tx.set(vRef, vehicle, { merge: true });
      const { updatedAt: _u, ...saved } = vehicle;
      tx.set(pRef, { vehicle: saved, vehicleId: vRef.id, updatedAt: now }, { merge: true });
      if (!approved) tx.set(profileRef, { userId: id, vehicleId: vRef.id }, { merge: true });
      if (approved && vRef.id !== prev) {
        tx.set(aRef, { status: 'in_review', pendingVehicleId: vRef.id, updatedAt: now }, { merge: true });
      }
    }
    const nextStep = input.step === 'personal' ? 'vehicle' : 'documents';
    if (!app.exists) {
      tx.set(aRef, { driverId: id, status: 'draft', step: nextStep, createdAt: now, updatedAt: now });
    } else if (!approved) {
      const cur = STEPS.indexOf(app.data()?.step ?? 'personal');
      tx.set(aRef, { step: STEPS[Math.max(cur, STEPS.indexOf(nextStep))], updatedAt: now }, { merge: true });
    }
    return { step: input.step, saved: true };
  });
}

/** Lo que el chófer guardó (para reanudar), su estado y sus documentos. */
export async function getDriverApplication(deps: RegDeps, uid: string | undefined) {
  const id = await requireDriver(deps.db, uid);
  const db = deps.db;
  const [app, priv, docs, ops] = await Promise.all([
    appRef(db, id).get(), privateRef(db, id).get(), appRef(db, id).collection('documents').get(),
    opsConfig(db, nowMs(deps)),
  ]);
  const p = priv.data() ?? {};
  const personal = p.personal ? { ...p.personal, licenseExpiry: (p.personal.licenseExpiry as admin.firestore.Timestamp)?.toMillis?.() ?? null } : null;
  const v = p.vehicle ?? null;
  return {
    status: app.data()?.status ?? 'draft',
    step: app.data()?.step ?? 'personal',
    requirementsConfigured: readRequirements(ops) !== null,
    requirements: readRequirements(ops) ?? [],
    personal,
    vehicle: v ? { make: v.make, model: v.model, year: v.year, color: v.color, colorOther: v.colorOther ?? null,
      plate: v.plate, bodyType: v.bodyType, passengers: v.capacity, vehicleClass: v.class } : null,
    documents: docs.docs.map((d) => {
      const x = d.data();
      return { type: d.id, status: x.status, version: x.version ?? 0,
        expiresAt: x.expiresAt?.toMillis?.() ?? null, rejectReason: x.rejectReason ?? null, rejectNote: x.rejectNote ?? null };
    }),
  };
}

// ---------------------------------------------------------------------------
// Subida (registerDocumentUpload)
// ---------------------------------------------------------------------------

export const uploadSchema = z.strictObject({
  type: z.enum(DOC_TYPES),
  version: z.number().int().min(1).max(999_999),
  /** Vencimiento del documento, ms UTC (obligatorio si el tipo vence). */
  expiresAt: z.number().int().positive().max(4_102_444_800_000).optional(),
});

const allowedFor = (type: DocType, real: SniffedType) =>
  real === 'application/pdf' ? PDF_TYPES.includes(type) : true;

/**
 * El chófer ya subió driverDocs/{uid}/{tipo}/{versión}: se comprueba que
 * existe, su tamaño y su tipo real; si no cumple, se marca el objeto y se
 * rechaza. Idempotente por versión.
 */
export async function registerDocumentUpload(deps: RegDeps, uid: string | undefined, data: unknown) {
  const id = await requireDriver(deps.db, uid);
  const input = parseInput(uploadSchema, data);
  const db = deps.db;
  const nowMillis = nowMs(deps);
  const ops = await opsConfig(db, nowMillis);
  const req = readRequirements(ops)?.find((r) => r.type === input.type);
  if (req?.expires && input.expiresAt === undefined) {
    throw regError('invalid-argument', 'invalid_request', { fields: ['expiresAt'] });
  }
  if (input.expiresAt !== undefined && input.expiresAt <= nowMillis) {
    throw regError('invalid-argument', 'document_expired', { fields: ['expiresAt'] });
  }

  const current = (await docRef(db, id, input.type).get()).data();
  if (current?.version === input.version && current?.status !== 'pending_upload') {
    return { type: input.type, version: input.version, status: current.status as DocStatus };
  }
  const expected = (current?.version ?? 0) + 1;
  if (input.version !== expected) throw regError('failed-precondition', 'unexpected_version', { fields: ['version'] });

  // La ruta la construye el servidor con el uid de la sesión: un chófer no
  // puede registrar el archivo de otro.
  const path = storagePath(id, input.type, input.version);
  const md = await deps.store.metadata(path);
  if (!md) throw regError('failed-precondition', 'file_missing');
  let invalid: string | null = null;
  let real: SniffedType | null = null;
  if (md.size <= 0 || md.size > MAX_FILE_BYTES) invalid = 'size';
  else {
    real = sniffType(await deps.store.head(path, SNIFF_BYTES));
    if (!real) invalid = 'type';
    else if (!allowedFor(input.type, real)) invalid = 'type_not_allowed';
  }
  if (invalid) {
    await deps.store.markInvalid(path, invalid);
    await fileRef(db, id, input.type).set({
      lastInvalid: { version: input.version, reason: invalid, at: ts(nowMillis) },
    }, { merge: true });
    // Solo tipo y motivo en el log: nunca la ruta ni el nombre del archivo.
    logger.warn('registerDocumentUpload', 'invalid file', { type: input.type, reason: invalid });
    throw regError('invalid-argument', 'invalid_file', { fields: ['file'] });
  }

  const now = ts(nowMillis);
  return db.runTransaction(async (tx) => {
    const aRef = appRef(db, id);
    const [app, cur] = await Promise.all([tx.get(aRef), tx.get(docRef(db, id, input.type))]);
    if ((cur.data()?.version ?? 0) + 1 !== input.version) throw regError('failed-precondition', 'unexpected_version');
    const status = (app.data()?.status as AppStatus | undefined) ?? 'draft';
    if (status === 'rejected') throw regError('failed-precondition', 'application_closed');
    tx.set(docRef(db, id, input.type), {
      type: input.type, status: 'uploaded', version: input.version,
      expiresAt: input.expiresAt !== undefined ? ts(input.expiresAt) : null,
      uploadedAt: now, rejectReason: null, rejectNote: null, reviewedAt: null, remindedDays: [],
    });
    tx.set(fileRef(db, id, input.type), {
      path, size: md.size, contentType: real, version: input.version, uploadedAt: now, reviewedBy: null,
    }, { merge: true });
    if (!app.exists) tx.set(aRef, { driverId: id, status: 'draft', step: 'documents', createdAt: now, updatedAt: now });
    // Un documento nuevo tras aprobar (o tras pedir cambios) vuelve a revisión.
    else if (status === 'approved' || status === 'needs_changes') {
      tx.set(aRef, { status: status === 'approved' ? 'in_review' : 'needs_changes', updatedAt: now }, { merge: true });
    } else tx.set(aRef, { updatedAt: now }, { merge: true });
    return { type: input.type, version: input.version, status: 'uploaded' as DocStatus };
  });
}

// ---------------------------------------------------------------------------
// Envío (submitApplication)
// ---------------------------------------------------------------------------

/** Qué falta para enviar: obligatorios sin subir, vencidos o sin fecha. */
export function missingRequirements(reqs: Requirement[], docs: Map<string, admin.firestore.DocumentData>,
  nowMillis: number, accepted: DocStatus[] = ['uploaded', 'approved']): string[] {
  return reqs.filter((r) => r.required).filter((r) => {
    const d = docs.get(r.type);
    if (!d || !accepted.includes(d.status)) return true;
    if (r.expires) {
      const e = d.expiresAt?.toMillis?.();
      return typeof e !== 'number' || e <= nowMillis;
    }
    return false;
  }).map((r) => r.type);
}

export async function submitApplication(deps: RegDeps, uid: string | undefined) {
  const id = await requireDriver(deps.db, uid);
  const db = deps.db;
  const nowMillis = nowMs(deps);
  const reqs = readRequirements(await opsConfig(db, nowMillis));
  if (!reqs) throw regError('failed-precondition', 'requirements_not_configured');
  return db.runTransaction(async (tx) => {
    const aRef = appRef(db, id);
    const [app, priv, docs] = await Promise.all([tx.get(aRef), tx.get(privateRef(db, id)),
      tx.get(aRef.collection('documents'))]);
    const status = (app.data()?.status as AppStatus | undefined) ?? 'draft';
    if (status === 'submitted' || status === 'in_review') return { status };
    if (status === 'approved' || status === 'rejected') throw regError('failed-precondition', 'application_closed');
    const p = priv.data() ?? {};
    const steps = [!p.personal ? 'personal' : null, !p.vehicle ? 'vehicle' : null].filter(Boolean) as string[];
    if (steps.length) throw regError('failed-precondition', 'steps_incomplete', { fields: steps });
    const missing = missingRequirements(reqs, new Map(docs.docs.map((d) => [d.id, d.data()])), nowMillis);
    if (missing.length) throw regError('failed-precondition', 'documents_missing', { fields: missing });
    const now = ts(nowMillis);
    tx.set(aRef, { status: 'submitted', step: 'review', submittedAt: now, updatedAt: now }, { merge: true });
    // Sin datos personales: central abre la solicitud en el panel.
    tx.set(db.collection('adminAlerts').doc(), {
      type: 'driver_application_submitted', severity: 'low', driverId: id, resolved: false, createdAt: now,
      message: 'Solicitud de chófer enviada para revisión.',
    });
    return { status: 'submitted' as AppStatus };
  });
}

// ---------------------------------------------------------------------------
// Revisión (admin)
// ---------------------------------------------------------------------------

export const docUrlSchema = z.strictObject({ driverId: docId, type: z.enum(DOC_TYPES) });

/** URL firmada de pocos minutos; cada llamada queda en la bitácora de accesos. */
export async function adminGetDocumentUrl(deps: RegDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(docUrlSchema, data);
  const db = deps.db;
  const file = (await fileRef(db, input.driverId, input.type).get()).data();
  if (!file?.path) throw regError('not-found', 'document_not_found');
  const nowMillis = nowMs(deps);
  const url = await deps.store.signedReadUrl(file.path as string, URL_TTL_MS);
  // Quién y cuándo; ni la URL ni la ruta.
  await db.collection('driverDocAccessLogs').add({
    adminId: actor.adminId, adminEmail: actor.adminEmail, driverId: input.driverId, type: input.type,
    version: file.version ?? null, at: ts(nowMillis),
  });
  return { url, expiresAt: nowMillis + URL_TTL_MS, contentType: file.contentType ?? null };
}

export const reviewSchema = z.strictObject({
  driverId: docId,
  type: z.enum(DOC_TYPES),
  version: z.number().int().min(1),
  decision: z.enum(['approve', 'reject']),
  rejectReason: z.enum(REJECT_REASONS).optional(),
  note: z.string().max(1000).transform(cleanText).optional(),
}).refine((r) => r.decision === 'approve' || r.rejectReason !== undefined, { message: 'reason', path: ['rejectReason'] });

export async function adminReviewDocument(deps: RegDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(reviewSchema, data);
  const db = deps.db;
  const now = ts(nowMs(deps));
  const result = await db.runTransaction(async (tx) => {
    const aRef = appRef(db, input.driverId);
    const dRef = docRef(db, input.driverId, input.type);
    const [app, doc] = await Promise.all([tx.get(aRef), tx.get(dRef)]);
    if (!doc.exists) throw regError('not-found', 'document_not_found');
    const d = doc.data()!;
    if (d.version !== input.version) throw regError('failed-precondition', 'stale_version');
    if (!['uploaded', 'approved', 'rejected'].includes(d.status)) throw regError('failed-precondition', 'not_reviewable');
    const status: DocStatus = input.decision === 'approve' ? 'approved' : 'rejected';
    const after = {
      status, reviewedAt: now,
      rejectReason: status === 'rejected' ? input.rejectReason : null,
      rejectNote: status === 'rejected' ? (input.note || null) : null,
    };
    tx.update(dRef, after);
    tx.set(fileRef(db, input.driverId, input.type), { reviewedBy: actor.adminId, reviewedAt: now }, { merge: true });
    if (app.data()?.status === 'submitted') tx.update(aRef, { status: 'in_review', updatedAt: now });
    writeAudit(tx, db, {
      actor, operation: status === 'approved' ? 'approve_driver_document' : 'reject_driver_document',
      collection: 'driverApplications', docId: input.driverId, targetType: 'driver_document',
      changes: { [input.type]: { before: d.status, after: status } }, reason: input.note || null,
      details: `Documento ${input.type} v${input.version}${status === 'rejected' ? ` rechazado (${input.rejectReason})` : ' aprobado'}`,
    });
    return { type: input.type, status };
  });
  if (result.status === 'approved') await recomputeDocsBlock(deps, input.driverId);
  return result;
}

export const decideSchema = z.strictObject({
  driverId: docId,
  decision: z.enum(['approve', 'needs_changes', 'reject']),
  reason: reasonSchema,
});

const DECISION_STATUS: Record<'approve' | 'needs_changes' | 'reject', AppStatus> = {
  approve: 'approved', needs_changes: 'needs_changes', reject: 'rejected',
};
const DECISION_NOTICE: Record<'approve' | 'needs_changes' | 'reject', NoticeType> = {
  approve: 'driver_application_approved', needs_changes: 'driver_application_needs_changes',
  reject: 'driver_application_rejected',
};

/**
 * Aprobar exige todos los obligatorios aprobados y vigentes, y verifica con
 * los caminos de siempre: adminVerifyDriver (sin activar vehículos) y
 * adminSetVehicleActive para el vehículo de la solicitud.
 */
export async function adminDecideApplication(deps: RegDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(decideSchema, data);
  const db = deps.db;
  const nowMillis = nowMs(deps);
  const aRef = appRef(db, input.driverId);
  const [app, priv, docs] = await Promise.all([aRef.get(), privateRef(db, input.driverId).get(), aRef.collection('documents').get()]);
  if (!app.exists) throw regError('not-found', 'application_not_found');
  const status = app.data()!.status as AppStatus;
  if (!['submitted', 'in_review', 'needs_changes'].includes(status)) throw regError('failed-precondition', 'not_decidable');

  if (input.decision === 'approve') {
    const reqs = readRequirements(await opsConfig(db, nowMillis));
    if (!reqs) throw regError('failed-precondition', 'requirements_not_configured');
    const missing = missingRequirements(reqs, new Map(docs.docs.map((d) => [d.id, d.data()])), nowMillis, ['approved']);
    if (missing.length) throw regError('failed-precondition', 'documents_not_approved', { fields: missing });
    const vehicleId = (app.data()!.pendingVehicleId ?? priv.data()?.vehicleId) as string | undefined;
    if (!vehicleId) throw regError('failed-precondition', 'steps_incomplete', { fields: ['vehicle'] });
    const adminDeps = { db, now: deps.now };
    try {
      await adminVerifyDriver(adminDeps, actor, { driverId: input.driverId, vehicleReviewed: false, reason: input.reason });
    } catch (e) {
      // Ya verificado (cambio de vehículo o de documento): sigue.
      if (((e as HttpsError).details as { reason?: string } | undefined)?.reason !== 'no_change') throw e;
    }
    const vehicle = await db.collection('vehicles').doc(vehicleId).get();
    if (vehicle.data()?.isActive !== true) {
      await adminSetVehicleActive(adminDeps, actor, { vehicleId, active: true, reason: input.reason });
    }
    // El vehículo anterior sale de servicio cuando se aprueba el nuevo.
    const profile = await db.collection('driverProfiles').doc(input.driverId).get();
    const previous = profile.data()?.vehicleId as string | undefined;
    if (previous && previous !== vehicleId) {
      const prev = await db.collection('vehicles').doc(previous).get();
      if (prev.data()?.isActive === true) {
        await adminSetVehicleActive(adminDeps, actor, { vehicleId: previous, active: false, reason: input.reason });
      }
    }
    await db.collection('driverProfiles').doc(input.driverId).set({ vehicleId }, { merge: true });
  }

  const now = ts(nowMillis);
  const next = DECISION_STATUS[input.decision];
  await db.runTransaction(async (tx) => {
    const cur = await tx.get(aRef);
    tx.update(aRef, {
      status: next, decidedAt: now, updatedAt: now,
      ...(input.decision === 'approve' ? { pendingVehicleId: admin.firestore.FieldValue.delete() } : {}),
    });
    writeAudit(tx, db, {
      actor, operation: `driver_application_${input.decision}`, collection: 'driverApplications', docId: input.driverId,
      targetType: 'driver_application', changes: { status: { before: cur.data()?.status, after: next } },
      reason: input.reason, details: `Solicitud de chófer: ${next}`,
    });
    await notifyDriver(deps, tx, input.driverId, DECISION_NOTICE[input.decision], {}, now);
  });
  if (input.decision === 'approve') await recomputeDocsBlock(deps, input.driverId);
  return { driverId: input.driverId, status: next };
}

/** Aviso al chófer en su idioma (bandeja en la transacción; push después). */
async function notifyDriver(deps: RegDeps, tx: admin.firestore.Transaction | null, uid: string, type: NoticeType,
  params: Record<string, string>, at: admin.firestore.Timestamp): Promise<void> {
  const db = deps.db;
  const user = (await db.collection('users').doc(uid).get()).data();
  const locale: AppLocale = localeOf(user);
  const n = notice(type, locale, params);
  const ref = db.collection('users').doc(uid).collection('notifications').doc();
  const doc = { id: ref.id, userId: uid, title: n.title, body: n.body, type, locale, isRead: false, createdAt: at };
  if (tx) tx.set(ref, doc); else await ref.set(doc);
  const tokens = (user?.fcmTokens as string[] | undefined) ?? [];
  if (tokens.length && deps.push) {
    deps.push(tokens, n.title, n.body, { type }).catch((e) =>
      logger.warn('driverRegistration', 'push failed', { type, error: String(e) }));
  }
}

// ---------------------------------------------------------------------------
// Vencimientos y bloqueo para ponerse en línea
// ---------------------------------------------------------------------------

/** Obligatorios vencidos de un chófer: { tipo: versión }. */
async function expiredRequired(db: admin.firestore.Firestore, uid: string, reqs: Requirement[] | null,
  nowMillis: number): Promise<Record<string, number>> {
  if (!reqs) return {};
  const required = reqs.filter((r) => r.required && r.expires).map((r) => r.type);
  if (!required.length) return {};
  const docs = await appRef(db, uid).collection('documents').get();
  const out: Record<string, number> = {};
  for (const d of docs.docs) {
    const e = d.data().expiresAt?.toMillis?.();
    if (required.includes(d.id as DocType) && (d.data().status === 'expired' || (typeof e === 'number' && e <= nowMillis))) {
      out[d.id] = d.data().version ?? 0;
    }
  }
  return out;
}

const sameOrSubset = (a: Record<string, number>, b: Record<string, number> | undefined) =>
  !!b && Object.entries(a).every(([k, v]) => b[k] === v);

/**
 * docsBlocked en driverProfiles: true solo si config/ops.blockOnExpiredDocs
 * es true, hay un obligatorio vencido y el admin no lo autorizó para esas
 * versiones. Al bloquear, si no está en un viaje, sale de línea; un viaje en
 * curso nunca se corta. Las reglas y el servidor impiden volver a línea.
 */
export async function recomputeDocsBlock(deps: RegDeps, uid: string): Promise<boolean> {
  const db = deps.db;
  const nowMillis = nowMs(deps);
  const ops = await opsConfig(db, nowMillis);
  const profileRef = db.collection('driverProfiles').doc(uid);
  const expired = await expiredRequired(db, uid, readRequirements(ops), nowMillis);
  const activeTrip = await db.collection('bookings').where('driverId', '==', uid)
    .where('status', 'in', ['confirmed', 'driver_arriving', 'driver_arrived', 'verified', 'in_progress']).limit(1).get();
  return db.runTransaction(async (tx) => {
    const p = await tx.get(profileRef);
    if (!p.exists) return false;
    const blocked = ops.blockOnExpiredDocs === true && Object.keys(expired).length > 0 &&
      !sameOrSubset(expired, p.data()?.docsBlockOverride?.versions);
    const update: Record<string, unknown> = {};
    if ((p.data()?.docsBlocked === true) !== blocked) update.docsBlocked = blocked;
    if (blocked && activeTrip.empty && (p.data()?.isAvailable || p.data()?.online)) {
      update.isAvailable = false;
      update.online = false;
    }
    if (Object.keys(update).length) tx.update(profileRef, update);
    return blocked;
  });
}

/** El admin autoriza a ponerse en línea pese a los vencidos actuales. */
export const overrideSchema = z.strictObject({ driverId: docId, reason: reasonSchema });

export async function adminAllowDriverOnline(deps: RegDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(overrideSchema, data);
  const db = deps.db;
  const nowMillis = nowMs(deps);
  const expired = await expiredRequired(db, input.driverId, readRequirements(await opsConfig(db, nowMillis)), nowMillis);
  const ref = db.collection('driverProfiles').doc(input.driverId);
  return db.runTransaction(async (tx) => {
    const p = await tx.get(ref);
    if (!p.exists) throw regError('not-found', 'driver_not_found');
    const override = { versions: expired, by: actor.adminId, at: ts(nowMillis), reason: input.reason };
    tx.update(ref, { docsBlocked: false, docsBlockOverride: override });
    writeAudit(tx, db, {
      actor, operation: 'allow_driver_online_expired_docs', collection: 'driverProfiles', docId: input.driverId,
      targetType: 'driver', changes: { docsBlocked: { before: p.data()?.docsBlocked === true, after: false } },
      reason: input.reason, details: `Autorizado en línea con documentos vencidos: ${Object.keys(expired).join(', ') || 'ninguno'}`,
    });
    return { driverId: input.driverId, docsBlocked: false };
  });
}

/**
 * Tarea diaria: avisos a los días de config/ops.docExpiryReminderDays,
 * marca vencidos, una alerta a central por documento y versión, y recalcula
 * el bloqueo. Sin docExpiryReminderDays, solo marca vencidos y alerta.
 */
export async function runDocExpiry(deps: RegDeps) {
  const db = deps.db;
  const nowMillis = nowMs(deps);
  const ops = await opsConfig(db, nowMillis);
  const days = reminderDays(ops);
  const horizon = nowMillis + (days[0] ?? 0) * DAY_MS;
  const snap = await db.collectionGroup('documents').where('expiresAt', '<=', ts(horizon)).get();
  const touched = new Set<string>();
  let reminders = 0;
  let expired = 0;
  for (const d of snap.docs) {
    const appDoc = d.ref.parent.parent;
    if (!appDoc || appDoc.parent.id !== 'driverApplications') continue;
    const uid = appDoc.id;
    const x = d.data();
    const e = x.expiresAt?.toMillis?.() as number | undefined;
    if (typeof e !== 'number' || x.status === 'pending_upload') continue;
    if (e <= nowMillis) {
      if (x.status !== 'expired') {
        await d.ref.update({ status: 'expired', expiredAt: ts(nowMillis) });
        await notifyDriver(deps, null, uid, 'driver_document_expired', {}, ts(nowMillis));
        expired++;
      }
      // Una alerta por documento y versión (episodio): create() falla si ya está.
      await db.collection('adminAlerts').doc(`driver_doc_expired_${uid}_${d.id}_${x.version ?? 0}`).create({
        type: 'driver_document_expired', severity: 'medium', driverId: uid, documentType: d.id,
        version: x.version ?? 0, resolved: false, createdAt: ts(nowMillis),
        message: 'Documento de chófer vencido.',
      }).catch((err) => { if ((err as { code?: number }).code !== 6) throw err; });
      touched.add(uid);
      continue;
    }
    const left = Math.ceil((e - nowMillis) / DAY_MS);
    const due = days.find((n) => left <= n && !(x.remindedDays ?? []).includes(n));
    if (due !== undefined) {
      // Solo se avisa una vez por umbral (el más cercano que aún no se avisó).
      const all = days.filter((n) => left <= n);
      await d.ref.update({ remindedDays: [...new Set([...(x.remindedDays ?? []), ...all])] });
      await notifyDriver(deps, null, uid, 'driver_document_expiring', { days: String(left) }, ts(nowMillis));
      reminders++;
    }
  }
  for (const uid of touched) await recomputeDocsBlock(deps, uid);
  logger.info('runDocExpiry', 'done', { reminders, expired, drivers: touched.size });
  return { reminders, expired, drivers: touched.size };
}

// ---------------------------------------------------------------------------
// Purga manual (sin activar)
// ---------------------------------------------------------------------------

export const purgeSchema = z.strictObject({ driverId: docId, reason: reasonSchema });

/**
 * Borra los archivos de un chófer. Desactivada: solo funciona si
 * config/ops.driverDocsPurgeEnabled es true (la retención la decide el
 * abogado; puede haber obligación de conservarlos). Nada la programa.
 */
export async function adminPurgeDriverDocuments(deps: RegDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(purgeSchema, data);
  const db = deps.db;
  if ((await opsConfig(db, nowMs(deps))).driverDocsPurgeEnabled !== true) {
    throw regError('failed-precondition', 'purge_disabled');
  }
  const deleted = await deps.store.deletePrefix(`driverDocs/${input.driverId}/`);
  await db.runTransaction(async (tx) => {
    writeAudit(tx, db, {
      actor, operation: 'purge_driver_documents', collection: 'driverApplications', docId: input.driverId,
      targetType: 'driver_document', changes: { files: { before: deleted, after: 0 } }, reason: input.reason,
      details: `Archivos del chófer borrados: ${deleted}`,
    });
  });
  return { driverId: input.driverId, deleted };
}
