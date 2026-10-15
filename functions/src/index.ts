import * as admin from 'firebase-admin';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as stripe from './stripe_service';
import { logger } from './logger';
import * as err from './errors';
import { checkBookingPrice, DEFAULT_FARES, fareId, FareRule } from './pricing';
import { distanceKm } from './assignment';
import { computeSettlement, planBackfill, Settlement } from './settlement';
import { rankCandidates } from './assignment';
import { fromCents, toCents } from './money';
import { linkRejection, paymentAction, validIntentAmount } from './payments';
import { checkCorporateBooking } from './corporate_functions';

export * from './corporate_functions';
import { driverBookkeeping, driverSnapshot, isExpiredPending, isRecentlySeen, nextRating, riderMessage } from './lifecycle';

admin.initializeApp();
const db = admin.firestore();

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type BookingStatus =
  | 'pending'
  | 'confirmed'
  | 'driver_arriving'
  | 'driver_arrived'
  | 'in_progress'
  | 'completed'
  | 'cancelled';

type PaymentStatus = 'pending' | 'captured' | 'refunded' | 'failed';

interface BookingDoc {
  riderId: string;
  // La app guarda las coordenadas como GeoPoint en `coordinates`.
  origin?: { coordinates?: admin.firestore.GeoPoint; lat?: number; lng?: number };
  destination?: { coordinates?: admin.firestore.GeoPoint; lat?: number; lng?: number } | null;
  scheduledAt?: Timestamp;
  cancelledBy?: string;
  driverId?: string;
  status: BookingStatus;
  // La app guarda la clase en `class`; `vehicleClass` es el nombre antiguo.
  class?: string;
  vehicleClass?: string;
  serviceType?: string;
  hours?: number | null;
  estimatedPrice: number;
  finalPrice?: number;
  paymentId?: string;
  paymentIntentId?: string | null;
  paymentStatus?: string | null;
  settlement?: Settlement;
}

interface RideDoc {
  bookingId: string;
  riderId: string;
  driverId: string;
  completedAt?: Timestamp;
  distanceKm?: number;
  durationMin?: number;
}

