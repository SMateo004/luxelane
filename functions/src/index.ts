import * as admin from 'firebase-admin';
import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as stripe from './stripe_service';
import { logger } from './logger';
import * as err from './errors';
import { checkBookingPrice, DEFAULT_FARES, fareId, FareRule } from './pricing';
import { computeSettlement, planBackfill, Settlement } from './settlement';
import { rankCandidates } from './assignment';
import { fromCents, toCents } from './money';
import { driverBookkeeping, driverSnapshot, isExpiredPending, isRecentlySeen, riderMessage } from './lifecycle';

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
  scheduledAt?: admin.firestore.Timestamp;
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
  settlement?: Settlement;
}

interface RideDoc {
  bookingId: string;
  riderId: string;
  driverId: string;
  completedAt?: admin.firestore.Timestamp;
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
  createdAt: admin.firestore.Timestamp;
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

export const createPaymentIntent = onCall(async (req) => {
  const uid = requireAuth(req);
  const { amount, currency, customerId } = req.data as {
    amount: number;
    currency: string;
    customerId: string;
  };

  if (!amount || !currency || !customerId) throw err.invalidArgument('amount, currency, customerId required');
  if (amount <= 0) throw err.invalidArgument('amount must be positive');

  logger.info('createPaymentIntent', 'start', { uid, amount, currency });

  try {
    const clientSecret = await stripe.createIntent({ amount, currency, customerId });
    logger.info('createPaymentIntent', 'success', { uid });
    return { clientSecret };
  } catch (e) {
    logger.error('createPaymentIntent', 'stripe error', { error: String(e) });
    throw err.paymentFailed(String(e));
  }
});

// ---------------------------------------------------------------------------
// capturePayment
// ---------------------------------------------------------------------------

export const capturePayment = onCall(async (req) => {
  const uid = requireAuth(req);
  // El importe y el pasajero salen de la reserva, nunca del cliente.
  const { bookingId, stripePaymentIntentId } = req.data as {
    bookingId: string;
    stripePaymentIntentId: string;
  };

  if (!bookingId || !stripePaymentIntentId) throw err.invalidArgument('bookingId and stripePaymentIntentId required');

  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();
  if (!bookingSnap.exists) throw err.notFound('Booking not found');

  const booking = bookingSnap.data() as BookingDoc;
  if (booking.riderId !== uid) await requireAdmin(req);
  if (booking.status !== 'completed') throw err.failedPrecondition('Ride must be completed before capture');

  if (booking.paymentId) {
    const existing = await db.collection('payments').doc(booking.paymentId).get();
    if (existing.data()?.status === 'captured') throw err.failedPrecondition('Booking already paid');
  }

  const chargedBs = booking.finalPrice ?? booking.estimatedPrice;
  const amountToCapture = toCents(chargedBs);
  logger.info('capturePayment', 'start', { bookingId, amountToCapture });

  try {
    const intent = await stripe.captureIntent(stripePaymentIntentId, amountToCapture);
    const captured = intent.amount_received ?? amountToCapture;
    if (captured < amountToCapture) {
      logger.warn('capturePayment', 'captured less than charged', { bookingId, captured, amountToCapture });
    }

    const paymentRef = db.collection('payments').doc();
    const payment: PaymentDoc = {
      bookingId,
      riderId: booking.riderId,
      stripePaymentIntentId,
      amount: captured,
      currency: intent.currency ?? 'bob',
      status: intent.status === 'succeeded' ? 'captured' : 'failed',
      createdAt: admin.firestore.Timestamp.now(),
    };

    const batch = db.batch();
    batch.set(paymentRef, payment);
    batch.update(bookingRef, {
      paymentId: paymentRef.id,
      // El precio final se mantiene si ya existía; si no, es lo cobrado.
      ...(booking.finalPrice == null ? { finalPrice: fromCents(captured) } : {}),
    });
    await batch.commit();

    logger.info('capturePayment', 'success', { paymentId: paymentRef.id });
    return { paymentId: paymentRef.id, status: payment.status, amount: captured, currency: payment.currency };
  } catch (e) {
    logger.error('capturePayment', 'stripe error', { error: String(e) });
    throw err.paymentFailed(String(e));
  }
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
    const now = admin.firestore.Timestamp.now();
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
  requireAuth(req);
  const { customerId } = req.data as { customerId: string };
  if (!customerId) throw err.invalidArgument('customerId required');

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
  requireAuth(req);
  const { customerId, paymentMethodId } = req.data as {
    customerId: string;
    paymentMethodId: string;
  };
  if (!customerId || !paymentMethodId) throw err.invalidArgument('customerId and paymentMethodId required');

  await stripe.attachPaymentMethod(customerId, paymentMethodId);
  return { success: true };
});

// ---------------------------------------------------------------------------
// detachPaymentMethod
// ---------------------------------------------------------------------------

export const detachPaymentMethod = onCall(async (req) => {
  requireAuth(req);
  const { paymentMethodId } = req.data as { paymentMethodId: string };
  if (!paymentMethodId) throw err.invalidArgument('paymentMethodId required');

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

export const onBookingCreated = onDocumentCreated('bookings/{bookingId}', async (event) => {
  const booking = event.data?.data() as BookingDoc | undefined;
  if (!booking) return;
  const vehicleClass = booking.class ?? booking.vehicleClass ?? 'business';

  // Control de tarifas: la reserva debe respetar la tarifa vigente del admin.
  const id = fareId(vehicleClass, booking.serviceType ?? 'oneWay');
  const ruleSnap = await db.collection('pricingRules').doc(id).get();
  const rule = ruleSnap.exists ? (ruleSnap.data() as FareRule) : DEFAULT_FARES[id];
  const check = checkBookingPrice(booking, rule);
  if (!check.ok) {
    logger.warn('onBookingCreated', 'pricing review', { bookingId: event.params.bookingId, ...check });
    await event.data!.ref.update({
      pricingReview: { reason: check.reason, expectedMinimum: check.expectedMinimum ?? null },
    });
  }

  logger.info('onBookingCreated', 'notifying drivers', {
    bookingId: event.params.bookingId,
    vehicleClass,
  });

  const driversSnap = await db
    .collection('driverProfiles')
    .where('isAvailable', '==', true)
    .where('documentsVerified', '==', true)
    .limit(20)
    .get();

  const tokens: string[] = [];
  for (const doc of driversSnap.docs) {
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

  const now = admin.firestore.Timestamp.now();

  // 1. Chófer: libre al terminar o cancelar; suma el viaje al completar.
  const book = driverBookkeeping(before, after);
  if (book) {
    await db.collection('driverProfiles').doc(book.driverId).set(
      {
        isAvailable: true,
        ...(book.countRide ? { totalRides: admin.firestore.FieldValue.increment(1) } : {}),
      },
      { merge: true },
    );
  }

  // 2. Registro del trayecto (rides/{bookingId}): lo escribe solo el servidor.
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

  // 3. Aviso al pasajero: push y bandeja de notificaciones de la app.
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
    db.collection('vehicles').doc(`v_${after.driverId}`).get(),
  ]);
  await event.data!.after.ref.update(
    driverSnapshot(userSnap.data() as never, vehicleSnap.data() as never),
  );
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
    createdAt: admin.firestore.Timestamp.now(),
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
  await bookingRef.update({ status: 'completed' as BookingStatus, updatedAt: admin.firestore.Timestamp.now() });
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
        isRecentlySeen((p.data()!.lastSeenAt as admin.firestore.Timestamp | undefined)?.toMillis(), nowMs),
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
        updatedAt: admin.firestore.Timestamp.now(),
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
        updatedAt: admin.firestore.Timestamp.now(),
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
    .where('scheduledAt', '<', admin.firestore.Timestamp.fromMillis(nowMs - 30 * 60 * 1000))
    .limit(450)
    .get();

  const expired = staleSnap.docs.filter((d) =>
    isExpiredPending(
      {
        status: d.data().status,
        scheduledAtMs: (d.data().scheduledAt as admin.firestore.Timestamp | undefined)?.toMillis(),
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
      updatedAt: admin.firestore.Timestamp.now(),
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
