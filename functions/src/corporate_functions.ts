// Programa para empresas: Cloud Functions (alta, equipo, reservas con cuenta
// de empresa y extracto mensual). Las reglas de negocio están en corporate.ts.

import * as admin from 'firebase-admin';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from './logger';
import * as err from './errors';
import {
  Adjustment,
  allocatePayment,
  buildStatement,
  CORPORATE_REJECTION_MESSAGES,
  corporateRejection,
  dueDateMs,
  isPeriod,
  parseLimit,
  periodBounds,
  periodOf,
  placeLabel,
  previousPeriod,
  StatementBooking,
  statementId,
  validateAdjustment,
  validateCompanyInput,
} from './corporate';

// Perezoso: index.ts inicializa la app de Admin después de importar módulos.
const db = () => admin.firestore();
const now = () => Timestamp.now();
const FN = 'corporate';

/** Cuántos meses atrás se buscan viajes sin facturar al generar un extracto. */
const CARRY_DAYS = 92;

function requireAuth(req: CallableRequest): string {
  if (!req.auth?.uid) throw err.unauthenticated();
  return req.auth.uid;
}

async function requireAdmin(req: CallableRequest): Promise<string> {
  const uid = requireAuth(req);
  const user = await db().collection('users').doc(uid).get();
  if (user.data()?.role !== 'admin') throw err.permissionDenied('Admin role required');
  return uid;
}

/** Administrador activo de su empresa; devuelve uid y empresa. */
async function requireCompanyAdmin(req: CallableRequest) {
  const uid = requireAuth(req);
  const user = (await db().collection('users').doc(uid).get()).data();
  const companyId = user?.companyId as string | undefined;
  if (!companyId || user?.companyRole !== 'admin' || user?.isActive === false) {
    throw err.permissionDenied('Solo el administrador de la empresa puede hacer esto.');
  }
  const companyRef = db().collection('companies').doc(companyId);
  const company = (await companyRef.get()).data();
  if (!company) throw err.notFound('Empresa no encontrada');
  return { uid, companyId, companyRef, company };
}

async function notify(userIds: string[], title: string, body: string, type: string, extra: Record<string, unknown> = {}) {
  const batch = db().batch();
  const tokens: string[] = [];
  for (const id of new Set(userIds)) {
    batch.set(db().collection('users').doc(id).collection('notifications').doc(), {
      userId: id, title, body, type, isRead: false, createdAt: now(), ...extra,
    });
    const u = await db().collection('users').doc(id).get();
    tokens.push(...((u.data()?.fcmTokens as string[]) ?? []));
  }
  await batch.commit();
  if (tokens.length) {
    await admin.messaging().sendEachForMulticast({ tokens, notification: { title, body } }).catch(() => undefined);
  }
}

async function companyAdminIds(companyId: string): Promise<string[]> {
  const snap = await db().collection('companies').doc(companyId).collection('members')
    .where('role', '==', 'admin').get();
  return snap.docs.filter((d) => d.data().active !== false).map((d) => d.id);
}

function audit(adminId: string, action: string, targetId: string, details: string) {
  return db().collection('admin_logs').add({
    adminId, action, targetId, targetType: 'company', details, createdAt: now(),
  });
}

// ---------------------------------------------------------------------------
// Alta de empresa (queda pendiente de aprobación)
// ---------------------------------------------------------------------------

