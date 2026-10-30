import * as admin from 'firebase-admin';
import { CallableRequest, onRequest } from 'firebase-functions/v2/https';
import { secureCallable } from './callable';
import { callableSchemas as schema, parseInput } from './schemas';
import { onDocumentCreated, onDocumentUpdated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineBoolean, defineSecret } from 'firebase-functions/params';
import * as bookingService from './booking_service';
import * as preferences from './preferences';
import { AppLocale, formatMoney, localeOf, notice, NoticeType, vehicleClassName } from './i18n';
import { reconcileOpenRequests } from './reconcile';
import { resolveAdminAlert } from './alerts';
import * as tripFlow from './trip_flow';
import * as businessLeads from './business_leads';
import * as identity from './identity';
import * as adminOps from './admin_ops';
import * as cancellation from './cancellation';
import * as incidents from './incidents';
import { deviceSchema, registerDriverDevice as registerDriverDeviceService } from './driver_devices';
import { isTransient, withRetryPolicy } from './retry_policy';
import * as stripe from './stripe_service';
import { loadPaymentSettings } from './payment_config';
import { isPaid, readPaymentState } from './payment_booking';
import * as payManual from './payment_manual';
import * as payCard from './payment_card';
import * as payRefund from './payment_refund';
import { reconcileFinalAmount } from './payment_final';
import * as payInbox from './payment_inbox';
import * as payBalance from './payment_balance';
import { expirePayments } from './payment_expiry';
import { computeCancelSettle, readForSettle, writeCancelSettle } from './payment_settle';
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
export const createBooking = secureCallable('createBooking', { secrets: [MAPS_SERVER_KEY] }, async (req) => {
  // Con sesión, reservar exige el correo verificado (decisión 1, H6) y los
  // términos vigentes aceptados (decisión 7).
  if (req.auth) {
    identity.requireVerifiedEmail(req.auth.token as unknown as Record<string, unknown>);
    await identity.requireCurrentTerms(db, req.auth.uid);
  }
  return bookingService.createBooking(bookingDeps(), req.auth?.uid, req.data);
});

/** Preferencias del perfil para el chófer: solo por aquí, nunca desde el cliente. */
export const updatePreferences = secureCallable('updatePreferences', {}, (req) =>
  preferences.updatePreferences({ db }, req.auth?.uid, req.data));

/** Si la app ofrece el campo de la lista de música (config/ops.playlistHosts). */
export const getPreferenceOptions = secureCallable('getPreferenceOptions', {}, (req) => {
  parseInput(schema.getPreferenceOptions, req.data);
  return preferences.preferenceOptions({ db }, req.auth?.uid);
});

const identityDeps = (): identity.IdentityDeps => ({ db, auth: identity.realAuth() });

/** Operaciones sensibles: inicio de sesión de hace menos de 5 minutos (decisión 6). */
const RECENT_AUTH_SECONDS = 5 * 60;

/** Cambia el rol de un usuario: claim, documento, sesiones revocadas y auditoría. */
export const setUserRole = secureCallable('setUserRole', {}, async (req) => {
  const input = parseInput(schema.setUserRole, req.data);
  return identity.setUserRole(identityDeps(), await adminActor(req), input);
}, { role: 'admin' });

/** Bloquea o desbloquea: Auth deshabilitado, sesiones revocadas, isActive y auditoría. */
export const setUserBlocked = secureCallable('setUserBlocked', {}, async (req) => {
  const input = parseInput(schema.setUserBlocked, req.data);
  return identity.setUserBlocked(identityDeps(), await adminActor(req), input);
}, { role: 'admin' });

/** La app la llama tras verificar el correo: el servidor lo comprueba en Auth. */
export const syncEmailVerification = secureCallable('syncEmailVerification', {}, (req) => {
  parseInput(schema.syncEmailVerification, req.data);
  return identity.syncEmailVerification(identityDeps(), requireAuth(req));
});

/** El chófer anota su dispositivo (decisión 5): sin bloqueo, con aviso al admin. */
export const registerDriverDevice = secureCallable('registerDriverDevice', {}, (req) => {
  const input = parseInput(deviceSchema, req.data);
  return registerDriverDeviceService(db, requireAuth(req), input);
}, { role: 'driver' });

/** Aceptación de los términos: versión vigente, hora del servidor y versión de la app. */
export const acceptTerms = secureCallable('acceptTerms', {}, (req) => {
  const input = parseInput(schema.acceptTerms, req.data);
  return identity.acceptTerms(db, requireAuth(req), input);
});

