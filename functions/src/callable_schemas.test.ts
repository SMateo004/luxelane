/**
 * Cada callable tiene un esquema estricto. Por callable: una entrada válida
 * pasa; un campo extra, un tipo incorrecto y un valor extremo se rechazan.
 */
import { describe, it, expect } from '@jest/globals';
import { z } from 'zod';
import * as index from './index';
import { quoteSchema, createSchema } from './booking_schema';
import { advanceSchema, pickupCodeSchema, verifySchema, overrideSchema } from './trip_flow';
import { raiseSchema, incidentIdSchema, closeSchema } from './incidents';
import { resolveSchema } from './alerts';
import { leadSchema } from './business_leads';
import { callableSchemas as c } from './schemas';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Exported = Record<string, any>;

const ID = 'abcDEF123_-xyz';
const LONG_ID = 'a'.repeat(129);
const place = { name: 'Hotel', address: 'Calle 1', lat: 40.4, lng: -3.7 };
const trip = {
  origin: place, destination: { ...place, lat: 40.5 },
  scheduledAt: 1_900_000_000_000, vehicleClass: 'business', serviceType: 'oneWay',
};

interface Case {
  schema: z.ZodType;
  valid: unknown;
  /** Campo con el tipo equivocado. */
  wrongType: unknown;
  /** Longitud, rango o formato fuera de lo admitido. */
  extreme: unknown[];
}

const lead = {
  company: 'Empresa SA', contactName: 'Laura', email: 'laura@example.com',
  phone: '+59170000000', travellers: '11–50', message: 'Hola',
};