export const registerCompany = onCall(async (req) => {
  const uid = requireAuth(req);
  const parsed = validateCompanyInput(req.data ?? {});
  if ('error' in parsed) throw err.invalidArgument(parsed.error);
  const input = parsed.data;

  const userRef = db().collection('users').doc(uid);
  const companyRef = db().collection('companies').doc();
  await db().runTransaction(async (tx) => {
    const user = (await tx.get(userRef)).data();
    if (!user) throw err.notFound('Perfil no encontrado');
    if (user.isActive === false) throw err.permissionDenied('Cuenta suspendida.');
    if (user.role !== 'rider') throw err.failedPrecondition('Solo una cuenta de pasajero puede registrar una empresa.');
    if (user.companyId) throw err.failedPrecondition('Tu cuenta ya pertenece a una empresa.');
    const dup = await tx.get(db().collection('companies').where('taxId', '==', input.taxId).limit(1));
    if (!dup.empty && dup.docs[0].data().status !== 'rejected') {
      throw err.failedPrecondition('Ya hay una empresa registrada con ese NIT.');
    }
    tx.set(companyRef, {
      ...input,
      status: 'pending',
      ownerId: uid,
      monthlyBudgetBs: null,
      discountPct: 0,
      paymentTermsDays: 15,
      createdAt: now(),
    });
    tx.set(companyRef.collection('members').doc(uid), {
      uid, email: user.email ?? '', displayName: user.displayName ?? '',
      role: 'admin', active: true, monthlyLimitBs: null, addedAt: now(), addedBy: uid,
    });
    tx.update(userRef, { companyId: companyRef.id, companyRole: 'admin' });
  });

  logger.info(FN, 'registerCompany', { companyId: companyRef.id, uid });
  const admins = await db().collection('users').where('role', '==', 'admin').get();
  await notify(admins.docs.map((d) => d.id), 'Nueva empresa por aprobar',
    `${input.name} (NIT ${input.taxId}) solicitó una cuenta de empresa.`, 'company_pending',
    { companyId: companyRef.id });
  return { companyId: companyRef.id, status: 'pending' };
});

// ---------------------------------------------------------------------------
// Administración de Luxelane: aprobar, rechazar, suspender, condiciones
// ---------------------------------------------------------------------------

export const adminUpdateCompany = onCall(async (req) => {
  const adminId = await requireAdmin(req);
  const { companyId, action, reason, discountPct, paymentTermsDays, monthlyBudgetBs } = req.data as {
    companyId: string; action: string; reason?: string;
    discountPct?: number; paymentTermsDays?: number; monthlyBudgetBs?: number | null;
  };
  const ref = db().collection('companies').doc(companyId ?? '_');
  const company = (await ref.get()).data();
  if (!company) throw err.notFound('Empresa no encontrada');

  const update: Record<string, unknown> = { updatedAt: now() };
  const transitions: Record<string, { from: string[]; to: string }> = {
    approve: { from: ['pending', 'rejected'], to: 'active' },
    reject: { from: ['pending'], to: 'rejected' },
    suspend: { from: ['active'], to: 'suspended' },
    reactivate: { from: ['suspended'], to: 'active' },
  };
  if (action !== 'update') {
    const t = transitions[action];
    if (!t) throw err.invalidArgument('Acción no válida');
    if (!t.from.includes(company.status)) {
      throw err.failedPrecondition(`No se puede pasar de "${company.status}" a "${t.to}".`);
    }
    update.status = t.to;
    if (t.to === 'active') update.approvedAt = now();
    if (action === 'reject' || action === 'suspend') update.statusReason = (reason ?? '').toString().slice(0, 200);
  }
  if (discountPct !== undefined) {
    const d = Number(discountPct);
    if (!Number.isFinite(d) || d < 0 || d > 50) throw err.invalidArgument('Descuento entre 0 y 50 %.');
    update.discountPct = Math.round(d * 100) / 100;
  }
  if (paymentTermsDays !== undefined) {
    const d = Number(paymentTermsDays);
    if (!Number.isInteger(d) || d < 0 || d > 120) throw err.invalidArgument('Plazo de pago entre 0 y 120 días.');
    update.paymentTermsDays = d;
  }
  if (monthlyBudgetBs !== undefined) {
    const b = parseLimit(monthlyBudgetBs);
    if (b === undefined) throw err.invalidArgument('Presupuesto no válido.');
    update.monthlyBudgetBs = b;
  }
  await ref.update(update);
  await audit(adminId, `company_${action}`, companyId, `${company.name}${reason ? ` · ${reason}` : ''}`);

  if (update.status) {
    const msgs: Record<string, [string, string]> = {
      active: ['Cuenta de empresa activa', `${company.name} ya puede reservar con cuenta de empresa. Invita a tu equipo desde el panel.`],
      rejected: ['Solicitud de empresa rechazada', `No pudimos aprobar ${company.name}.${reason ? ` Motivo: ${reason}` : ''}`],
      suspended: ['Cuenta de empresa suspendida', `Las reservas con la cuenta de ${company.name} están en pausa.${reason ? ` Motivo: ${reason}` : ''}`],
    };
    const m = msgs[update.status as string];
    if (m) await notify(await companyAdminIds(companyId), m[0], m[1], 'company_status', { companyId });
  }
  return { status: update.status ?? company.status };
});