interface PaymentDoc {
  bookingId: string;
  riderId: string;
  stripePaymentIntentId: string;
  /** Centavos enteros (como Stripe); ver money.ts. */
  amount: number;
  currency: string;
  status: PaymentStatus;
  createdAt: Timestamp;
  receiptUrl?: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function requireAuth(req: CallableRequest): string {
  if (!req.auth?.uid) throw err.unauthenticated();
  return req.auth.uid;
}

const VEHICLE_CLASS_LABELS: Record<string, string> = {
  business: 'Business Class',
  businessSuv: 'Business SUV',
  businessVan: 'Business Van',
  firstClass: 'First Class',
  electric: 'Eléctrico',
};

function vehicleClassLabel(vehicleClass: string | undefined): string {
  return (vehicleClass && VEHICLE_CLASS_LABELS[vehicleClass]) || 'Luxelane';
}

async function requireAdmin(req: CallableRequest): Promise<string> {
  const uid = requireAuth(req);
  const user = await db.collection('users').doc(uid).get();
  if (user.data()?.role !== 'admin') throw err.permissionDenied('Admin role required');
  return uid;
}

async function sendPush(tokens: string[], title: string, body: string): Promise<void> {
  if (!tokens.length) return;
  await admin.messaging().sendEachForMulticast({ tokens, notification: { title, body } });
}

async function getUserTokens(userId: string): Promise<string[]> {
  const doc = await db.collection('users').doc(userId).get();
  return (doc.data()?.fcmTokens as string[]) ?? [];
}

// ---------------------------------------------------------------------------
// createPaymentIntent
// ---------------------------------------------------------------------------

/** Cliente de Stripe del usuario; lo crea si aún no existe. */
async function stripeCustomerOf(uid: string): Promise<string> {
  const ref = db.collection('users').doc(uid);
  const snap = await ref.get();
  if (!snap.exists) throw err.notFound('User not found');
  const existing = snap.data()?.stripeCustomerId as string | undefined;
  if (existing) return existing;
  const id = await stripe.createCustomer(snap.data()?.email ?? '', snap.data()?.displayName ?? '');
  await ref.update({ stripeCustomerId: id });
  return id;
}

export const createPaymentIntent = onCall(async (req) => {
  const uid = requireAuth(req);
  // El cliente Stripe sale de la cuenta del usuario, nunca de la petición.
  const { amount } = req.data as { amount: number };
  if (!validIntentAmount(amount)) throw err.invalidArgument('amount must be integer cents within limits');

  logger.info('createPaymentIntent', 'start', { uid, amount });
  try {
    const customerId = await stripeCustomerOf(uid);
    const intent = await stripe.createIntent({ amount, currency: 'bob', customerId, metadata: { uid } });
    return { clientSecret: intent.clientSecret, paymentIntentId: intent.id };
  } catch (e) {
    logger.error('createPaymentIntent', 'stripe error', { error: String(e) });
    throw err.paymentFailed(String(e));
  }
});

// ---------------------------------------------------------------------------
// linkBookingPayment — vincula la retención autorizada a la reserva
// ---------------------------------------------------------------------------

export const linkBookingPayment = onCall(async (req) => {
  const uid = requireAuth(req);
  const { bookingId, paymentIntentId } = req.data as { bookingId: string; paymentIntentId: string };
  if (!bookingId || !paymentIntentId) throw err.invalidArgument('bookingId and paymentIntentId required');

  const bookingRef = db.collection('bookings').doc(bookingId);
  const intent = await stripe.retrieveIntent(paymentIntentId);
  const outcome = await db.runTransaction(async (tx) => {
    const snap = await tx.get(bookingRef);
    if (!snap.exists) return 'not_found';
    const booking = snap.data() as BookingDoc;
    const rejection = linkRejection(uid, booking, intent);
    if (rejection) return rejection;
    tx.update(bookingRef, {
      paymentIntentId,
      paymentStatus: 'authorized',
      paymentMethod: 'card',
    });
    return 'linked';
  });

  if (outcome !== 'linked') {
    logger.warn('linkBookingPayment', 'rejected', { bookingId, outcome });
    // Una retención que no queda vinculada se libera para no bloquear
    // dinero del pasajero (salvo que sea de otro usuario).
    if (intent.metadata?.uid === uid && intent.status === 'requires_capture' && outcome !== 'already_linked') {
      await stripe.cancelIntent(paymentIntentId).catch(() => undefined);
    }
    return { linked: false, reason: outcome };
  }
  return { linked: true };
});

// ---------------------------------------------------------------------------
// releasePaymentHold — la app libera una retención que no llegó a reserva
// ---------------------------------------------------------------------------

export const releasePaymentHold = onCall(async (req) => {
  const uid = requireAuth(req);
  const { paymentIntentId } = req.data as { paymentIntentId: string };
  if (!paymentIntentId) throw err.invalidArgument('paymentIntentId required');
  const intent = await stripe.retrieveIntent(paymentIntentId);
  if (intent.metadata?.uid !== uid) throw err.permissionDenied('Not your payment');
  if (intent.status !== 'requires_capture') return { released: false };
  // Nunca se libera una retención ya vinculada a una reserva.
  const linked = await db.collection('bookings').where('paymentIntentId', '==', paymentIntentId).limit(1).get();
  if (!linked.empty) return { released: false };
  await stripe.cancelIntent(paymentIntentId);
  return { released: true };
});

/** Cobra o libera la retención de una reserva según su nuevo estado. */
async function settleCardPayment(bookingId: string, after: BookingDoc): Promise<void> {
  const action = paymentAction(after);
  if (!action || !after.paymentIntentId) return;
  const bookingRef = db.collection('bookings').doc(bookingId);

  // Reclama la operación para no cobrar dos veces si el trigger se repite.
  const claimed = await db.runTransaction(async (tx) => {
    const cur = (await tx.get(bookingRef)).data() as BookingDoc | undefined;
    if (cur?.paymentStatus !== 'authorized') return false;
    tx.update(bookingRef, { paymentStatus: action === 'capture' ? 'capturing' : 'releasing' });
    return true;
  });
  if (!claimed) return;

  if (action === 'release') {
    try {
      await stripe.cancelIntent(after.paymentIntentId);
      await bookingRef.update({ paymentStatus: 'released' });
    } catch (e) {
      logger.error('settleCardPayment', 'release failed', { bookingId, error: String(e) });
      await bookingRef.update({ paymentStatus: 'authorized' });
    }
    return;
  }

  const amountToCapture = toCents(after.finalPrice ?? after.estimatedPrice);
  const paymentRef = db.collection('payments').doc();
  try {
    const intent = await stripe.captureIntent(after.paymentIntentId, amountToCapture);
    const captured = intent.amount_received ?? amountToCapture;
    const ok = intent.status === 'succeeded';
    const payment: PaymentDoc = {
      bookingId,
      riderId: after.riderId,
      stripePaymentIntentId: after.paymentIntentId,
      amount: captured,
      currency: intent.currency ?? 'bob',
      status: ok ? 'captured' : 'failed',
      createdAt: Timestamp.now(),
    };
    const batch = db.batch();
    batch.set(paymentRef, payment);
    batch.update(bookingRef, {
      paymentId: paymentRef.id,
      paymentStatus: ok ? 'captured' : 'failed',
      ...(after.finalPrice == null ? { finalPrice: fromCents(captured) } : {}),
    });
    await batch.commit();
    if (captured < amountToCapture) {
      logger.warn('settleCardPayment', 'captured less than charged', { bookingId, captured, amountToCapture });
    }
  } catch (e) {
    // Queda como cobro fallido: el admin lo ve en cuentas por cobrar.
    logger.error('settleCardPayment', 'capture failed', { bookingId, error: String(e) });
    const batch = db.batch();
    batch.set(paymentRef, {
      bookingId,
      riderId: after.riderId,
      stripePaymentIntentId: after.paymentIntentId,
      amount: amountToCapture,
      currency: 'bob',
      status: 'failed',
      createdAt: Timestamp.now(),
    } as PaymentDoc);
    batch.update(bookingRef, { paymentId: paymentRef.id, paymentStatus: 'failed' });
    await batch.commit();
  }
}

// ---------------------------------------------------------------------------
// capturePayment — reintento manual del admin sobre una reserva completada
// ---------------------------------------------------------------------------

export const capturePayment = onCall(async (req) => {
  await requireAdmin(req);
  const { bookingId } = req.data as { bookingId: string };
  if (!bookingId) throw err.invalidArgument('bookingId required');

  const bookingRef = db.collection('bookings').doc(bookingId);
  const snap = await bookingRef.get();
  if (!snap.exists) throw err.notFound('Booking not found');
  const booking = snap.data() as BookingDoc;
  if (booking.status !== 'completed') throw err.failedPrecondition('Ride must be completed before capture');
  if (!booking.paymentIntentId) throw err.failedPrecondition('Booking has no card payment');
  if (booking.paymentStatus === 'captured') throw err.failedPrecondition('Booking already paid');

  // Un cobro fallido se puede reintentar mientras la retención siga viva.
  await bookingRef.update({ paymentStatus: 'authorized' });
  await settleCardPayment(bookingId, { ...booking, paymentStatus: 'authorized' });
  const after = (await bookingRef.get()).data() as BookingDoc;
  return { paymentId: after.paymentId ?? null, status: after.paymentStatus ?? null };
});

// ---------------------------------------------------------------------------
// refundPayment
// ---------------------------------------------------------------------------

export const refundPayment = onCall(async (req) => {
  // Solo un admin puede reembolsar: mueve dinero y altera las finanzas.
  const adminId = await requireAdmin(req);
  const { paymentId, reason } = req.data as { paymentId: string; reason?: string };

  if (!paymentId) throw err.invalidArgument('paymentId required');

  const paymentRef = db.collection('payments').doc(paymentId);
  const snap = await paymentRef.get();
  if (!snap.exists) throw err.notFound('Payment not found');

  const payment = snap.data() as PaymentDoc;
  if (payment.status !== 'captured') throw err.failedPrecondition('Only captured payments can be refunded');

  logger.info('refundPayment', 'start', { paymentId, adminId });

  try {
    // Los cobros registrados a mano (efectivo, QR…) no pasan por Stripe.
    if (payment.stripePaymentIntentId) {
      await stripe.refundIntent(payment.stripePaymentIntentId);
    }
    const now = Timestamp.now();
    const batch = db.batch();
    batch.update(paymentRef, {
      status: 'refunded' as PaymentStatus,
      refundedAt: now,
      refundedBy: adminId,
      refundReason: reason ?? '',
    });
    batch.set(db.collection('admin_logs').doc(), {
      adminId,
      adminEmail: req.auth?.token.email ?? null,
      action: 'refund_payment',
      targetId: payment.bookingId,
      targetType: 'payment',
      details: `Pago ${paymentId}${reason ? ` · ${reason}` : ''}`,
      createdAt: now,
    });
    await batch.commit();
    logger.info('refundPayment', 'success', { paymentId });
    return { status: 'refunded' };
  } catch (e) {
    logger.error('refundPayment', 'stripe error', { error: String(e) });
    throw err.paymentFailed(String(e));
  }
});

// ---------------------------------------------------------------------------
// listPaymentMethods
// ---------------------------------------------------------------------------

export const listPaymentMethods = onCall(async (req) => {
  const uid = requireAuth(req);
  const customerId = await stripeCustomerOf(uid);
  const methods = await stripe.listPaymentMethods(customerId);
  return {
    cards: methods.map((m) => ({
      id: m.id,
      brand: m.card?.brand,
      last4: m.card?.last4,
      expMonth: m.card?.exp_month,
      expYear: m.card?.exp_year,
    })),
  };
});

// ---------------------------------------------------------------------------
// attachPaymentMethod
// ---------------------------------------------------------------------------

export const attachPaymentMethod = onCall(async (req) => {
  const uid = requireAuth(req);
  const { paymentMethodId } = req.data as { paymentMethodId: string };
  if (!paymentMethodId) throw err.invalidArgument('paymentMethodId required');

  const customerId = await stripeCustomerOf(uid);
  try {
    await stripe.attachPaymentMethod(customerId, paymentMethodId);
  } catch (e) {
    logger.warn('attachPaymentMethod', 'stripe error', { error: String(e) });
    throw err.paymentFailed('No se pudo guardar la tarjeta');
  }
  return { success: true };
});

// ---------------------------------------------------------------------------
// detachPaymentMethod
// ---------------------------------------------------------------------------

export const detachPaymentMethod = onCall(async (req) => {
  const uid = requireAuth(req);
  const { paymentMethodId } = req.data as { paymentMethodId: string };
  if (!paymentMethodId) throw err.invalidArgument('paymentMethodId required');

  // Solo se quitan tarjetas propias.
  const customerId = await stripeCustomerOf(uid);
  const pm = await stripe.retrievePaymentMethod(paymentMethodId);
  if (pm.customer !== customerId) throw err.permissionDenied('Not your card');

  await stripe.detachPaymentMethod(paymentMethodId);
  return { success: true };
});

// ---------------------------------------------------------------------------
// createStripeCustomer  (onCreate /users/{uid})
// ---------------------------------------------------------------------------

export const createStripeCustomer = onDocumentCreated('users/{uid}', async (event) => {
  const data = event.data?.data();
  if (!data || data.role !== 'rider') return;

  logger.info('createStripeCustomer', 'start', { uid: event.params.uid });

  try {
    const customerId = await stripe.createCustomer(data.email, data.displayName);
    await db.collection('users').doc(event.params.uid).update({ stripeCustomerId: customerId });
    logger.info('createStripeCustomer', 'success', { uid: event.params.uid, customerId });
  } catch (e) {
    logger.error('createStripeCustomer', 'failed', { error: String(e) });
  }
});

// ---------------------------------------------------------------------------
// onBookingCreated  (onCreate /bookings/{bookingId})
// ---------------------------------------------------------------------------

/** Coordenadas de un lugar de la reserva (GeoPoint o lat/lng sueltos). */
function pointOf(p?: { coordinates?: admin.firestore.GeoPoint; lat?: number; lng?: number } | null) {
  if (p?.coordinates) return { lat: p.coordinates.latitude, lng: p.coordinates.longitude };
  if (p?.lat != null && p?.lng != null) return { lat: p.lat, lng: p.lng };
  return null;
}

export const onBookingCreated = onDocumentCreated('bookings/{bookingId}', async (event) => {
  const booking = event.data?.data() as BookingDoc | undefined;
  if (!booking) return;
  const vehicleClass = booking.class ?? booking.vehicleClass ?? 'business';

  // Control de tarifas: la reserva debe respetar la tarifa vigente del admin.
  const id = fareId(vehicleClass, booking.serviceType ?? 'oneWay');
  const ruleSnap = await db.collection('pricingRules').doc(id).get();
  const rule = ruleSnap.exists ? (ruleSnap.data() as FareRule) : DEFAULT_FARES[id];
  const o = pointOf(booking.origin);
  const d = pointOf(booking.destination);
  const check = checkBookingPrice(booking, rule, o && d ? distanceKm(o, d) : 0);
  if (!check.ok) {
    // Precio por debajo de la tarifa (manipulado o tarifa cambiada) o
    // servicio desactivado: no se ofrece a chóferes y se avisa al pasajero.
    logger.warn('onBookingCreated', 'pricing rejected', { bookingId: event.params.bookingId, ...check });
    await event.data!.ref.update({
      pricingReview: { reason: check.reason, expectedMinimum: check.expectedMinimum ?? null },
      status: 'cancelled' as BookingStatus,
      cancelledBy: 'pricing',
      cancellationReason: 'Precio no válido para la tarifa vigente',
      updatedAt: Timestamp.now(),
    });
    return;
  }

  // Cuenta de empresa: miembro activo, empresa aprobada y dentro de límites.
  if ((booking as BookingDoc & { paymentMethod?: string }).paymentMethod === 'corporate') {
    const ok = await checkCorporateBooking(event.data!.ref, booking as never);
    if (!ok) return;
  }

  logger.info('onBookingCreated', 'notifying drivers', {
    bookingId: event.params.bookingId,
    vehicleClass,
  });

  // Solo chóferes conectados de la clase pedida.
  const [driversSnap, ...classSnaps] = await Promise.all([
    db
      .collection('driverProfiles')
      .where('isAvailable', '==', true)
      .where('documentsVerified', '==', true)
      .limit(100)
      .get(),
    ...['class', 'vehicleClass'].map((field) =>
      db.collection('vehicles').where(field, '==', vehicleClass).where('isActive', '==', true).get(),
    ),
  ]);
  const ofClass = new Set(classSnaps.flatMap((q) => q.docs.map((v) => v.data().driverId as string)));
  const nowMs = Date.now();
  const targets = driversSnap.docs
    .filter((p) => ofClass.has(p.id))
    .filter((p) => isRecentlySeen((p.data().lastSeenAt as Timestamp | undefined)?.toMillis(), nowMs))
    .slice(0, 20);

  const tokens: string[] = [];
  for (const doc of targets) {
    const driverTokens = await getUserTokens(doc.id);
    tokens.push(...driverTokens);
  }

  await sendPush(
    tokens,
    'Nuevo viaje disponible',
    `${vehicleClassLabel(vehicleClass)} · Bs ${Math.round(booking.estimatedPrice)}`,
  );
});

// ---------------------------------------------------------------------------
// onBookingStatusChanged  (onUpdate /bookings/{bookingId})
// ---------------------------------------------------------------------------

export const onBookingStatusChanged = onDocumentUpdated('bookings/{bookingId}', async (event) => {
  const before = event.data?.before.data() as BookingDoc | undefined;
  const after = event.data?.after.data() as BookingDoc | undefined;
  const bookingId = event.params.bookingId;

  if (!before || !after || before.status === after.status) return;

  logger.info('onBookingStatusChanged', 'status changed', {
    bookingId,
    from: before.status,
    to: after.status,
  });

  const now = Timestamp.now();

  // 1. Chófer: libre al terminar o cancelar; suma el viaje al completar.
  const book = driverBookkeeping(before, after);
  if (book) {
    await db.collection('driverProfiles').doc(book.driverId).set(
      {
        isAvailable: true,
        ...(book.countRide ? { totalRides: FieldValue.increment(1) } : {}),
      },
      { merge: true },
    );
  }

  // 2. Tarjeta: cobrar al completar o liberar la retención al cancelar.
  try {
    await settleCardPayment(bookingId, after);
  } catch (e) {
    logger.error('onBookingStatusChanged', 'payment', { bookingId, error: String(e) });
  }

  // 3. Registro del trayecto (rides/{bookingId}): lo escribe solo el servidor.
  const rideRef = db.collection('rides').doc(bookingId);
  if (after.status === 'in_progress' && after.driverId) {
    await rideRef.set(
      { bookingId, riderId: after.riderId, driverId: after.driverId, startedAt: now },
      { merge: true },
    );
  } else if (after.status === 'completed' && after.driverId) {
    await rideRef.set(
      { bookingId, riderId: after.riderId, driverId: after.driverId, completedAt: now },
      { merge: true },
    );
  }

  // 4. Aviso al pasajero: push y bandeja de notificaciones de la app.
  const msg = riderMessage(after.status, after.cancelledBy);
  if (!msg) return;
  await db.collection('users').doc(after.riderId).collection('notifications').add({
    userId: after.riderId,
    title: msg.title,
    body: msg.body,
    type: msg.type,
    bookingId,
    isRead: false,
    createdAt: now,
  });
  const tokens = await getUserTokens(after.riderId);
  await sendPush(tokens, msg.title, msg.body);
});

// ---------------------------------------------------------------------------
// syncBookingDriver  (onUpdate /bookings/{bookingId})
// Copia en la reserva el nombre, teléfono y vehículo del chófer asignado: el
// pasajero no puede leer /users de otros, y así ve a su chófer.
// ---------------------------------------------------------------------------

export const syncBookingDriver = onDocumentUpdated('bookings/{bookingId}', async (event) => {
  const before = event.data?.before.data() as BookingDoc | undefined;
  const after = event.data?.after.data() as BookingDoc | undefined;
  if (!after || !after.driverId || before?.driverId === after.driverId) return;

  const [userSnap, vehicleSnap] = await Promise.all([
    db.collection('users').doc(after.driverId).get(),
    // El vehículo puede tener otro id si lo dio de alta un admin.
    db.collection('vehicles').where('driverId', '==', after.driverId).limit(1).get(),
  ]);
  await event.data!.after.ref.update(
    driverSnapshot(userSnap.data() as never, vehicleSnap.docs[0]?.data() as never),
  );
});

// ---------------------------------------------------------------------------
// onBookingRated  (onUpdate /bookings/{bookingId})
// El pasajero valora en su reserva (las reglas permiten una sola vez, 1-5);
// el servidor actualiza la media del chófer y el registro del trayecto.
// ---------------------------------------------------------------------------

export const onBookingRated = onDocumentUpdated('bookings/{bookingId}', async (event) => {
  const before = event.data?.before.data() as (BookingDoc & { riderRating?: number }) | undefined;
  const after = event.data?.after.data() as (BookingDoc & { riderRating?: number }) | undefined;
  if (!after?.driverId || after.riderRating == null || before?.riderRating != null) return;

  const stars = after.riderRating;
  const driverRef = db.collection('driverProfiles').doc(after.driverId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(driverRef);
    if (!snap.exists) return;
    tx.update(driverRef, nextRating(snap.data() ?? {}, stars));
  });
  await db.collection('rides').doc(event.params.bookingId).set({ riderRating: stars }, { merge: true });
});


