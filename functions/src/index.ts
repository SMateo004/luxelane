import * as admin from 'firebase-admin';
import { CallableRequest } from 'firebase-functions/v2/https';
import { secureCallable } from './callable';
import { callableSchemas as schema, parseInput } from './schemas';
import { onDocumentCreated, onDocumentUpdated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineSecret } from 'firebase-functions/params';
import * as bookingService from './booking_service';
import { reconcileOpenRequests } from './reconcile';
import { resolveAdminAlert } from './alerts';
import * as tripFlow from './trip_flow';
import * as incidents from './incidents';
import { isTransient, withRetryPolicy } from './retry_policy';
import * as stripe from './stripe_service';
import { logger } from './logger';
import * as err from './errors';
import { checkBookingPrice, fareId, FareRule } from './pricing';
import { computeSettlement, planBackfill, Settlement } from './settlement';
import { rankCandidates } from './assignment';
import { fromCents, toCents } from './money';

admin.initializeApp();
const db = admin.firestore();

// Funciones que llaman a Stripe: reciben la clave de Secret Manager.
const withStripe = { secrets: [stripe.STRIPE_SECRET_KEY] };

// Clave de servidor de Maps (Routes API) para la distancia de los traslados.
const MAPS_SERVER_KEY = defineSecret('MAPS_SERVER_KEY');

// ---------------------------------------------------------------------------
// quoteBooking / createBooking — el precio lo calcula el servidor (D2)
// ---------------------------------------------------------------------------

const bookingDeps = (): bookingService.BookingDeps => ({ db, mapsKey: MAPS_SERVER_KEY.value() });

/** Precio y desglose de un viaje, sin crear nada. */
export const quoteBooking = secureCallable('quoteBooking', { secrets: [MAPS_SERVER_KEY] }, (req) =>
  bookingService.quoteBooking(bookingDeps(), req.auth?.uid, req.data));

/** Única forma de crear una reserva: con precio del servidor y su solicitud abierta. */
export const createBooking = secureCallable('createBooking', { secrets: [MAPS_SERVER_KEY] }, (req) =>
  bookingService.createBooking(bookingDeps(), req.auth?.uid, req.data));

// ---------------------------------------------------------------------------
// Pasos del viaje desde la recogida (D1): solo el servidor cambia el estado
// ---------------------------------------------------------------------------

// Secreto del código de recogida (HMAC). Sin él no hay códigos: falla cerrado.
const PICKUP_CODE_SECRET = defineSecret('PICKUP_CODE_SECRET');

const tripDeps = (): tripFlow.TripDeps => ({ db, pickupSecret: PICKUP_CODE_SECRET.value() });

/** Único camino del chófer: en camino, llegué, iniciar y completar. */
export const advanceBooking = secureCallable('advanceBooking', {}, (req) =>
  tripFlow.advanceBooking({ db }, req.auth?.uid, req.data));

/** El pasajero de la reserva ve su código mientras el chófer espera. */
export const getPickupCode = secureCallable('getPickupCode', { secrets: [PICKUP_CODE_SECRET] }, (req) =>
  tripFlow.getPickupCode(tripDeps(), req.auth?.uid, req.data));

/** El chófer asignado comprueba el código: driver_arrived → verified. */
export const verifyPickup = secureCallable('verifyPickup', { secrets: [PICKUP_CODE_SECRET] }, (req) =>
  tripFlow.verifyPickup(tripDeps(), req.auth?.uid, req.data));

/** Excepción del admin, con motivo: deja la reserva verificada y avisa. */
export const adminOverrideVerify = secureCallable('adminOverrideVerify', {}, async (req) => {
  const adminId = await requireAdmin(req);
  return tripFlow.adminOverrideVerify({ db }, {
    adminId,
    adminEmail: (req.auth?.token.email as string | undefined) ?? null,
  }, req.data);
});

// ---------------------------------------------------------------------------
// SOS e incidentes (D1, F9)
// ---------------------------------------------------------------------------

// El push del SOS no depende del interruptor «Notificaciones push» del panel:
// es un aviso de seguridad.
const incidentDeps = (): incidents.IncidentDeps => ({
  db,
  push: async (tokens, title, body, data) => {
    await admin.messaging().sendEachForMulticast({ tokens, notification: { title, body }, data });
  },
});

const adminActor = async (req: CallableRequest): Promise<incidents.AdminActor> => ({
  adminId: await requireAdmin(req),
  adminEmail: (req.auth?.token.email as string | undefined) ?? null,
});