// ---------------------------------------------------------------------------
// Equipo: invitar, aceptar, cambiar límites, quitar
// ---------------------------------------------------------------------------

const inviteId = (companyId: string, email: string) =>
  `${companyId}_${email.toLowerCase().replace(/[^a-z0-9@._+-]/g, '')}`;

export const inviteCompanyMember = onCall(async (req) => {
  const { uid, companyId, company } = await requireCompanyAdmin(req);
  if (company.status !== 'active') throw err.failedPrecondition('Tu empresa aún no está aprobada.');
  const email = String(req.data?.email ?? '').trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email)) throw err.invalidArgument('Correo no válido.');
  const role = req.data?.role === 'admin' ? 'admin' : 'employee';
  const limit = parseLimit(req.data?.monthlyLimitBs ?? null);
  if (limit === undefined) throw err.invalidArgument('Límite mensual no válido.');

  const existing = await db().collection('users').where('email', '==', email).limit(1).get();
  const target = existing.docs[0];
  if (target?.data().companyId === companyId) throw err.failedPrecondition('Esa persona ya está en tu equipo.');
  if (target?.data().companyId) throw err.failedPrecondition('Esa persona ya pertenece a otra empresa.');
  if (target && target.data().role !== 'rider') throw err.failedPrecondition('Esa cuenta no puede unirse a una empresa.');

  await db().collection('companyInvites').doc(inviteId(companyId, email)).set({
    companyId, companyName: company.name, email, role, monthlyLimitBs: limit,
    status: 'pending', invitedBy: uid, createdAt: now(),
  });
  if (target) {
    await notify([target.id], 'Invitación de empresa',
      `${company.name} te invitó a usar su cuenta de empresa en Luxelane.`, 'company_invite', { companyId });
  }
  return { invited: true, registered: !!target };
});

export const revokeCompanyInvite = onCall(async (req) => {
  const { companyId } = await requireCompanyAdmin(req);
  const email = String(req.data?.email ?? '').trim().toLowerCase();
  const ref = db().collection('companyInvites').doc(inviteId(companyId, email));
  const inv = (await ref.get()).data();
  if (!inv || inv.status !== 'pending') throw err.notFound('Invitación no encontrada');
  await ref.update({ status: 'revoked', updatedAt: now() });
  return { revoked: true };
});

/** El invitado acepta (o rechaza) con su correo ya verificado. */
export const respondCompanyInvite = onCall(async (req) => {
  const uid = requireAuth(req);
  const email = (req.auth?.token.email ?? '').toLowerCase();
  const companyId = String(req.data?.companyId ?? '');
  const accept = req.data?.accept !== false;
  const ref = db().collection('companyInvites').doc(inviteId(companyId, email));

  if (accept && req.auth?.token.email_verified !== true) {
    throw err.failedPrecondition('Verifica tu correo para unirte a la empresa.');
  }
  await db().runTransaction(async (tx) => {
    const inv = (await tx.get(ref)).data();
    if (!inv || inv.status !== 'pending' || inv.email !== email) throw err.notFound('Invitación no encontrada');
    if (!accept) {
      tx.update(ref, { status: 'declined', updatedAt: now() });
      return;
    }
    const userRef = db().collection('users').doc(uid);
    const user = (await tx.get(userRef)).data();
    const company = (await tx.get(db().collection('companies').doc(companyId))).data();
    if (!user || user.isActive === false) throw err.permissionDenied('Cuenta suspendida.');
    if (user.role !== 'rider') throw err.failedPrecondition('Esta cuenta no puede unirse a una empresa.');
    if (user.companyId) throw err.failedPrecondition('Ya perteneces a una empresa.');
    if (company?.status !== 'active') throw err.failedPrecondition('La empresa no está activa.');
    tx.set(db().collection('companies').doc(companyId).collection('members').doc(uid), {
      uid, email, displayName: user.displayName ?? '', role: inv.role ?? 'employee', active: true,
      monthlyLimitBs: inv.monthlyLimitBs ?? null, addedAt: now(), addedBy: inv.invitedBy,
    });
    tx.update(userRef, { companyId, companyRole: inv.role ?? 'employee' });
    tx.update(ref, { status: 'accepted', acceptedBy: uid, updatedAt: now() });
  });
  return { joined: accept };
});

