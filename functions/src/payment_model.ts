/**
 * Modelo de pagos (A1). El pago es requisito para pedir chófer: una reserva
 * existe desde createBooking, pero no se ofrece a ningún chófer hasta que su
 * pago esté confirmado (decisión 1).
 *
 * Dónde vive cada cosa:
 * - bookings/{id}/payment/state: estado del pago de la reserva. Solo lo
 *   escribe el servidor; lo leen el pasajero dueño y el admin. NO va en la
 *   reserva porque el chófer asignado lee la reserva entera y no debe ver
 *   nada de pagos (ni importes ni retenciones).
 * - payments/{id}: asientos (charge, refund, fee_retained). Solo el
 *   servidor; los lee el pasajero dueño y el admin.
 * - paymentRefs/{ref} y paymentOperations/{clave}: unicidad de la
 *   referencia del pago y del número de operación. Nadie los lee.
 *
 * Todos los importes del servidor en céntimos enteros (unidad mínima de la
 * moneda); nunca vienen del cliente.
 */
import { randomInt } from 'crypto';
import * as admin from 'firebase-admin';

export const PAYMENT_STATUSES = [
  'awaiting_payment', 'paid', 'refund_pending', 'refunded', 'partially_refunded', 'failed', 'expired',
] as const;
export type PaymentStatus = (typeof PAYMENT_STATUSES)[number];

export const PAYMENT_METHODS = ['manual_qr', 'card'] as const;
export type PaymentMethod = (typeof PAYMENT_METHODS)[number];

export const LEDGER_TYPES = ['charge', 'refund', 'fee_retained'] as const;
export type LedgerType = (typeof LEDGER_TYPES)[number];

/** Moneda de todos los importes (la de las tarifas). */
export const CURRENCY = 'bob';

export interface PaymentState {
  bookingId: string;
  riderId: string;
  paymentStatus: PaymentStatus;
  paymentMethod: PaymentMethod | null;
  /** Lo que se debe pagar, en céntimos (de la reserva, calculado por el servidor). */
  amountDue: number;
  /** Lo cobrado, en céntimos. */
  amountPaid: number;
  /** Referencia corta y sin ambigüedad que el pasajero pone en el pago. */
  paymentRef: string;
  paidAt: admin.firestore.Timestamp | null;
  /** null: sin vencimiento automático (config/ops.paymentWindowMinutes no está). */
  paymentDeadline: admin.firestore.Timestamp | null;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  /** Retenido por cancelación y lo que queda por devolver, en céntimos. */
  amountRetained?: number;
  amountRefunded?: number;
  refundDue?: number;
  /** Diferencia del importe final (A9), en céntimos: lo que debe el pasajero. */
  balanceDue?: number;
  /** Métodos que se ofrecieron al crear la reserva. */
  methodsOffered?: PaymentMethod[];
  /** «Ya pagué» del pasajero (A4). */
  riderReportedAt?: admin.firestore.Timestamp | null;
  riderOperationNumber?: string | null;
}

export interface LedgerEntry {
  type: LedgerType;
  bookingId: string;
  riderId: string;
  /** Céntimos enteros, siempre positivos; el tipo dice el sentido. */
  amount: number;
  currency: string;
  method: PaymentMethod | null;
  /** Rol del actor; el uid del admin va a la auditoría (el pasajero lee esto). */
  actor: { role: 'rider' | 'admin' | 'system' | 'provider' };
  /** Referencia externa: número de operación, id del proveedor… */
  externalRef: string | null;
  reason: string;
  /** pending: aún por ejecutar (reembolso manual, saldo por cobrar). */
  status: 'completed' | 'pending';
  createdAt: admin.firestore.Timestamp;
}

export const paymentStateRef = (db: admin.firestore.Firestore, bookingId: string) =>
  db.collection('bookings').doc(bookingId).collection('payment').doc('state');

export const paymentRefDoc = (db: admin.firestore.Firestore, ref: string) =>
  db.collection('paymentRefs').doc(ref);

// Sin 0/O, 1/I/L ni U/V: se dicta y se copia sin confundirse.
export const REF_ALPHABET = '23456789ABCDEFGHJKMNPQRSTWXYZ';
export const REF_LENGTH = 8;

/** Referencia nueva (al azar; la unicidad la asegura paymentRefs). */
export function newPaymentRef(rand: (max: number) => number = randomInt): string {
  let out = '';
  for (let i = 0; i < REF_LENGTH; i++) out += REF_ALPHABET[rand(REF_ALPHABET.length)];
  return out;
}

export const isPaymentRef = (v: string): boolean =>
  v.length === REF_LENGTH && [...v].every((c) => REF_ALPHABET.includes(c));

/** Céntimos enteros desde bolivianos (los de las tarifas tienen dos decimales). */
export const cents = (bs: number): number => Math.round(Number(bs) * 100);

/** Asiento nuevo dentro de la transacción; el id se puede fijar para la idempotencia. */
export function addLedger(tx: admin.firestore.Transaction, db: admin.firestore.Firestore,
  e: Omit<LedgerEntry, 'currency' | 'createdAt'> & { createdAt: admin.firestore.Timestamp }, id?: string) {
  const ref = id ? db.collection('payments').doc(id) : db.collection('payments').doc();
  tx.set(ref, { currency: CURRENCY, ...e });
  return ref;
}