// ---------------------------------------------------------------------------
// settleBooking  (onUpdate /bookings/{bookingId})
// Fija el reparto plataforma / chófer de cada viaje completado. Se dispara
// también al ajustar el precio final; la segunda escritura no cambia nada,
// así que no hay bucle.
// ---------------------------------------------------------------------------

export const settleBooking = onDocumentUpdated('bookings/{bookingId}', async (event) => {
  const after = event.data?.after.data() as BookingDoc | undefined;
  if (!after || after.status !== 'completed') return;

  const finance = await db.collection('config').doc('finance').get();
  const settlement = computeSettlement(after, finance.data()?.platformCommissionPct);
  if (!settlement) return;

  await event.data!.after.ref.update({ settlement });
  logger.info('settleBooking', 'settled', { bookingId: event.params.bookingId, ...settlement });
});

// ---------------------------------------------------------------------------
// backfillSettlements  (HTTPS Callable, solo admin)
// Asigna el reparto a los viajes completados antes de existir settleBooking,
// con la comisión vigente. Es idempotente: volver a ejecutarlo no cambia
// los viajes ya repartidos.
// ---------------------------------------------------------------------------

export const backfillSettlements = onCall({ timeoutSeconds: 540 }, async (req) => {
  const adminId = await requireAdmin(req);
  const finance = await db.collection('config').doc('finance').get();
  const pct = finance.data()?.platformCommissionPct;

  const PAGE = 300;
  let scanned = 0;
  let settled = 0;
  let last: admin.firestore.QueryDocumentSnapshot | undefined;

  for (;;) {
    let query = db
      .collection('bookings')
      .where('status', '==', 'completed')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(PAGE);
    if (last) query = query.startAfter(last);
    const snap = await query.get();
    if (snap.empty) break;

    scanned += snap.size;
    const plan = planBackfill(
      snap.docs.map((d) => ({ id: d.id, data: d.data() as BookingDoc })),
      pct,
    );
    if (plan.length) {
      const batch = db.batch();
      for (const p of plan) {
        batch.update(db.collection('bookings').doc(p.id), { settlement: p.settlement });
      }
      await batch.commit();
      settled += plan.length;
    }
    last = snap.docs[snap.docs.length - 1];
    if (snap.size < PAGE) break;
  }

  await db.collection('admin_logs').add({
    adminId,
    adminEmail: req.auth?.token.email ?? null,
    action: 'backfill_settlements',
    targetId: 'bookings',
    targetType: 'finance',
    details: `${settled} de ${scanned} viajes completados repartidos`,
    createdAt: Timestamp.now(),
  });
  logger.info('backfillSettlements', 'done', { scanned, settled });
  return { scanned, settled };
});