/** Pasajero o chófer de la reserva: avisa a central (idempotente, con límite). */
export const raiseIncident = secureCallable('raiseIncident', {}, (req) => incidents.raiseIncident(incidentDeps(), req.auth?.uid, req.data));

/** Falsa alarma: solo quien lo disparó; el admin recibe igual el aviso. */
export const cancelIncident = secureCallable('cancelIncident', {}, (req) => incidents.cancelIncident(incidentDeps(), req.auth?.uid, req.data));

export const acknowledgeIncident = secureCallable('acknowledgeIncident', {}, async (req) =>
  incidents.acknowledgeIncident(incidentDeps(), await adminActor(req), req.data));

/** Cierre con nota obligatoria (mínimo 10 caracteres). */
export const closeIncident = secureCallable('closeIncident', {}, async (req) =>
  incidents.closeIncident(incidentDeps(), await adminActor(req), req.data));

/** Reenvía alerta y push de los incidentes sin reconocer (config/global). */
export const escalateIncidentsJob = onSchedule('every 1 minutes', async () => {
  await incidents.escalateIncidents(incidentDeps());
});

/** Borra las ubicaciones de incidentes cuya retención venció, si se configuró. */
export const purgeIncidentLocationsJob = onSchedule('every 24 hours', async () => {
  const purged = await incidents.purgeIncidentLocations(incidentDeps());
  if (purged.length) logger.info('purgeIncidentLocations', 'purged', { incidents: purged });
});

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type BookingStatus =
  | 'pending'
  | 'confirmed'
  | 'driver_arriving'
  | 'driver_arrived'
  | 'verified'
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
  stripePaymentIntentId?: string;
  stripePaymentMethodId?: string;
  scheduledAt?: admin.firestore.Timestamp;
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

/** Reservas que siguen en curso o pendientes de realizarse. */
const ACTIVE_BOOKING_STATUSES = ['pending', 'confirmed', 'driver_arriving', 'driver_arrived', 'verified', 'in_progress'];

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
  if (user.data()?.role !== 'admin') throw err.permissionDenied('admin_required');
  return uid;
}

