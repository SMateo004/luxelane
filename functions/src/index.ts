import * as admin from 'firebase-admin';
import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as stripe from './stripe_service';
import { STRIPE_SECRET_KEY } from './stripe_service';
import { defineSecret } from 'firebase-functions/params';
import { logger } from './logger';
import { Lang, MessageKey, clock, langOf, money, t, vehicleName } from './messages';
import { buildChauffeur, isValidRating, nextAverage } from './chauffeur';
import {
  DispatchState,
  DriverCandidate,
  advanceOffer,
  dispatchMode,
  initialDispatch,
  rankDrivers,
} from './dispatch';
import {
  ADJUST_THRESHOLD_MIN,
  adjustedPickup,
  flightDateUtc,
  normalizeFlightNumber,
  parseAeroDataBox,
  shouldTrack,
} from './flights';
import * as err from './errors';
import {
  BookingStatus,
  UserRole,
  canCapture,
  chunk,
  freeWaitEnd,
  isStalePending,
  isValidAmount,
  toMinorUnits,
} from './policy';
import {
  CAPACITY,
  CURRENCY,
  DEFAULT_RULES,
  LatLng,
  QUOTE_TTL_MS,
  ServiceType,
  VehicleClass,
  clampHours,
  computePrice,
  isLatLng,
  isServiceType,
  isVehicleClass,
  resolveDistanceKm,
  ruleFromDoc,
} from './pricing';

admin.initializeApp();
const db = admin.firestore();

const MAX_ADVANCE_MS = 365 * 24 * 60 * 60 * 1000;
const stripeOpts = { secrets: [STRIPE_SECRET_KEY] };

// AeroDataBox key (RapidAPI). Set with: firebase functions:secrets:set FLIGHT_API_KEY
const FLIGHT_API_KEY = defineSecret('FLIGHT_API_KEY');

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
  pickupAt?: admin.firestore.Timestamp;
  createdAt?: admin.firestore.Timestamp;
  flightNumber?: string | null;
  chauffeur?: { driverId?: string; phone?: string | null };
  riderRating?: number;
  driverArrivedAt?: admin.firestore.Timestamp;
  origin?: { coordinates?: admin.firestore.GeoPoint };
  dispatch?: StoredDispatch;
  flight?: { estimatedArrival?: admin.firestore.Timestamp | null } | null;
}

interface StoredDispatch {
  mode: 'targeted' | 'broadcast';
  candidates: string[];
  index: number;
  offeredTo: string | null;
  offerExpiresAt: admin.firestore.Timestamp | null;
  declined: string[];
}

function toStored(d: DispatchState): StoredDispatch {
  return {
    mode: d.mode,
    candidates: d.candidates,
    index: d.index,
    offeredTo: d.offeredTo,
    offerExpiresAt: d.offerExpiresAtMs ? admin.firestore.Timestamp.fromMillis(d.offerExpiresAtMs) : null,
    declined: d.declined,
  };
}