// ---------------------------------------------------------------------------
// onRideCompleted  (onUpdate /rides/{rideId})
// ---------------------------------------------------------------------------

export const onRideCompleted = onDocumentUpdated('rides/{rideId}', async (event) => {
  const before = event.data?.before.data() as RideDoc | undefined;
  const after = event.data?.after.data() as RideDoc | undefined;

  if (!before || !after) return;
  if (before.completedAt || !after.completedAt) return;

  // El registro lo crea onBookingStatusChanged cuando la reserva ya está
  // completada; solo un cierre hecho desde el trayecto (admin) completa aquí
  // la reserva. La contabilidad del chófer la hace onBookingStatusChanged.
  const bookingRef = db.collection('bookings').doc(after.bookingId);
  const booking = (await bookingRef.get()).data() as BookingDoc | undefined;
  if (booking?.status !== 'in_progress') return;

  logger.info('onRideCompleted', 'ride completed', { rideId: event.params.rideId });
  await bookingRef.update({ status: 'completed' as BookingStatus, updatedAt: Timestamp.now() });
});


// ---------------------------------------------------------------------------
// assignNearestDriver  (HTTPS Callable)
// ---------------------------------------------------------------------------

export const assignNearestDriver = onCall(async (req) => {
  const uid = requireAuth(req);
  const { bookingId } = req.data as { bookingId: string };
  if (!bookingId) throw err.invalidArgument('bookingId required');

  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();
  if (!bookingSnap.exists) throw err.notFound('Booking not found');

  const booking = bookingSnap.data() as BookingDoc;
  if (booking.riderId !== uid) await requireAdmin(req);
  if (booking.status !== 'pending') throw err.failedPrecondition('Booking must be pending');

  const vehicleClass = booking.class ?? booking.vehicleClass ?? 'business';
  logger.info('assignNearestDriver', 'searching', { bookingId, vehicleClass });

  // La app guarda la clase del vehículo en `class`; `vehicleClass` es el
  // nombre de documentos antiguos.
  const vehicleQueries = await Promise.all(
    ['class', 'vehicleClass'].map((field) =>
      db.collection('vehicles').where(field, '==', vehicleClass).where('isActive', '==', true).limit(50).get(),
    ),
  );
  const driverIds = [
    ...new Set(vehicleQueries.flatMap((q) => q.docs.map((d) => d.data().driverId as string)).filter(Boolean)),
  ];
  if (!driverIds.length) {
    logger.warn('assignNearestDriver', 'no vehicles found', { vehicleClass });
    return { assigned: false, reason: 'no_drivers_available' };
  }

  const profiles = await db.getAll(...driverIds.map((id) => db.collection('driverProfiles').doc(id)));
  const nowMs = Date.now();
  const ranked = rankCandidates(
    profiles
      .filter((p) => p.exists)
      .filter((p) =>
        isRecentlySeen((p.data()!.lastSeenAt as Timestamp | undefined)?.toMillis(), nowMs),
      )
      .map((p) => {
        const d = p.data()!;
        const gp = d.currentLocation as admin.firestore.GeoPoint | undefined;
        return {
          driverId: p.id,
          isAvailable: d.isAvailable === true,
          documentsVerified: d.documentsVerified === true,
          location: gp ? { lat: gp.latitude, lng: gp.longitude } : null,
        };
      }),
    booking.origin?.coordinates
      ? { lat: booking.origin.coordinates.latitude, lng: booking.origin.coordinates.longitude }
      : booking.origin?.lat != null && booking.origin?.lng != null
        ? { lat: booking.origin.lat, lng: booking.origin.lng }
        : null,
  );

  // Del más cercano al más lejano; la transacción evita asignar una reserva
  // ya tomada o un chófer que acaba de ocuparse.
  for (const driverId of ranked) {
    const driverRef = db.collection('driverProfiles').doc(driverId);
    const outcome = await db.runTransaction(async (tx) => {
      const [b, d, u] = await Promise.all([
        tx.get(bookingRef),
        tx.get(driverRef),
        tx.get(db.collection('users').doc(driverId)),
      ]);
      if ((b.data() as BookingDoc | undefined)?.status !== 'pending') return 'taken';
      if (!d.data()?.isAvailable) return 'busy';
      // Cuenta bloqueada por un administrador: no recibe viajes.
      if (u.data()?.isActive === false || u.data()?.role !== 'driver') return 'busy';
      tx.update(bookingRef, {
        driverId,
        status: 'confirmed' as BookingStatus,
        updatedAt: Timestamp.now(),
      });
      tx.update(driverRef, { isAvailable: false });
      return 'assigned';
    });
    if (outcome === 'taken') return { assigned: false, reason: 'already_taken' };
    if (outcome === 'busy') continue;

    const driverTokens = await getUserTokens(driverId);
    await sendPush(driverTokens, 'Nueva reserva', 'Se te ha asignado un nuevo viaje.');
    logger.info('assignNearestDriver', 'assigned', { bookingId, driverId });
    return { assigned: true, driverId };
  }

  return { assigned: false, reason: 'no_drivers_available' };
});

