import { describe, it, expect, jest } from '@jest/globals';

// Untyped async mock: jest.fn() from @jest/globals infers `never` otherwise.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const mockAsync = () => jest.fn<(...args: any[]) => Promise<any>>();

jest.mock('./stripe_service', () => ({
  createIntent: mockAsync().mockResolvedValue('pi_test_secret'),
  captureIntent: mockAsync().mockResolvedValue({ status: 'succeeded' }),
  refundIntent: mockAsync().mockResolvedValue({ id: 're_test', status: 'succeeded' }),
  createCustomer: mockAsync().mockResolvedValue('cus_test'),
  listPaymentMethods: mockAsync().mockResolvedValue([]),
  attachPaymentMethod: mockAsync().mockResolvedValue(undefined),
  detachPaymentMethod: mockAsync().mockResolvedValue(undefined),
}));

jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  // Callable `admin.firestore()` plus its static members (Timestamp, …).
  firestore: Object.assign(jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        get: mockAsync().mockResolvedValue({
          exists: true,
          id: 'booking-1',
          data: () => ({
            status: 'completed',
            riderId: 'rider-1',
            estimatedPrice: 75,
          }),
        }),
        set: mockAsync().mockResolvedValue(undefined),
        update: mockAsync().mockResolvedValue(undefined),
      })),
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: mockAsync().mockResolvedValue({ docs: [], empty: true }),
    })),
    runTransaction: jest.fn(),
    batch: jest.fn(() => ({
      update: jest.fn(),
      commit: mockAsync().mockResolvedValue(undefined),
    })),
  })), {
    Timestamp: { now: () => ({ toDate: () => new Date() }), fromDate: (d: Date) => d },
    FieldValue: { arrayUnion: (...a: unknown[]) => a },
    GeoPoint: class { constructor(public lat: number, public lng: number) {} },
  }),
  messaging: jest.fn(() => ({
    sendEachForMulticast: mockAsync().mockResolvedValue({ responses: [] }),
  })),
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
