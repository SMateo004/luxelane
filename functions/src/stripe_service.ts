import Stripe from 'stripe';
import { defineSecret } from 'firebase-functions/params';
import { logger } from './logger';

// Set with: firebase functions:secrets:set STRIPE_SECRET_KEY
// Every function that touches Stripe must list it in `secrets`.
export const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');

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

export async function retrieveIntent(paymentIntentId: string): Promise<Stripe.PaymentIntent> {
  return stripeClient().paymentIntents.retrieve(paymentIntentId);
}

export async function captureIntent(
  paymentIntentId: string,
  amountToCapture?: number,
): Promise<Stripe.PaymentIntent> {
  logger.info(FN, 'captureIntent', { paymentIntentId, amountToCapture });

  const intent = await stripeClient().paymentIntents.capture(
    paymentIntentId,
    amountToCapture ? { amount_to_capture: amountToCapture } : undefined,
  );

  logger.info(FN, 'captureIntent.success', { status: intent.status });
  return intent;
}

export async function cancelIntent(paymentIntentId: string): Promise<Stripe.PaymentIntent> {
  logger.info(FN, 'cancelIntent', { paymentIntentId });
  return stripeClient().paymentIntents.cancel(paymentIntentId);
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

export async function attachPaymentMethod(
  customerId: string,
  paymentMethodId: string,
): Promise<void> {
  await stripeClient().paymentMethods.attach(paymentMethodId, { customer: customerId });
}

export async function retrievePaymentMethod(paymentMethodId: string): Promise<Stripe.PaymentMethod> {
  return stripeClient().paymentMethods.retrieve(paymentMethodId);
}

export async function detachPaymentMethod(paymentMethodId: string): Promise<void> {
  await stripeClient().paymentMethods.detach(paymentMethodId);
}

export async function createCustomer(email: string, name: string): Promise<string> {
  const customer = await stripeClient().customers.create({ email, name });
  return customer.id;
}
