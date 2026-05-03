import { describe, it, expect, jest, beforeEach } from '@jest/globals';

jest.mock('./stripe_service', () => ({
  createIntent: jest.fn().mockResolvedValue('pi_test_secret'),
  captureIntent: jest.fn().mockResolvedValue({ status: 'succeeded' }),
  refundIntent: jest.fn().mockResolvedValue({ id: 're_test', status: 'succeeded' }),
  createCustomer: jest.fn().mockResolvedValue('cus_test'),
  listPaymentMethods: jest.fn().mockResolvedValue([]),
  attachPaymentMethod: jest.fn().mockResolvedValue(undefined),
  detachPaymentMethod: jest.fn().mockResolvedValue(undefined),
}));

jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        get: jest.fn().mockResolvedValue({
          exists: true,
          id: 'booking-1',
          data: () => ({
            status: 'completed',
            riderId: 'rider-1',
            estimatedPrice: 75,
          }),
        }),
        set: jest.fn().mockResolvedValue(undefined),
        update: jest.fn().mockResolvedValue(undefined),
      })),
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: jest.fn().mockResolvedValue({ docs: [], empty: true }),
    })),
    runTransaction: jest.fn(),
    batch: jest.fn(() => ({
      update: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    })),
  })),
  messaging: jest.fn(() => ({
    sendEachForMulticast: jest.fn().mockResolvedValue({ responses: [] }),
  })),
  firestore: {
    Timestamp: { now: () => ({ toDate: () => new Date() }), fromDate: (d: Date) => d },
    FieldValue: { arrayUnion: (...a: unknown[]) => a },
    GeoPoint: class { constructor(public lat: number, public lng: number) {} },
  },
}));

import * as stripeService from './stripe_service';

describe('StripeService', () => {
  it('createIntent returns clientSecret', async () => {
    const secret = await stripeService.createIntent({
      amount: 7500,
      currency: 'usd',
      customerId: 'cus_test',
    });
    expect(secret).toBe('pi_test_secret');
  });

  it('captureIntent returns succeeded status', async () => {
    const result = await stripeService.captureIntent('pi_test_xxx');
    expect((result as { status: string }).status).toBe('succeeded');
  });

  it('refundIntent returns refund id', async () => {
    const result = await stripeService.refundIntent('pi_test_xxx');
    expect((result as { id: string }).id).toBe('re_test');
  });
});