async function sendPush(
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<void> {
  if (!tokens.length) return;
  // Interruptor "Notificaciones push" del panel admin (activado por defecto).
  const global = await db.collection('config').doc('global').get();
  if (global.data()?.pushNotificationsEnabled === false) return;
  await admin.messaging().sendEachForMulticast({ tokens, notification: { title, body }, ...(data ? { data } : {}) });
}

async function getUserTokens(userId: string): Promise<string[]> {
  const doc = await db.collection('users').doc(userId).get();
  return (doc.data()?.fcmTokens as string[]) ?? [];
}

// ---------------------------------------------------------------------------
// createPaymentIntent
// ---------------------------------------------------------------------------

// Autoriza la tarjeta para una reserva ya creada. El importe, la moneda y el
// cliente de Stripe salen del servidor; el id del intent queda en la reserva
// para cobrarlo al completar el viaje (captureOnCompletion) o liberarlo si se
// cancela.
/** Margen bajo los 7 días que Stripe mantiene una autorización. */
const HOLD_WINDOW_MS = 6 * 24 * 60 * 60 * 1000;

export const createPaymentIntent = secureCallable('createPaymentIntent', withStripe, async (req) => {
  const uid = requireAuth(req);
  const { bookingId, paymentMethodId } = parseInput(schema.createPaymentIntent, req.data);

  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();
  if (!bookingSnap.exists) throw err.notFound('booking_not_found');
  const booking = bookingSnap.data() as BookingDoc;
  if (booking.riderId !== uid) throw err.permissionDenied('not_your_booking');
  // Un chófer puede aceptar en los segundos entre crear y autorizar.
  if (booking.status !== 'pending' && booking.status !== 'confirmed') {
    throw err.failedPrecondition('booking_not_open');
  }
  if (booking.stripePaymentIntentId || booking.stripePaymentMethodId) {
    throw err.failedPrecondition('already_has_payment');
  }
  const customerId = await ensureStripeCustomerFor(uid);

  // Stripe libera una autorización a los 7 días: para viajes más lejanos se
  // guarda la tarjeta y se cobra al completar (cobro sin el pasajero
  // presente, con la tarjeta que ya autorizó al guardarla).
  const scheduledMs = booking.scheduledAt?.toMillis() ?? Date.now();
  if (scheduledMs - Date.now() > HOLD_WINDOW_MS) {
    if (!paymentMethodId) throw err.invalidArgument('payment_method_required');
    const owner = await stripe.paymentMethodCustomer(paymentMethodId);
    if (owner !== customerId) throw err.permissionDenied('not_your_payment_method');
    await bookingRef.update({ stripePaymentMethodId: paymentMethodId });
    logger.info('createPaymentIntent', 'deferred', { uid, bookingId });
    return { deferred: true };
  }

  const amount = toCents(booking.estimatedPrice);
  if (amount <= 0) throw err.invalidArgument('invalid_amount');
  logger.info('createPaymentIntent', 'start', { uid, bookingId, amount });

  try {
    const { id, clientSecret } = await stripe.createIntent({
      amount,
      currency: 'bob',
      customerId,
      bookingId,
    });
    await bookingRef.update({ stripePaymentIntentId: id });
    logger.info('createPaymentIntent', 'success', { uid, bookingId });
    return { clientSecret };
  } catch (e) {
    logger.error('createPaymentIntent', 'stripe error', { error: String(e) });
    throw err.paymentFailed();
  }
});

// ---------------------------------------------------------------------------
// capturePayment
// ---------------------------------------------------------------------------

export const capturePayment = secureCallable('capturePayment', withStripe, async (req) => {
  const uid = requireAuth(req);
  // El importe y el pasajero salen de la reserva, nunca del cliente.
  const { bookingId, stripePaymentIntentId } = parseInput(schema.capturePayment, req.data);

  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();
  if (!bookingSnap.exists) throw err.notFound('booking_not_found');

  const booking = bookingSnap.data() as BookingDoc;
  if (booking.riderId !== uid) await requireAdmin(req);
  // Solo se cobra el intent de esta reserva: nunca uno que mande el cliente.
  if (!booking.stripePaymentIntentId || booking.stripePaymentIntentId !== stripePaymentIntentId) {
    throw err.permissionDenied('payment_mismatch');
  }
  if (booking.status !== 'completed') throw err.failedPrecondition('ride_not_completed');

  if (booking.paymentId) {
    const existing = await db.collection('payments').doc(booking.paymentId).get();
    if (existing.data()?.status === 'captured') throw err.failedPrecondition('already_paid');
  }

  try {
    return await captureBookingPayment(bookingRef, booking, stripePaymentIntentId);
  } catch (e) {
    logger.error('capturePayment', 'stripe error', { error: String(e) });
    throw err.paymentFailed();
  }
});

/** Cobra lo autorizado de una reserva completada y registra el pago. */
async function captureBookingPayment(
  bookingRef: admin.firestore.DocumentReference,
  booking: BookingDoc,
  stripePaymentIntentId: string,
): Promise<{ paymentId: string; status: PaymentStatus; amount: number; currency: string }> {
  const bookingId = bookingRef.id;
  // Si mientras tanto el admin registró el cobro a mano (efectivo, QR…),
  // no se cobra la tarjeta: se libera la retención.
  const fresh = (await bookingRef.get()).data() as BookingDoc | undefined;
  if (fresh?.paymentId) {
    await stripe.cancelIntent(stripePaymentIntentId);
    logger.warn('capturePayment', 'already paid, hold released', { bookingId });
    return { paymentId: fresh.paymentId, status: 'captured', amount: 0, currency: 'bob' };
  }
  const chargedBs = booking.finalPrice ?? booking.estimatedPrice;
  const amountToCapture = toCents(chargedBs);
  logger.info('capturePayment', 'start', { bookingId, amountToCapture });

  {
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
  }
}

// ---------------------------------------------------------------------------
// captureOnCompletion  (onUpdate /bookings/{bookingId})
// Al completarse un viaje pagado con tarjeta se cobra lo autorizado; si se
// cancela, se libera la retención en la tarjeta del pasajero.
// ---------------------------------------------------------------------------

export const captureOnCompletion = onDocumentUpdated({ document: 'bookings/{bookingId}', ...withStripe }, async (event) => {
  const before = event.data?.before.data() as BookingDoc | undefined;
  const after = event.data?.after.data() as BookingDoc | undefined;
  if (!before || !after || before.status === after.status) return;
  if (after.paymentId) return;
  const intentId = after.stripePaymentIntentId;

  try {
    if (after.status === 'completed' && !intentId && after.stripePaymentMethodId) {
      // Reserva lejana: cobro de la tarjeta guardada al completar.
      const customerId = (await db.collection('users').doc(after.riderId).get()).data()
        ?.stripeCustomerId as string | undefined;
      if (!customerId) throw new Error('rider has no payment profile');
      const id = await stripe.chargeOffSession({
        amount: toCents(after.finalPrice ?? after.estimatedPrice),
        currency: 'bob',
        customerId,
        paymentMethodId: after.stripePaymentMethodId,
        bookingId: event.params.bookingId,
      });
      await event.data!.after.ref.update({ stripePaymentIntentId: id });
      await captureBookingPayment(event.data!.after.ref, after, id);
    } else if (!intentId) {
      return;
    } else if (after.status === 'completed') {
      await captureBookingPayment(event.data!.after.ref, after, intentId);
    } else if (after.status === 'cancelled') {
      await stripe.cancelIntent(intentId);
      logger.info('captureOnCompletion', 'hold released', { bookingId: event.params.bookingId });
    }
  } catch (e) {
    // El admin puede registrar el cobro a mano desde el panel: se marca
    // para que el panel lo permita.
    logger.error('captureOnCompletion', 'failed', { bookingId: event.params.bookingId, error: String(e) });
    if (after.status === 'completed') {
      await event.data!.after.ref.update({ cardPaymentFailed: true });
    }
  }
});

// ---------------------------------------------------------------------------
// refundPayment
// ---------------------------------------------------------------------------

export const refundPayment = secureCallable('refundPayment', withStripe, async (req) => {
  // Solo un admin puede reembolsar: mueve dinero y altera las finanzas.
  const adminId = await requireAdmin(req);
  const { paymentId, reason } = parseInput(schema.refundPayment, req.data);

  const paymentRef = db.collection('payments').doc(paymentId);
  const snap = await paymentRef.get();
  if (!snap.exists) throw err.notFound('payment_not_found');

  const payment = snap.data() as PaymentDoc;
  if (payment.status !== 'captured') throw err.failedPrecondition('not_captured');

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
    throw err.paymentFailed();
  }
});

