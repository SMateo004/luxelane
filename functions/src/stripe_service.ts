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
  bookingId: string;
}): Promise<{ id: string; clientSecret: string }> {
  logger.info(FN, 'createIntent', { amount: params.amount, currency: params.currency });

  const intent = await stripe.paymentIntents.create({
    amount: params.amount,
    currency: params.currency,
    customer: params.customerId,
    capture_method: 'manual',
    automatic_payment_methods: { enabled: true },
    metadata: { bookingId: params.bookingId },
  });

  logger.info(FN, 'createIntent.success', { intentId: intent.id });
  return { id: intent.id, clientSecret: intent.client_secret! };
}

/**
 * Autoriza sin el pasajero presente la tarjeta que guardó, para cobrarla
 * enseguida con captureIntent (reservas de más de 6 días de antelación).
 */
export async function chargeOffSession(params: {
  amount: number;
  currency: string;
  customerId: string;
  paymentMethodId: string;
  bookingId: string;
}): Promise<string> {
  const intent = await stripe.paymentIntents.create({
    amount: params.amount,
    currency: params.currency,
    customer: params.customerId,
    payment_method: params.paymentMethodId,
    capture_method: 'manual',
    off_session: true,
    confirm: true,
    metadata: { bookingId: params.bookingId },
  });
  logger.info(FN, 'chargeOffSession', { intentId: intent.id, status: intent.status });
  return intent.id;
}

/** Libera una autorización que no se va a cobrar (reserva cancelada). */
export async function cancelIntent(paymentIntentId: string): Promise<void> {
  const intent = await stripe.paymentIntents.retrieve(paymentIntentId);
  if (intent.status === 'requires_capture' || intent.status === 'requires_payment_method' ||
      intent.status === 'requires_confirmation' || intent.status === 'requires_action') {
    await stripe.paymentIntents.cancel(paymentIntentId);
  }
}

/**
 * Captura un PaymentIntent autorizado. Con [amountToCapture] (centavos) cobra
 * ese importe, sin pasar de lo autorizado; sin él, todo lo autorizado.
 */
export async function captureIntent(
  paymentIntentId: string,
  amountToCapture?: number,
): Promise<Stripe.PaymentIntent> {
  logger.info(FN, 'captureIntent', { paymentIntentId, amountToCapture });

  let params: Stripe.PaymentIntentCaptureParams | undefined;
  if (amountToCapture !== undefined) {
    const authorized = await stripe.paymentIntents.retrieve(paymentIntentId);
    params = { amount_to_capture: Math.min(amountToCapture, authorized.amount_capturable) };
  }
  const intent = await stripe.paymentIntents.capture(paymentIntentId, params);

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

/** Cliente de Stripe al que pertenece la tarjeta, o null si no tiene. */
export async function paymentMethodCustomer(paymentMethodId: string): Promise<string | null> {
  const pm = await stripe.paymentMethods.retrieve(paymentMethodId);
  return typeof pm.customer === 'string' ? pm.customer : pm.customer?.id ?? null;
}

export async function detachPaymentMethod(paymentMethodId: string): Promise<void> {
  await stripe.paymentMethods.detach(paymentMethodId);
}

export async function createCustomer(email: string, name: string): Promise<string> {
  const customer = await stripe.customers.create({ email, name });
  return customer.id;
}