// ---------------------------------------------------------------------------
// acceptBooking  (HTTPS Callable) — atomic driver self-assignment
// Prevents two drivers from accepting the same booking simultaneously.
// ---------------------------------------------------------------------------

export const acceptBooking = onCall(async (req) => {
  const driverId = requireAuth(req);
  const { bookingId } = req.data as { bookingId: string };
  if (!bookingId) throw err.invalidArgument('bookingId required');

  const bookingRef = db.collection('bookings').doc(bookingId);
  const driverRef  = db.collection('driverProfiles').doc(driverId);


  try {
    await db.runTransaction(async (tx) => {
      const [bookingSnap, driverSnap] = await Promise.all([
        tx.get(bookingRef),
        tx.get(driverRef),
      ]);

      if (!bookingSnap.exists) throw err.notFound('Booking not found');
      const booking = bookingSnap.data() as BookingDoc;
      if (booking.status !== 'pending') throw new Error('ALREADY_TAKEN');

      if (!driverSnap.exists) throw err.notFound('Driver profile not found');
      // Solo un chófer verificado, activo y conectado (no en otro viaje).
      const userSnap = await tx.get(db.collection('users').doc(driverId));
      const user = userSnap.data();
      if (user?.role !== 'driver' || user?.isActive === false) throw new Error('NOT_ALLOWED');
      if (driverSnap.data()?.documentsVerified !== true) throw new Error('NOT_VERIFIED');
      if (!driverSnap.data()?.isAvailable) throw new Error('DRIVER_BUSY');
      // Como Uber: solo se aceptan viajes de la clase del vehículo del chófer.
      const vehicleSnap = await tx.get(
        db.collection('vehicles').where('driverId', '==', driverId).limit(1),
      );
      const vehicle = vehicleSnap.docs[0]?.data();
      if (!vehicle || vehicle.isActive === false) throw new Error('NOT_ALLOWED');
      const wanted = booking.class ?? booking.vehicleClass ?? 'business';
      const has = vehicle.class ?? vehicle.vehicleClass ?? 'business';
      if (wanted !== has) throw new Error('WRONG_CLASS');

      tx.update(bookingRef, {
        driverId,
        status: 'confirmed' as BookingStatus,
        updatedAt: Timestamp.now(),
      });
      tx.update(driverRef, { isAvailable: false });
    });

    // El aviso al pasajero lo envía onBookingStatusChanged (confirmed).

    logger.info('acceptBooking', 'success', { bookingId, driverId });
    return { accepted: true };
  } catch (e: any) {
    if (e.message === 'ALREADY_TAKEN') {
      return { accepted: false, reason: 'already_taken' };
    }
    if (e.message === 'DRIVER_BUSY') {
      return { accepted: false, reason: 'driver_busy' };
    }
    if (e.message === 'NOT_VERIFIED') {
      return { accepted: false, reason: 'not_verified' };
    }
    if (e.message === 'WRONG_CLASS') {
      return { accepted: false, reason: 'wrong_class' };
    }
    if (e.message === 'NOT_ALLOWED') {
      return { accepted: false, reason: 'not_allowed' };
    }
    logger.error('acceptBooking', 'error', { error: String(e) });
    throw e;
  }
});

