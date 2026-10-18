import Stripe from 'stripe';
import { defineSecret } from 'firebase-functions/params';
import { logger } from './logger';

// Set with: firebase functions:secrets:set STRIPE_SECRET_KEY
// Every function that touches Stripe must list it in `secrets`.
export const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');

/**
 * Card payments are off until a real Stripe key is set (sk_live_… or
 * sk_test_…); the secret only has to exist to deploy. While off, no user
 * data is sent to Stripe.
 */
export function stripeEnabled(): boolean {
  return isStripeKey(STRIPE_SECRET_KEY.value());
}

export function isStripeKey(key: string | undefined): boolean {
  return /^sk_(live|test)_/.test((key ?? '').trim());
}

let client: Stripe | undefined;

function stripeClient(): Stripe {
  if (!client) {
    const key = STRIPE_SECRET_KEY.value();
    if (!key) throw new Error('STRIPE_SECRET_KEY is not configured');
    client = new Stripe(key, { apiVersion: '2024-06-20' });
  }
  return client;
}

const FN = 'StripeService';

export async function createIntent(params: {
  amount: number;
  currency: string;
  customerId: string;
  metadata?: Record<string, string>;
}): Promise<string> {
  logger.info(FN, 'createIntent', { amount: params.amount, currency: params.currency });

  const intent = await stripeClient().paymentIntents.create({
    amount: params.amount,
    currency: params.currency,
    customer: params.customerId,
    capture_method: 'manual',
    automatic_payment_methods: { enabled: true },
    metadata: params.metadata,
  });

  logger.info(FN, 'createIntent.success', { intentId: intent.id });
  return intent.client_secret!;
}

/**
 * Authorises, without the rider present, the card they saved, to capture it
 * right away with captureIntent (bookings more than 6 days ahead, beyond the
 * 7 days Stripe keeps an authorisation).
 */
export async function chargeOffSession(params: {
  amount: number;
  currency: string;
  customerId: string;
  paymentMethodId: string;
  metadata?: Record<string, string>;
}): Promise<string> {
  const intent = await stripeClient().paymentIntents.create({
    amount: params.amount,
    currency: params.currency,
    customer: params.customerId,
    payment_method: params.paymentMethodId,
    capture_method: 'manual',
    off_session: true,
    confirm: true,
    metadata: params.metadata,
  });
  logger.info(FN, 'chargeOffSession', { intentId: intent.id, status: intent.status });
  return intent.id;
}

export async function retrieveIntent(paymentIntentId: string): Promise<Stripe.PaymentIntent> {
  return stripeClient().paymentIntents.retrieve(paymentIntentId);
}

export async function captureIntent(
  paymentIntentId: string,
  amountToCapture?: number,
): Promise<Stripe.PaymentIntent> {
  logger.info(FN, 'captureIntent', { paymentIntentId, amountToCapture });

  // Never ask for more than was authorised: Stripe would reject the capture.
  let params: Stripe.PaymentIntentCaptureParams | undefined;
  if (amountToCapture) {
    const authorized = await stripeClient().paymentIntents.retrieve(paymentIntentId);
    params = { amount_to_capture: Math.min(amountToCapture, authorized.amount_capturable) };
  }
  const intent = await stripeClient().paymentIntents.capture(paymentIntentId, params);

  logger.info(FN, 'captureIntent.success', { status: intent.status });
  return intent;
}

/** Releases an authorisation that won't be charged (cancelled booking). */
export async function cancelIntent(paymentIntentId: string): Promise<void> {
  logger.info(FN, 'cancelIntent', { paymentIntentId });
  const intent = await stripeClient().paymentIntents.retrieve(paymentIntentId);
  if (intent.status === 'requires_capture' || intent.status === 'requires_payment_method' ||
      intent.status === 'requires_confirmation' || intent.status === 'requires_action') {
    await stripeClient().paymentIntents.cancel(paymentIntentId);
  }
}

export async function refundIntent(paymentIntentId: string): Promise<Stripe.Refund> {
  logger.info(FN, 'refundIntent', { paymentIntentId });

  const refund = await stripeClient().refunds.create({ payment_intent: paymentIntentId });

  logger.info(FN, 'refundIntent.success', { refundId: refund.id, status: refund.status });
  return refund;
}

export async function listPaymentMethods(customerId: string): Promise<Stripe.PaymentMethod[]> {
  const methods = await stripeClient().paymentMethods.list({ customer: customerId, type: 'card' });
  return methods.data;
}

/** The customer's default card (the one proposed when booking). */
export async function defaultPaymentMethod(customerId: string): Promise<string | null> {
  const customer = await stripeClient().customers.retrieve(customerId);
  if (customer.deleted) return null;
  const pm = customer.invoice_settings?.default_payment_method;
  return typeof pm === 'string' ? pm : pm?.id ?? null;
}

export async function setDefaultPaymentMethod(customerId: string, paymentMethodId: string): Promise<void> {
  await stripeClient().customers.update(customerId, {
    invoice_settings: { default_payment_method: paymentMethodId },
  });
}

export async function attachPaymentMethod(
  customerId: string,
  paymentMethodId: string,
): Promise<void> {
  await stripeClient().paymentMethods.attach(paymentMethodId, { customer: customerId });
}

export async function retrievePaymentMethod(paymentMethodId: string): Promise<Stripe.PaymentMethod> {
  return stripeClient().paymentMethods.retrieve(paymentMethodId);
}

/** Stripe customer the card belongs to, or null if none. */
export async function paymentMethodCustomer(paymentMethodId: string): Promise<string | null> {
  const pm = await stripeClient().paymentMethods.retrieve(paymentMethodId);
  return typeof pm.customer === 'string' ? pm.customer : pm.customer?.id ?? null;
}

export async function detachPaymentMethod(paymentMethodId: string): Promise<void> {
  await stripeClient().paymentMethods.detach(paymentMethodId);
}

/** Deletes the customer and, with it, their saved cards (account deleted). */
export async function deleteCustomer(customerId: string): Promise<void> {
  await stripeClient().customers.del(customerId);
}

export async function createCustomer(email: string, name: string): Promise<string> {
  const customer = await stripeClient().customers.create({ email, name });
  return customer.id;
}
