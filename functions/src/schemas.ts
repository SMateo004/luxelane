/**
 * Esquemas de entrada de las callables que no tienen el suyo en su módulo
 * (booking_schema.ts, trip_flow.ts, incidents.ts, alerts.ts). Todos
 * estrictos: un campo desconocido se rechaza (invalid_request).
 */
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';

/** ID de documento de Firestore (los nuestros: automáticos o hex). */
export const docId = z.string().regex(/^[A-Za-z0-9_-]{1,128}$/);

/** ID de Stripe con su prefijo (pi_, pm_, cus_…). */
export const stripeId = (prefix: string) => z.string().regex(new RegExp(`^${prefix}_[A-Za-z0-9_]{1,255}$`));

/** Callables sin datos: la app manda null o {}. */
export const noInput = z.union([z.undefined(), z.null(), z.strictObject({})]);

export const callableSchemas = {
  createPaymentIntent: z.strictObject({
    bookingId: docId,
    paymentMethodId: stripeId('pm').nullable().optional(),
  }),
  capturePayment: z.strictObject({ bookingId: docId, stripePaymentIntentId: stripeId('pi') }),
  refundPayment: z.strictObject({ paymentId: docId, reason: z.string().trim().max(500).optional() }),
  listPaymentMethods: z.strictObject({ customerId: stripeId('cus') }),
  setDefaultPaymentMethod: z.strictObject({ paymentMethodId: stripeId('pm') }),
  attachPaymentMethod: z.strictObject({ customerId: stripeId('cus'), paymentMethodId: stripeId('pm') }),
  detachPaymentMethod: z.strictObject({ paymentMethodId: stripeId('pm') }),
  deleteAccount: noInput,
  ensureStripeCustomer: noInput,
  backfillSettlements: noInput,
  syncEmailVerification: noInput,
  assignNearestDriver: z.strictObject({ bookingId: docId }),
  acceptBooking: z.strictObject({ bookingId: docId }),
} as const;

export function parseInput<T>(schema: z.ZodType<T>, data: unknown): T {
  const r = schema.safeParse(data);
  if (!r.success) {
    const fields = [...new Set(r.error.issues.map((i) => i.path.join('.') || '(raíz)'))];
    throw new HttpsError('invalid-argument', 'invalid_request', { reason: 'invalid_request', fields });
  }
  return r.data;
}
