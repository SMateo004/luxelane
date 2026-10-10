import * as admin from 'firebase-admin';
import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentUpdated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as stripe from './stripe_service';
import { STRIPE_SECRET_KEY } from './stripe_service';
import { defineSecret } from 'firebase-functions/params';
import { logger } from './logger';
import { Lang, MessageKey, clock, docName, langOf, money, t, vehicleName } from './messages';
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
import { ASSIGNED_STATUSES, SUSPENDED, isSuspended, suspensionChange } from './accounts';
import { WINDOW_MS, bestDiscount, loyaltyDiscount, nextTier, parseConfig, tierFor } from './loyalty';
import {
  MAX_MESSAGE,
  MAX_STACK,
  NO_DRIVERS_ONLINE_THROTTLE_MS,
  clip,
  fingerprint,
  isPlatform,
  needsEscalation,
  needsNoDriverAlert,
  normalizeMessage,
  throttled,
} from './observability';
import { AuthorRole, TicketCategory, preview, priorityFor, statusAfterMessage } from './support';
import { PromoDoc, evaluatePromo, normalizeCode, promoDefinitionError } from './promo';
import {
  DocStatus,
  DocType,
  DriverDoc,
  REMINDER_DAYS,
  approvalError,
  daysLeft,
  isDocType,
  isExpired,
  isFullyVerified,
  reminderDue,
} from './documents';
import {
  CompanyDoc,
  CompanyRole,
  BillingInput,
  CorporateBilling,
  isCompanyRole,
  leavesAdmin,
  normalizeEmail,
  resolveBilling,
  validateCompany,
} from './corporate';
import {
  BookingStatus,
  UserRole,
  canCapture,
  canRelease,
  chunk,
  freeWaitEnd,
  isStalePending,
  isLateCancellation,
  ADMIN_CANCELLABLE,
  RIDER_CANCELLABLE,
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
  clampDays,
  clampHours,
  computeCharterPrice,
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
  cancelledBy?: 'rider' | 'admin' | 'system';
  promoCode?: string | null;
  promoReleased?: boolean;
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
  /** Chauffeur by the day (hourly charters only); 1 otherwise. */
  days?: number;
  amount: number;
  currency: string;
  expiresAt: admin.firestore.Timestamp;
  createdAt: admin.firestore.Timestamp;
  bookingId?: string;
  /** Promo applied at quote time: amount = baseAmount - discount. */
  promoCode?: string | null;
  baseAmount?: number;
  discount?: number;
  /** Loyalty tier whose discount applied instead of a promo (if larger). */
  loyaltyTier?: string | null;
}