export const updateCompanyMember = onCall(async (req) => {
  const { uid, companyId, companyRef } = await requireCompanyAdmin(req);
  const memberId = String(req.data?.uid ?? '');
  const memberRef = companyRef.collection('members').doc(memberId);
  const member = (await memberRef.get()).data();
  if (!member) throw err.notFound('Miembro no encontrado');

  const update: Record<string, unknown> = { updatedAt: now() };
  if (req.data?.monthlyLimitBs !== undefined) {
    const l = parseLimit(req.data.monthlyLimitBs);
    if (l === undefined) throw err.invalidArgument('Límite mensual no válido.');
    update.monthlyLimitBs = l;
  }
  if (typeof req.data?.active === 'boolean') {
    if (memberId === uid && !req.data.active) throw err.failedPrecondition('No puedes desactivarte a ti mismo.');
    update.active = req.data.active;
  }
  if (req.data?.role === 'admin' || req.data?.role === 'employee') {
    if (memberId === uid && req.data.role !== 'admin') {
      const admins = await companyAdminIds(companyId);
      if (admins.length <= 1) throw err.failedPrecondition('La empresa necesita al menos un administrador.');
    }
    update.role = req.data.role;
  }
  const batch = db().batch();
  batch.update(memberRef, update);
  if (update.role) batch.update(db().collection('users').doc(memberId), { companyRole: update.role });
  await batch.commit();
  return { updated: true };
});

export const removeCompanyMember = onCall(async (req) => {
  const { uid, companyId, companyRef } = await requireCompanyAdmin(req);
  const memberId = String(req.data?.uid ?? '');
  if (memberId === uid) throw err.failedPrecondition('No puedes quitarte a ti mismo del equipo.');
  const memberRef = companyRef.collection('members').doc(memberId);
  if (!(await memberRef.get()).exists) throw err.notFound('Miembro no encontrado');
  const batch = db().batch();
  batch.delete(memberRef);
  batch.update(db().collection('users').doc(memberId), {
    companyId: FieldValue.delete(),
    companyRole: FieldValue.delete(),
  });
  await batch.commit();
  logger.info(FN, 'removeCompanyMember', { companyId, memberId });
  return { removed: true };
});

/** El administrador de la empresa fija su presupuesto mensual. */
export const updateCompanyBudget = onCall(async (req) => {
  const { companyRef } = await requireCompanyAdmin(req);
  const b = parseLimit(req.data?.monthlyBudgetBs ?? null);
  if (b === undefined) throw err.invalidArgument('Presupuesto no válido.');
  await companyRef.update({ monthlyBudgetBs: b, updatedAt: now() });
  return { monthlyBudgetBs: b };
});

// ---------------------------------------------------------------------------
// Reserva con cuenta de empresa (la llama onBookingCreated)
// ---------------------------------------------------------------------------

const ACTIVE_BOOKING = new Set(['pending', 'confirmed', 'driver_arriving', 'driver_arrived', 'in_progress', 'completed']);

/**
 * Comprueba una reserva nueva con `paymentMethod: corporate`. Si no procede
 * la cancela con el motivo y devuelve false (no se ofrece a chóferes).
 */