// ---------------------------------------------------------------------------
// listPaymentMethods
// ---------------------------------------------------------------------------

/** Cada usuario solo opera sobre su propio cliente de Stripe. */
async function requireOwnCustomer(uid: string, customerId: string): Promise<void> {
  const user = await db.collection('users').doc(uid).get();
  if (user.data()?.stripeCustomerId !== customerId) {
    throw err.permissionDenied('not_your_payment_profile');
  }
}

export const listPaymentMethods = secureCallable('listPaymentMethods', withStripe, async (req) => {
  const uid = requireAuth(req);
  const { customerId } = parseInput(schema.listPaymentMethods, req.data);
  await requireOwnCustomer(uid, customerId);

  const [methods, defaultId] = await Promise.all([
    stripe.listPaymentMethods(customerId),
    stripe.defaultPaymentMethod(customerId),
  ]);
  // La predeterminada va primero: la reserva propone la primera tarjeta.
  const cards = methods.map((m) => ({
    id: m.id,
    brand: m.card?.brand,
    last4: m.card?.last4,
    expMonth: m.card?.exp_month,
    expYear: m.card?.exp_year,
    isDefault: m.id === defaultId,
  }));
  cards.sort((a, b) => Number(b.isDefault) - Number(a.isDefault));
  return { cards };
});

// ---------------------------------------------------------------------------
// setDefaultPaymentMethod
// ---------------------------------------------------------------------------

export const setDefaultPaymentMethod = secureCallable('setDefaultPaymentMethod', withStripe, async (req) => {
  const uid = requireAuth(req);
  const { paymentMethodId } = parseInput(schema.setDefaultPaymentMethod, req.data);
  const owner = await stripe.paymentMethodCustomer(paymentMethodId);
  if (!owner) throw err.permissionDenied('not_your_payment_method');
  await requireOwnCustomer(uid, owner);

  await stripe.setDefaultPaymentMethod(owner, paymentMethodId);
  return { success: true };
});

// ---------------------------------------------------------------------------
// attachPaymentMethod
// ---------------------------------------------------------------------------

export const attachPaymentMethod = secureCallable('attachPaymentMethod', withStripe, async (req) => {
  const uid = requireAuth(req);
  const { customerId, paymentMethodId } = parseInput(schema.attachPaymentMethod, req.data);
  await requireOwnCustomer(uid, customerId);

  await stripe.attachPaymentMethod(customerId, paymentMethodId);
  return { success: true };
});

// ---------------------------------------------------------------------------
// detachPaymentMethod
// ---------------------------------------------------------------------------

