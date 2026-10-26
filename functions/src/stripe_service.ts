import Stripe from 'stripe';
import { defineSecret } from 'firebase-functions/params';
import { logger } from './logger';

/**
 * Clave secreta de Stripe en Secret Manager. Toda función que use este
 * módulo debe declararla en `secrets` para que esté disponible.
 */
export const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');

/** Clave leída en ejecución; falla con un error claro si falta. */
export function requireStripeKey(value: string | undefined): string {
  const key = value?.trim();
  if (!key) {
    throw new Error(
      'STRIPE_SECRET_KEY no está configurada: créala con ' +
        '`firebase functions:secrets:set STRIPE_SECRET_KEY` y declárala en ' +
        'los `secrets` de la función.',
    );
  }
  return key;
}

let client: Stripe | undefined;

// Se crea en la primera llamada: el secreto solo existe en ejecución.
function stripeClient(): Stripe {
  client ??= new Stripe(requireStripeKey(STRIPE_SECRET_KEY.value()), {
    apiVersion: '2024-06-20',
  });
  return client;
}

const FN = 'StripeService';

export async function createIntent(params: {
  amount: number;
  currency: string;
  customerId: string;
  bookingId: string;
}): Promise<{ id: string; clientSecret: string }> {
  logger.info(FN, 'createIntent', { amount: params.amount, currency: params.currency });

  const intent = await stripeClient().paymentIntents.create({
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
  const intent = await stripeClient().paymentIntents.create({
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
  const intent = await stripeClient().paymentIntents.retrieve(paymentIntentId);
  if (intent.status === 'requires_capture' || intent.status === 'requires_payment_method' ||
      intent.status === 'requires_confirmation' || intent.status === 'requires_action') {
    await stripeClient().paymentIntents.cancel(paymentIntentId);
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
    const authorized = await stripeClient().paymentIntents.retrieve(paymentIntentId);
    params = { amount_to_capture: Math.min(amountToCapture, authorized.amount_capturable) };
  }
  const intent = await stripeClient().paymentIntents.capture(paymentIntentId, params);

  logger.info(FN, 'captureIntent.success', { status: intent.status });
  return intent;
}

/**
 * Cobro inmediato al pedir chófer (A5): captura automática, sin retención
 * posterior. La clave de idempotencia evita un segundo cargo si se repite.
 */
export async function createCharge(params: {
  amount: number;
  currency: string;
  bookingId: string;
  paymentRef: string;
  idempotencyKey: string;
}): Promise<{ id: string; clientSecret: string }> {
  const intent = await stripeClient().paymentIntents.create({
    amount: params.amount,
    currency: params.currency,
    capture_method: 'automatic',
    automatic_payment_methods: { enabled: true },
    metadata: { bookingId: params.bookingId, paymentRef: params.paymentRef },
  }, { idempotencyKey: params.idempotencyKey });
  logger.info(FN, 'createCharge', { intentId: intent.id });
  return { id: intent.id, clientSecret: intent.client_secret! };
}

/** Reembolso de una parte (céntimos), con clave de idempotencia (A8). */
export async function refundAmount(paymentIntentId: string, amount: number,
  idempotencyKey: string): Promise<Stripe.Refund> {
  const refund = await stripeClient().refunds.create({ payment_intent: paymentIntentId, amount }, { idempotencyKey });
  logger.info(FN, 'refundAmount', { refundId: refund.id, status: refund.status });
  return refund;
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

/** Tarjeta predeterminada del cliente (la que se propone al reservar). */
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

/** Cliente de Stripe al que pertenece la tarjeta, o null si no tiene. */
export async function paymentMethodCustomer(paymentMethodId: string): Promise<string | null> {
  const pm = await stripeClient().paymentMethods.retrieve(paymentMethodId);
  return typeof pm.customer === 'string' ? pm.customer : pm.customer?.id ?? null;
}

export async function detachPaymentMethod(paymentMethodId: string): Promise<void> {
  await stripeClient().paymentMethods.detach(paymentMethodId);
}

/** Borra el cliente y, con él, sus tarjetas guardadas (cuenta eliminada). */
export async function deleteCustomer(customerId: string): Promise<void> {
  await stripeClient().customers.del(customerId);
}

export async function createCustomer(email: string, name: string): Promise<string> {
  const customer = await stripeClient().customers.create({ email, name });
  return customer.id;
}