// ---------------------------------------------------------------------------
// Pasos del viaje desde la recogida (D1): solo el servidor cambia el estado
// ---------------------------------------------------------------------------

// Secreto del código de recogida (HMAC). Sin él no hay códigos: falla cerrado.
const PICKUP_CODE_SECRET = defineSecret('PICKUP_CODE_SECRET');
// Sal del HMAC con que se seudonimiza la IP del formulario de empresas.
const RATE_LIMIT_SALT = defineSecret('RATE_LIMIT_SALT');

/** Formulario de empresas, también sin sesión (H5). */
// Diagnóstico temporal de x-forwarded-for (0.4): apagado por defecto.
// Encender y apagar: DEPLOY.md, «Diagnóstico de x-forwarded-for».
const XFF_DIAGNOSTIC = defineBoolean('XFF_DIAGNOSTIC', { default: false });

export const submitBusinessLead = secureCallable('submitBusinessLead', { secrets: [RATE_LIMIT_SALT] }, (req) =>
  businessLeads.submitBusinessLead(
    { db, salt: RATE_LIMIT_SALT.value(), xffDiagnostic: XFF_DIAGNOSTIC.value() },
    req as unknown as businessLeads.LeadRequest,
  ));


const tripDeps = (): tripFlow.TripDeps => ({ db, pickupSecret: PICKUP_CODE_SECRET.value() });

/** Único camino del chófer: en camino, llegué, iniciar y completar. */
export const advanceBooking = secureCallable('advanceBooking', {}, (req) =>
  tripFlow.advanceBooking({ db }, req.auth?.uid, req.data), { requireMfa: true });

/** El pasajero de la reserva ve su código mientras el chófer espera. */
export const getPickupCode = secureCallable('getPickupCode', { secrets: [PICKUP_CODE_SECRET] }, (req) =>
  tripFlow.getPickupCode(tripDeps(), req.auth?.uid, req.data));

/** El chófer asignado comprueba el código: driver_arrived → verified. */
export const verifyPickup = secureCallable('verifyPickup', { secrets: [PICKUP_CODE_SECRET] }, (req) =>
  tripFlow.verifyPickup(tripDeps(), req.auth?.uid, req.data), { requireMfa: true });

/** Excepción del admin, con motivo: deja la reserva verificada y avisa. */
export const adminOverrideVerify = secureCallable('adminOverrideVerify', {}, async (req) => {
  const adminId = await requireAdmin(req);
  return tripFlow.adminOverrideVerify({ db }, {
    adminId,
    adminEmail: (req.auth?.token.email as string | undefined) ?? null,
  }, req.data);
}, { role: 'admin' });

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

/** El pasajero cancela su reserva (o pide el recargo antes de confirmar). */
export const cancelBooking = secureCallable('cancelBooking', {}, (req) =>
  cancellation.cancelBooking({ db }, req.auth?.uid, req.data));

/** El chófer devuelve una reserva antes de llegar (motivo de lista cerrada). */
export const releaseBooking = secureCallable('releaseBooking', {}, (req) =>
  cancellation.releaseBooking({ db }, req.auth?.uid, req.data), { requireMfa: true });

/** Pasajero o chófer de la reserva: avisa a central (idempotente, con límite). */
export const raiseIncident = secureCallable('raiseIncident', {}, (req) => incidents.raiseIncident(incidentDeps(), req.auth?.uid, req.data));

/** Falsa alarma: solo quien lo disparó; el admin recibe igual el aviso. */
export const cancelIncident = secureCallable('cancelIncident', {}, (req) => incidents.cancelIncident(incidentDeps(), req.auth?.uid, req.data));

export const acknowledgeIncident = secureCallable('acknowledgeIncident', {}, async (req) =>
  incidents.acknowledgeIncident(incidentDeps(), await adminActor(req), req.data),
{ role: 'admin', skipAdminSessionLimit: true });

/** Cierre con nota obligatoria (mínimo 10 caracteres). */
export const closeIncident = secureCallable('closeIncident', {}, async (req) =>
  incidents.closeIncident(incidentDeps(), await adminActor(req), req.data),
{ role: 'admin', skipAdminSessionLimit: true });

/** Reenvía alerta y push de los incidentes sin reconocer (config/ops). */
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
  | 'cancelled'
  | 'no_show';

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