export const detachPaymentMethod = secureCallable('detachPaymentMethod', withStripe, async (req) => {
  const uid = requireAuth(req);
  const { paymentMethodId } = parseInput(schema.detachPaymentMethod, req.data);
  const owner = await stripe.paymentMethodCustomer(paymentMethodId);
  if (!owner) throw err.permissionDenied('not_your_payment_method');
  await requireOwnCustomer(uid, owner);

  // Una reserva futura se cobra fuera de sesión con esta tarjeta: quitarla
  // dejaría ese viaje sin pago.
  const inUse = await db.collection('bookings')
    .where('riderId', '==', uid)
    .where('stripePaymentMethodId', '==', paymentMethodId)
    .where('status', 'in', ACTIVE_BOOKING_STATUSES)
    .limit(1).get();
  if (!inUse.empty) throw err.failedPrecondition('card-in-use');

  await stripe.detachPaymentMethod(paymentMethodId);
  return { success: true };
});

// ---------------------------------------------------------------------------
// deleteAccount
// ---------------------------------------------------------------------------

// El propio usuario elimina su cuenta (exigido por App Store y Google Play).
// Se borran el perfil, los avisos, el perfil de chófer, el cliente de Stripe
// y el acceso; las reservas y pagos se conservan por obligación contable y
// solo guardan el uid, que deja de apuntar a datos personales.
export const deleteAccount = secureCallable('deleteAccount', withStripe, async (req) => {
  const uid = requireAuth(req);
  parseInput(schema.deleteAccount, req.data);
  const userRef = db.collection('users').doc(uid);
  const user = (await userRef.get()).data();
  if (user?.role === 'admin') {
    throw err.failedPrecondition('admin_account');
  }

  const [asRider, asDriver] = await Promise.all([
    db.collection('bookings').where('riderId', '==', uid)
      .where('status', 'in', ACTIVE_BOOKING_STATUSES).limit(1).get(),
    db.collection('bookings').where('driverId', '==', uid)
      .where('status', 'in', ACTIVE_BOOKING_STATUSES).limit(1).get(),
  ]);
  if (!asRider.empty || !asDriver.empty) {
    throw err.failedPrecondition('active-bookings');
  }

  if (user?.stripeCustomerId) {
    try {
      await stripe.deleteCustomer(user.stripeCustomerId);
    } catch (e) {
      // Un cliente ya borrado en Stripe no impide eliminar la cuenta.
      logger.warn('deleteAccount', 'stripe customer not deleted', { uid, error: String(e) });
    }
  }

  const notifications = await userRef.collection('notifications').get();
  const vehicles = await db.collection('vehicles').where('driverId', '==', uid).get();
  const refs = notifications.docs.map((d) => d.ref);
  // Lotes de 400 para no rozar el límite de 500 escrituras por lote.
  for (let i = 0; i < refs.length; i += 400) {
    const batch = db.batch();
    refs.slice(i, i + 400).forEach((r) => batch.delete(r));
    await batch.commit();
  }
  const batch = db.batch();
  // Los vehículos siguen en el historial de reservas, pero salen de servicio.
  vehicles.docs.forEach((v) => batch.update(v.ref, { isActive: false }));
  batch.delete(db.collection('driverProfiles').doc(uid));
  batch.delete(userRef);
  batch.set(db.collection('admin_logs').doc(), {
    adminId: uid,
    adminEmail: req.auth?.token.email ?? null,
    action: 'delete_account',
    targetId: uid,
    targetType: 'user',
    details: `Cuenta eliminada por el usuario (${user?.role ?? 'sin perfil'})`,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await batch.commit();

  await admin.auth().deleteUser(uid);
  logger.info('deleteAccount', 'success', { uid });
  return { success: true };
});

// ---------------------------------------------------------------------------
// createStripeCustomer  (onCreate /users/{uid})
// ---------------------------------------------------------------------------

/**
 * Devuelve el cliente de Stripe del usuario y lo crea si falta (p. ej. si
 * Stripe falló al registrarse). Si dos llamadas compiten, gana la primera
 * en guardarse y la otra borra el cliente que sobra.
 */
async function ensureStripeCustomerFor(uid: string): Promise<string> {
  const ref = db.collection('users').doc(uid);
  const snap = await ref.get();
  const data = snap.data();
  if (!data) throw err.failedPrecondition('no_payment_profile');
  if (data.stripeCustomerId) return data.stripeCustomerId as string;

  const created = await stripe.createCustomer(data.email, data.displayName);
  const kept = await db.runTransaction(async (tx) => {
    const current = (await tx.get(ref)).data()?.stripeCustomerId as string | undefined;
    if (current) return current;
    tx.update(ref, { stripeCustomerId: created });
    return created;
  });
  if (kept !== created) {
    await stripe.deleteCustomer(created).catch(() => undefined);
  }
  return kept;
}

export const createStripeCustomer = onDocumentCreated({ document: 'users/{uid}', ...withStripe }, async (event) => {
  const data = event.data?.data();
  if (!data || data.role !== 'rider') return;

  logger.info('createStripeCustomer', 'start', { uid: event.params.uid });

  try {
    const customerId = await ensureStripeCustomerFor(event.params.uid);
    logger.info('createStripeCustomer', 'success', { uid: event.params.uid, customerId });
  } catch (e) {
    // ensureStripeCustomer lo reintenta cuando el pasajero vaya a pagar.
    logger.error('createStripeCustomer', 'failed', { error: String(e) });
  }
});

// Perfil de pagos bajo demanda (pantalla de tarjetas y alta de tarjeta).
export const ensureStripeCustomer = secureCallable('ensureStripeCustomer', withStripe, async (req) => {
  const uid = requireAuth(req);
  parseInput(schema.ensureStripeCustomer, req.data);
  return { customerId: await ensureStripeCustomerFor(uid) };
});

// ---------------------------------------------------------------------------
// onBookingCreated  (onCreate /bookings/{bookingId})
// ---------------------------------------------------------------------------

// Con reintento: si falla por un error transitorio, la plataforma lo repite
// (retry_policy.ts); un error permanente se registra y no se repite. Todo es
// idempotente: la revisión de tarifa escribe lo mismo y el aviso a los
// chóferes se envía una vez (marca driversNotifiedAt).
export const onBookingCreated = onDocumentCreated({ document: 'bookings/{bookingId}', retry: true }, (event) =>
  withRetryPolicy('onBookingCreated', { bookingId: event.params.bookingId }, () => notifyNewBooking(event)));

async function notifyNewBooking(
  event: Parameters<Parameters<typeof onDocumentCreated>[1]>[0],
): Promise<void> {
  const booking = event.data?.data() as BookingDoc | undefined;
  // Datos que nunca serán válidos: nada que avisar ni reintentar.
  if (!booking || booking.status !== 'pending') return;
  const vehicleClass = booking.class ?? booking.vehicleClass ?? 'business';

  // Red de seguridad: createBooking ya calculó el precio con la tarifa vigente.
  const id = fareId(vehicleClass, booking.serviceType ?? 'oneWay');
  const ruleSnap = await db.collection('pricingRules').doc(id).get();
  // Sin tarifa en Firestore no hay con qué comparar: unknown_fare.
  const rule = ruleSnap.exists ? (ruleSnap.data() as FareRule) : undefined;
  const global = (await db.collection('config').doc('global').get()).data() ?? {};
  // Apps antiguas o escrituras directas pueden saltarse los interruptores
  // del panel: se marcan para revisión igual que una tarifa fuera de rango.
  const blocked = global.isMaintenanceMode === true
    ? 'maintenance'
    : vehicleClass === 'firstClass' && global.firstClassEnabled !== true
      ? 'class_disabled'
      : null;
  const check = blocked
    ? { ok: false as const, reason: blocked, expectedMinimum: undefined }
    : checkBookingPrice(booking, rule);
  if (!check.ok) {
    logger.warn('onBookingCreated', 'pricing review', { bookingId: event.params.bookingId, ...check });
    await event.data!.ref.update({
      pricingReview: { reason: check.reason, expectedMinimum: check.expectedMinimum ?? null },
    });
  }

  // La solicitud abierta la crea createBooking en la misma transacción que
  // la reserva; este trigger solo avisa a los chóferes.

  const firstNotice = await db.runTransaction(async (tx) => {
    const fresh = await tx.get(event.data!.ref);
    // Borrada o ya avisada: no hay nada que hacer.
    if (!fresh.exists || fresh.data()?.driversNotifiedAt) return false;
    tx.update(event.data!.ref, { driversNotifiedAt: admin.firestore.Timestamp.now() });
    return true;
  });
  if (!firstNotice) return;

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

  try {
    await sendPush(
      tokens,
      'Nuevo viaje disponible',
      `${vehicleClassLabel(vehicleClass)} · Bs ${Math.round(booking.estimatedPrice)}`,
    );
  } catch (e) {
    // Si el envío puede salir bien en el reintento, se quita la marca para
    // que el reintento avise; si no, queda marcada y no se repite.
    if (isTransient(e)) {
      await event.data!.ref.update({ driversNotifiedAt: admin.firestore.FieldValue.delete() }).catch(() => undefined);
    }
    throw e;
  }
}

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

  const statusMessages: Partial<Record<BookingStatus, [string, string, string]>> = {
    confirmed: ['Chófer asignado', 'Tu chófer ha sido asignado.', 'booking_confirmed'],
    driver_arriving: ['El chófer está en camino', 'Tu chófer va hacia el punto de recogida.', 'driver_arriving'],
    // Sin el código del pasajero el viaje no empieza: el aviso lo recuerda
    // (el código no va en el aviso; solo se ve en la app).
    driver_arrived: ['El chófer ha llegado', 'Tu chófer te espera. Abre la app y dale tu código de recogida.', 'driver_arrived'],
    // verified no avisa: el pasajero está junto al chófer.
    in_progress: ['Viaje iniciado', 'Tu trayecto ha comenzado.', 'ride_started'],
    completed: ['Viaje completado', 'Has llegado. Gracias por viajar con Luxelane.', 'ride_completed'],
    cancelled: ['Reserva cancelada', 'Tu reserva ha sido cancelada.', 'booking_cancelled'],
  };

  const entry = statusMessages[after.status];
  if (!entry) return;
  const [title, body, type] = entry;

  // Una sola notificación por cambio, escrita aquí y no por la app (que la
  // duplicaba cada vez que se abría el viaje).
  const ref = db.collection('users').doc(after.riderId).collection('notifications').doc();
  await ref.set({
    id: ref.id,
    userId: after.riderId,
    title,
    body,
    type,
    isRead: false,
    bookingId: event.params.bookingId,
    createdAt: admin.firestore.Timestamp.now(),
  });

  const tokens = await getUserTokens(after.riderId);
  await sendPush(tokens, title, body, { bookingId: event.params.bookingId });
});

