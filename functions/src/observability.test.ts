import { fingerprint, needsEscalation, needsNoDriverAlert, normalizeMessage, throttled, topFrame } from './observability';

const now = new Date('2026-10-08T12:00:00Z');
const inMin = (m: number) => new Date(now.getTime() + m * 60000);

describe('client error grouping', () => {
  it('masks ids, numbers, urls and quoted values', () => {
    expect(normalizeMessage('Booking abc12345ef not found (404) at https://x.y/z')).toBe('Booking <id> not found (<n>) at <url>');
    expect(normalizeMessage("Null check on 'driverName'")).toBe('Null check on <str>');
  });

  it('same bug from two users shares a fingerprint; another platform does not', () => {
    const stack = '#0 RideScreen.build (package:luxelane/features/ride/ride_screen.dart:120:7)\n#1 ...';
    const a = fingerprint('web', 'Booking 1a2b3c4d5e not found', stack);
    const b = fingerprint('web', 'Booking 9f8e7d6c5b not found', stack.replace('120:7', '121:9'));
    expect(a).toBe(b);
    expect(fingerprint('android', 'Booking 1a2b3c4d5e not found', stack)).not.toBe(a);
    expect(a).toHaveLength(20);
  });

  it('top frame prefers app code', () => {
    expect(topFrame('#0 dart:core\n#1 Foo (package:luxelane/a.dart:3:4)')).toBe('#1 Foo (package:luxelane/a.dart)');
    expect(topFrame('')).toBe('');
  });
});

describe('operational alerts', () => {
  const b = { status: 'pending', driverId: null, pickup: inMin(20) };
  it('pages for pending bookings within 30 min without a chauffeur, once', () => {
    expect(needsNoDriverAlert(b, now)).toBe(true);
    expect(needsNoDriverAlert({ ...b, alertedNoDriver: true }, now)).toBe(false);
    expect(needsNoDriverAlert({ ...b, driverId: 'd1' }, now)).toBe(false);
    expect(needsNoDriverAlert({ ...b, status: 'confirmed' }, now)).toBe(false);
    expect(needsNoDriverAlert({ ...b, pickup: inMin(45) }, now)).toBe(false);
    expect(needsNoDriverAlert({ ...b, pickup: inMin(-5) }, now)).toBe(false);
  });

  it('throttle window', () => {
    expect(throttled(null, now, 3600000)).toBe(false);
    expect(throttled(inMin(-30), now, 3600000)).toBe(true);
    expect(throttled(inMin(-61), now, 3600000)).toBe(false);
  });
});

describe('needsEscalation', () => {
  const now = new Date('2026-10-10T12:00:00Z');
  const t = {
    status: 'open',
    priority: 'urgent',
    lastAuthorRole: 'rider',
    lastMessageAt: new Date('2026-10-10T11:45:00Z'),
    escalatedAt: null,
  };
  it('pages again once after 10 min without a team reply', () => {
    expect(needsEscalation(t, now)).toBe(true);
    expect(needsEscalation({ ...t, escalatedAt: new Date('2026-10-10T11:56:00Z') }, now)).toBe(false);
    // A new message after the last escalation counts again.
    expect(needsEscalation({ ...t, escalatedAt: new Date('2026-10-10T11:40:00Z') }, now)).toBe(true);
  });
  it('not before 10 min, not when answered, not for normal tickets', () => {
    expect(needsEscalation({ ...t, lastMessageAt: new Date('2026-10-10T11:55:00Z') }, now)).toBe(false);
    expect(needsEscalation({ ...t, lastAuthorRole: 'admin' }, now)).toBe(false);
    expect(needsEscalation({ ...t, priority: 'normal' }, now)).toBe(false);
    expect(needsEscalation({ ...t, status: 'answered' }, now)).toBe(false);
  });
});