// ---------------------------------------------------------------------------
// scheduledCleanup  (daily)
// ---------------------------------------------------------------------------

export const scheduledCleanup = onSchedule('every 1 hours', async () => {
  logger.info('scheduledCleanup', 'start');

  // Pendientes cuya hora de recogida ya pasó sin chófer. Las programadas
  // para el futuro no se tocan (antes se filtraba por createdAt y se
  // cancelaban reservas de mañana).
  const nowMs = Date.now();
  const staleSnap = await db
    .collection('bookings')
    .where('status', '==', 'pending')
    .where('scheduledAt', '<', Timestamp.fromMillis(nowMs - 30 * 60 * 1000))
    .limit(450)
    .get();

  const expired = staleSnap.docs.filter((d) =>
    isExpiredPending(
      {
        status: d.data().status,
        scheduledAtMs: (d.data().scheduledAt as Timestamp | undefined)?.toMillis(),
      },
      nowMs,
    ),
  );
  if (!expired.length) return;

  const batch = db.batch();
  for (const d of expired) {
    batch.update(d.ref, {
      status: 'cancelled' as BookingStatus,
      cancelledBy: 'system',
      cancellationReason: 'Sin chófer disponible a la hora de recogida',
      updatedAt: Timestamp.now(),
    });
  }
  await batch.commit();
  logger.info('scheduledCleanup', 'done', { cancelled: expired.length });
});


// ---------------------------------------------------------------------------
// sendRideReceipt  (onUpdate /payments/{paymentId})
// ---------------------------------------------------------------------------

export const sendRideReceipt = onDocumentUpdated('payments/{paymentId}', async (event) => {
  const before = event.data?.before.data() as PaymentDoc | undefined;
  const after = event.data?.after.data() as PaymentDoc | undefined;

  if (!before || !after) return;
  if (before.status === after.status || after.status !== 'captured') return;

  logger.info('sendRideReceipt', 'sending receipt', { paymentId: event.params.paymentId });

  const tokens = await getUserTokens(after.riderId);
  await sendPush(
    tokens,
    'Pago confirmado',
    `Se cobraron Bs ${(after.amount / 100).toFixed(2)} por tu trayecto.`,
  );
});
