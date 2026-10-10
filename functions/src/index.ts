import * as admin from 'firebase-admin';
import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as stripe from './stripe_service';
import { logger } from './logger';
import * as err from './errors';
import { checkBookingPrice, DEFAULT_FARES, fareId, FareRule } from './pricing';
import { computeSettlement, planBackfill, Settlement } from './settlement';

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
  requireAuth(req);
  const { bookingId, riderId, stripePaymentIntentId, amount, currency } = req.data as {
    bookingId: string;
    riderId: string;
    stripePaymentIntentId: string;
    amount: number;
    currency: string;
  };

  if (!bookingId || !stripePaymentIntentId) throw err.invalidArgument('bookingId and stripePaymentIntentId required');

  const bookingSnap = await db.collection('bookings').doc(bookingId).get();
  if (!bookingSnap.exists) throw err.notFound('Booking not found');

  const booking = bookingSnap.data() as BookingDoc;
  if (booking.status !== 'completed') throw err.failedPrecondition('Ride must be completed before capture');

  logger.info('capturePayment', 'start', { bookingId, amount });

  try {
    const intent = await stripe.captureIntent(stripePaymentIntentId);

    const paymentRef = db.collection('payments').doc();
    const payment: PaymentDoc = {
      bookingId,
      riderId,
      stripePaymentIntentId,
      amount,
      currency,
      status: intent.status === 'succeeded' ? 'captured' : 'failed',
      createdAt: admin.firestore.Timestamp.now(),
    };

    await paymentRef.set(payment);
    await db.collection('bookings').doc(bookingId).update({
      paymentId: paymentRef.id,
      finalPrice: amount / 100,
    });

    logger.info('capturePayment', 'success', { paymentId: paymentRef.id });
    return { paymentId: paymentRef.id, status: payment.status };
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

  await sendPush(tokens, 'New Ride Available', `${vehicleClass} · Bs ${booking.estimatedPrice}`);
});

// ---------------------------------------------------------------------------
// onBookingStatusChanged  (onUpdate /bookings/{bookingId})
// ---------------------------------------------------------------------------

export const onBookingStatusChanged = onDocumentUpdated('bookings/{bookingId}', async (event) => {
  const before = event.data?.before.data() as BookingDoc | undefined;
  const after = event.data?.after.data() as BookingDoc | undefined;

  if (!before || !after || before.status === after.status) return;

  logger.info('onBookingStatusChanged', 'status changed', {
    bookingId: event.params.bookingId,
    from: before.status,
    to: after.status,
  });

  const statusMessages: Partial<Record<BookingStatus, string>> = {
    confirmed: 'Your driver has been assigned',
    driver_arriving: 'Your driver is on the way',
    driver_arrived: 'Your driver has arrived',
    in_progress: 'Your ride has started',
    completed: 'You have arrived. Have a great day!',
    cancelled: 'Your booking has been cancelled',
  };

  const message = statusMessages[after.status];
  if (!message) return;

  const tokens = await getUserTokens(after.riderId);
  await sendPush(tokens, 'Luxelane', message);
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

  logger.info('onRideCompleted', 'ride completed', { rideId: event.params.rideId });

  await db.collection('bookings').doc(after.bookingId).update({ status: 'completed' as BookingStatus, updatedAt: admin.firestore.Timestamp.now() });

  const driverRef = db.collection('driverProfiles').doc(after.driverId);
  await db.runTransaction(async (tx) => {
    const driverSnap = await tx.get(driverRef);
    const current = driverSnap.data() ?? {};
    tx.update(driverRef, {
      totalRides: (current.totalRides ?? 0) + 1,
      isAvailable: true,
    });
  });
});

// ---------------------------------------------------------------------------
// assignNearestDriver  (HTTPS Callable)
// ---------------------------------------------------------------------------

