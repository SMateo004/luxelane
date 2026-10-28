/**
 * Claves de pagos en config/ops (A2, A3, A7). Todas las decide el
 * responsable; aquí solo se validan con zod. Si una falta o no es válida, el
 * sistema se comporta de la forma más restrictiva:
 *
 * - paymentMethods: qué métodos se ofrecen. Sin ella, ninguno (nada se
 *   puede pagar y nada se ofrece a los chóferes).
 * - paymentInstructions: datos de cobro de cada método (titular, cuenta,
 *   QR…) y el proveedor de tarjeta. Sin los del método manual, el método
 *   manual no se ofrece aunque esté activado.
 * - paymentWindowMinutes: plazo para pagar. Sin él no hay vencimiento
 *   automático (central ve las reservas en la bandeja de impagos).
 * - cancellationPolicy: etapas de retención. Sin ella, 0 % en todo.
 */
import * as admin from 'firebase-admin';
import { z } from 'zod';
import { opsConfig } from './ops_config';
import type { PaymentMethod } from './payment_model';

export const paymentMethodsSchema = z.strictObject({
  manual_qr: z.boolean().optional(),
  card: z.boolean().optional(),
});

const text = (max: number) => z.string().trim().min(1).max(max);

export const manualInstructionsSchema = z.strictObject({
  holderName: text(120),
  bankName: text(120).optional(),
  accountType: text(60).optional(),
  accountNumber: text(60).optional(),
  /** Imagen del QR de cobro (https). */
  qrImageUrl: z.string().trim().url().max(500).refine((u) => u.startsWith('https://')).optional(),
  /** Texto adicional que se muestra tal cual. */
  note: text(1000).optional(),
}).refine((m) => m.accountNumber !== undefined || m.qrImageUrl !== undefined,
  { message: 'falta accountNumber o qrImageUrl' });
export type ManualInstructions = z.infer<typeof manualInstructionsSchema>;

/** Proveedores de tarjeta con código: elegir otro exige integrarlo antes. */
export const CARD_PROVIDERS = ['stripe'] as const;

export const paymentInstructionsSchema = z.strictObject({
  manual_qr: manualInstructionsSchema.optional(),
  card: z.strictObject({ provider: z.enum(CARD_PROVIDERS) }).optional(),
});

export const paymentWindowSchema = z.number().int().min(1).max(7 * 24 * 60);

export interface PaymentSettings {
  /** Métodos que se pueden usar ahora (activados y con sus datos). */
  enabled: PaymentMethod[];
  manual: ManualInstructions | null;
  cardProvider: (typeof CARD_PROVIDERS)[number] | null;
  windowMinutes: number | null;
  /** Claves presentes pero no válidas (para el log y la alerta). */
  invalid: string[];
}

/** Lee y valida las claves de pagos de config/ops (función pura). */
export function readPaymentSettings(ops: Record<string, unknown>): PaymentSettings {
  const invalid: string[] = [];
  const parse = <T>(key: string, schema: z.ZodType<T>): T | null => {
    if (ops[key] === undefined || ops[key] === null) return null;
    const r = schema.safeParse(ops[key]);
    if (!r.success) invalid.push(key);
    return r.success ? r.data : null;
  };
  const methods = parse('paymentMethods', paymentMethodsSchema) ?? {};
  const instructions = parse('paymentInstructions', paymentInstructionsSchema) ?? {};
  const windowMinutes = parse('paymentWindowMinutes', paymentWindowSchema);
  const manual = instructions.manual_qr ?? null;
  const cardProvider = instructions.card?.provider ?? null;
  const enabled: PaymentMethod[] = [];
  if (methods.manual_qr === true && manual) enabled.push('manual_qr');
  if (methods.card === true && cardProvider) enabled.push('card');
  return { enabled, manual, cardProvider, windowMinutes, invalid };
}

/** config/ops leído por el servidor y validado. */
export async function loadPaymentSettings(db: admin.firestore.Firestore): Promise<PaymentSettings> {
  return readPaymentSettings(await opsConfig(db));
}