/** Admin por el claim `role` (o Firestore en la transición) y con la cuenta activa. */
async function requireAdmin(req: CallableRequest): Promise<string> {
  requireAuth(req);
  return identity.requireRole(db, req.auth as unknown as { uid: string; token: Record<string, unknown> }, 'admin');
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

/** Tokens de push e idioma (users/{uid}.locale; por defecto español). */
async function getUserTarget(userId: string): Promise<{ tokens: string[]; locale: AppLocale }> {
  const data = (await db.collection('users').doc(userId).get()).data();
  return { tokens: (data?.fcmTokens as string[]) ?? [], locale: localeOf(data) };
}

/** Push de un aviso del catálogo (i18n.ts) en el idioma de quien lo recibe. */
async function pushNotice(userId: string, type: NoticeType, params: Record<string, string> = {},
  data?: Record<string, string>): Promise<void> {
  const { tokens, locale } = await getUserTarget(userId);
  const n = notice(type, locale, params);
  await sendPush(tokens, n.title, n.body, data);
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
  // Tarjeta desactivada en config/ops.paymentMethods (A2): se rechaza antes
  // de llamar al proveedor.
  if (!(await loadPaymentSettings(db)).enabled.includes('card')) throw err.failedPrecondition('method_disabled');

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
}, { role: 'admin' });

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
}, { recentAuthSeconds: RECENT_AUTH_SECONDS });

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
}, { recentAuthSeconds: RECENT_AUTH_SECONDS });

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
}, { recentAuthSeconds: RECENT_AUTH_SECONDS });

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

  // A3: a los chóferes se les avisa cuando el pago queda confirmado
  // (notifyDriversOnPaid), no al crear la reserva.
}

/**
 * Aviso a los chóferes de una reserva pagada, una sola vez (marca
 * driversNotifiedAt). Lo dispara el paso del pago a paid.
 */
async function notifyDriversOfBooking(bookingRef: admin.firestore.DocumentReference): Promise<void> {
  const booking = (await bookingRef.get()).data() as BookingDoc | undefined;
  if (!booking || booking.status !== 'pending') return;
  const vehicleClass = booking.class ?? booking.vehicleClass ?? 'business';
  const firstNotice = await db.runTransaction(async (tx) => {
    const fresh = await tx.get(bookingRef);
    // Borrada o ya avisada: no hay nada que hacer.
    if (!fresh.exists || fresh.data()?.driversNotifiedAt) return false;
    tx.update(bookingRef, { driversNotifiedAt: admin.firestore.Timestamp.now() });
    return true;
  });
  if (!firstNotice) return;

  logger.info('notifyDrivers', 'notifying drivers', { bookingId: bookingRef.id, vehicleClass });

  const driversSnap = await db
    .collection('driverProfiles')
    .where('isAvailable', '==', true)
    .where('documentsVerified', '==', true)
    .limit(20)
    .get();

  // Un envío por idioma: cada chófer lo recibe en el suyo.
  const byLocale = new Map<AppLocale, string[]>();
  for (const doc of driversSnap.docs) {
    const { tokens, locale } = await getUserTarget(doc.id);
    byLocale.set(locale, [...(byLocale.get(locale) ?? []), ...tokens]);
  }

  try {
    for (const [locale, tokens] of byLocale) {
      const n = notice('new_trip_available', locale, {
        vehicleClass: vehicleClassName(vehicleClass, locale),
        amount: formatMoney(Math.round(booking.estimatedPrice), locale),
      });
      await sendPush(tokens, n.title, n.body);
    }
  } catch (e) {
    // Si el envío puede salir bien en el reintento, se quita la marca para
    // que el reintento avise; si no, queda marcada y no se repite.
    if (isTransient(e)) {
      await bookingRef.update({ driversNotifiedAt: admin.firestore.FieldValue.delete() }).catch(() => undefined);
    }
    throw e;
  }
}