// ---------------------------------------------------------------------------
// publishDriverInfo  (onUpdate /bookings/{bookingId})
// El pasajero no puede leer /users de otros: el nombre, teléfono y vehículo
// del chófer asignado se copian a la reserva.
// ---------------------------------------------------------------------------

// Al dejar de estar pendiente (aceptada, asignada o cancelada) la solicitud
// desaparece para los demás chóferes.
export const closeOpenRequest = onDocumentUpdated({ document: 'bookings/{bookingId}', retry: true }, async (event) => {
  const before = event.data?.before.data() as BookingDoc | undefined;
  const after = event.data?.after.data() as BookingDoc | undefined;
  if (!before || !after || before.status !== 'pending' || after.status === 'pending') return;
  // Borrar es idempotente: un reintento no cambia nada. Solo se reintentan
  // los errores transitorios (retry_policy.ts).
  await withRetryPolicy('closeOpenRequest', { bookingId: event.params.bookingId }, () =>
    db.collection('openRequests').doc(event.params.bookingId).delete().then(() => undefined));
});

/** El admin marca una alerta como revisada (auditado en el servidor). */
export const resolveAlert = secureCallable('resolveAlert', {}, async (req) => {
  const adminId = await requireAdmin(req);
  return resolveAdminAlert(db, { adminId, adminEmail: (req.auth?.token.email as string | undefined) ?? null }, req.data);
});

