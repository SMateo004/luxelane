// Reglas del cobro con tarjeta de una reserva (funciones puras).
//
// Flujo: la app autoriza una retención (PaymentIntent de captura manual) por
// el precio estimado, crea la reserva y pide al servidor vincularlas. Al
// completar el viaje el servidor captura el importe final; al cancelar,
// libera la retención. El cliente nunca decide importes ni clientes Stripe.

import { toCents } from './money';

/** Importe máximo de una retención: Bs 100 000. */
export const MAX_INTENT_CENTS = 10_000_000;
/** Importe mínimo que acepta Stripe (Bs 1). */
export const MIN_INTENT_CENTS = 100;

export function validIntentAmount(cents: unknown): cents is number {
  return (
    typeof cents === 'number' &&
    Number.isInteger(cents) &&
    cents >= MIN_INTENT_CENTS &&
    cents <= MAX_INTENT_CENTS
  );
}

export type LinkRejection =
  | 'not_owner'
  | 'already_linked'
  | 'booking_closed'
  | 'intent_not_owned'
  | 'intent_not_authorized'
  | 'amount_too_low';

/** Motivo por el que una retención no puede vincularse a la reserva, o null. */
export function linkRejection(
  uid: string,
  booking: { riderId: string; status: string; estimatedPrice: number; paymentIntentId?: string | null },
  intent: { status: string; amount: number; metadata?: Record<string, string> | null },
): LinkRejection | null {
  if (booking.riderId !== uid) return 'not_owner';
  if (booking.paymentIntentId) return 'already_linked';
  if (booking.status === 'cancelled' || booking.status === 'completed') return 'booking_closed';
  if (intent.metadata?.uid !== uid) return 'intent_not_owned';
  if (intent.status !== 'requires_capture') return 'intent_not_authorized';
  if (intent.amount < toCents(booking.estimatedPrice)) return 'amount_too_low';
  return null;
}

/** Qué hacer con la retención cuando cambia el estado de la reserva. */
export function paymentAction(
  after: { status: string; paymentIntentId?: string | null; paymentStatus?: string | null },
): 'capture' | 'release' | null {
  if (!after.paymentIntentId || after.paymentStatus !== 'authorized') return null;
  if (after.status === 'completed') return 'capture';
  if (after.status === 'cancelled') return 'release';
  return null;
}
