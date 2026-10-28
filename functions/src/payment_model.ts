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
  /** Asiento pendiente vigente de cada serie (H4) y cuántos se crearon. */
  balanceEntryId?: string | null;
  balanceSeq?: number;
  refundFinalEntryId?: string | null;
  refundFinalSeq?: number;
  /** Saldo ya cobrado por central (G2), en céntimos. */
  balanceCollected?: number;
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
  /**
   * pending: aún por ejecutar (reembolso manual, saldo por cobrar).
   * completed: el propio asiento es el movimiento de dinero.
   * superseded: lo sustituyen otros asientos (closedBy): un cobro de saldo,
   * el resto que queda por cobrar o una diferencia final recalculada.
   */
  status: 'completed' | 'pending' | 'superseded';
  createdAt: admin.firestore.Timestamp;
  /** Al cerrar un asiento pendiente (una sola vez). */
  completedAt?: admin.firestore.Timestamp;
  closedAt?: admin.firestore.Timestamp;
  closedBy?: string[];
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

/**
 * El libro `payments` es de solo anexado (H4): un asiento se crea una vez
 * (tx.create: si ya existe, la transacción falla), nunca se borra y su
 * importe, tipo, método y motivo no cambian. Lo único que se escribe
 * después es el cierre de un asiento pendiente, una sola vez
 * (closePending).
 */
export function addLedger(tx: admin.firestore.Transaction, db: admin.firestore.Firestore,
  e: Omit<LedgerEntry, 'currency' | 'createdAt'> & { createdAt: admin.firestore.Timestamp }, id?: string) {
  const ref = id ? db.collection('payments').doc(id) : db.collection('payments').doc();
  tx.create(ref, { currency: CURRENCY, ...e });
  return ref;
}

/**
 * Cierra un asiento pendiente: completed (el asiento es el movimiento, con
 * su referencia externa) o superseded (lo sustituyen [closedBy]). Solo
 * toca el estado y los datos del cierre.
 */
export function closePending(tx: admin.firestore.Transaction, ref: admin.firestore.DocumentReference,
  c: { status: 'completed'; externalRef: string; at: admin.firestore.Timestamp }
    | { status: 'superseded'; closedBy: string[]; at: admin.firestore.Timestamp }) {
  tx.update(ref, c.status === 'completed'
    ? { status: 'completed', externalRef: c.externalRef, completedAt: c.at }
    : { status: 'superseded', closedBy: c.closedBy, closedAt: c.at });
}

/**
 * Id del siguiente asiento de una serie (saldo o devolución por diferencia
 * final): el primero conserva el id de siempre (balance_{id}); los demás,
 * balance_{id}_2, _3…
 */
export const seriesId = (prefix: string, bookingId: string, n: number) =>
  n <= 1 ? `${prefix}_${bookingId}` : `${prefix}_${bookingId}_${n}`;