// El pago pasa a paid (confirmación del admin o del proveedor): ahora sí se
// avisa a los chóferes. Con reintento, como onBookingCreated.
export const notifyDriversOnPaid = onDocumentWritten(
  { document: 'bookings/{bookingId}/payment/{docId}', retry: true }, (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (after?.paymentStatus !== 'paid' || before?.paymentStatus === 'paid') return Promise.resolve();
    return withRetryPolicy('notifyDriversOnPaid', { bookingId: event.params.bookingId },
      () => notifyDriversOfBooking(db.collection('bookings').doc(event.params.bookingId)));
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

  // Textos en i18n.ts, en el idioma del pasajero.
  const statusNotices: Partial<Record<BookingStatus, NoticeType>> = {
    confirmed: 'booking_confirmed',
    driver_arriving: 'driver_arriving',
    // Sin el código del pasajero el viaje no empieza: el aviso lo recuerda
    // (el código no va en el aviso; solo se ve en la app).
    driver_arrived: 'driver_arrived',
    // verified no avisa: el pasajero está junto al chófer.
    in_progress: 'ride_started',
    completed: 'ride_completed',
    cancelled: 'booking_cancelled',
    // B5: el chófer liberó la reserva; se busca otro.
    pending: 'booking_driver_released',
    no_show: 'rider_no_show',
  };

  const noticeType = statusNotices[after.status];
  if (!noticeType) return;
  const { tokens, locale } = await getUserTarget(after.riderId);
  const { title, body, type } = notice(noticeType, locale);

  // Una sola notificación por cambio, escrita aquí y no por la app (que la
  // duplicaba cada vez que se abría el viaje).
  const ref = db.collection('users').doc(after.riderId).collection('notifications').doc();
  await ref.set({
    id: ref.id,
    userId: after.riderId,
    title,
    body,
    type,
    locale,
    isRead: false,
    bookingId: event.params.bookingId,
    createdAt: admin.firestore.Timestamp.now(),
  });

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

// ---------------------------------------------------------------------------
// Escrituras de admin (Parte A): cada una con su auditoría en la misma
// transacción. Rol admin por claim y, con mfaEnforced, segundo factor.
// ---------------------------------------------------------------------------

/** Asignar o reasignar chófer, cancelar, mover el estado o ajustar el importe. */
export const adminUpdateBooking = secureCallable('adminUpdateBooking', {}, async (req) =>
  adminOps.adminUpdateBooking({ db }, await adminActor(req), req.data), { role: 'admin', requireMfa: true });

/** Registrar o corregir un cobro manual (efectivo, QR, transferencia). */
export const adminRecordPayment = secureCallable('adminRecordPayment', {}, async (req) =>
  adminOps.adminRecordPayment({ db }, await adminActor(req), req.data), { role: 'admin', requireMfa: true });

/** Ajustes de config/global (lista blanca), config/finance y config/ops; nunca config/security. */
export const adminUpdateConfig = secureCallable('adminUpdateConfig', {}, async (req) =>
  adminOps.adminUpdateConfig({ db }, await adminActor(req), req.data), { role: 'admin', requireMfa: true });

/** Crear, cambiar o desactivar una tarifa (borrar = desactivar). */
export const adminUpdatePricingRule = secureCallable('adminUpdatePricingRule', {}, async (req) =>
  adminOps.adminUpdatePricingRule({ db }, await adminActor(req), req.data), { role: 'admin', requireMfa: true });

/** Verificar los documentos del chófer (y activar su vehículo revisado). */
export const adminVerifyDriver = secureCallable('adminVerifyDriver', {}, async (req) =>
  adminOps.adminVerifyDriver({ db }, await adminActor(req), req.data), { role: 'admin', requireMfa: true });

/** Licencia o vehículo a petición del chófer (tras verificar él no puede). */
export const adminUpdateDriverSensitive = secureCallable('adminUpdateDriverSensitive', {}, async (req) =>
  adminOps.adminUpdateDriverSensitive({ db }, await adminActor(req), req.data), { role: 'admin', requireMfa: true });

/** Activar o desactivar un vehículo. */
export const adminSetVehicleActive = secureCallable('adminSetVehicleActive', {}, async (req) =>
  adminOps.adminSetVehicleActive({ db }, await adminActor(req), req.data), { role: 'admin', requireMfa: true });

/** Marcar una solicitud de empresa como atendida o pendiente. */
export const adminSetLeadHandled = secureCallable('adminSetLeadHandled', {}, async (req) =>
  adminOps.adminSetLeadHandled({ db }, await adminActor(req), req.data), { role: 'admin', requireMfa: true });

// ---------------------------------------------------------------------------
// Pagos (A4): pago manual por QR o transferencia.
// ---------------------------------------------------------------------------

/** El pasajero avisa «ya pagué»: alerta para central, no confirma nada. */
export const markPaymentSent = secureCallable('markPaymentSent', {}, (req) =>
  payManual.markPaymentSent({ db }, req.auth?.uid, req.data));

/** Confirmar un pago manual: importe exacto, número de operación único y motivo. */
export const adminConfirmPayment = secureCallable('adminConfirmPayment', {}, async (req) =>
  payManual.adminConfirmPayment({ db }, await adminActor(req), req.data), { role: 'admin', requireMfa: true });

/** Rechazar un «ya pagué» que no llegó. */
export const adminRejectPayment = secureCallable('adminRejectPayment', {}, async (req) =>
  payManual.adminRejectPayment({ db }, await adminActor(req), req.data), { role: 'admin', requireMfa: true });

/** Empezar a pagar: instrucciones del pago manual o cobro con tarjeta (A5). */
export const startPayment = secureCallable('startPayment', withStripe, (req) =>
  payCard.startPayment({ db }, req.auth?.uid, req.data));

/**
 * Webhook del proveedor de tarjeta (A5). La firma la verifica el proveedor
 * activo; sin tarjeta activada responde 404. No es una callable: no lleva
 * App Check ni sesión, la firma es la única puerta.
 */
export const paymentWebhook = onRequest({ ...withStripe }, async (req, res) => {
  const r = await payCard.handlePaymentWebhook({ db }, req.rawBody, req.get('x-payment-signature') ?? undefined);
  res.status(r.status).json(r.body);
});

/** Registrar una devolución (manual) o pedirla al proveedor (tarjeta) (A8). */
export const adminRecordRefund = secureCallable('adminRecordRefund', withStripe, async (req) =>
  payRefund.adminRecordRefund({ db }, await adminActor(req), req.data), { role: 'admin', requireMfa: true });

// Con tarjeta, la devolución se pide al proveedor al pasar a refund_pending (A8).
export const refundOnRefundPending = onDocumentWritten(
  { document: 'bookings/{bookingId}/payment/{docId}', ...withStripe }, async (event) => {
    await payRefund.onRefundPending({ db }, event.params.bookingId,
      event.data?.before.data(), event.data?.after.data());
  });

/** Cobrar un saldo pendiente (G2): importe ≤ saldo, n.º de operación único y motivo. */
export const adminCollectBalance = secureCallable('adminCollectBalance', {}, async (req) =>
  payBalance.adminCollectBalance({ db }, await adminActor(req), req.data), { role: 'admin', requireMfa: true });

/** Bandejas de pagos del panel (A11): pendientes, «ya pagué», devoluciones y saldos. */
export const adminPaymentInbox = secureCallable('adminPaymentInbox', {}, async (req) =>
  payInbox.adminPaymentInbox(db, req.data), { role: 'admin', requireMfa: true });

/** El admin marca una alerta como revisada (auditado en el servidor). */
export const resolveAlert = secureCallable('resolveAlert', {}, async (req) => {
  const adminId = await requireAdmin(req);
  return resolveAdminAlert(db, { adminId, adminEmail: (req.auth?.token.email as string | undefined) ?? null }, req.data);
}, { role: 'admin', skipAdminSessionLimit: true });

// Pagos A6: vence el plazo para pagar (solo con paymentWindowMinutes).
export const expirePaymentsJob = onSchedule('every 5 minutes', async () => {
  const r = await expirePayments({ db });
  if (r.expired.length) logger.info('expirePayments', 'expired', { count: r.expired.length });
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
// cierre (chófer, pasajero o admin), y que suma el viaje
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
    await pushNotice(driverId, 'trip_cancelled_by_rider');
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
// reconcileFinalPayment  (onUpdate /bookings/{bookingId})  — pagos A9/A10
// Al completarse (o si cambia el importe final ya completada) compara con lo
// pagado: saldo o devolución pendiente, con asiento y alerta; nada se cobra
// ni se devuelve solo.
// ---------------------------------------------------------------------------

export const reconcileFinalPayment = onDocumentUpdated('bookings/{bookingId}', async (event) => {
  const before = event.data?.before.data() as BookingDoc | undefined;
  const after = event.data?.after.data() as BookingDoc | undefined;
  if (!before || !after || after.status !== 'completed') return;
  if (before.status === 'completed' && before.finalPrice === after.finalPrice) return;
  const r = await reconcileFinalAmount(db, event.params.bookingId);
  if (r.action !== 'none' && r.action !== 'skipped') {
    logger.info('reconcileFinalPayment', r.action, { bookingId: event.params.bookingId, diff: r.diff });
  }
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
}, { role: 'admin' });

/** Chóferes que liberaron la reserva (releaseBooking, B5/0.3). */
function releasedByOf(b: unknown): string[] {
  const v = (b as { releasedBy?: unknown } | undefined)?.releasedBy;
  return Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string') : [];
}

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
  // A3: sin pago confirmado no se busca chófer.
  if (!isPaid(await readPaymentState(db, bookingId))) return { assigned: false, reason: 'not_paid' };
  // Los chóferes que liberaron esta reserva no se vuelven a asignar.
  const released = new Set(releasedByOf(booking));

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
  ].filter((id) => !released.has(id));
  if (!driverIds.length) {
    logger.warn('assignNearestDriver', 'no vehicles found', { vehicleClass });
    return { assigned: false, reason: 'no_drivers_available' };
  }

  const [profiles, users] = await Promise.all([
    db.getAll(...driverIds.map((id) => db.collection('driverProfiles').doc(id))),
    db.getAll(...driverIds.map((id) => db.collection('users').doc(id))),
  ]);
  // Un chófer bloqueado no se asigna aunque su perfil diga disponible (H10).
  const active = new Set(users.filter((u) => u.exists && u.data()?.isActive !== false).map((u) => u.id));
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
          isActive: active.has(p.id),
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
      const [b, d, u, pay] = await Promise.all([
        tx.get(bookingRef), tx.get(driverRef), tx.get(db.collection('users').doc(driverId)),
        readPaymentState(db, bookingId, tx),
      ]);
      if ((b.data() as BookingDoc | undefined)?.status !== 'pending') return 'taken';
      if (!isPaid(pay)) return 'not_paid';
      if (releasedByOf(b.data()).includes(driverId)) return 'busy';
      if (!d.data()?.isAvailable || u.data()?.isActive === false) return 'busy';
      tx.update(bookingRef, {
        driverId,
        status: 'confirmed' as BookingStatus,
        updatedAt: admin.firestore.Timestamp.now(),
      });
      tx.update(driverRef, { isAvailable: false });
      return 'assigned';
    });
    if (outcome === 'taken') return { assigned: false, reason: 'already_taken' };
    if (outcome === 'not_paid') return { assigned: false, reason: 'not_paid' };
    if (outcome === 'busy') continue;

    await pushNotice(driverId, 'driver_assigned');
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
      const [bookingSnap, driverSnap, paymentSnap] = await Promise.all([
        tx.get(bookingRef),
        tx.get(driverRef),
        readPaymentState(db, bookingId, tx),
      ]);

      if (!bookingSnap.exists) throw err.notFound('booking_not_found');
      const booking = bookingSnap.data() as BookingDoc;
      if (booking.status !== 'pending') throw new Error('ALREADY_TAKEN');
      // A3: una reserva sin pago confirmado no se ofrece ni se acepta.
      if (!isPaid(paymentSnap)) throw new Error('NOT_PAID');
      if (releasedByOf(booking).includes(driverId)) throw new Error('RELEASED_BY_YOU');

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
      // Antes decía «Tu chófer está en camino» aunque aún no salía.
      await pushNotice(riderId, 'booking_confirmed');
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
    if (e.message === 'RELEASED_BY_YOU') {
      return { accepted: false, reason: 'released_by_you' };
    }
    if (e.message === 'NOT_PAID') {
      return { accepted: false, reason: 'not_paid' };
    }
    logger.error('acceptBooking', 'error', { error: String(e) });
    throw e;
  }
}, { requireMfa: true });

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

  // Sin chófer a tiempo (A7, decisión 2): si estaba pagada, devolución
  // entera; si no, el pedido de pago deja de valer. Una transacción por
  // reserva, revalidada (pudo asignarse mientras).
  const now = admin.firestore.Timestamp.now();
  for (const doc of staleSnap.docs) {
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (fresh.data()?.status !== 'pending') return;
      const read = await readForSettle(tx, db, doc.id, 'pending');
      const settle = { bookingId: doc.id, status: 'pending', cause: 'system' as const, policy: null,
        policyState: 'missing' as const, read, at: now };
      tx.update(doc.ref, {
        status: 'cancelled' as BookingStatus, cancelledBy: 'system', cancelledAt: now,
        cancellationReason: 'no_driver_found', updatedAt: now,
      });
      writeCancelSettle(tx, db, settle, computeCancelSettle(settle));
    });
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

  const { tokens, locale } = await getUserTarget(after.riderId);
  const n = notice('payment_receipt', locale, { amount: formatMoney(after.amount / 100, locale) });
  await sendPush(tokens, n.title, n.body);
});
