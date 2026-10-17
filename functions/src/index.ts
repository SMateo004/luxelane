import * as admin from 'firebase-admin';
import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentUpdated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as stripe from './stripe_service';
import { logger } from './logger';
import * as err from './errors';
import { checkBookingPrice, DEFAULT_FARES, fareId, FareRule } from './pricing';
import { computeSettlement, planBackfill, Settlement } from './settlement';
import { rankCandidates } from './assignment';
import { fromCents, toCents } from './money';

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
  // Place.toJson guarda la posición como GeoPoint en `coordinates`.
  origin?: { coordinates?: admin.firestore.GeoPoint };
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
  // Interruptor "Notificaciones push" del panel admin (activado por defecto).
  const global = await db.collection('config').doc('global').get();
  if (global.data()?.pushNotificationsEnabled === false) return;
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
    // Stripe no cobra más de lo autorizado: si queda por debajo, el precio
    // final pasa a ser lo cobrado para que el reparto use dinero real.
    const shortfall = captured < amountToCapture;
    if (shortfall) {
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
      ...(booking.finalPrice == null || shortfall ? { finalPrice: fromCents(captured) } : {}),
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
    // La app del chófer no lee pagos: la reserva le indica que ya no cobra.
    if (payment.bookingId) {
      batch.update(db.collection('bookings').doc(payment.bookingId), { refunded: true });
    }
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

/** Cada usuario solo opera sobre su propio cliente de Stripe. */
async function requireOwnCustomer(uid: string, customerId: string): Promise<void> {
  const user = await db.collection('users').doc(uid).get();
  if (user.data()?.stripeCustomerId !== customerId) {
    throw err.permissionDenied('Not your payment profile');
  }
}

export const listPaymentMethods = onCall(async (req) => {
  const uid = requireAuth(req);
  const { customerId } = req.data as { customerId: string };
  if (!customerId) throw err.invalidArgument('customerId required');
  await requireOwnCustomer(uid, customerId);

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
  const { customerId, paymentMethodId } = req.data as {
    customerId: string;
    paymentMethodId: string;
  };
  if (!customerId || !paymentMethodId) throw err.invalidArgument('customerId and paymentMethodId required');
  await requireOwnCustomer(uid, customerId);

  await stripe.attachPaymentMethod(customerId, paymentMethodId);
  return { success: true };
});

// ---------------------------------------------------------------------------
// detachPaymentMethod
// ---------------------------------------------------------------------------

export const detachPaymentMethod = onCall(async (req) => {
  const uid = requireAuth(req);
  const { paymentMethodId } = req.data as { paymentMethodId: string };
  if (!paymentMethodId) throw err.invalidArgument('paymentMethodId required');
  const owner = await stripe.paymentMethodCustomer(paymentMethodId);
  if (!owner) throw err.permissionDenied('Not your payment method');
  await requireOwnCustomer(uid, owner);

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

  if (!before || !after || before.status === after.status) return;

  logger.info('onBookingStatusChanged', 'status changed', {
    bookingId: event.params.bookingId,
    from: before.status,
    to: after.status,
  });

  const statusMessages: Partial<Record<BookingStatus, string>> = {
    confirmed: 'Tu chófer ha sido asignado.',
    driver_arriving: 'Tu chófer está en camino.',
    driver_arrived: 'Tu chófer te espera en el punto de recogida.',
    in_progress: 'Tu trayecto ha comenzado.',
    completed: 'Has llegado. Gracias por viajar con Luxelane.',
    cancelled: 'Tu reserva ha sido cancelada.',
  };

  const message = statusMessages[after.status];
  if (!message) return;

  const tokens = await getUserTokens(after.riderId);
  await sendPush(tokens, 'Luxelane', message);
});

// ---------------------------------------------------------------------------
// releaseDriver  (onUpdate /bookings/{bookingId})
// Único punto que libera al chófer al cerrarse un viaje, lo cierre quien lo
// cierre (chófer, pasajero, admin o el viaje en /rides), y que suma el viaje
// a su contador. Si el pasajero cancela, avisa al chófer.
// ---------------------------------------------------------------------------

export const releaseDriver = onDocumentUpdated('bookings/{bookingId}', async (event) => {
  const before = event.data?.before.data() as BookingDoc | undefined;
  const after = event.data?.after.data() as BookingDoc | undefined;
  if (!before || !after || before.status === after.status) return;
  if (after.status !== 'completed' && after.status !== 'cancelled') return;

  // Un chófer reasignado antes del cierre ya lo liberó quien lo reasignó.
  const driverId = after.driverId;
  if (!driverId) return;

  const driverRef = db.collection('driverProfiles').doc(driverId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(driverRef);
    if (!snap.exists) return;
    tx.update(driverRef, {
      isAvailable: true,
      ...(after.status === 'completed'
        ? { totalRides: (snap.data()?.totalRides ?? 0) + 1 }
        : {}),
    });
  });

  if (after.status === 'cancelled' && (after as { cancelledBy?: string }).cancelledBy !== 'admin') {
    const tokens = await getUserTokens(driverId);
    await sendPush(tokens, 'Viaje cancelado', 'El pasajero canceló la reserva. Ya estás disponible.');
  }
  logger.info('releaseDriver', 'released', { bookingId: event.params.bookingId, driverId, status: after.status });
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

  // Solo cierra reservas abiertas: una cancelada no se reabre. Liberar al
  // chófer y contar el viaje lo hace releaseDriver al completarse la reserva.
  const bookingRef = db.collection('bookings').doc(after.bookingId);
  await db.runTransaction(async (tx) => {
    const bookingSnap = await tx.get(bookingRef);
    const status = (bookingSnap.data() as BookingDoc | undefined)?.status;
    if (!status || status === 'completed' || status === 'cancelled') return;
    tx.update(bookingRef, { status: 'completed' as BookingStatus, updatedAt: admin.firestore.Timestamp.now() });
  });
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
  const ranked = rankCandidates(
    profiles
      .filter((p) => p.exists)
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
      : null,
  );

  // Del más cercano al más lejano; la transacción evita asignar una reserva
  // ya tomada o un chófer que acaba de ocuparse.
  for (const driverId of ranked) {
    const driverRef = db.collection('driverProfiles').doc(driverId);
    const outcome = await db.runTransaction(async (tx) => {
      const [b, d] = await Promise.all([tx.get(bookingRef), tx.get(driverRef)]);
      if ((b.data() as BookingDoc | undefined)?.status !== 'pending') return 'taken';
      if (!d.data()?.isAvailable) return 'busy';
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

  // Solo un chófer activo (no bloqueado desde el panel) acepta viajes.
  const me = (await db.collection('users').doc(driverId).get()).data();
  if (me?.role !== 'driver' || me?.isActive === false) throw err.permissionDenied('Active driver required');

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
      if (driverSnap.data()?.documentsVerified !== true) throw err.permissionDenied('Driver not verified');
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
      await sendPush(tokens, 'Chófer asignado', 'Tu chófer está en camino.');
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

  // Solo las reservas cuya hora de recogida pasó hace más de 30 min sin
  // chófer; las programadas para otro día siguen esperando.
  const cutoff = new Date(Date.now() - 30 * 60 * 1000);
  const staleSnap = await db
    .collection('bookings')
    .where('status', '==', 'pending')
    .where('scheduledAt', '<', admin.firestore.Timestamp.fromDate(cutoff))
    .get();

  // Un batch admite 500 escrituras.
  const now = admin.firestore.Timestamp.now();
  for (let i = 0; i < staleSnap.docs.length; i += 500) {
    const batch = db.batch();
    staleSnap.docs.slice(i, i + 500).forEach((doc) => {
      batch.update(doc.ref, { status: 'cancelled' as BookingStatus, updatedAt: now });
    });
    await batch.commit();
  }
  logger.info('scheduledCleanup', 'done', { cancelled: staleSnap.size });
});

// ---------------------------------------------------------------------------
// sendRideReceipt  (onWrite /payments/{paymentId})
// Los cobros se crean ya capturados (capturePayment, cobro manual del admin),
// así que se escucha también la creación.
// ---------------------------------------------------------------------------

export const sendRideReceipt = onDocumentWritten('payments/{paymentId}', async (event) => {
  const before = event.data?.before.data() as PaymentDoc | undefined;
  const after = event.data?.after.data() as PaymentDoc | undefined;

  if (!after || after.status !== 'captured' || before?.status === 'captured') return;

  logger.info('sendRideReceipt', 'sending receipt', { paymentId: event.params.paymentId });

  const tokens = await getUserTokens(after.riderId);
  await sendPush(
    tokens,
    'Pago confirmado',
    `Se cobraron Bs ${(after.amount / 100).toFixed(2)} por tu trayecto.`,
  );
});