interface UserDoc {
  locale?: string;
  isActive?: boolean;
  role?: UserRole;
  email?: string;
  displayName?: string;
  companyId?: string | null;
  companyRole?: CompanyRole | null;
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

/** Suspended accounts (isActive=false) can't book or take rides. */
async function requireActive(uid: string): Promise<UserDoc> {
  const user = await getUser(uid);
  if (isSuspended(user)) throw err.permissionDenied(SUSPENDED);
  return user;
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
// Promo codes — promoCodes/{CODE}, per-rider uses in .../redemptions/{uid}
// ---------------------------------------------------------------------------

const promoRef = (code: string) => db.collection('promoCodes').doc(code);

function toPromo(data: admin.firestore.DocumentData | undefined): PromoDoc | null {
  if (!data) return null;
  return {
    ...(data as PromoDoc),
    validFrom: (data.validFrom as admin.firestore.Timestamp | null | undefined)?.toDate() ?? null,
    validUntil: (data.validUntil as admin.firestore.Timestamp | null | undefined)?.toDate() ?? null,
  };
}

/** Checks a code for this rider and fare (outside a transaction). */
async function checkPromo(uid: string, code: string, fare: number, vehicleClass: string) {
  const [promoSnap, redemptionSnap, completed] = await Promise.all([
    promoRef(code).get(),
    promoRef(code).collection('redemptions').doc(uid).get(),
    db.collection('bookings').where('riderId', '==', uid).where('status', '==', 'completed').limit(1).get(),
  ]);
  return evaluatePromo(toPromo(promoSnap.data()), {
    now: new Date(),
    fare,
    vehicleClass,
    userRedemptions: (redemptionSnap.data()?.count as number | undefined) ?? 0,
    hasCompletedRide: !completed.empty,
  });
}

/** Preview for the booking screen; the binding check happens in quoteBooking. */
export const checkPromoCode = onCall(async (req) => {
  const uid = requireAuth(req);
  const d = (req.data ?? {}) as { code?: unknown; fare?: unknown; vehicleClass?: unknown };
  const code = normalizeCode(d.code);
  if (!code) return { ok: false, error: 'promo/invalid' };
  const fare = Number(d.fare);
  if (!Number.isFinite(fare) || fare <= 0) throw err.invalidArgument('invalid fare');
  return await checkPromo(uid, code, fare, String(d.vehicleClass ?? ''));
});

/** Admin: create or edit a promo code (the redemption counter is server-owned). */
export const savePromoCode = onCall(async (req) => {
  const uid = await requireAdmin(req);
  const d = (req.data ?? {}) as Record<string, unknown>;
  const code = normalizeCode(d.code);
  const ms = (v: unknown) => (Number.isFinite(Number(v)) && Number(v) > 0 ? new Date(Number(v)) : null);
  const def: Partial<PromoDoc> = {
    code: code ?? undefined,
    type: d.type as PromoDoc['type'],
    value: Number(d.value),
    maxDiscount: Math.max(0, Number(d.maxDiscount) || 0),
    minFare: Math.max(0, Number(d.minFare) || 0),
    validFrom: ms(d.validFrom),
    validUntil: ms(d.validUntil),
    maxRedemptions: Math.max(0, Math.floor(Number(d.maxRedemptions) || 0)),
    perUserLimit: Math.max(1, Math.floor(Number(d.perUserLimit) || 1)),
    firstRideOnly: d.firstRideOnly === true,
    vehicleClasses: Array.isArray(d.vehicleClasses) ? d.vehicleClasses.filter(isVehicleClass) : [],
    active: d.active !== false,
  };
  const error = promoDefinitionError(def);
  if (error || !code) throw err.invalidArgument(error ?? 'promo/bad-code');

  const ref = promoRef(code);
  const ts = admin.firestore.Timestamp.now();
  const existing = await ref.get();
  if (d.create === true && existing.exists) throw err.failedPrecondition('promo/exists');
  await ref.set(
    {
      ...def,
      validFrom: def.validFrom ? admin.firestore.Timestamp.fromDate(def.validFrom) : null,
      validUntil: def.validUntil ? admin.firestore.Timestamp.fromDate(def.validUntil) : null,
      description: typeof d.description === 'string' ? d.description.trim().slice(0, 120) : '',
      updatedAt: ts,
      ...(existing.exists ? {} : { createdAt: ts, createdBy: uid, redemptions: 0 }),
    },
    { merge: true },
  );
  await writeAudit(existing.exists ? 'promo_updated' : 'promo_created', { code, by: uid });
  return { code };
});

// ---------------------------------------------------------------------------
// Loyalty — tiers by completed rides in the last 12 months (config/loyalty)
// ---------------------------------------------------------------------------

async function loadLoyalty(uid: string) {
  const config = parseConfig((await db.collection('config').doc('loyalty').get()).data());
  if (!config.enabled) return { config, rides: 0, tier: null, next: null };
  const since = admin.firestore.Timestamp.fromMillis(Date.now() - WINDOW_MS);
  const count = await db
    .collection('bookings')
    .where('riderId', '==', uid)
    .where('status', '==', 'completed')
    .where('scheduledAt', '>=', since)
    .count()
    .get();
  const rides = count.data().count;
  return { config, rides, tier: tierFor(rides, config), next: nextTier(rides, config) };
}

/** The rider's standing for the profile and the booking screen. */
export const myLoyalty = onCall(async (req) => {
  const uid = requireAuth(req);
  const { config, rides, tier, next } = await loadLoyalty(uid);
  return { enabled: config.enabled, rides, tier, next, tiers: config.tiers };
});

// ---------------------------------------------------------------------------
// quoteBooking — fixed, server-computed price in Bs, valid for 15 minutes
// ---------------------------------------------------------------------------

export const quoteBooking = onCall(async (req) => {
  const uid = requireAuth(req);
  await requireActive(uid);
  const { vehicleClass, serviceType, origin, destination, routeDistanceKm, hours, days, promoCode } = (req.data ?? {}) as {
    vehicleClass: unknown;
    serviceType: unknown;
    origin: unknown;
    destination?: unknown;
    routeDistanceKm?: unknown;
    hours?: unknown;
    days?: unknown;
    promoCode?: unknown;
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
  const quoteDays = hourly ? clampDays(days) : 1;
  const baseAmount = hourly
    ? computeCharterPrice(rule, quoteHours ?? 0, quoteDays)
    : computePrice(rule, serviceType, { km: distanceKm ?? 0 });

  // A valid promo lowers the fixed price; an invalid one is reported and the
  // quote keeps the full price.
  let promoDiscount = 0;
  let appliedCode: string | null = null;
  let promoError: string | null = null;
  if (promoCode !== undefined && promoCode !== null && promoCode !== '') {
    const code = normalizeCode(promoCode);
    const result = code ? await checkPromo(uid, code, baseAmount, vehicleClass) : { ok: false as const, error: 'promo/invalid' };
    if (result.ok) {
      promoDiscount = result.discount;
      appliedCode = code;
    } else {
      promoError = result.error;
    }
  }

  // Loyalty tier discount; discounts don't stack, the larger one applies.
  const loyalty = await loadLoyalty(uid);
  const best = bestDiscount(promoDiscount, loyaltyDiscount(baseAmount, loyalty.tier));
  let loyaltyTier: string | null = null;
  if (best.source === 'loyalty') {
    loyaltyTier = loyalty.tier!.id;
    if (appliedCode) promoError = 'promo/loyalty-better';
    appliedCode = null; // the promo isn't used, so it isn't redeemed either
  }
  const discount = best.amount;
  const amount = baseAmount - discount;

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
    days: quoteDays,
    amount,
    currency: CURRENCY,
    expiresAt,
    createdAt: now,
    promoCode: appliedCode,
    baseAmount,
    discount,
    loyaltyTier,
  };
  const ref = await db.collection('quotes').add(quote);

  logger.info('quoteBooking', 'quoted', { uid, quoteId: ref.id, vehicleClass, serviceType, amount, days: quoteDays });
  return {
    quoteId: ref.id,
    amount,
    currency: CURRENCY,
    distanceKm,
    hours: quoteHours,
    days: quoteDays,
    expiresAt: expiresAt.toMillis(),
    baseAmount,
    discount,
    promoCode: appliedCode,
    promoError,
    loyaltyTier,
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
  await requireActive(uid);
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
    billing?: BillingInput;
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

  // Corporate billing: the company is invoiced monthly, nothing is charged
  // to the rider and the chauffeur collects nothing.
  let corporate: CorporateBilling | null = null;
  if (d.billing && d.billing.type === 'corporate') {
    if (paymentIntentId) throw err.invalidArgument('billing/card-with-corporate');
    const rider = await getUser(uid);
    const cid = rider.companyId ?? null;
    const [companySnap, memberSnap] = cid
      ? await Promise.all([
          db.collection('companies').doc(cid).get(),
          db.collection('companies').doc(cid).collection('members').doc(uid).get(),
        ])
      : [null, null];
    const billing = resolveBilling(
      d.billing,
      cid,
      (companySnap?.data() as CompanyDoc | undefined) ?? null,
      memberSnap?.exists ?? false,
    );
    if (!billing.ok) throw err.failedPrecondition(billing.error);
    corporate = billing.value;
  }

  const quoteRef = db.collection('quotes').doc(d.quoteId);
  const bookingRef = db.collection('bookings').doc();
  const ts = admin.firestore.Timestamp.now();

  await db.runTransaction(async (tx) => {
    const fresh = await tx.get(quoteRef);
    if ((fresh.data() as QuoteDoc | undefined)?.bookingId) throw err.failedPrecondition('Quote already used');

    // Redeem the promo atomically: limits are re-checked against live counts.
    if (quote.promoCode) {
      const pRef = promoRef(quote.promoCode);
      const rRef = pRef.collection('redemptions').doc(uid);
      const [pSnap, rSnap] = await Promise.all([tx.get(pRef), tx.get(rRef)]);
      const check = evaluatePromo(toPromo(pSnap.data()), {
        now: new Date(),
        fare: quote.baseAmount ?? quote.amount,
        vehicleClass: quote.vehicleClass,
        userRedemptions: (rSnap.data()?.count as number | undefined) ?? 0,
        hasCompletedRide: false, // checked when quoted
      });
      if (!check.ok) throw err.failedPrecondition(check.error);
      tx.update(pRef, { redemptions: admin.firestore.FieldValue.increment(1) });
      tx.set(
        rRef,
        {
          count: admin.firestore.FieldValue.increment(1),
          bookingIds: admin.firestore.FieldValue.arrayUnion(bookingRef.id),
          updatedAt: admin.firestore.Timestamp.now(),
        },
        { merge: true },
      );
    }
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
      baseAmount: quote.baseAmount ?? quote.amount,
      discount: quote.discount ?? 0,
      promoCode: quote.promoCode ?? null,
      loyaltyTier: quote.loyaltyTier ?? null,
      finalPrice: null,
      paymentId: null,
      currency: quote.currency,
      quoteId: d.quoteId,
      distanceKm: quote.distanceKm,
      hours: quote.hours,
      days: quote.days ?? 1,
      paymentMethod: corporate ? 'corporate' : paymentIntentId ? 'card' : 'pay_later',
      companyId: corporate?.companyId ?? null,
      companyName: corporate?.companyName ?? null,
      costCenter: corporate?.costCenter ?? null,
      billingReference: corporate?.billingReference ?? null,
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

  logger.info('createBooking', 'created', {
    uid,
    bookingId: bookingRef.id,
    amount: quote.amount,
    companyId: corporate?.companyId ?? null,
  });
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
  return snap.docs.filter((d) => d.data().suspended !== true).map((d) => {
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
  await startDispatch(event.data.ref, booking, event.params.bookingId);
});

/** Offers a pending booking to the nearest chauffeurs, or to everyone. */
async function startDispatch(
  ref: admin.firestore.DocumentReference,
  booking: BookingDoc,
  bookingId: string,
): Promise<void> {
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
  await ref.update({ dispatch: toStored(dispatch) });

  logger.info('startDispatch', 'dispatch', {
    bookingId,
    mode: dispatch.mode,
    candidates: dispatch.candidates.length,
  });

  if (dispatch.offeredTo) {
    await notifyOffer(dispatch.offeredTo, booking, ranked[0]?.distanceKm);
  } else {
    await notifyBroadcast(booking);
  }
}

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

    // Cancelled → give the promo use back to the rider (once).
    if (after.status === 'cancelled' && after.promoCode && !after.promoReleased) {
      const code = after.promoCode;
      try {
        await db.runTransaction(async (tx) => {
          const b = await tx.get(bookingRef);
          if ((b.data() as BookingDoc | undefined)?.promoReleased) return;
          const pRef = promoRef(code);
          tx.update(pRef, { redemptions: admin.firestore.FieldValue.increment(-1) });
          tx.set(
            pRef.collection('redemptions').doc(after.riderId),
            {
              count: admin.firestore.FieldValue.increment(-1),
              bookingIds: admin.firestore.FieldValue.arrayRemove(bookingId),
            },
            { merge: true },
          );
          tx.update(bookingRef, { promoReleased: true });
        });
      } catch (e) {
        logger.error('onBookingStatusChanged', 'promo release failed', { bookingId, error: String(e) });
      }
    }

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
    // The rider cancelled it themselves in the app: no need to tell them.
    if (after.status === 'cancelled' && after.cancelledBy === 'rider') return;

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

  // Same ranking as automatic dispatch: nearest verified, available driver
  // of the right class with a fresh position.
  const geo = booking.origin?.coordinates;
  const ranked = geo
    ? rankDrivers(await loadDriverCandidates(), { lat: geo.latitude, lng: geo.longitude }, vehicleClass, new Date())
    : [];

  for (const { driverId } of ranked) {
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
// onUserSuspensionChanged — when an admin turns an account off (isActive),
// a chauffeur is taken offline and out of dispatch, and admins are told
// about rides still assigned to them. Turning it back on lifts the flag
// (the chauffeur goes online again themselves).
// ---------------------------------------------------------------------------

export const onUserSuspensionChanged = onDocumentUpdated('users/{uid}', async (event) => {
  const before = event.data?.before.data() as UserDoc | undefined;
  const after = event.data?.after.data() as UserDoc | undefined;
  const change = suspensionChange(before, after);
  if (!change) return;
  const uid = event.params.uid;
  await writeAudit(change === 'suspended' ? 'user_suspended' : 'user_reactivated', { userId: uid, role: after?.role ?? null });
  if (after?.role !== 'driver') return;

  const profileRef = db.collection('driverProfiles').doc(uid);
  if (!(await profileRef.get()).exists) return;
  if (change === 'reactivated') {
    await profileRef.update({ suspended: false });
    return;
  }
  await profileRef.update({ suspended: true, isAvailable: false });

  const assigned = await db
    .collection('bookings')
    .where('driverId', '==', uid)
    .where('status', 'in', [...ASSIGNED_STATUSES])
    .get();
  logger.warn('onUserSuspensionChanged', 'chauffeur suspended', { uid, assigned: assigned.size });
  if (assigned.size > 0) {
    await pushAdmins('opsSuspendedDriverTitle', 'opsSuspendedDriverBody', () => ({
      name: after?.displayName || after?.email || uid,
      count: assigned.size,
    }));
  }
});

// ---------------------------------------------------------------------------
// acceptBooking  (HTTPS Callable) — atomic self-assignment by a verified driver.
// Prevents two drivers from accepting the same booking simultaneously.
// ---------------------------------------------------------------------------

export const acceptBooking = onCall(async (req) => {
  const driverId = requireAuth(req);
  const { bookingId } = req.data as { bookingId: string };
  if (!bookingId) throw err.invalidArgument('bookingId required');

  const caller = await requireActive(driverId);
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
// cancelBooking — rider (before the ride starts) or admin. Free up to 1 h
// before pickup; later cancellations are flagged for the future policy.
// ---------------------------------------------------------------------------

export const cancelBooking = onCall(async (req) => {
  const uid = requireAuth(req);
  const { bookingId, reason } = (req.data ?? {}) as { bookingId: string; reason?: string };
  if (!bookingId) throw err.invalidArgument('bookingId required');

  const caller = await getUser(uid);
  const isAdmin = caller.role === 'admin';
  const ref = db.collection('bookings').doc(bookingId);
  const now = new Date();

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw err.notFound('Booking not found');
    const b = snap.data() as BookingDoc;
    if (!isAdmin && b.riderId !== uid) throw err.permissionDenied();
    const allowed = isAdmin ? ADMIN_CANCELLABLE : RIDER_CANCELLABLE;
    if (!allowed.includes(b.status)) throw err.failedPrecondition('booking/not-cancellable');

    const pickup = (b.pickupAt ?? b.scheduledAt)?.toDate() ?? now;
    const late = !isAdmin && isLateCancellation(pickup, now);
    tx.update(ref, {
      status: 'cancelled' as BookingStatus,
      cancelledBy: isAdmin ? 'admin' : 'rider',
      cancelledAt: admin.firestore.Timestamp.fromDate(now),
      cancelReason: reason ? String(reason).slice(0, 300) : null,
      lateCancellation: late,
      updatedAt: admin.firestore.Timestamp.fromDate(now),
    });
    if (b.driverId) {
      tx.update(db.collection('driverProfiles').doc(b.driverId), { isAvailable: true });
    }
    return { driverId: b.driverId, pickup, late, riderId: b.riderId };
  });

  if (result.driverId) {
    await pushUser(result.driverId, 'riderCancelledTitle', 'riderCancelledBody', (lang) => ({
      time: clock(result.pickup, lang),
    }));
  }
  if (isAdmin) {
    await writeAudit('booking_cancelled_by_admin', { bookingId, by: uid, reason: reason ?? null });
  }
  logger.info('cancelBooking', 'cancelled', { bookingId, by: isAdmin ? 'admin' : 'rider', late: result.late });
  return { cancelled: true, lateCancellation: result.late };
});

// ---------------------------------------------------------------------------
// releaseChauffeur — admin takes a ride away from its chauffeur (can't make
// it, suspended…) before the trip starts; it goes back to pending and to
// dispatch, and both rider and chauffeur are told.
// ---------------------------------------------------------------------------

export const releaseChauffeur = onCall(async (req) => {
  const adminId = await requireAdmin(req);
  const { bookingId, reason } = (req.data ?? {}) as { bookingId?: string; reason?: string };
  if (!bookingId) throw err.invalidArgument('bookingId required');
  const ref = db.collection('bookings').doc(bookingId);

  const released = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw err.notFound('Booking not found');
    const b = snap.data() as BookingDoc;
    if (!canRelease(b.status, b.driverId)) throw err.failedPrecondition('booking/not-releasable');
    tx.update(ref, {
      status: 'pending' as BookingStatus,
      driverId: null,
      chauffeur: null,
      driverArrivedAt: null,
      alertedNoDriver: false,
      updatedAt: admin.firestore.Timestamp.now(),
    });
    tx.update(db.collection('driverProfiles').doc(b.driverId!), { isAvailable: true });
    return b;
  });

  await ref.collection('tracking').doc('live').delete().catch(() => undefined);
  const pickup = (released.pickupAt ?? released.scheduledAt)?.toDate() ?? new Date();
  const time = (lang: Lang) => ({ time: clock(pickup, lang) });
  await Promise.all([
    pushUser(released.driverId!, 'releasedTitle', 'releasedBody', time),
    pushUser(released.riderId, 'reassigningTitle', 'reassigningBody', time),
  ]);
  await writeAudit('booking_chauffeur_released', {
    bookingId,
    by: adminId,
    driverId: released.driverId,
    reason: reason ? String(reason).slice(0, 300) : null,
  });
  await startDispatch(ref, { ...released, status: 'pending', driverId: undefined }, bookingId);
  logger.info('releaseChauffeur', 'released', { bookingId, driverId: released.driverId });
  return { released: true };
});

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

  // Support conversations are personal data too.
  const tickets = await db.collection('supportTickets').where('userId', '==', uid).get();
  for (const t of tickets.docs) {
    const msgs = await t.ref.collection('messages').get();
    for (const group of chunk(msgs.docs, 400)) {
      const batch = db.batch();
      group.forEach((m) => batch.delete(m.ref));
      await batch.commit();
    }
    await t.ref.delete();
  }

  const notifications = await db.collection('users').doc(uid).collection('notifications').get();
  for (const group of chunk(notifications.docs, 400)) {
    const batch = db.batch();
    group.forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }

  if (user.role === 'driver') {
    // Identity documents are personal data: remove files and their records.
    const docs = await verificationDocs(uid).get();
    await Promise.all(docs.docs.map((d) => d.ref.delete()));
    await admin.storage().bucket().deleteFiles({ prefix: `driver_documents/${uid}/` }).catch(() => undefined);
    await db.collection('driverProfiles').doc(uid).delete().catch(() => undefined);
    const vehicles = await db.collection('vehicles').where('driverId', '==', uid).get();
    await Promise.all(vehicles.docs.map((v) => v.ref.update({ isActive: false })));
  }

  if (user.companyId) {
    await db.collection('companies').doc(user.companyId).collection('members').doc(uid).delete().catch(() => undefined);
  }

  await db.collection('users').doc(uid).delete();
  await writeAudit('account_deleted', { uid, role: user.role ?? 'unknown' });
  await admin.auth().deleteUser(uid);

  logger.info('deleteAccount', 'deleted', { uid });
  return { ok: true };
});

// ---------------------------------------------------------------------------
// Corporate accounts — companies are invoiced monthly for their members'
// rides. Membership lives in companies/{id}/members/{uid} and is mirrored on
// users/{uid}.companyId / companyRole (read by the rules and the app).
// Invites for people without an account wait in companyInvites/{email}.
// ---------------------------------------------------------------------------

const companies = () => db.collection('companies');

async function loadCompany(companyId: unknown): Promise<{ id: string; data: CompanyDoc }> {
  if (typeof companyId !== 'string' || !companyId) throw err.invalidArgument('companyId required');
  const snap = await companies().doc(companyId).get();
  if (!snap.exists) throw err.notFound('Company not found');
  return { id: snap.id, data: snap.data() as CompanyDoc };
}

/** Platform admins manage every company; company admins only their own. */
async function requireCompanyManager(uid: string, companyId: string): Promise<{ platformAdmin: boolean }> {
  const user = await getUser(uid);
  if (user.role === 'admin') return { platformAdmin: true };
  const member = await companies().doc(companyId).collection('members').doc(uid).get();
  if (member.data()?.role !== 'admin') throw err.permissionDenied('Company admin only');
  return { platformAdmin: false };
}

async function companyAdminUids(companyId: string): Promise<string[]> {
  const snap = await companies().doc(companyId).collection('members').where('role', '==', 'admin').get();
  return snap.docs.map((d) => d.id);
}

/** Links an existing rider account to a company (one company per rider). */
async function linkMember(
  companyId: string,
  company: CompanyDoc,
  uid: string,
  role: CompanyRole,
  by: string,
): Promise<void> {
  const userRef = db.collection('users').doc(uid);
  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const user = (userSnap.data() as UserDoc | undefined) ?? {};
    if (!userSnap.exists) throw err.notFound('User not found');
    if (user.role !== 'rider') throw err.failedPrecondition('company/not-a-rider');
    if (user.companyId && user.companyId !== companyId) throw err.failedPrecondition('company/user-in-other-company');
    tx.set(companies().doc(companyId).collection('members').doc(uid), {
      uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      role,
      addedBy: by,
      addedAt: admin.firestore.Timestamp.now(),
    });
    tx.update(userRef, { companyId, companyRole: role });
  });
  await pushUser(uid, 'companyAddedTitle', 'companyAddedBody', { company: company.name });
}

/** Adds by e-mail: links the account if it exists, otherwise leaves an invite. */
async function addMemberByEmail(
  companyId: string,
  company: CompanyDoc,
  email: string,
  role: CompanyRole,
  by: string,
): Promise<'linked' | 'invited'> {
  let authUid: string | null = null;
  try {
    authUid = (await admin.auth().getUserByEmail(email)).uid;
  } catch {
    authUid = null;
  }
  const userDoc = authUid ? await db.collection('users').doc(authUid).get() : null;
  if (authUid && userDoc?.exists) {
    await linkMember(companyId, company, authUid, role, by);
    return 'linked';
  }
  await db.collection('companyInvites').doc(email).set({
    email,
    companyId,
    companyName: company.name,
    role,
    invitedBy: by,
    createdAt: admin.firestore.Timestamp.now(),
  });
  return 'invited';
}

export const createCompany = onCall(async (req) => {
  const uid = await requireAdmin(req);
  const d = (req.data ?? {}) as Record<string, unknown>;
  const v = validateCompany(d, false);
  if (!v.ok) throw err.invalidArgument(v.error);
  const adminEmail = normalizeEmail(d.adminEmail);
  if (!adminEmail) throw err.invalidArgument('company/invalid-admin-email');

  const now = admin.firestore.Timestamp.now();
  const company = { ...(v.value as CompanyDoc), active: true };
  const ref = await companies().add({ ...company, createdAt: now, updatedAt: now, createdBy: uid });
  const result = await addMemberByEmail(ref.id, company, adminEmail, 'admin', uid);

  await writeAudit('company_created', { companyId: ref.id, by: uid, name: company.name });
  logger.info('createCompany', 'created', { companyId: ref.id, admin: result });
  return { companyId: ref.id, admin: result };
});

export const updateCompany = onCall(async (req) => {
  const uid = requireAuth(req);
  const d = (req.data ?? {}) as Record<string, unknown>;
  const { id, data } = await loadCompany(d.companyId);
  const { platformAdmin } = await requireCompanyManager(uid, id);

  const v = validateCompany(d, true);
  if (!v.ok) throw err.invalidArgument(v.error);
  const update: Record<string, unknown> = { ...v.value };
  // Only Luxelane can suspend or reactivate a company account.
  if (d.active !== undefined) {
    if (!platformAdmin) throw err.permissionDenied('Admin only');
    update.active = d.active === true;
  }
  const merged = { ...data, ...update } as CompanyDoc;
  if (merged.requireCostCenter && merged.costCenters.length === 0) {
    throw err.invalidArgument('company/cost-center-required-without-list');
  }
  if (merged.name !== data.name) {
    // Keep pending invites readable with the new name.
    const invites = await db.collection('companyInvites').where('companyId', '==', id).get();
    await Promise.all(invites.docs.map((i) => i.ref.update({ companyName: merged.name })));
  }
  await companies().doc(id).update({ ...update, updatedAt: admin.firestore.Timestamp.now() });
  await writeAudit('company_updated', { companyId: id, by: uid, fields: Object.keys(update) });
  return { ok: true };
});

export const addCompanyMember = onCall(async (req) => {
  const uid = requireAuth(req);
  const d = (req.data ?? {}) as Record<string, unknown>;
  const { id, data } = await loadCompany(d.companyId);
  await requireCompanyManager(uid, id);
  const email = normalizeEmail(d.email);
  if (!email) throw err.invalidArgument('company/invalid-email');
  const role: CompanyRole = isCompanyRole(d.role) ? d.role : 'member';
  if (!data.active) throw err.failedPrecondition('billing/company-inactive');

  const result = await addMemberByEmail(id, data, email, role, uid);
  await writeAudit('company_member_added', { companyId: id, by: uid, email, role, result });
  return { result };
});

export const updateCompanyMember = onCall(async (req) => {
  const uid = requireAuth(req);
  const d = (req.data ?? {}) as Record<string, unknown>;
  const { id } = await loadCompany(d.companyId);
  await requireCompanyManager(uid, id);
  const memberUid = typeof d.uid === 'string' ? d.uid : '';
  if (!memberUid) throw err.invalidArgument('uid required');
  const role = isCompanyRole(d.role) ? d.role : null;
  const remove = d.remove === true;
  if (!remove && !role) throw err.invalidArgument('company/invalid-role');

  const memberRef = companies().doc(id).collection('members').doc(memberUid);
  if (!(await memberRef.get()).exists) throw err.notFound('Member not found');
  if (!leavesAdmin(await companyAdminUids(id), memberUid, remove ? null : role)) {
    throw err.failedPrecondition('company/last-admin');
  }

  const userRef = db.collection('users').doc(memberUid);
  const batch = db.batch();
  if (remove) {
    batch.delete(memberRef);
    batch.set(userRef, { companyId: null, companyRole: null }, { merge: true });
  } else {
    batch.update(memberRef, { role });
    batch.set(userRef, { companyRole: role }, { merge: true });
  }
  await batch.commit();
  await writeAudit(remove ? 'company_member_removed' : 'company_member_role', {
    companyId: id,
    by: uid,
    member: memberUid,
    role: remove ? null : role,
  });
  return { ok: true };
});

export const cancelCompanyInvite = onCall(async (req) => {
  const uid = requireAuth(req);
  const d = (req.data ?? {}) as Record<string, unknown>;
  const email = normalizeEmail(d.email);
  if (!email) throw err.invalidArgument('company/invalid-email');
  const ref = db.collection('companyInvites').doc(email);
  const invite = await ref.get();
  if (!invite.exists) return { ok: true };
  await requireCompanyManager(uid, invite.data()!.companyId as string);
  await ref.delete();
  return { ok: true };
});

/** A new rider whose e-mail was invited joins the company on sign-up. */
export const claimCompanyInvite = onDocumentCreated('users/{uid}', async (event) => {
  const data = event.data?.data() as UserDoc | undefined;
  const email = normalizeEmail(data?.email);
  if (!data || data.role !== 'rider' || !email) return;
  const ref = db.collection('companyInvites').doc(email);
  const invite = await ref.get();
  if (!invite.exists) return;
  const inv = invite.data() as { companyId: string; role: CompanyRole; invitedBy: string };
  try {
    const { id, data: company } = await loadCompany(inv.companyId);
    if (!company.active) return;
    await linkMember(id, company, event.params.uid, inv.role, inv.invitedBy);
    await ref.delete();
    logger.info('claimCompanyInvite', 'joined', { uid: event.params.uid, companyId: id });
  } catch (e) {
    logger.error('claimCompanyInvite', 'failed', { uid: event.params.uid, error: String(e) });
  }
});

// ---------------------------------------------------------------------------
// Chauffeur verification documents — driverProfiles/{uid}/verificationDocs/{type}
// The chauffeur uploads (status 'pending'), an admin approves or rejects, and
// a daily job expires documents and sends renewal reminders. Verification
// (driverProfiles.documentsVerified) is always recomputed from the documents.
// ---------------------------------------------------------------------------

const verificationDocs = (uid: string) => db.collection('driverProfiles').doc(uid).collection('verificationDocs');

function toDriverDoc(data: admin.firestore.DocumentData | undefined): DriverDoc | undefined {
  if (!data) return undefined;
  return {
    status: data.status as DocStatus,
    expiresAt: (data.expiresAt as admin.firestore.Timestamp | null | undefined)?.toDate() ?? null,
    remindedDays: (data.remindedDays as number | null | undefined) ?? null,
  };
}

/** Recomputes documentsVerified; an unverified chauffeur goes offline. */
async function recomputeVerification(uid: string): Promise<boolean> {
  const snap = await verificationDocs(uid).get();
  const docs: Partial<Record<DocType, DriverDoc>> = {};
  snap.docs.forEach((d) => {
    if (isDocType(d.id)) docs[d.id] = toDriverDoc(d.data());
  });
  const verified = isFullyVerified(docs, new Date());
  const profileRef = db.collection('driverProfiles').doc(uid);
  const profile = await profileRef.get();
  if (!profile.exists) return verified;
  const update: Record<string, unknown> = { documentsVerified: verified };
  if (!verified) update.isAvailable = false;
  if (profile.data()?.documentsVerified !== verified || (!verified && profile.data()?.isAvailable)) {
    await profileRef.update(update);
  }
  return verified;
}

export const onVerificationDocWritten = onDocumentWritten(
  'driverProfiles/{uid}/verificationDocs/{type}',
  async (event) => {
    const verified = await recomputeVerification(event.params.uid);
    logger.info('onVerificationDocWritten', 'recomputed', { uid: event.params.uid, type: event.params.type, verified });
  },
);

export const reviewDriverDocument = onCall(async (req) => {
  const uid = await requireAdmin(req);
  const d = (req.data ?? {}) as {
    driverId?: unknown;
    type?: unknown;
    approve?: unknown;
    reason?: unknown;
    expiresAt?: unknown;
  };
  if (typeof d.driverId !== 'string' || !d.driverId) throw err.invalidArgument('driverId required');
  if (!isDocType(d.type)) throw err.invalidArgument('documents/invalid-type');
  const ref = verificationDocs(d.driverId).doc(d.type);
  const snap = await ref.get();
  if (!snap.exists) throw err.notFound('Document not found');

  const now = new Date();
  const approve = d.approve === true;
  const update: Record<string, unknown> = {
    reviewedAt: admin.firestore.Timestamp.fromDate(now),
    reviewedBy: uid,
    remindedDays: null,
  };
  if (approve) {
    // The admin confirms (or corrects) the expiry printed on the document.
    const ms = Number(d.expiresAt);
    const expiresAt = Number.isFinite(ms) && ms > 0
      ? new Date(ms)
      : (snap.data()?.expiresAt as admin.firestore.Timestamp | undefined)?.toDate() ?? null;
    const error = approvalError(d.type, expiresAt, now);
    if (error) throw err.invalidArgument(error);
    update.status = 'approved' as DocStatus;
    update.expiresAt = expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null;
    update.rejectionReason = null;
  } else {
    const reason = typeof d.reason === 'string' ? d.reason.trim().slice(0, 300) : '';
    if (!reason) throw err.invalidArgument('documents/reason-required');
    update.status = 'rejected' as DocStatus;
    update.rejectionReason = reason;
  }
  await ref.update(update);

  const type = d.type;
  if (approve) {
    await pushUser(d.driverId, 'docApprovedTitle', 'docApprovedBody', (lang) => ({ doc: docName(type, lang) }));
  } else {
    await pushUser(d.driverId, 'docRejectedTitle', 'docRejectedBody', (lang) => ({
      doc: docName(type, lang),
      reason: update.rejectionReason as string,
    }));
  }
  await writeAudit(approve ? 'driver_document_approved' : 'driver_document_rejected', {
    driverId: d.driverId,
    type,
    by: uid,
  });
  return { ok: true };
});

/** Daily: expires documents and reminds chauffeurs 30 and 7 days before. */
export const checkDocumentExpiry = onSchedule(
  { schedule: 'every day 09:00', timeZone: 'America/La_Paz' },
  async () => {
    const now = new Date();
    const horizon = admin.firestore.Timestamp.fromMillis(now.getTime() + REMINDER_DAYS[0] * 86400000);
    const snap = await db
      .collectionGroup('verificationDocs')
      .where('status', '==', 'approved')
      .where('expiresAt', '<=', horizon)
      .get();

    let expired = 0;
    let reminded = 0;
    for (const doc of snap.docs) {
      const driverId = doc.ref.parent.parent?.id;
      const data = toDriverDoc(doc.data());
      if (!driverId || !data) continue;
      const type = doc.id;
      if (isExpired(data, now)) {
        await doc.ref.update({ status: 'expired' as DocStatus });
        await pushUser(driverId, 'docExpiredTitle', 'docExpiredBody', (lang) => ({ doc: docName(type, lang) }));
        expired++;
        continue;
      }
      const due = reminderDue(data, now);
      if (due !== null && data.expiresAt) {
        const left = daysLeft(data.expiresAt, now);
        await doc.ref.update({ remindedDays: due });
        await pushUser(driverId, 'docExpiringTitle', 'docExpiringBody', (lang) => ({
          doc: docName(type, lang),
          days: left,
        }));
        reminded++;
      }
    }
    logger.info('checkDocumentExpiry', 'done', { expired, reminded });
  },
);

// ---------------------------------------------------------------------------
// Support — supportTickets/{id} with messages/{messageId}. Clients write
// tickets and messages under the security rules; this trigger keeps the
// ticket summary up to date and notifies the other side.
// ---------------------------------------------------------------------------

export const onSupportMessageCreated = onDocumentCreated(
  'supportTickets/{ticketId}/messages/{messageId}',
  async (event) => {
    const msg = event.data?.data() as { authorRole?: AuthorRole; text?: string; createdAt?: admin.firestore.Timestamp } | undefined;
    if (!msg?.authorRole || typeof msg.text !== 'string') return;
    const ticketRef = db.collection('supportTickets').doc(event.params.ticketId);
    const ticket = (await ticketRef.get()).data() as
      | { userId: string; userName?: string; category?: TicketCategory }
      | undefined;
    if (!ticket) return;

    const text = preview(msg.text);
    const fromTeam = msg.authorRole === 'admin';
    await ticketRef.update({
      status: statusAfterMessage(msg.authorRole),
      lastMessageAt: msg.createdAt ?? admin.firestore.Timestamp.now(),
      lastMessagePreview: text,
      lastAuthorRole: msg.authorRole,
      unreadForUser: fromTeam,
      unreadForAdmin: !fromTeam,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    if (fromTeam) {
      await pushUser(ticket.userId, 'supportReplyTitle', 'supportReplyBody', { preview: text });
      return;
    }
    const urgent = ticket.category ? priorityFor(ticket.category) === 'urgent' : false;
    const admins = await db.collection('users').where('role', '==', 'admin').limit(20).get();
    await Promise.all(
      admins.docs.map((a) =>
        pushUser(a.id, urgent ? 'supportUrgentTitle' : 'supportNewTitle', 'supportNewBody', {
          name: ticket.userName || '—',
          preview: text,
        }),
      ),
    );
    logger.info('onSupportMessageCreated', 'notified', { ticketId: event.params.ticketId, fromTeam, urgent });
  },
);

// ---------------------------------------------------------------------------
// Observability — client errors (web has no Crashlytics) and an operations
// monitor that pages the team and keeps system/health up to date.
// ---------------------------------------------------------------------------

async function pushAdmins(
  titleKey: MessageKey,
  bodyKey: MessageKey,
  params: (lang: Lang) => Record<string, string | number>,
): Promise<void> {
  const admins = await db.collection('users').where('role', '==', 'admin').limit(20).get();
  await Promise.all(admins.docs.map((a) => pushUser(a.id, titleKey, bodyKey, params)));
}

/** Groups app errors by fingerprint in clientErrors/{fp}. */
export const reportClientError = onCall(async (req) => {
  const d = (req.data ?? {}) as Record<string, unknown>;
  if (!isPlatform(d.platform)) throw err.invalidArgument('invalid platform');
  const message = clip(d.message, MAX_MESSAGE);
  if (!message) throw err.invalidArgument('message required');
  const stack = clip(d.stack, MAX_STACK);
  const fp = fingerprint(d.platform, message, stack);
  const ref = db.collection('clientErrors').doc(fp);
  const now = admin.firestore.Timestamp.now();
  const common = {
    lastSeen: now,
    lastRoute: clip(d.route, 120) || null,
    lastAppVersion: clip(d.appVersion, 40) || null,
    lastUserId: req.auth?.uid ?? null,
    // A new occurrence of a resolved error reopens it (regression).
    resolved: false,
  };
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) {
      tx.update(ref, { ...common, count: admin.firestore.FieldValue.increment(1) });
    } else {
      tx.set(ref, {
        ...common,
        fingerprint: fp,
        platform: d.platform,
        message,
        normalized: normalizeMessage(message),
        stack,
        count: 1,
        firstSeen: now,
      });
    }
  });
  return { ok: true };
});

/** Every 5 minutes: unassigned bookings close to pickup, nobody online, health summary. */
export const opsWatch = onSchedule('every 5 minutes', async () => {
  const now = new Date();
  const in2h = admin.firestore.Timestamp.fromMillis(now.getTime() + 2 * 60 * 60 * 1000);
  const pendingSnap = await db
    .collection('bookings')
    .where('status', '==', 'pending')
    .where('scheduledAt', '<=', in2h)
    .get();

  const upcoming = pendingSnap.docs.filter((doc) => {
    const b = doc.data() as BookingDoc;
    const pickup = (b.pickupAt ?? b.scheduledAt)?.toDate();
    return !!pickup && pickup.getTime() > now.getTime();
  });

  // 1. Pending bookings within 30 min without a chauffeur → page once each.
  let unassignedSoon = 0;
  for (const doc of upcoming) {
    const b = doc.data() as BookingDoc & { alertedNoDriver?: boolean; origin?: { name?: string; address?: string } };
    const pickup = (b.pickupAt ?? b.scheduledAt)?.toDate() ?? null;
    if (!b.driverId && pickup && pickup.getTime() - now.getTime() <= 30 * 60 * 1000) unassignedSoon++;
    if (!needsNoDriverAlert({ status: b.status, driverId: b.driverId, pickup, alertedNoDriver: b.alertedNoDriver }, now)) {
      continue;
    }
    await doc.ref.update({ alertedNoDriver: true });
    await pushAdmins('opsNoDriverTitle', 'opsNoDriverBody', (lang) => ({
      time: clock(pickup!, lang),
      place: b.origin?.name || b.origin?.address || '—',
    }));
  }

  // 2. Bookings coming up and nobody online → page, at most hourly.
  const online = await db
    .collection('driverProfiles')
    .where('isAvailable', '==', true)
    .where('documentsVerified', '==', true)
    .count()
    .get();
  const onlineDrivers = online.data().count;
  const alertsRef = db.collection('system').doc('alerts');
  if (upcoming.length > 0 && onlineDrivers === 0) {
    const last = ((await alertsRef.get()).data()?.noDriversOnlineAt as admin.firestore.Timestamp | undefined)?.toDate();
    if (!throttled(last, now, NO_DRIVERS_ONLINE_THROTTLE_MS)) {
      await alertsRef.set({ noDriversOnlineAt: admin.firestore.Timestamp.fromDate(now) }, { merge: true });
      await pushAdmins('opsNoDriversOnlineTitle', 'opsNoDriversOnlineBody', () => ({ count: upcoming.length }));
    }
  }

  // 3. Urgent (safety) tickets unanswered for 10 min → page again, once per message.
  const urgent = await db.collection('supportTickets').where('status', '==', 'open').where('priority', '==', 'urgent').get();
  for (const doc of urgent.docs) {
    const tk = doc.data();
    const lastMessageAt = (tk.lastMessageAt as admin.firestore.Timestamp | undefined)?.toDate() ?? null;
    const state = {
      status: tk.status as string,
      priority: tk.priority as string,
      lastAuthorRole: tk.lastAuthorRole as string | undefined,
      lastMessageAt,
      escalatedAt: (tk.escalatedAt as admin.firestore.Timestamp | undefined)?.toDate() ?? null,
    };
    if (!needsEscalation(state, now)) continue;
    await doc.ref.update({ escalatedAt: admin.firestore.Timestamp.fromDate(now) });
    await pushAdmins('supportEscalationTitle', 'supportEscalationBody', () => ({
      name: (tk.userName as string) || '—',
      minutes: Math.floor((now.getTime() - lastMessageAt!.getTime()) / 60000),
    }));
  }

  // 4. Health summary for the admin panel.
  const [errors] = await Promise.all([
    db
      .collection('clientErrors')
      .where('lastSeen', '>=', admin.firestore.Timestamp.fromMillis(now.getTime() - 24 * 60 * 60 * 1000))
      .count()
      .get(),
  ]);
  await db.collection('system').doc('health').set({
    checkedAt: admin.firestore.Timestamp.fromDate(now),
    pendingNext2h: upcoming.length,
    unassignedSoon,
    onlineDrivers,
    urgentTickets: urgent.size,
    clientErrors24h: errors.data().count,
  });
  logger.info('opsWatch', 'checked', { pending: upcoming.length, unassignedSoon, onlineDrivers });
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