export const assignNearestDriver = onCall(async (req) => {
  requireAuth(req);
  const { bookingId, vehicleClass } = req.data as {
    bookingId: string;
    vehicleClass: string;
  };

  if (!bookingId || !vehicleClass) throw err.invalidArgument('bookingId and vehicleClass required');

  const bookingSnap = await db.collection('bookings').doc(bookingId).get();
  if (!bookingSnap.exists) throw err.notFound('Booking not found');

  const booking = bookingSnap.data() as BookingDoc;
  if (booking.status !== 'pending') throw err.failedPrecondition('Booking must be pending');

  logger.info('assignNearestDriver', 'searching', { bookingId, vehicleClass });

  const vehicleSnap = await db
    .collection('vehicles')
    .where('vehicleClass', '==', vehicleClass)
    .where('isActive', '==', true)
    .limit(10)
    .get();

  if (vehicleSnap.empty) {
    logger.warn('assignNearestDriver', 'no vehicles found', { vehicleClass });
    return { assigned: false, reason: 'no_drivers_available' };
  }

  const vehicleDoc = vehicleSnap.docs[0];
  const driverId = vehicleDoc.data().driverId as string;

  const driverSnap = await db.collection('driverProfiles').doc(driverId).get();
  if (!driverSnap.exists || !driverSnap.data()?.isAvailable) {
    return { assigned: false, reason: 'no_drivers_available' };
  }

  await db.collection('bookings').doc(bookingId).update({
    driverId,
    status: 'confirmed' as BookingStatus,
    updatedAt: admin.firestore.Timestamp.now(),
  });

  await db.collection('driverProfiles').doc(driverId).update({ isAvailable: false });

  const driverTokens = await getUserTokens(driverId);
  await sendPush(driverTokens, 'New Booking', 'You have been assigned a new ride');

  logger.info('assignNearestDriver', 'assigned', { bookingId, driverId });
  return { assigned: true, driverId };
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

  let riderId = '';

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
      if (!driverSnap.data()?.isAvailable) throw new Error('DRIVER_BUSY');

      riderId = booking.riderId;

      tx.update(bookingRef, {
        driverId,
        status: 'confirmed' as BookingStatus,
        updatedAt: admin.firestore.Timestamp.now(),
      });
      tx.update(driverRef, { isAvailable: false });
    });

    // Notify rider their driver is confirmed
    if (riderId) {
      const tokens = await getUserTokens(riderId);
      await sendPush(tokens, 'Driver Assigned', 'Your driver is on the way!');
    }

    logger.info('acceptBooking', 'success', { bookingId, driverId });
    return { accepted: true };
  } catch (e: any) {
    if (e.message === 'ALREADY_TAKEN') {
      return { accepted: false, reason: 'already_taken' };
    }
    if (e.message === 'DRIVER_BUSY') {
      return { accepted: false, reason: 'driver_busy' };
    }
    logger.error('acceptBooking', 'error', { error: String(e) });
    throw e;
  }
});

// ---------------------------------------------------------------------------
// scheduledCleanup  (daily)
// ---------------------------------------------------------------------------

export const scheduledCleanup = onSchedule('every 24 hours', async () => {
  logger.info('scheduledCleanup', 'start');

  const cutoff = new Date(Date.now() - 30 * 60 * 1000);
  const staleSnap = await db
    .collection('bookings')
    .where('status', '==', 'pending')
    .where('createdAt', '<', admin.firestore.Timestamp.fromDate(cutoff))
    .get();

  const batch = db.batch();
  staleSnap.docs.forEach((doc) => {
    batch.update(doc.ref, {
      status: 'cancelled' as BookingStatus,
      updatedAt: admin.firestore.Timestamp.now(),
    });
  });

  await batch.commit();
  logger.info('scheduledCleanup', 'done', { cancelled: staleSnap.size });
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
    'Payment Confirmed',
    `Your ride has been charged Bs ${(after.amount / 100).toFixed(2)}`,
  );
});
