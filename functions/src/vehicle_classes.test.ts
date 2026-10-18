import { DEFAULT_RULES } from './pricing';
import { isVehicleClassId, nameIn, resolveVehicleClass, validateVehicleClassInput } from './vehicle_classes';

const keep = (_: unknown, f: { base: number; perKm: number; perHour: number; min: number }) => f;

const valid = {
  name: { es: 'SUV Premium', en: 'Premium SUV', pt: 'SUV Premium' },
  description: { es: 'BMW X5 o similar' },
  active: true,
  order: 4,
  capacity: 5,
  carryOn: 4,
  checked: 3,
  extraLarge: 2,
  childSeat: true,
  icon: 'suv',
  color: '#1a2b3c',
  imageUrl: 'https://firebasestorage.googleapis.com/v0/b/x/o/suv.png',
  slides: [{ url: 'https://example.com/1.jpg', caption: { es: 'Amplia' } }],
  services: { oneWay: { base: 70, perKm: 4, min: 70 }, byTheHour: { perHour: 110, min: 220 } },
};

describe('vehicle_classes', () => {
  it('ids are short slugs', () => {
    expect(isVehicleClassId('premiumSuv')).toBe(true);
    expect(isVehicleClassId('suv-2')).toBe(true);
    expect(isVehicleClassId('a')).toBe(false);
    expect(isVehicleClassId('2suv')).toBe(false);
    expect(isVehicleClassId('a b')).toBe(false);
    expect(isVehicleClassId(5)).toBe(false);
  });

  it('built-ins use the defaults (and old pricingRules) until an admin saves them', () => {
    const b = resolveVehicleClass('business', undefined, keep)!;
    expect(b.active).toBe(true);
    expect(b.capacity).toBe(3);
    expect(b.services.oneWay).toEqual(DEFAULT_RULES.business.oneWay);
    const legacy = resolveVehicleClass('business', undefined, (st, f) => (st === 'oneWay' ? { ...f, min: 99 } : f))!;
    expect(legacy.services.oneWay?.min).toBe(99);
    expect(resolveVehicleClass('electric', undefined, keep)!.active).toBe(false);
    expect(resolveVehicleClass('nope', undefined, keep)).toBeNull();
  });

  it('an admin document decides prices, services, capacity and names', () => {
    const doc = validateVehicleClassInput('premiumSuv', { ...valid, services: { byTheHour: { perHour: 110, min: 220 } } });
    expect(doc.ok).toBe(true);
    const c = resolveVehicleClass('premiumSuv', (doc as { doc: Record<string, unknown> }).doc, keep)!;
    expect(c.capacity).toBe(5);
    expect(c.services.oneWay).toBeUndefined(); // not offered
    expect(c.services.byTheHour).toEqual({ base: 0, perKm: 0, perHour: 110, min: 220 });
    expect(nameIn(c, 'premiumSuv', 'en')).toBe('Premium SUV');
    // An archived built-in can't be booked.
    expect(resolveVehicleClass('business', { active: false, services: {} }, keep)!.active).toBe(false);
  });

  it('validates what admins save', () => {
    const ok = validateVehicleClassInput('premiumSuv', valid);
    expect(ok.ok && ok.doc.color).toBe('#1A2B3C');
    const bad = (patch: Record<string, unknown>, id = 'premiumSuv') =>
      (validateVehicleClassInput(id, { ...valid, ...patch }) as { error?: string }).error;
    expect(bad({}, 'x y')).toBe('vehicle/id');
    expect(bad({ name: { es: 'SUV' } })).toBe('vehicle/name');
    expect(bad({ name: { es: 'x'.repeat(41), en: 'a', pt: 'b' } })).toBe('vehicle/length');
    expect(bad({ capacity: 0 })).toBe('vehicle/numbers');
    expect(bad({ capacity: 2.5 })).toBe('vehicle/numbers');
    expect(bad({ icon: 'rocket' })).toBe('vehicle/icon');
    expect(bad({ color: 'red' })).toBe('vehicle/color');
    expect(bad({ imageUrl: 'http://insecure.example/x.png' })).toBe('vehicle/image');
    expect(bad({ slides: Array(9).fill({ url: 'https://e.com/1.jpg' }) })).toBe('vehicle/slides');
    expect(bad({ services: {} })).toBe('vehicle/services');
    expect(bad({ services: { oneWay: { base: 10, perKm: 1, min: 0 } } })).toBe('vehicle/price');
    expect(bad({ services: { byTheHour: { perHour: 0, min: 100 } } })).toBe('vehicle/price');
    expect(bad({ services: { oneWay: { base: -5, perKm: 1, min: 10 } } })).toBeUndefined(); // negatives read as 0
    expect(bad({ active: 'yes' })).toBe('vehicle/data');
  });
});
