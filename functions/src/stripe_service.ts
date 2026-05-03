import Stripe from 'stripe';
import { logger } from './logger';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY ?? '', {
  apiVersion: '2024-06-20',
});

const FN = 'StripeService';

export async function createIntent(params: {
  amount: number;
  currency: string;
  customerId: string;
}): Promise<string> {
  logger.info(FN, 'createIntent', { amount: params.amount, currency: params.currency });

  const intent = await stripe.paymentIntents.create({
    amount: params.amount,
    currency: params.currency,
    customer: params.customerId,
    capture_method: 'manual',
    automatic_payment_methods: { enabled: true },
  });

  logger.info(FN, 'createIntent.success', { intentId: intent.id });
  return intent.client_secret!;
}

export async function captureIntent(paymentIntentId: string): Promise<Stripe.PaymentIntent> {
  logger.info(FN, 'captureIntent', { paymentIntentId });

  const intent = await stripe.paymentIntents.capture(paymentIntentId);

  logger.info(FN, 'captureIntent.success', { status: intent.status });
  return intent;
}

export async function refundIntent(paymentIntentId: string): Promise<Stripe.Refund> {
  logger.info(FN, 'refundIntent', { paymentIntentId });

  const refund = await stripe.refunds.create({ payment_intent: paymentIntentId });

  logger.info(FN, 'refundIntent.success', { refundId: refund.id, status: refund.status });
  return refund;
}

export async function listPaymentMethods(customerId: string): Promise<Stripe.PaymentMethod[]> {
  const methods = await stripe.paymentMethods.list({ customer: customerId, type: 'card' });
  return methods.data;
}

export async function attachPaymentMethod(
  customerId: string,
  paymentMethodId: string,
): Promise<void> {
  await stripe.paymentMethods.attach(paymentMethodId, { customer: customerId });
}

export async function detachPaymentMethod(paymentMethodId: string): Promise<void> {
  await stripe.paymentMethods.detach(paymentMethodId);
}

export async function createCustomer(email: string, name: string): Promise<string> {
  const customer = await stripe.customers.create({ email, name });
  return customer.id;
}