export async function checkCorporateBooking(
  ref: admin.firestore.DocumentReference,
  booking: { riderId: string; companyId?: string | null; estimatedPrice: number; scheduledAt?: Timestamp },
): Promise<boolean> {
  const companyId = booking.companyId ?? null;
  const [userSnap, companySnap, memberSnap] = await Promise.all([
    db().collection('users').doc(booking.riderId).get(),
    companyId ? db().collection('companies').doc(companyId).get() : Promise.resolve(null),
    companyId ? db().collection('companies').doc(companyId).collection('members').doc(booking.riderId).get() : Promise.resolve(null),
  ]);

  let memberSpentBs = 0;
  let companySpentBs = 0;
  if (companyId) {
    const when = booking.scheduledAt?.toMillis() ?? Date.now();
    const { startMs, endMs } = periodBounds(periodOf(when));
    const month = await db().collection('bookings')
      .where('companyId', '==', companyId)
      .where('scheduledAt', '>=', Timestamp.fromMillis(startMs))
      .where('scheduledAt', '<', Timestamp.fromMillis(endMs))
      .get();
    for (const d of month.docs) {
      if (d.id === ref.id) continue;
      const b = d.data();
      if (b.paymentMethod !== 'corporate' || !ACTIVE_BOOKING.has(b.status)) continue;
      const amount = Number(b.finalPrice ?? b.estimatedPrice ?? 0);
      companySpentBs += amount;
      if (b.riderId === booking.riderId) memberSpentBs += amount;
    }
  }

  const rejection = corporateRejection({
    company: companySnap?.data() ?? null,
    member: memberSnap?.data() ?? null,
    userCompanyId: userSnap.data()?.companyId ?? null,
    bookingCompanyId: companyId,
    memberSpentBs,
    companySpentBs,
    priceBs: Number(booking.estimatedPrice ?? 0),
  });
  if (!rejection) {
    await ref.update({ companyName: companySnap?.data()?.name ?? null, riderName: userSnap.data()?.displayName ?? null });
    return true;
  }
  logger.warn(FN, 'corporate booking rejected', { bookingId: ref.id, rejection });
  await ref.update({
    status: 'cancelled',
    cancelledBy: 'corporate',
    cancellationReason: CORPORATE_REJECTION_MESSAGES[rejection],
    updatedAt: now(),
  });
  return false;
}

// ---------------------------------------------------------------------------
// Extracto mensual
// ---------------------------------------------------------------------------


/** Crea o recalcula el borrador del extracto de un mes (conserva ajustes). */
export async function generateStatement(companyId: string, period: string, by: string) {
  const companyRef = db().collection('companies').doc(companyId);
  const company = (await companyRef.get()).data();
  if (!company) throw err.notFound('Empresa no encontrada');
  const id = statementId(companyId, period);
  const ref = db().collection('companyStatements').doc(id);
  const current = (await ref.get()).data();
  if (current && current.status !== 'draft') {
    throw err.failedPrecondition('El extracto ya fue emitido; no se puede recalcular.');
  }

  const { startMs, endMs } = periodBounds(period);
  const carryFromMs = startMs - CARRY_DAYS * 86400e3;
  const snap = await db().collection('bookings')
    .where('companyId', '==', companyId)
    .where('scheduledAt', '>=', Timestamp.fromMillis(carryFromMs))
    .where('scheduledAt', '<', Timestamp.fromMillis(endMs))
    .get();

  const docs = snap.docs.filter((d) => {
    const b = d.data();
    if (b.paymentMethod !== 'corporate') return false;
    // Ya facturada en otro extracto: no se repite.
    if (b.statementId && b.statementId !== id) return false;
    // Antes del periodo solo entran las aún sin extracto.
    const ms = (b.scheduledAt as Timestamp).toMillis();
    return ms >= startMs || !b.statementId;
  });

  const riderIds = [...new Set(docs.map((d) => d.data().riderId as string))];
  const riders = riderIds.length
    ? await db().getAll(...riderIds.map((r) => db().collection('users').doc(r)))
    : [];
  const names = new Map(riders.map((r) => [r.id, (r.data()?.displayName as string) ?? '']));

  const bookings: StatementBooking[] = docs.map((d) => {
    const b = d.data();
    return {
      id: d.id,
      status: b.status,
      riderId: b.riderId,
      riderName: names.get(b.riderId) || b.riderName || '',
      scheduledAtMs: (b.scheduledAt as Timestamp).toMillis(),
      // El nombre del lugar ("Equipetrol") se entiende mejor en una
      // factura que la dirección formateada (a veces un código plus).
      origin: placeLabel(b.origin),
      destination: b.serviceType === 'byTheHour' ? `${b.hours ?? ''} h por horas` : placeLabel(b.destination),
      vehicleClass: b.class ?? b.vehicleClass,
      serviceType: b.serviceType,
      costCenter: b.costCenter ?? null,
      estimatedPrice: Number(b.estimatedPrice ?? 0),
      finalPrice: b.finalPrice != null ? Number(b.finalPrice) : null,
    };
  });

  const adjustments = (current?.adjustments as Adjustment[] | undefined) ?? [];
  const totals = buildStatement(period, bookings, Number(company.discountPct ?? 0), adjustments, carryFromMs);
  await ref.set({
    companyId,
    companyName: company.name,
    taxId: company.taxId,
    billingEmail: company.billingEmail,
    period,
    periodStart: Timestamp.fromMillis(startMs),
    periodEnd: Timestamp.fromMillis(endMs),
    status: 'draft',
    ...totals,
    adjustments,
    paymentTermsDays: company.paymentTermsDays ?? 15,
    generatedAt: now(),
    generatedBy: by,
    createdAt: current?.createdAt ?? now(),
  });
  logger.info(FN, 'generateStatement', { id, trips: totals.tripCount, total: totals.totalBs });
  return { statementId: id, ...totals };
}

