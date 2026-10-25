import { describe, it, expect } from '@jest/globals';
import * as admin from 'firebase-admin';
import { changedFields, reasonSchema } from './admin_audit';

describe('changedFields', () => {
  it('solo los campos que cambian, con antes y después', () => {
    expect(changedFields({ a: 1, b: 'x', c: true }, { a: 2, b: 'x' })).toEqual({ a: { before: 1, after: 2 } });
  });

  it('un campo nuevo queda con before null', () => {
    expect(changedFields({}, { finalPrice: 120 })).toEqual({ finalPrice: { before: null, after: 120 } });
  });

  it('compara fechas por su valor', () => {
    const t = admin.firestore.Timestamp.fromMillis(1_700_000_000_000);
    expect(changedFields({ d: t }, { d: admin.firestore.Timestamp.fromMillis(1_700_000_000_000) })).toEqual({});
  });
});

describe('reasonSchema', () => {
  it('exige de 10 a 500 caracteres', () => {
    expect(reasonSchema.safeParse('corto').success).toBe(false);
    expect(reasonSchema.safeParse('   espacios   ').success).toBe(false);
    expect(reasonSchema.safeParse('Pedido por el pasajero').success).toBe(true);
    expect(reasonSchema.safeParse('x'.repeat(501)).success).toBe(false);
  });
});
