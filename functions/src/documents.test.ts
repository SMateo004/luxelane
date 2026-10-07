import { DOC_TYPES, DriverDoc, approvalError, daysLeft, isFullyVerified, isValid, reminderDue } from './documents';

const now = new Date('2026-10-07T12:00:00Z');
const inDays = (d: number) => new Date(now.getTime() + d * 86400000);
const ok = (expiresAt: Date | null = inDays(200)): DriverDoc => ({ status: 'approved', expiresAt });

describe('verification', () => {
  const all = Object.fromEntries(DOC_TYPES.map((t) => [t, ok()]));

  it('needs every required document approved and current', () => {
    expect(isFullyVerified(all, now)).toBe(true);
    expect(isFullyVerified({ ...all, soat: undefined }, now)).toBe(false);
    expect(isFullyVerified({ ...all, soat: { status: 'pending', expiresAt: inDays(100) } }, now)).toBe(false);
    expect(isFullyVerified({ ...all, license: ok(inDays(-1)) }, now)).toBe(false);
  });

  it('documents without expiry stay valid', () => {
    expect(isValid(ok(null), now)).toBe(true);
    expect(isValid({ status: 'rejected' }, now)).toBe(false);
  });
});

describe('approvalError', () => {
  it('expiring documents need a future date', () => {
    expect(approvalError('license', null, now)).toBe('documents/expiry-required');
    expect(approvalError('soat', inDays(-2), now)).toBe('documents/already-expired');
    expect(approvalError('soat', inDays(300), now)).toBeNull();
    expect(approvalError('vehicleRegistration', null, now)).toBeNull();
  });
});

describe('reminderDue', () => {
  it('sends 30 then 7 days, once each', () => {
    expect(reminderDue(ok(inDays(40)), now)).toBeNull();
    expect(reminderDue(ok(inDays(29)), now)).toBe(30);
    expect(reminderDue({ ...ok(inDays(29)), remindedDays: 30 }, now)).toBeNull();
    expect(reminderDue({ ...ok(inDays(6)), remindedDays: 30 }, now)).toBe(7);
    expect(reminderDue({ ...ok(inDays(6)), remindedDays: 7 }, now)).toBeNull();
    // Approved late (already inside 7 days): only the 7-day reminder.
    expect(reminderDue(ok(inDays(3)), now)).toBe(7);
  });

  it('nothing for expired, pending or undated documents', () => {
    expect(reminderDue(ok(inDays(-1)), now)).toBeNull();
    expect(reminderDue({ status: 'pending', expiresAt: inDays(3) }, now)).toBeNull();
    expect(reminderDue(ok(null), now)).toBeNull();
  });

  it('daysLeft rounds up and never goes negative', () => {
    expect(daysLeft(inDays(6.2), now)).toBe(7);
    expect(daysLeft(inDays(-3), now)).toBe(0);
  });
});