function fromStored(d: StoredDispatch): DispatchState {
  return {
    mode: d.mode,
    candidates: d.candidates ?? [],
    index: d.index ?? 0,
    offeredTo: d.offeredTo ?? null,
    offerExpiresAtMs: d.offerExpiresAt?.toMillis() ?? null,
    declined: d.declined ?? [],
  };
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

interface PlaceInput extends LatLng {
  address?: string;
  name?: string;
  placeId?: string;
}

/** Stored shape matches Dart `Place.toJson` (coordinates as a GeoPoint). */
interface StoredPlace {
  name: string;
  address: string;
  coordinates: admin.firestore.GeoPoint;
}

interface QuoteDoc {
  riderId: string;
  vehicleClass: VehicleClass;
  serviceType: ServiceType;
  origin: StoredPlace;
  destination: StoredPlace;
  distanceKm: number | null;
  hours: number | null;
  amount: number;
  currency: string;
  expiresAt: admin.firestore.Timestamp;
  createdAt: admin.firestore.Timestamp;
  bookingId?: string;
}

interface UserDoc {
  locale?: string;
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

/**
 * Sends a push in the recipient's language. [params] may be a function of
 * the language for values that need localised formatting (money, times).
 */
async function pushUser(
  userId: string,
  titleKey: MessageKey,
  bodyKey: MessageKey,
  params: Record<string, string | number> | ((lang: Lang) => Record<string, string | number>) = {},
): Promise<void> {
  const user = await getUser(userId);
  const tokens = user.fcmTokens ?? [];
  if (!tokens.length) return;
  const lang = langOf(user.locale);
  const p = typeof params === 'function' ? params(lang) : params;
  await sendPush(tokens, t(lang, titleKey, p), t(lang, bodyKey, p));
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

function toPlace(p: PlaceInput): StoredPlace {
  return {
    name: String(p.name ?? '').slice(0, 200),
    address: String(p.address ?? '').slice(0, 300),
    coordinates: new admin.firestore.GeoPoint(p.lat, p.lng),
  };
}

/**
 * Loads a quote and checks it belongs to the caller, is unused and fresh.
 * [graceMs] extends validity, e.g. when the card was already authorised for
 * this quote and the rider spent a while on 3-D Secure.
 */
async function loadValidQuote(uid: string, quoteId: unknown, graceMs = 0): Promise<QuoteDoc> {
  if (typeof quoteId !== 'string' || !quoteId) throw err.invalidArgument('quoteId required');
  const snap = await db.collection('quotes').doc(quoteId).get();
  if (!snap.exists) throw err.notFound('Quote not found');
  const quote = snap.data() as QuoteDoc;
  if (quote.riderId !== uid) throw err.permissionDenied();
  if (quote.bookingId) throw err.failedPrecondition('Quote already used');
  if (quote.expiresAt.toMillis() + graceMs < Date.now()) throw err.failedPrecondition('quote/expired');
  return quote;
}

// ---------------------------------------------------------------------------
// quoteBooking — fixed, server-computed price in Bs, valid for 15 minutes
// ---------------------------------------------------------------------------

export const quoteBooking = onCall(async (req) => {
  const uid = requireAuth(req);
  const { vehicleClass, serviceType, origin, destination, routeDistanceKm, hours } = (req.data ?? {}) as {
    vehicleClass: unknown;
    serviceType: unknown;
    origin: unknown;
    destination?: unknown;
    routeDistanceKm?: unknown;
    hours?: unknown;
  };

  if (!isVehicleClass(vehicleClass)) throw err.invalidArgument('invalid vehicleClass');
  if (!isServiceType(serviceType)) throw err.invalidArgument('invalid serviceType');
  if (!isLatLng(origin)) throw err.invalidArgument('origin required');

  const hourly = serviceType === 'byTheHour';
  // Hourly charters may omit the destination (the chauffeur stays with you).
  const dest = isLatLng(destination) ? destination : hourly ? origin : null;
  if (!dest) throw err.invalidArgument('destination required');

  const ruleSnap = await db.collection('pricingRules').doc(`${vehicleClass}_${serviceType}`).get();
  const rule = ruleFromDoc(ruleSnap.data(), DEFAULT_RULES[vehicleClass][serviceType]);

  const distanceKm = hourly ? null : resolveDistanceKm(origin, dest, routeDistanceKm);
  const quoteHours = hourly ? clampHours(hours) : null;
  const amount = computePrice(rule, serviceType, { km: distanceKm ?? 0, hours: quoteHours ?? 0 });

  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromMillis(now.toMillis() + QUOTE_TTL_MS);
  const quote: QuoteDoc = {
    riderId: uid,
    vehicleClass,
    serviceType,
    origin: toPlace(origin as PlaceInput),
    destination: toPlace(dest as PlaceInput),
    distanceKm,
    hours: quoteHours,
    amount,
    currency: CURRENCY,
    expiresAt,
    createdAt: now,
  };
  const ref = await db.collection('quotes').add(quote);

  logger.info('quoteBooking', 'quoted', { uid, quoteId: ref.id, vehicleClass, serviceType, amount });
  return {
    quoteId: ref.id,
    amount,
    currency: CURRENCY,
    distanceKm,
    hours: quoteHours,
    expiresAt: expiresAt.toMillis(),
  };
});

// ---------------------------------------------------------------------------
// createPaymentIntent — authorises (does not charge) the quoted amount
// ---------------------------------------------------------------------------

export const createPaymentIntent = onCall(stripeOpts, async (req) => {
  const uid = requireAuth(req);
  const { quoteId, customerId: claimed } = req.data as {
    quoteId: string;
    customerId?: string;
  };

  const quote = await loadValidQuote(uid, quoteId);
  const amount = toMinorUnits(quote.amount);
  if (!isValidAmount(amount)) throw err.invalidArgument('invalid quote amount');
  const customerId = await requireOwnCustomer(uid, claimed);

  logger.info('createPaymentIntent', 'start', { uid, quoteId, amount });

  try {
    const clientSecret = await stripe.createIntent({
      amount,
      currency: quote.currency,
      customerId,
      metadata: { uid, quoteId },
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
// createBooking — the only way to create a booking. Price, route and vehicle
// come from the quote; the client only adds trip details.
// ---------------------------------------------------------------------------

export const createBooking = onCall(stripeOpts, async (req) => {
  const uid = requireAuth(req);
  const d = (req.data ?? {}) as {
    quoteId: string;
    scheduledAt: number;
    paymentIntentId?: string;
    notes?: string;
    flightNumber?: string;
    passengerCount?: number;
    luggageCount?: number;
    passengerName?: string;
    passengerPhone?: string;
  };

  // An authorisation for this exact quote already locks the price.
  const quote = await loadValidQuote(uid, d.quoteId, d.paymentIntentId ? 30 * 60 * 1000 : 0);

  const scheduledMs = Number(d.scheduledAt);
  const now = Date.now();
  if (!Number.isFinite(scheduledMs) || scheduledMs < now - 5 * 60 * 1000 || scheduledMs > now + MAX_ADVANCE_MS) {
    throw err.invalidArgument('invalid scheduledAt');
  }

  const capacity = CAPACITY[quote.vehicleClass];
  const passengers = Math.round(Number(d.passengerCount ?? 1));
  if (!(passengers >= 1 && passengers <= capacity)) throw err.invalidArgument('invalid passengerCount');
  const luggage = Math.round(Number(d.luggageCount ?? 0));
  if (!(luggage >= 0 && luggage <= 10)) throw err.invalidArgument('invalid luggageCount');

  const flight = d.flightNumber ? String(d.flightNumber).trim().toUpperCase().slice(0, 10) : null;
  if (flight && !/^[A-Z0-9]{2,3}\s?\d{1,4}[A-Z]?$/.test(flight)) throw err.invalidArgument('invalid flightNumber');

  // Card payment: the authorisation must be for this quote, this rider and
  // exactly the quoted amount.
  let paymentIntentId: string | null = null;
  if (d.paymentIntentId) {
    const intent = await stripe.retrieveIntent(String(d.paymentIntentId));
    const valid =
      intent.metadata?.uid === uid &&
      intent.metadata?.quoteId === d.quoteId &&
      intent.amount === toMinorUnits(quote.amount) &&
      intent.status === 'requires_capture';
    if (!valid) throw err.failedPrecondition('payment/not-authorised');
    paymentIntentId = intent.id;
  }

  const quoteRef = db.collection('quotes').doc(d.quoteId);
  const bookingRef = db.collection('bookings').doc();
  const ts = admin.firestore.Timestamp.now();

  await db.runTransaction(async (tx) => {
    const fresh = await tx.get(quoteRef);
    if ((fresh.data() as QuoteDoc | undefined)?.bookingId) throw err.failedPrecondition('Quote already used');
    tx.set(bookingRef, {
      id: bookingRef.id,
      riderId: uid,
      driverId: null,
      origin: quote.origin,
      destination: quote.destination,
      scheduledAt: admin.firestore.Timestamp.fromMillis(scheduledMs),
      class: quote.vehicleClass,
      serviceType: quote.serviceType,
      status: 'pending' as BookingStatus,
      estimatedPrice: quote.amount,
      finalPrice: null,
      paymentId: null,
      currency: quote.currency,
      quoteId: d.quoteId,
      distanceKm: quote.distanceKm,
      hours: quote.hours,
      paymentMethod: paymentIntentId ? 'card' : 'pay_later',
      stripePaymentIntentId: paymentIntentId,
      notes: d.notes ? String(d.notes).slice(0, 1000) : null,
      flightNumber: flight,
      passengerCount: passengers,
      // Who the chauffeur picks up (the rider or a guest): used for the
      // meet & greet name sign and for calling the passenger.
      passengerName: d.passengerName ? String(d.passengerName).trim().slice(0, 80) : null,
      passengerPhone: d.passengerPhone ? String(d.passengerPhone).replace(/[^0-9+ ]/g, '').slice(0, 20) : null,
      luggageCount: luggage,
      createdAt: ts,
      updatedAt: ts,
    });
    tx.update(quoteRef, { bookingId: bookingRef.id });
  });

  logger.info('createBooking', 'created', { uid, bookingId: bookingRef.id, amount: quote.amount });
  return { bookingId: bookingRef.id };
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

/** Available, verified drivers with their vehicle class and last position. */
async function loadDriverCandidates(): Promise<DriverCandidate[]> {
  const snap = await db
    .collection('driverProfiles')
    .where('isAvailable', '==', true)
    .where('documentsVerified', '==', true)
    .limit(100)
    .get();
  const vehicleRefs = snap.docs
    .map((d) => d.data().vehicleId as string | undefined)
    .filter((id): id is string => !!id)
    .map((id) => db.collection('vehicles').doc(id));
  const vehicles = vehicleRefs.length ? await db.getAll(...vehicleRefs) : [];
  const classById = new Map(vehicles.map((v) => [v.id, (v.data()?.class as string) ?? null]));
  return snap.docs.map((d) => {
    const p = d.data();
    const geo = p.currentLocation as admin.firestore.GeoPoint | undefined;
    return {
      driverId: d.id,
      location: geo ? { lat: geo.latitude, lng: geo.longitude } : null,
      locationUpdatedAt: (p.locationUpdatedAt as admin.firestore.Timestamp | undefined)?.toDate() ?? null,
      vehicleClass: p.vehicleId ? classById.get(p.vehicleId) ?? null : null,
      isAvailable: true,
      documentsVerified: true,
    };
  });
}

async function notifyOffer(driverId: string, booking: BookingDoc, distanceKm?: number): Promise<void> {
  await pushUser(driverId, 'offerTitle', 'offerBody', (lang) => ({
    price: money(booking.estimatedPrice, lang),
    distance: distanceKm !== undefined ? t(lang, 'offerDistance', { km: distanceKm.toFixed(1) }) : '',
  }));
}

async function notifyBroadcast(booking: BookingDoc): Promise<void> {
  const drivers = await loadDriverCandidates();
  await Promise.all(
    drivers.map((d) =>
      pushUser(d.driverId, 'broadcastTitle', 'broadcastBody', (lang) => ({
        vehicle: vehicleName(bookingClass(booking), lang),
        price: money(booking.estimatedPrice, lang),
      })),
    ),
  );
}

// ---------------------------------------------------------------------------
// onBookingCreated — proximity dispatch for imminent pickups, broadcast
// for advance bookings.
// ---------------------------------------------------------------------------

export const onBookingCreated = onDocumentCreated('bookings/{bookingId}', async (event) => {
  const booking = event.data?.data() as BookingDoc | undefined;
  if (!booking || !event.data) return;

  const now = new Date();
  const pickup = booking.scheduledAt?.toDate() ?? now;
  const geo = booking.origin?.coordinates;
  const mode = dispatchMode(pickup, now);

  let ranked: { driverId: string; distanceKm: number }[] = [];
  if (mode === 'targeted' && geo) {
    ranked = rankDrivers(
      await loadDriverCandidates(),
      { lat: geo.latitude, lng: geo.longitude },
      bookingClass(booking),
      now,
    );
  }
  const dispatch = initialDispatch(ranked, mode, now.getTime());
  await event.data.ref.update({ dispatch: toStored(dispatch) });

  logger.info('onBookingCreated', 'dispatch', {
    bookingId: event.params.bookingId,
    mode: dispatch.mode,
    candidates: dispatch.candidates.length,
  });

  if (dispatch.offeredTo) {
    await notifyOffer(dispatch.offeredTo, booking, ranked[0]?.distanceKm);
  } else {
    await notifyBroadcast(booking);
  }
});

/** Applies [advanceOffer] in a transaction and notifies whoever is next. */
async function moveOffer(bookingId: string, declinedBy?: string): Promise<void> {
  const ref = db.collection('bookings').doc(bookingId);
  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const b = snap.data() as BookingDoc | undefined;
    if (!b || b.status !== 'pending' || b.dispatch?.mode !== 'targeted') return null;
    const current = fromStored(b.dispatch);
    if (declinedBy && current.offeredTo !== declinedBy) return null;
    const next = advanceOffer(current, Date.now(), declinedBy ?? current.offeredTo ?? undefined);
    tx.update(ref, { dispatch: toStored(next) });
    return { booking: b, next };
  });
  if (!result) return;
  if (result.next.offeredTo) {
    await notifyOffer(result.next.offeredTo, result.booking);
  } else {
    await notifyBroadcast(result.booking);
  }
}

// ---------------------------------------------------------------------------
// declineOffer — the offered chauffeur passes; offer the next one
// ---------------------------------------------------------------------------

export const declineOffer = onCall(async (req) => {
  const uid = requireAuth(req);
  const { bookingId } = req.data as { bookingId: string };
  if (!bookingId) throw err.invalidArgument('bookingId required');
  await moveOffer(bookingId, uid);
  return { ok: true };
});

// ---------------------------------------------------------------------------
// dispatchTick — every minute, expired offers move to the next chauffeur
// ---------------------------------------------------------------------------

export const dispatchTick = onSchedule('every 1 minutes', async () => {
  const snap = await db
    .collection('bookings')
    .where('status', '==', 'pending')
    .where('dispatch.mode', '==', 'targeted')
    .get();
  const now = Date.now();
  for (const doc of snap.docs) {
    const d = (doc.data() as BookingDoc).dispatch;
    if (d?.offerExpiresAt && d.offerExpiresAt.toMillis() <= now) {
      await moveOffer(doc.id).catch((e) =>
        logger.error('dispatchTick', 'advance failed', { bookingId: doc.id, error: String(e) }),
      );
    }
  }
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

    const bookingRef = db.collection('bookings').doc(bookingId);

    // Driver assigned → copy a rider-facing chauffeur card onto the booking.
    if (after.driverId && after.chauffeur?.driverId !== after.driverId) {
      try {
        const [userSnap, profileSnap] = await Promise.all([
          db.collection('users').doc(after.driverId).get(),
          db.collection('driverProfiles').doc(after.driverId).get(),
        ]);
        const vehicleId = profileSnap.data()?.vehicleId as string | undefined;
        const vehicleSnap = vehicleId ? await db.collection('vehicles').doc(vehicleId).get() : undefined;
        await bookingRef.update({
          chauffeur: buildChauffeur(after.driverId, userSnap.data(), profileSnap.data(), vehicleSnap?.data()),
        });
      } catch (e) {
        logger.error('onBookingStatusChanged', 'chauffeur snapshot failed', { bookingId, error: String(e) });
      }
    }

    // Trip over → stop sharing the chauffeur's phone and live position.
    if (after.status === 'completed' || after.status === 'cancelled') {
      const cleanup: Record<string, unknown> = {};
      if (after.chauffeur?.phone) cleanup['chauffeur.phone'] = admin.firestore.FieldValue.delete();
      if (Object.keys(cleanup).length) await bookingRef.update(cleanup);
      await bookingRef.collection('tracking').doc('live').delete().catch(() => undefined);
    }

    if (after.status === 'completed' && after.driverId) {
      await db
        .collection('driverProfiles')
        .doc(after.driverId)
        .update({ totalRides: admin.firestore.FieldValue.increment(1) })
        .catch((e) => logger.warn('onBookingStatusChanged', 'totalRides update failed', { error: String(e) }));
    }

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

    let freeUntil: Date | null = null;
    if (after.status === 'driver_arrived') {
      const arrivedAt = new Date();
      await bookingRef.update({ driverArrivedAt: admin.firestore.Timestamp.fromDate(arrivedAt) });
      const pickup = (after.pickupAt ?? after.scheduledAt)?.toDate() ?? arrivedAt;
      freeUntil = freeWaitEnd({
        pickup,
        isAirport: !!after.flightNumber,
        landing: after.flight?.estimatedArrival?.toDate() ?? null,
        driverArrivedAt: arrivedAt,
      });
    }

    const statusKeys: Partial<Record<BookingStatus, MessageKey>> = {
      confirmed: 'statusConfirmed',
      driver_arriving: 'statusArriving',
      driver_arrived: 'statusArrived',
      in_progress: 'statusInProgress',
      completed: 'statusCompleted',
      cancelled: 'statusCancelled',
    };

    const key = statusKeys[after.status];
    if (!key) return;

    await pushUser(after.riderId, 'statusTitle', key, (lang) => ({
      time: freeUntil ? clock(freeUntil, lang) : '',
    }));
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
      await pushUser(driverId, 'assignedTitle', 'assignedBody');
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
      await pushUser(riderId, 'acceptedTitle', 'acceptedBody');
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
// rateBooking — the rider rates the chauffeur once, after completion
// ---------------------------------------------------------------------------

export const rateBooking = onCall(async (req) => {
  const uid = requireAuth(req);
  const { bookingId, rating, comment } = (req.data ?? {}) as {
    bookingId: string;
    rating: unknown;
    comment?: string;
  };
  if (!bookingId) throw err.invalidArgument('bookingId required');
  if (!isValidRating(rating)) throw err.invalidArgument('rating must be an integer 1–5');

  const bookingRef = db.collection('bookings').doc(bookingId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(bookingRef);
    if (!snap.exists) throw err.notFound('Booking not found');
    const b = snap.data() as BookingDoc;
    if (b.riderId !== uid) throw err.permissionDenied();
    if (b.status !== 'completed') throw err.failedPrecondition('Only completed trips can be rated');
    if (b.riderRating) throw err.failedPrecondition('Already rated');
    if (!b.driverId) throw err.failedPrecondition('No chauffeur on this booking');

    const driverRef = db.collection('driverProfiles').doc(b.driverId);
    const driver = (await tx.get(driverRef)).data() ?? {};
    const next = nextAverage(Number(driver.rating ?? 0), Number(driver.ratingCount ?? 0), rating);

    tx.update(bookingRef, {
      riderRating: rating,
      riderComment: comment ? String(comment).slice(0, 500) : null,
      ratedAt: admin.firestore.Timestamp.now(),
    });
    tx.update(driverRef, { rating: next.rating, ratingCount: next.count });
  });

  logger.info('rateBooking', 'rated', { bookingId, rating });
  return { ok: true };
});

// ---------------------------------------------------------------------------
// trackFlights — every 15 min, follows inbound flights for airport pickups
// and moves the pickup when the flight is delayed.
// ---------------------------------------------------------------------------

async function fetchFlight(flight: string, date: string, key: string): Promise<unknown> {
  const url = `https://aerodatabox.p.rapidapi.com/flights/number/${encodeURIComponent(flight)}/${date}`;
  const res = await fetch(url, {
    headers: { 'X-RapidAPI-Key': key, 'X-RapidAPI-Host': 'aerodatabox.p.rapidapi.com' },
  });
  if (res.status === 204 || res.status === 404) return [];
  if (!res.ok) throw new Error(`flight provider ${res.status}`);
  return res.json();
}

export const trackFlights = onSchedule(
  { schedule: 'every 15 minutes', secrets: [FLIGHT_API_KEY] },
  async () => {
    const key = FLIGHT_API_KEY.value().trim();
    // Secrets must exist to deploy; "none" means flight tracking is off.
    if (!key || key.toLowerCase() === 'none') {
      logger.warn('trackFlights', 'FLIGHT_API_KEY not configured — skipping');
      return;
    }
    const now = new Date();
    const snap = await db
      .collection('bookings')
      .where('status', 'in', ['pending', 'confirmed', 'driver_arriving'])
      .get();

    for (const doc of snap.docs) {
      const b = doc.data() as BookingDoc;
      const flight = normalizeFlightNumber(b.flightNumber);
      const original = b.scheduledAt?.toDate();
      if (!flight || !original || !shouldTrack(original, now)) continue;

      try {
        const json = await fetchFlight(flight, flightDateUtc(original), key);
        // Riders usually book pickup shortly after the scheduled landing.
        const status = parseAeroDataBox(json, flight, original);
        if (!status) continue;

        const { pickup, delayMin } = adjustedPickup(original, status.scheduledArrival, status.estimatedArrival);
        const previous = (b.pickupAt ?? b.scheduledAt)!.toDate();
        const moved = Math.abs(pickup.getTime() - previous.getTime()) >= ADJUST_THRESHOLD_MIN * 60000;

        await doc.ref.update({
          flight: {
            number: flight,
            status: status.status,
            scheduledArrival: status.scheduledArrival
              ? admin.firestore.Timestamp.fromDate(status.scheduledArrival)
              : null,
            estimatedArrival: status.estimatedArrival
              ? admin.firestore.Timestamp.fromDate(status.estimatedArrival)
              : null,
            delayMin,
            arrived: status.arrived,
            cancelled: status.cancelled,
            terminal: status.terminal,
            gate: status.gate,
            checkedAt: admin.firestore.Timestamp.now(),
          },
          pickupAt: admin.firestore.Timestamp.fromDate(pickup),
        });

        if (moved || status.cancelled) {
          const params = (lang: Lang) => ({ flight, minutes: delayMin, time: clock(pickup, lang) });
          await pushUser(b.riderId, 'flightTitle', status.cancelled ? 'flightCancelled' : 'flightDelayed', params);
          if (b.driverId && !status.cancelled) {
            await pushUser(b.driverId, 'pickupMovedTitle', 'pickupMovedBody', params);
          }
        }
      } catch (e) {
        logger.error('trackFlights', 'lookup failed', { bookingId: doc.id, flight, error: String(e) });
      }
    }
  },
);

// ---------------------------------------------------------------------------
// deleteAccount — required by app stores and personal-data rules.
// Bookings are kept for accounting but stripped of personal contact data.
// ---------------------------------------------------------------------------

const ACTIVE_STATUSES: BookingStatus[] = ['confirmed', 'driver_arriving', 'driver_arrived', 'in_progress'];

export const deleteAccount = onCall(async (req) => {
  const uid = requireAuth(req);
  const user = await getUser(uid);
  if (user.role === 'admin') throw err.failedPrecondition('Admins must be removed by another admin');

  const asRider = await db.collection('bookings').where('riderId', '==', uid).get();
  const asDriver = await db.collection('bookings').where('driverId', '==', uid).get();
  const all = [...asRider.docs, ...asDriver.docs];
  if (all.some((d) => ACTIVE_STATUSES.includes((d.data() as BookingDoc).status))) {
    throw err.failedPrecondition('account/active-trip');
  }

  const now = admin.firestore.Timestamp.now();
  for (const group of chunk(all, 400)) {
    const batch = db.batch();
    for (const doc of group) {
      const b = doc.data() as BookingDoc;
      const update: Record<string, unknown> = { updatedAt: now };
      if (b.riderId === uid) {
        update.passengerName = null;
        update.passengerPhone = null;
        update.notes = null;
        if (b.status === 'pending') {
          update.status = 'cancelled' as BookingStatus;
          update.cancelReason = 'account_deleted';
        }
      }
      if (b.driverId === uid) update['chauffeur.phone'] = admin.firestore.FieldValue.delete();
      batch.update(doc.ref, update);
    }
    await batch.commit();
  }

  const notifications = await db.collection('users').doc(uid).collection('notifications').get();
  for (const group of chunk(notifications.docs, 400)) {
    const batch = db.batch();
    group.forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }

  if (user.role === 'driver') {
    await db.collection('driverProfiles').doc(uid).delete().catch(() => undefined);
    const vehicles = await db.collection('vehicles').where('driverId', '==', uid).get();
    await Promise.all(vehicles.docs.map((v) => v.ref.update({ isActive: false })));
  }

  await db.collection('users').doc(uid).delete();
  await writeAudit('account_deleted', { uid, role: user.role ?? 'unknown' });
  await admin.auth().deleteUser(uid);

  logger.info('deleteAccount', 'deleted', { uid });
  return { ok: true };
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
      // pickupAt reflects flight delays; fall back to the booked time.
      { status: b.status, scheduledAt: (b.pickupAt ?? b.scheduledAt)?.toDate(), createdAt: b.createdAt?.toDate() },
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

  await pushUser(payment.riderId, 'paymentTitle', 'paymentBody', (lang) => ({
    price: money(payment.amount / 100, lang),
  }));
});
