import { describe, it, expect } from '@jest/globals';
import { linkRejection, paymentAction, validIntentAmount } from './payments';

const booking = { riderId: 'u1', status: 'pending', estimatedPrice: 120 };
const intent = { status: 'requires_capture', amount: 12000, metadata: { uid: 'u1' } };

describe('validIntentAmount', () => {
  it('solo céntimos enteros en rango', () => {
    expect(validIntentAmount(12000)).toBe(true);
    expect(validIntentAmount(12000.5)).toBe(false);
    expect(validIntentAmount(-5)).toBe(false);
    expect(validIntentAmount(50)).toBe(false);
    expect(validIntentAmount(1e9)).toBe(false);
    expect(validIntentAmount('12000')).toBe(false);
  });
});

describe('linkRejection', () => {
  it('vincula la retención autorizada del propio pasajero', () => {
    expect(linkRejection('u1', booking, intent)).toBeNull();
  });
  it('rechaza reservas ajenas, ya vinculadas o cerradas', () => {
    expect(linkRejection('u2', booking, intent)).toBe('not_owner');
    expect(linkRejection('u1', { ...booking, paymentIntentId: 'pi' }, intent)).toBe('already_linked');
    expect(linkRejection('u1', { ...booking, status: 'cancelled' }, intent)).toBe('booking_closed');
  });
  it('rechaza retenciones de otro usuario, sin autorizar o por menos', () => {
    expect(linkRejection('u1', booking, { ...intent, metadata: { uid: 'u2' } })).toBe('intent_not_owned');
    expect(linkRejection('u1', booking, { ...intent, status: 'requires_payment_method' })).toBe('intent_not_authorized');
    expect(linkRejection('u1', booking, { ...intent, amount: 100 })).toBe('amount_too_low');
  });
});

describe('paymentAction', () => {
  const linked = { paymentIntentId: 'pi', paymentStatus: 'authorized' };
  it('captura al completar y libera al cancelar', () => {
    expect(paymentAction({ status: 'completed', ...linked })).toBe('capture');
    expect(paymentAction({ status: 'cancelled', ...linked })).toBe('release');
  });
  it('no toca pagos en efectivo, ya cobrados o en curso', () => {
    expect(paymentAction({ status: 'completed' })).toBeNull();
    expect(paymentAction({ status: 'completed', paymentIntentId: 'pi', paymentStatus: 'captured' })).toBeNull();
    expect(paymentAction({ status: 'in_progress', ...linked })).toBeNull();
  });
});
