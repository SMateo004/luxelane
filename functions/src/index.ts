import * as admin from 'firebase-admin';
import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as stripe from './stripe_service';
import { STRIPE_SECRET_KEY } from './stripe_service';
import { logger } from './logger';
import * as err from './errors';
import {
  BookingStatus,
  UserRole,
  canCapture,
  chunk,
  formatMoney,
  isStalePending,
  isValidAmount,
  toMinorUnits,
} from './policy';

admin.initializeApp();
const db = admin.firestore();

const DEFAULT_CURRENCY = 'bob';
const stripeOpts = { secrets: [STRIPE_SECRET_KEY] };

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type PaymentStatus = 'pending' | 'captured' | 'refunded' | 'failed';

interface BookingDoc {
  riderId: string;
  driverId?: string;
  status: BookingStatus;
  // Dart writes `class`; `vehicleClass` kept for older documents.
  class?: string;
  vehicleClass?: string;
  estimatedPrice: number;
  finalPrice?: number;
  currency?: string;
  paymentId?: string;
  stripePaymentIntentId?: string;
  scheduledAt?: admin.firestore.Timestamp;
  createdAt?: admin.firestore.Timestamp;
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

interface UserDoc {
  role?: UserRole;
  stripeCustomerId?: string;
  fcmTokens?: string[];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function requireAuth(req: CallableRequest): string {
  if (!req.auth?.uid) throw err.unauthenticated();
  return req.auth.uid;
}

async function getUser(uid: string): Promise<UserDoc> {
  const doc = await db.collection('users').doc(uid).get();
  return (doc.data() as UserDoc | undefined) ?? {};
}

async function requireAdmin(req: CallableRequest): Promise<string> {
  const uid = requireAuth(req);
  const user = await getUser(uid);
  if (user.role !== 'admin') throw err.permissionDenied('Admin only');
  return uid;
}

/**
 * Resolves the caller's own Stripe customer. If the client passed a
 * customerId it must match — callers can never act on someone else's customer.
 */
async function requireOwnCustomer(uid: string, claimed?: string): Promise<string> {
  const user = await getUser(uid);
  const customerId = user.stripeCustomerId;
  if (!customerId) throw err.failedPrecondition('No payment profile for this user');
  if (claimed && claimed !== customerId) throw err.permissionDenied();
  return customerId;
}

function bookingClass(b: BookingDoc): string {
  return b.class ?? b.vehicleClass ?? 'business';
}

async function sendPush(tokens: string[], title: string, body: string): Promise<void> {
  if (!tokens.length) return;
  await admin.messaging().sendEachForMulticast({ tokens, notification: { title, body } });
}

async function getUserTokens(userId: string): Promise<string[]> {
  return (await getUser(userId)).fcmTokens ?? [];
}

async function writeAudit(action: string, data: Record<string, unknown>): Promise<void> {
  await db.collection('admin_logs').add({
    action,
    ...data,
    actor: 'system',
    timestamp: admin.firestore.Timestamp.now(),
  });
}

/**
 * Captures the authorised amount for a completed booking. The amount always
 * comes from the booking document, never from the client.
 */
async function captureBookingPayment(bookingId: string, booking: BookingDoc): Promise<string | null> {
  if (booking.paymentId || !booking.stripePaymentIntentId) return null;

  const rider = await getUser(booking.riderId);
  const intent = await stripe.retrieveIntent(booking.stripePaymentIntentId);
  if (intent.customer !== rider.stripeCustomerId || intent.metadata?.uid !== booking.riderId) {
    logger.error('captureBookingPayment', 'intent does not belong to rider', { bookingId });
    throw err.permissionDenied('Payment does not belong to this booking');
  }

  const price = booking.finalPrice ?? booking.estimatedPrice;
  const amount = Math.min(toMinorUnits(price), intent.amount_capturable || intent.amount);
  const captured =
    intent.status === 'requires_capture'
      ? await stripe.captureIntent(intent.id, amount)
      : intent;

  const paymentRef = db.collection('payments').doc();
  const payment: PaymentDoc = {
    bookingId,
    riderId: booking.riderId,
    stripePaymentIntentId: intent.id,
    amount,
    currency: captured.currency,
    status: captured.status === 'succeeded' ? 'captured' : 'failed',
    createdAt: admin.firestore.Timestamp.now(),
  };
  await paymentRef.set(payment);
  await db.collection('bookings').doc(bookingId).update({
    paymentId: paymentRef.id,
    finalPrice: amount / 100,
  });
  return paymentRef.id;
}

// ---------------------------------------------------------------------------
// createPaymentIntent — authorises (does not charge) the rider's card
// ---------------------------------------------------------------------------

export const createPaymentIntent = onCall(stripeOpts, async (req) => {
  const uid = requireAuth(req);
  const { amount, currency, customerId: claimed } = req.data as {
    amount: number;
    currency?: string;
    customerId?: string;
  };

  if (!isValidAmount(amount)) throw err.invalidArgument('amount must be a positive integer in minor units');
  const customerId = await requireOwnCustomer(uid, claimed);

  logger.info('createPaymentIntent', 'start', { uid, amount, currency });

  try {
    const clientSecret = await stripe.createIntent({
      amount,
      currency: (currency ?? DEFAULT_CURRENCY).toLowerCase(),
      customerId,
      metadata: { uid },
    });
    const paymentIntentId = clientSecret.split('_secret_')[0];
    logger.info('createPaymentIntent', 'success', { uid, paymentIntentId });
    return { clientSecret, paymentIntentId };
  } catch (e) {
    logger.error('createPaymentIntent', 'stripe error', { error: String(e) });
    throw err.paymentFailed(String(e));
  }
});

// ---------------------------------------------------------------------------
// capturePayment — manual capture by admin or the assigned driver.
// Normally capture happens automatically in onBookingStatusChanged.
// ---------------------------------------------------------------------------

export const capturePayment = onCall(stripeOpts, async (req) => {
  const uid = requireAuth(req);
  const { bookingId } = req.data as { bookingId: string };
  if (!bookingId) throw err.invalidArgument('bookingId required');

  const bookingSnap = await db.collection('bookings').doc(bookingId).get();
  if (!bookingSnap.exists) throw err.notFound('Booking not found');
  const booking = bookingSnap.data() as BookingDoc;

  const caller = await getUser(uid);
  if (!canCapture({ uid, role: caller.role }, booking)) throw err.permissionDenied();
  if (booking.status !== 'completed') throw err.failedPrecondition('Ride must be completed before capture');
  if (booking.paymentId) return { paymentId: booking.paymentId, status: 'captured' };
  if (!booking.stripePaymentIntentId) throw err.failedPrecondition('Booking has no payment authorisation');

  try {
    const paymentId = await captureBookingPayment(bookingId, booking);
    logger.info('capturePayment', 'success', { bookingId, paymentId });
    return { paymentId, status: 'captured' };
  } catch (e) {
    logger.error('capturePayment', 'stripe error', { error: String(e) });
    throw err.paymentFailed(String(e));
  }
});

// ---------------------------------------------------------------------------
// refundPayment — admin only
// ---------------------------------------------------------------------------

export const refundPayment = onCall(stripeOpts, async (req) => {
  const uid = await requireAdmin(req);
  const { paymentId } = req.data as { paymentId: string };
  if (!paymentId) throw err.invalidArgument('paymentId required');

  const snap = await db.collection('payments').doc(paymentId).get();
  if (!snap.exists) throw err.notFound('Payment not found');

  const payment = snap.data() as PaymentDoc;
  if (payment.status !== 'captured') throw err.failedPrecondition('Only captured payments can be refunded');

  logger.info('refundPayment', 'start', { paymentId, by: uid });

  try {
    await stripe.refundIntent(payment.stripePaymentIntentId);
    await db.collection('payments').doc(paymentId).update({ status: 'refunded' as PaymentStatus });
    await writeAudit('payment_refunded', { paymentId, bookingId: payment.bookingId, by: uid });
    logger.info('refundPayment', 'success', { paymentId });
    return { status: 'refunded' };
  } catch (e) {
    logger.error('refundPayment', 'stripe error', { error: String(e) });
    throw err.paymentFailed(String(e));
  }
});

// ---------------------------------------------------------------------------
// Saved cards — always scoped to the caller's own Stripe customer
// ---------------------------------------------------------------------------

export const listPaymentMethods = onCall(stripeOpts, async (req) => {
  const uid = requireAuth(req);
  const { customerId: claimed } = (req.data ?? {}) as { customerId?: string };
  const customerId = await requireOwnCustomer(uid, claimed);

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

export const attachPaymentMethod = onCall(stripeOpts, async (req) => {
  const uid = requireAuth(req);
  const { customerId: claimed, paymentMethodId } = req.data as {
    customerId?: string;
    paymentMethodId: string;
  };
  if (!paymentMethodId) throw err.invalidArgument('paymentMethodId required');
  const customerId = await requireOwnCustomer(uid, claimed);

  await stripe.attachPaymentMethod(customerId, paymentMethodId);
  return { success: true };
});

export const detachPaymentMethod = onCall(stripeOpts, async (req) => {
  const uid = requireAuth(req);
  const { paymentMethodId } = req.data as { paymentMethodId: string };
  if (!paymentMethodId) throw err.invalidArgument('paymentMethodId required');
  const customerId = await requireOwnCustomer(uid);

  const method = await stripe.retrievePaymentMethod(paymentMethodId);
  if (method.customer !== customerId) throw err.permissionDenied();

  await stripe.detachPaymentMethod(paymentMethodId);
  return { success: true };
});

// ---------------------------------------------------------------------------
// createStripeCustomer  (onCreate /users/{uid})
// ---------------------------------------------------------------------------

export const createStripeCustomer = onDocumentCreated(
  { document: 'users/{uid}', ...stripeOpts },
  async (event) => {
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
  },
);

// ---------------------------------------------------------------------------
// onBookingCreated  (onCreate /bookings/{bookingId})
// ---------------------------------------------------------------------------

export const onBookingCreated = onDocumentCreated('bookings/{bookingId}', async (event) => {
  const booking = event.data?.data() as BookingDoc | undefined;
  if (!booking) return;

  const vehicleClass = bookingClass(booking);
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

  const tokenLists = await Promise.all(driversSnap.docs.map((d) => getUserTokens(d.id)));
  const tokens = tokenLists.flat();

  await sendPush(
    tokens,
    'Nueva reserva disponible',
    `${vehicleClass} · ${formatMoney(booking.estimatedPrice, booking.currency ?? DEFAULT_CURRENCY)}`,
  );
});

// ---------------------------------------------------------------------------
// onBookingStatusChanged  (onUpdate /bookings/{bookingId})
// Notifies the rider, and settles the payment authorisation:
//   completed → capture,  cancelled → release the hold.
// ---------------------------------------------------------------------------

export const onBookingStatusChanged = onDocumentUpdated(
  { document: 'bookings/{bookingId}', ...stripeOpts },
  async (event) => {
    const before = event.data?.before.data() as BookingDoc | undefined;
    const after = event.data?.after.data() as BookingDoc | undefined;
    const bookingId = event.params.bookingId;

    if (!before || !after || before.status === after.status) return;

    logger.info('onBookingStatusChanged', 'status changed', {
      bookingId,
      from: before.status,
      to: after.status,
    });

    if (after.status === 'completed') {
      try {
        await captureBookingPayment(bookingId, after);
      } catch (e) {
        logger.error('onBookingStatusChanged', 'capture failed', { bookingId, error: String(e) });
        await writeAudit('payment_capture_failed', { bookingId, error: String(e) });
      }
    }

    if (after.status === 'cancelled' && after.stripePaymentIntentId && !after.paymentId) {
      try {
        await stripe.cancelIntent(after.stripePaymentIntentId);
      } catch (e) {
        logger.error('onBookingStatusChanged', 'release failed', { bookingId, error: String(e) });
      }
    }

    const statusMessages: Partial<Record<BookingStatus, string>> = {
      confirmed: 'Tu chófer ha sido asignado',
      driver_arriving: 'Tu chófer está en camino',
      driver_arrived: 'Tu chófer ha llegado',
      in_progress: 'Tu viaje ha comenzado',
      completed: 'Has llegado. ¡Gracias por viajar con Luxelane!',
      cancelled: 'Tu reserva ha sido cancelada',
    };

    const message = statusMessages[after.status];
    if (!message) return;

    const tokens = await getUserTokens(after.riderId);
    await sendPush(tokens, 'Luxelane', message);
  },
);

// ---------------------------------------------------------------------------
// onRideCompleted  (onUpdate /rides/{rideId})
// ---------------------------------------------------------------------------

export const onRideCompleted = onDocumentUpdated('rides/{rideId}', async (event) => {
  const before = event.data?.before.data() as RideDoc | undefined;
  const after = event.data?.after.data() as RideDoc | undefined;

  if (!before || !after) return;
  if (before.completedAt || !after.completedAt) return;

  logger.info('onRideCompleted', 'ride completed', { rideId: event.params.rideId });

  await db
    .collection('bookings')
    .doc(after.bookingId)
    .update({ status: 'completed' as BookingStatus, updatedAt: admin.firestore.Timestamp.now() });

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
// assignNearestDriver  (HTTPS Callable) — admin/dispatcher only
// ---------------------------------------------------------------------------

export const assignNearestDriver = onCall(async (req) => {
  await requireAdmin(req);
  const { bookingId, vehicleClass } = req.data as {
    bookingId: string;
    vehicleClass: string;
  };

  if (!bookingId || !vehicleClass) throw err.invalidArgument('bookingId and vehicleClass required');

  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();
  if (!bookingSnap.exists) throw err.notFound('Booking not found');

  const booking = bookingSnap.data() as BookingDoc;
  if (booking.status !== 'pending') throw err.failedPrecondition('Booking must be pending');

  logger.info('assignNearestDriver', 'searching', { bookingId, vehicleClass });

  // TODO: rank by distance (geohash) instead of first match.
  const vehicleSnap = await db
    .collection('vehicles')
    .where('class', '==', vehicleClass)
    .where('isActive', '==', true)
    .limit(10)
    .get();

  for (const vehicleDoc of vehicleSnap.docs) {
    const driverId = vehicleDoc.data().driverId as string;
    const driverRef = db.collection('driverProfiles').doc(driverId);

    const assigned = await db.runTransaction(async (tx) => {
      const [b, d] = await Promise.all([tx.get(bookingRef), tx.get(driverRef)]);
      if ((b.data() as BookingDoc | undefined)?.status !== 'pending') return false;
      if (!d.exists || !d.data()?.isAvailable || !d.data()?.documentsVerified) return false;
      tx.update(bookingRef, {
        driverId,
        status: 'confirmed' as BookingStatus,
        updatedAt: admin.firestore.Timestamp.now(),
      });
      tx.update(driverRef, { isAvailable: false });
      return true;
    });

    if (assigned) {
      await sendPush(await getUserTokens(driverId), 'Nueva reserva', 'Se te ha asignado un nuevo viaje');
      logger.info('assignNearestDriver', 'assigned', { bookingId, driverId });
      return { assigned: true, driverId };
    }
  }

  logger.warn('assignNearestDriver', 'no drivers available', { vehicleClass });
  return { assigned: false, reason: 'no_drivers_available' };
});

// ---------------------------------------------------------------------------
// acceptBooking  (HTTPS Callable) — atomic self-assignment by a verified driver.
// Prevents two drivers from accepting the same booking simultaneously.
// ---------------------------------------------------------------------------

export const acceptBooking = onCall(async (req) => {
  const driverId = requireAuth(req);
  const { bookingId } = req.data as { bookingId: string };
  if (!bookingId) throw err.invalidArgument('bookingId required');

  const caller = await getUser(driverId);
  if (caller.role !== 'driver') throw err.permissionDenied('Drivers only');

  const bookingRef = db.collection('bookings').doc(bookingId);
  const driverRef = db.collection('driverProfiles').doc(driverId);

  let riderId = '';

  try {
    await db.runTransaction(async (tx) => {
      const [bookingSnap, driverSnap] = await Promise.all([tx.get(bookingRef), tx.get(driverRef)]);

      if (!bookingSnap.exists) throw err.notFound('Booking not found');
      const booking = bookingSnap.data() as BookingDoc;
      if (booking.status !== 'pending') throw new Error('ALREADY_TAKEN');

      if (!driverSnap.exists) throw err.notFound('Driver profile not found');
      if (!driverSnap.data()?.documentsVerified) throw new Error('NOT_VERIFIED');
      if (!driverSnap.data()?.isAvailable) throw new Error('DRIVER_BUSY');

      riderId = booking.riderId;

      tx.update(bookingRef, {
        driverId,
        status: 'confirmed' as BookingStatus,
        updatedAt: admin.firestore.Timestamp.now(),
      });
      tx.update(driverRef, { isAvailable: false });
    });

    if (riderId) {
      await sendPush(await getUserTokens(riderId), 'Chófer asignado', 'Tu chófer ha confirmado la reserva');
    }

    logger.info('acceptBooking', 'success', { bookingId, driverId });
    return { accepted: true };
  } catch (e: unknown) {
    const message = e instanceof Error ? e.message : '';
    if (message === 'ALREADY_TAKEN') return { accepted: false, reason: 'already_taken' };
    if (message === 'DRIVER_BUSY') return { accepted: false, reason: 'driver_busy' };
    if (message === 'NOT_VERIFIED') return { accepted: false, reason: 'not_verified' };
    logger.error('acceptBooking', 'error', { error: String(e) });
    throw e;
  }
});

// ---------------------------------------------------------------------------
// scheduledCleanup — cancels pending bookings whose pickup time has passed
// ---------------------------------------------------------------------------

export const scheduledCleanup = onSchedule('every 1 hours', async () => {
  logger.info('scheduledCleanup', 'start');

  const now = new Date();
  const pendingSnap = await db.collection('bookings').where('status', '==', 'pending').get();

  const stale = pendingSnap.docs.filter((doc) => {
    const b = doc.data() as BookingDoc;
    return isStalePending(
      { status: b.status, scheduledAt: b.scheduledAt?.toDate(), createdAt: b.createdAt?.toDate() },
      now,
    );
  });

  for (const group of chunk(stale, 450)) {
    const batch = db.batch();
    group.forEach((doc) =>
      batch.update(doc.ref, {
        status: 'cancelled' as BookingStatus,
        cancelReason: 'no_driver_assigned',
        updatedAt: admin.firestore.Timestamp.now(),
      }),
    );
    await batch.commit();
  }

  logger.info('scheduledCleanup', 'done', { cancelled: stale.length });
});

// ---------------------------------------------------------------------------
// sendRideReceipt  (onWrite-ish: fires when a payment becomes captured)
// ---------------------------------------------------------------------------

export const sendRideReceipt = onDocumentCreated('payments/{paymentId}', async (event) => {
  const payment = event.data?.data() as PaymentDoc | undefined;
  if (!payment || payment.status !== 'captured') return;

  logger.info('sendRideReceipt', 'sending receipt', { paymentId: event.params.paymentId });

  await sendPush(
    await getUserTokens(payment.riderId),
    'Pago confirmado',
    `Se cobró ${formatMoney(payment.amount / 100, payment.currency)} por tu viaje`,
  );
});