export const generateCompanyStatement = onCall(async (req) => {
  const adminId = await requireAdmin(req);
  const { companyId, period } = req.data as { companyId: string; period: string };
  if (!companyId || !isPeriod(period)) throw err.invalidArgument('Empresa y mes (AAAA-MM) requeridos.');
  const r = await generateStatement(companyId, period, adminId);
  return { statementId: r.statementId, tripCount: r.tripCount, totalBs: r.totalBs };
});

async function draftRef(id: string) {
  const ref = db().collection('companyStatements').doc(id ?? '_');
  const s = (await ref.get()).data();
  if (!s) throw err.notFound('Extracto no encontrado');
  if (s.status !== 'draft') throw err.failedPrecondition('Solo se puede ajustar un extracto en borrador.');
  return { ref, s };
}

export const addStatementAdjustment = onCall(async (req) => {
  const adminId = await requireAdmin(req);
  const v = validateAdjustment(req.data?.concept, req.data?.amountBs);
  if ('error' in v) throw err.invalidArgument(v.error);
  const { s } = await draftRef(req.data?.statementId);
  const adjustments = [...((s.adjustments as Adjustment[]) ?? []), {
    id: db().collection('_').doc().id, concept: v.concept, amountBs: v.amountBs, by: adminId, atMs: Date.now(),
  }];
  await db().collection('companyStatements').doc(req.data.statementId).update({ adjustments });
  await audit(adminId, 'statement_adjustment', s.companyId, `${s.period} · ${v.concept} · Bs ${v.amountBs}`);
  return generateStatement(s.companyId, s.period, adminId).then((r) => ({ totalBs: r.totalBs }));
});

export const removeStatementAdjustment = onCall(async (req) => {
  const adminId = await requireAdmin(req);
  const { s } = await draftRef(req.data?.statementId);
  const adjustments = ((s.adjustments as Adjustment[]) ?? []).filter((a) => a.id !== req.data?.adjustmentId);
  await db().collection('companyStatements').doc(req.data.statementId).update({ adjustments });
  return generateStatement(s.companyId, s.period, adminId).then((r) => ({ totalBs: r.totalBs }));
});