// Red de seguridad de openRequests: crea las que faltan, borra las
// huérfanas y avisa al admin en adminAlerts.
export const reconcileOpenRequestsJob = onSchedule('every 15 minutes', async () => {
  const result = await reconcileOpenRequests(db);
  if (result.created.length || result.deleted.length) {
    logger.error('reconcileOpenRequests', 'fixed', { ...result });
  }
});

export const publishDriverInfo = onDocumentUpdated('bookings/{bookingId}', async (event) => {
  const before = event.data?.before.data() as BookingDoc | undefined;
  const after = event.data?.after.data() as BookingDoc | undefined;
  if (!before || !after || before.driverId === after.driverId) return;

  const contactRef = event.data!.after.ref.collection('driverContact').doc('phone');
  if (!after.driverId) {
    await Promise.all([
      event.data!.after.ref.update({ driverInfo: admin.firestore.FieldValue.delete() }),
      contactRef.delete(),
    ]);
    return;
  }
  // El pasajero ya no lee driverProfiles: lo que necesita ver del chófer
  // (nombre, foto, vehículo, placa y valoración) se copia aquí.
  const [userSnap, vehicleSnap, profileSnap] = await Promise.all([
    db.collection('users').doc(after.driverId).get(),
    db.collection('vehicles').where('driverId', '==', after.driverId).limit(1).get(),
    db.collection('driverProfiles').doc(after.driverId).get(),
  ]);
  const u = userSnap.data() ?? {};
  const v = vehicleSnap.docs[0]?.data();
  const rating = profileSnap.data()?.rating;
  // El teléfono no va en driverInfo (visible también en el historial): va
  // aparte y el pasajero solo lo lee mientras el viaje está activo.
  await contactRef.set({ phone: u.phone ?? '' });
  await event.data!.after.ref.update({
    driverInfo: {
      name: u.displayName ?? '',
      photoUrl: u.photoUrl ?? null,
      vehicle: v
        ? { make: v.make ?? '', model: v.model ?? '', plate: v.plate ?? '', color: v.color ?? '' }
        : null,
      rating: typeof rating === 'number' ? rating : null,
    },
  });
});