const CASES: Record<string, Case> = {
  submitBusinessLead: {
    schema: leadSchema, valid: lead,
    wrongType: { ...lead, travellers: 20 },
    extreme: [{ ...lead, company: 'x'.repeat(121) }, { ...lead, message: 'x'.repeat(2001) },
      { ...lead, email: 'no-es-correo' }, { ...lead, travellers: '1-10000' }, { ...lead, website: 'x'.repeat(201) }],
  },
  quoteBooking: {
    schema: quoteSchema, valid: trip,
    wrongType: { ...trip, scheduledAt: '2030-01-01' },
    extreme: [{ ...trip, scheduledAt: 9e15 }, { ...trip, hours: 1e9 },
      { ...trip, origin: { ...place, lat: 91 } }, { ...trip, origin: { ...place, address: 'x'.repeat(301) } }],
  },
  createBooking: {
    schema: createSchema,
    valid: { ...trip, passengerCount: 2, luggageCount: 1, requestId: '0b5d1c2e-8f3a-4b6c-9d7e-1a2b3c4d5e6f' },
    wrongType: { ...trip, passengerCount: '2', luggageCount: 1, requestId: '0b5d1c2e-8f3a-4b6c-9d7e-1a2b3c4d5e6f' },
    extreme: [
      { ...trip, passengerCount: 2, luggageCount: 1, requestId: '0b5d1c2e-8f3a-4b6c-9d7e-1a2b3c4d5e6f', quotedPrice: 1e12 },
      { ...trip, passengerCount: 1e9, luggageCount: 1, requestId: '0b5d1c2e-8f3a-4b6c-9d7e-1a2b3c4d5e6f' },
      { ...trip, passengerCount: 2, luggageCount: 1, requestId: 'no-es-uuid' },
      { ...trip, passengerCount: 2, luggageCount: 1, requestId: '0b5d1c2e-8f3a-4b6c-9d7e-1a2b3c4d5e6f', notes: 'x'.repeat(1001) },
    ],
  },
  advanceBooking: {
    schema: advanceSchema, valid: { bookingId: ID, to: 'driver_arriving' },
    wrongType: { bookingId: 42, to: 'driver_arriving' },
    extreme: [{ bookingId: LONG_ID, to: 'driver_arriving' }, { bookingId: ID, to: 'cancelled' },
      { bookingId: ID, to: 'completed', location: { lat: 0, lng: 181 } }],
  },
  getPickupCode: {
    schema: pickupCodeSchema, valid: { bookingId: ID },
    wrongType: { bookingId: [ID] }, extreme: [{ bookingId: LONG_ID }, { bookingId: '../users/x' }],
  },
  verifyPickup: {
    schema: verifySchema, valid: { bookingId: ID, code: '0427' },
    wrongType: { bookingId: ID, code: 427 },
    extreme: [{ bookingId: ID, code: '04270' }, { bookingId: ID, code: '0'.repeat(10000) }],
  },
  adminOverrideVerify: {
    schema: overrideSchema, valid: { bookingId: ID, reason: 'Código ilegible' },
    wrongType: { bookingId: ID, reason: true },
    extreme: [{ bookingId: ID, reason: 'x'.repeat(501) }, { bookingId: LONG_ID, reason: 'Código ilegible' }],
  },
  raiseIncident: {
    schema: raiseSchema, valid: { bookingId: ID, location: { lat: 40.4, lng: -3.7 } },
    wrongType: { bookingId: ID, location: '40.4,-3.7' },
    extreme: [{ bookingId: ID, location: { lat: Infinity, lng: 0 } }, { bookingId: ID, appVersion: '1'.repeat(41) }],
  },
  cancelIncident: {
    schema: incidentIdSchema, valid: { incidentId: ID },
    wrongType: { incidentId: null }, extreme: [{ incidentId: LONG_ID }, { incidentId: '' }],
  },
  acknowledgeIncident: {
    schema: incidentIdSchema, valid: { incidentId: ID },
    wrongType: { incidentId: 1 }, extreme: [{ incidentId: 'a/b' }],
  },
  closeIncident: {
    schema: closeSchema, valid: { incidentId: ID, note: 'Llamada hecha, todo bien' },
    wrongType: { incidentId: ID, note: 10 },
    extreme: [{ incidentId: ID, note: 'x'.repeat(1001) }, { incidentId: ID, note: 'corta' }],
  },
  resolveAlert: {
    schema: resolveSchema, valid: { alertId: ID },
    wrongType: { alertId: ID, note: {} }, extreme: [{ alertId: ID, note: 'x'.repeat(501) }, { alertId: LONG_ID }],
  },
  createPaymentIntent: {
    schema: c.createPaymentIntent, valid: { bookingId: ID, paymentMethodId: 'pm_123' },
    wrongType: { bookingId: ID, paymentMethodId: 123 },
    extreme: [{ bookingId: ID, paymentMethodId: 'tok_123' }, { bookingId: LONG_ID }],
  },
  capturePayment: {
    schema: c.capturePayment, valid: { bookingId: ID, stripePaymentIntentId: 'pi_123' },
    wrongType: { bookingId: ID, stripePaymentIntentId: { id: 'pi_123' } },
    extreme: [{ bookingId: ID, stripePaymentIntentId: 'pi_' + 'a'.repeat(256) }, { bookingId: ID, stripePaymentIntentId: 'ch_123' }],
  },
  refundPayment: {
    schema: c.refundPayment, valid: { paymentId: ID, reason: 'Cliente no se presentó' },
    wrongType: { paymentId: ID, reason: 5 }, extreme: [{ paymentId: ID, reason: 'x'.repeat(501) }],
  },
  listPaymentMethods: {
    schema: c.listPaymentMethods, valid: { customerId: 'cus_123' },
    wrongType: { customerId: 123 }, extreme: [{ customerId: 'cus_' + 'a'.repeat(256) }, { customerId: 'acct_1' }],
  },
  setDefaultPaymentMethod: {
    schema: c.setDefaultPaymentMethod, valid: { paymentMethodId: 'pm_1' },
    wrongType: { paymentMethodId: false }, extreme: [{ paymentMethodId: 'pm_' }, { paymentMethodId: 'pm_a b' }],
  },
  attachPaymentMethod: {
    schema: c.attachPaymentMethod, valid: { customerId: 'cus_1', paymentMethodId: 'pm_1' },
    wrongType: { customerId: 'cus_1', paymentMethodId: ['pm_1'] },
    extreme: [{ customerId: 'cus_1', paymentMethodId: 'pm_' + 'a'.repeat(256) }],
  },
  detachPaymentMethod: {
    schema: c.detachPaymentMethod, valid: { paymentMethodId: 'pm_1' },
    wrongType: { paymentMethodId: 1 }, extreme: [{ paymentMethodId: 'card_1' }],
  },
  deleteAccount: { schema: c.deleteAccount, valid: null, wrongType: 'borrar', extreme: [[]] },
  syncEmailVerification: { schema: c.syncEmailVerification, valid: null, wrongType: 'sí', extreme: [[]] },
  ensureStripeCustomer: { schema: c.ensureStripeCustomer, valid: {}, wrongType: 1, extreme: [[]] },
  backfillSettlements: { schema: c.backfillSettlements, valid: undefined, wrongType: true, extreme: [[]] },
  assignNearestDriver: {
    schema: c.assignNearestDriver, valid: { bookingId: ID },
    wrongType: { bookingId: 1 }, extreme: [{ bookingId: LONG_ID }],
  },
  acceptBooking: {
    schema: c.acceptBooking, valid: { bookingId: ID },
    wrongType: { bookingId: true }, extreme: [{ bookingId: 'x'.repeat(10000) }],
  },
};

/** Añade un campo desconocido; en las callables sin datos, un objeto con uno. */
const withExtra = (v: unknown) =>
  (v && typeof v === 'object' ? { ...(v as object), extra: 1 } : { extra: 1 });

const callables = Object.entries(index as Exported)
  .filter(([, fn]) => fn?.__endpoint?.callableTrigger !== undefined)
  .map(([name]) => name);

describe('esquemas de entrada de las callables', () => {
  it('toda callable exportada tiene su caso aquí', () => {
    expect(callables.length).toBeGreaterThanOrEqual(23);
    expect(callables.filter((n) => !CASES[n])).toEqual([]);
  });

  describe.each(Object.entries(CASES))('%s', (_name, k) => {
    it('acepta una entrada válida', () => {
      expect(k.schema.safeParse(k.valid).success).toBe(true);
    });
    it('rechaza un campo extra', () => {
      expect(k.schema.safeParse(withExtra(k.valid)).success).toBe(false);
    });
    it('rechaza un tipo incorrecto', () => {
      expect(k.schema.safeParse(k.wrongType).success).toBe(false);
    });
    it('rechaza valores extremos', () => {
      for (const v of k.extreme) expect(k.schema.safeParse(v).success).toBe(false);
    });
  });
});
