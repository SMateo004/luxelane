/**
 * Interfaz de proveedor de pago en el servidor (A2). Dos implementaciones:
 *
 * - manual_qr: QR o transferencia; el pasajero paga fuera y un admin lo
 *   confirma (adminConfirmPayment). El reembolso también es manual
 *   (adminRecordRefund).
 * - stripe: el código de Stripe de antes detrás de la interfaz. Desactivado
 *   mientras config/ops.paymentMethods.card no sea true y
 *   paymentInstructions.card.provider no sea 'stripe'.
 *
 * El proveedor de tarjeta definitivo no está decidido: el webhook se
 * verifica a través de la interfaz (verifyWebhook) y los tests usan un
 * proveedor simulado. Stripe no tiene secreto de webhook configurado, así
 * que el suyo rechaza todo.
 */
import { HttpsError } from 'firebase-functions/v2/https';
import type { ManualInstructions, PaymentSettings } from './payment_config';
import type { PaymentMethod } from './payment_model';
import * as stripe from './stripe_service';

export interface ChargeRequest {
  bookingId: string;
  riderId: string;
  /** Céntimos, del servidor. */
  amount: number;
  currency: string;
  paymentRef: string;
  /** El mismo intento, la misma clave: el proveedor no cobra dos veces. */
  idempotencyKey: string;
}

export type ChargeStart =
  | { kind: 'manual'; instructions: ManualInstructions }
  | { kind: 'client_secret'; clientSecret: string; externalRef: string };

/** Confirmación de un cobro: del admin (manual) o del webhook (tarjeta). */
export interface ConfirmInput {
  /** Lo que el admin dice que llegó, o lo que el proveedor cobró (céntimos). */
  amountReceived: number;
  amountDue: number;
  externalRef: string;
}

export interface RefundRequest {
  bookingId: string;
  amount: number;
  currency: string;
  /** Referencia del cobro en el proveedor (null en el manual). */
  chargeRef: string | null;
  idempotencyKey: string;
}

export type RefundResult = { status: 'pending_manual' } | { status: 'succeeded'; externalRef: string };

export interface WebhookEvent {
  type: 'charge.succeeded' | 'charge.failed';
  bookingId: string;
  amount: number;
  externalRef: string;
}

export interface PaymentProvider {
  readonly method: PaymentMethod;
  createCharge(req: ChargeRequest): Promise<ChargeStart>;
  /** Valida la confirmación; lanza amount_mismatch si el importe no es el debido. */
  confirm(input: ConfirmInput): { amount: number; externalRef: string };
  refund(req: RefundRequest): Promise<RefundResult>;
  /** Solo tarjeta: verifica la firma y traduce el evento; lanza si no es válido. */
  verifyWebhook?(rawBody: Buffer, signature: string | undefined): WebhookEvent;
}

const reject = (reason: string, code: 'failed-precondition' | 'invalid-argument' = 'failed-precondition') =>
  new HttpsError(code, reason, { reason });

/** El importe confirmado debe ser exactamente el debido (céntimos). */
function exactAmount(input: ConfirmInput): { amount: number; externalRef: string } {
  if (input.amountReceived !== input.amountDue) throw reject('amount_mismatch');
  return { amount: input.amountReceived, externalRef: input.externalRef };
}

export function manualProvider(instructions: ManualInstructions): PaymentProvider {
  return {
    method: 'manual_qr',
    createCharge: async () => ({ kind: 'manual', instructions }),
    confirm: exactAmount,
    // El dinero lo devuelve central fuera del sistema y lo anota con
    // adminRecordRefund.
    refund: async () => ({ status: 'pending_manual' }),
  };
}

export function stripeProvider(): PaymentProvider {
  return {
    method: 'card',
    async createCharge(req) {
      const { id, clientSecret } = await stripe.createCharge(req);
      return { kind: 'client_secret', clientSecret, externalRef: id };
    },
    confirm: exactAmount,
    async refund(req) {
      if (!req.chargeRef) throw reject('charge_ref_missing');
      const r = await stripe.refundAmount(req.chargeRef, req.amount, req.idempotencyKey);
      return { status: 'succeeded', externalRef: r.id };
    },
    verifyWebhook() {
      // Sin secreto de webhook configurado (proveedor por decidir).
      throw reject('webhook_not_configured');
    },
  };
}

/** Proveedores sustituibles en los tests (un simulado en lugar de Stripe). */
export type ProviderOverrides = Partial<Record<PaymentMethod, PaymentProvider>>;

/**
 * Proveedor del método, solo si está activado y con sus datos; si no,
 * method_disabled (un método desactivado se rechaza).
 */
export function providerFor(method: PaymentMethod, settings: PaymentSettings,
  overrides: ProviderOverrides = {}): PaymentProvider {
  if (!settings.enabled.includes(method)) throw reject('method_disabled');
  if (overrides[method]) return overrides[method]!;
  if (method === 'manual_qr') return manualProvider(settings.manual!);
  if (settings.cardProvider === 'stripe') return stripeProvider();
  throw reject('method_disabled');
}