// ---------------------------------------------------------------------------
// applyRiderRating  (onUpdate /bookings/{bookingId})
// La valoración del pasajero (1–5) actualiza la media del chófer.
// ---------------------------------------------------------------------------

export const applyRiderRating = onDocumentUpdated('bookings/{bookingId}', async (event) => {
  const before = event.data?.before.data() as (BookingDoc & { riderRating?: number }) | undefined;
  const after = event.data?.after.data() as (BookingDoc & { riderRating?: number }) | undefined;
  if (!before || !after || before.riderRating != null || after.riderRating == null) return;
  const rating = Math.min(5, Math.max(1, Math.round(after.riderRating)));
  if (!after.driverId) return;

  const driverRef = db.collection('driverProfiles').doc(after.driverId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(driverRef);
    if (!snap.exists) return;
    const d = snap.data() ?? {};
    const count = Number(d.ratingCount ?? 0);
    const avg = count > 0 ? Number(d.rating ?? 5) : 0;
    const next = Math.round(((avg * count + rating) / (count + 1)) * 100) / 100;
    tx.update(driverRef, { rating: next, ratingCount: count + 1 });
  });
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
      // Solo vuelve a estar disponible si sigue conectado (no se desconectó
      // ni cerró sesión durante el viaje).
      isAvailable: snap.data()?.online !== false,
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

export const backfillSettlements = secureCallable('backfillSettlements', { timeoutSeconds: 540 }, async (req) => {
  const adminId = await requireAdmin(req);
  parseInput(schema.backfillSettlements, req.data);
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

  // La reserva solo se completa desde in_progress con advanceBooking (D1):
  // cerrar el viaje en /rides ya no la completa ni dispara el cobro.
  logger.info('onRideCompleted', 'ride closed; booking untouched', { rideId: event.params.rideId, bookingId: after.bookingId });
});

// ---------------------------------------------------------------------------
// assignNearestDriver  (HTTPS Callable)
// ---------------------------------------------------------------------------

export const assignNearestDriver = secureCallable('assignNearestDriver', {}, async (req) => {
  const uid = requireAuth(req);
  const { bookingId } = parseInput(schema.assignNearestDriver, req.data);

  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingSnap = await bookingRef.get();
  if (!bookingSnap.exists) throw err.notFound('booking_not_found');

  const booking = bookingSnap.data() as BookingDoc;
  if (booking.riderId !== uid) await requireAdmin(req);
  if (booking.status !== 'pending') throw err.failedPrecondition('booking_not_pending');

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

export const acceptBooking = secureCallable('acceptBooking', {}, async (req) => {
  const driverId = requireAuth(req);
  const { bookingId } = parseInput(schema.acceptBooking, req.data);

  // Solo un chófer activo (no bloqueado desde el panel) acepta viajes.
  const me = (await db.collection('users').doc(driverId).get()).data();
  if (me?.role !== 'driver' || me?.isActive === false) throw err.permissionDenied('inactive_driver');

  const bookingRef = db.collection('bookings').doc(bookingId);
  const driverRef  = db.collection('driverProfiles').doc(driverId);

  let riderId = '';

  try {
    await db.runTransaction(async (tx) => {
      const [bookingSnap, driverSnap] = await Promise.all([
        tx.get(bookingRef),
        tx.get(driverRef),
      ]);

      if (!bookingSnap.exists) throw err.notFound('booking_not_found');
      const booking = bookingSnap.data() as BookingDoc;
      if (booking.status !== 'pending') throw new Error('ALREADY_TAKEN');

      if (!driverSnap.exists) throw err.notFound('driver_not_found');
      if (driverSnap.data()?.documentsVerified !== true) throw err.permissionDenied('driver_not_verified');
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