/** Emite el extracto: recalcula, bloquea sus viajes y avisa a la empresa. */
export const issueCompanyStatement = onCall(async (req) => {
  const adminId = await requireAdmin(req);
  const { s } = await draftRef(req.data?.statementId);
  const fresh = await generateStatement(s.companyId, s.period, adminId);
  const id = fresh.statementId;
  const issued = Date.now();

  const ids = fresh.lines.map((l) => l.bookingId);
  for (let i = 0; i < ids.length; i += 400) {
    const batch = db().batch();
    for (const b of ids.slice(i, i + 400)) batch.update(db().collection('bookings').doc(b), { statementId: id });
    await batch.commit();
  }
  await db().collection('companyStatements').doc(id).update({
    status: 'issued',
    issuedAt: Timestamp.fromMillis(issued),
    issuedBy: adminId,
    dueAt: Timestamp.fromMillis(dueDateMs(issued, s.paymentTermsDays)),
  });
  await audit(adminId, 'statement_issued', s.companyId, `${s.period} · Bs ${fresh.totalBs}`);
  await notify(await companyAdminIds(s.companyId), `Extracto de ${s.period} disponible`,
    `Total a pagar: Bs ${fresh.totalBs.toFixed(2)} (${fresh.tripCount} viajes).`, 'company_statement',
    { companyId: s.companyId, statementId: id });
  return { status: 'issued', totalBs: fresh.totalBs };
});

/** Registra el pago del extracto y lo reparte como pago de cada viaje. */
export const markStatementPaid = onCall(async (req) => {
  const adminId = await requireAdmin(req);
  const id = String(req.data?.statementId ?? '');
  const reference = String(req.data?.reference ?? '').trim().slice(0, 120);
  if (reference.length < 2) throw err.invalidArgument('Indica la referencia del pago (transferencia, factura…).');
  const ref = db().collection('companyStatements').doc(id);
  const s = (await ref.get()).data();
  if (!s) throw err.notFound('Extracto no encontrado');
  if (s.status !== 'issued') throw err.failedPrecondition('Solo se marca pagado un extracto emitido.');

  const parts = allocatePayment(s.lines ?? [], Number(s.totalBs ?? 0));
  for (let i = 0; i < parts.length; i += 200) {
    const batch = db().batch();
    for (const p of parts.slice(i, i + 200)) {
      const line = (s.lines as { bookingId: string; riderId: string }[]).find((l) => l.bookingId === p.bookingId)!;
      const payRef = db().collection('payments').doc();
      batch.set(payRef, {
        bookingId: p.bookingId, riderId: line.riderId, stripePaymentIntentId: '',
        amount: p.cents, currency: 'bob', status: 'captured', method: 'corporate',
        companyId: s.companyId, statementId: id, reference, createdAt: now(),
      });
      batch.update(db().collection('bookings').doc(p.bookingId), { paymentId: payRef.id, paymentStatus: 'captured' });
    }
    await batch.commit();
  }
  await ref.update({ status: 'paid', paidAt: now(), paidBy: adminId, paymentReference: reference });
  await audit(adminId, 'statement_paid', s.companyId, `${s.period} · ${reference}`);
  await notify(await companyAdminIds(s.companyId), `Pago recibido · ${s.period}`,
    `Registramos tu pago de Bs ${Number(s.totalBs).toFixed(2)}. Gracias.`, 'company_statement',
    { companyId: s.companyId, statementId: id });
  return { status: 'paid' };
});

/** Día 1 de cada mes, 06:00 en Bolivia: borradores del mes anterior. */
export const monthlyCompanyStatements = onSchedule(
  { schedule: '0 6 1 * *', timeZone: 'America/La_Paz' },
  async () => {
    const period = previousPeriod(Date.now());
    const companies = await db().collection('companies').where('status', 'in', ['active', 'suspended']).get();
    for (const c of companies.docs) {
      try {
        const existing = (await db().collection('companyStatements').doc(statementId(c.id, period)).get()).data();
        if (existing && existing.status !== 'draft') continue;
        await generateStatement(c.id, period, 'system');
      } catch (e) {
        logger.error(FN, 'monthly statement failed', { companyId: c.id, error: String(e) });
      }
    }
    logger.info(FN, 'monthlyCompanyStatements', { period, companies: companies.size });
  },
);
