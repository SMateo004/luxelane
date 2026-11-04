import { describe, it, expect } from '@jest/globals';
import {
  allocatePayment,
  buildStatement,
  corporateRejection,
  dueDateMs,
  isPeriod,
  parseLimit,
  periodBounds,
  periodOf,
  placeLabel,
  previousPeriod,
  validateAdjustment,
  validateCompanyInput,
} from './corporate';

describe('periodos en hora de Bolivia', () => {
  it('el mes empieza a medianoche de La Paz (04:00 UTC)', () => {
    const { startMs, endMs } = periodBounds('2026-10');
    expect(new Date(startMs).toISOString()).toBe('2026-10-01T04:00:00.000Z');
    expect(new Date(endMs).toISOString()).toBe('2026-11-01T04:00:00.000Z');
  });
  it('un viaje a las 23:30 del 31 en Bolivia es de ese mes', () => {
    expect(periodOf(Date.parse('2026-11-01T03:30:00Z'))).toBe('2026-10');
    expect(periodOf(Date.parse('2026-11-01T04:30:00Z'))).toBe('2026-11');
  });
  it('el 1 de enero factura diciembre del año anterior', () => {
    expect(previousPeriod(Date.parse('2027-01-01T12:00:00Z'))).toBe('2026-12');
    expect(previousPeriod(Date.parse('2026-10-01T12:00:00Z'))).toBe('2026-09');
  });
  it('valida el formato', () => {
    expect(isPeriod('2026-10')).toBe(true);
    expect(isPeriod('2026-13')).toBe(false);
    expect(isPeriod('26-10')).toBe(false);
  });
});

describe('validateCompanyInput', () => {
  const ok = {
    name: ' Acme SRL ', taxId: '1234 5678', billingEmail: 'Pagos@Acme.bo',
    contactName: 'Ana Pérez', phone: '+591 70000000', address: 'Av. San Martín 100',
  };
  it('limpia y acepta datos correctos', () => {
    const r = validateCompanyInput(ok);
    expect('data' in r && r.data).toMatchObject({ name: 'Acme SRL', taxId: '12345678', billingEmail: 'pagos@acme.bo' });
  });
  it('rechaza NIT, correo o teléfono inválidos', () => {
    expect(validateCompanyInput({ ...ok, taxId: 'ABC' })).toHaveProperty('error');
    expect(validateCompanyInput({ ...ok, billingEmail: 'x@' })).toHaveProperty('error');
    expect(validateCompanyInput({ ...ok, phone: '12' })).toHaveProperty('error');
    expect(validateCompanyInput({ ...ok, name: 42 as unknown as string })).toHaveProperty('error');
  });
});

describe('parseLimit', () => {
  it('vacío o cero es sin límite; negativos no valen', () => {
    expect(parseLimit(null)).toBeNull();
    expect(parseLimit(0)).toBeNull();
    expect(parseLimit(1500.456)).toBe(1500.46);
    expect(parseLimit(-5)).toBeUndefined();
    expect(parseLimit('abc')).toBeUndefined();
  });
});

describe('corporateRejection', () => {
  const base = {
    company: { status: 'active', monthlyBudgetBs: 1000 },
    member: { active: true, monthlyLimitBs: 300 },
    userCompanyId: 'c1', bookingCompanyId: 'c1',
    memberSpentBs: 100, companySpentBs: 500, priceBs: 150,
  };
  it('acepta dentro de límites', () => expect(corporateRejection(base)).toBeNull());
  it('rechaza a quien no es miembro o usa otra empresa', () => {
    expect(corporateRejection({ ...base, member: null })).toBe('not_member');
    expect(corporateRejection({ ...base, bookingCompanyId: 'c2' })).toBe('not_member');
  });
  it('rechaza empresa pendiente o suspendida y miembro desactivado', () => {
    expect(corporateRejection({ ...base, company: { status: 'pending' } })).toBe('company_inactive');
    expect(corporateRejection({ ...base, member: { active: false } })).toBe('member_inactive');
  });
  it('respeta el límite del empleado y el presupuesto de la empresa', () => {
    expect(corporateRejection({ ...base, priceBs: 250 })).toBe('member_limit');
    expect(corporateRejection({ ...base, member: { active: true, monthlyLimitBs: null }, companySpentBs: 900 })).toBe('company_budget');
    expect(corporateRejection({ ...base, priceBs: 200 })).toBeNull(); // justo en el límite
  });
});

describe('buildStatement', () => {
  const at = (iso: string) => Date.parse(iso);
  const bookings = [
    { id: 'a', status: 'completed', riderId: 'u1', riderName: 'Ana', scheduledAtMs: at('2026-10-05T15:00:00Z'), estimatedPrice: 100, finalPrice: 120 },
    { id: 'b', status: 'completed', riderId: 'u2', scheduledAtMs: at('2026-10-02T15:00:00Z'), estimatedPrice: 80.5 },
    { id: 'c', status: 'cancelled', riderId: 'u1', scheduledAtMs: at('2026-10-03T15:00:00Z'), estimatedPrice: 999 },
    { id: 'd', status: 'completed', riderId: 'u1', scheduledAtMs: at('2026-11-01T05:00:00Z'), estimatedPrice: 50 },
    { id: 'e', status: 'in_progress', riderId: 'u1', scheduledAtMs: at('2026-10-30T15:00:00Z'), estimatedPrice: 70 },
  ];
  it('solo completados del mes, ordenados por fecha, con precio final', () => {
    const s = buildStatement('2026-10', bookings, 0, []);
    expect(s.lines.map((l) => l.bookingId)).toEqual(['b', 'a']);
    expect(s.subtotalBs).toBe(200.5);
    expect(s.totalBs).toBe(200.5);
  });
  it('aplica descuento y ajustes', () => {
    const s = buildStatement('2026-10', bookings, 10, [
      { id: 'x', concept: 'Espera extra', amountBs: 30 },
      { id: 'y', concept: 'Abono por retraso', amountBs: -20.05 },
    ]);
    expect(s.discountBs).toBe(20.05);
    expect(s.adjustmentsBs).toBe(9.95);
    expect(s.totalBs).toBe(190.4);
  });
  it('incluye viajes de meses anteriores aún sin facturar', () => {
    const late = { id: 'old', status: 'completed', riderId: 'u1', scheduledAtMs: at('2026-09-30T15:00:00Z'), estimatedPrice: 40 };
    expect(buildStatement('2026-10', [late], 0, []).tripCount).toBe(0);
    expect(buildStatement('2026-10', [late], 0, [], at('2026-07-01T00:00:00Z')).tripCount).toBe(1);
  });
  it('el total nunca es negativo', () => {
    expect(buildStatement('2026-10', bookings, 0, [{ id: 'z', concept: 'Abono', amountBs: -1000 }]).totalBs).toBe(0);
  });
});

describe('validateAdjustment', () => {
  it('exige concepto e importe distinto de cero', () => {
    expect(validateAdjustment('Peaje', 25.555)).toEqual({ concept: 'Peaje', amountBs: 25.56 });
    expect(validateAdjustment('x', 10)).toHaveProperty('error');
    expect(validateAdjustment('Peaje', 0)).toHaveProperty('error');
    expect(validateAdjustment('Peaje', 'nada')).toHaveProperty('error');
  });
});

describe('allocatePayment', () => {
  it('reparte el total exacto en proporción', () => {
    const r = allocatePayment([{ bookingId: 'a', amountBs: 100 }, { bookingId: 'b', amountBs: 50 }], 135);
    expect(r).toEqual([{ bookingId: 'a', cents: 9000 }, { bookingId: 'b', cents: 4500 }]);
  });
  it('el redondeo lo absorbe el último y la suma cuadra', () => {
    const r = allocatePayment([{ bookingId: 'a', amountBs: 33.33 }, { bookingId: 'b', amountBs: 33.33 }, { bookingId: 'c', amountBs: 33.34 }], 99.99);
    expect(r.reduce((s, x) => s + x.cents, 0)).toBe(9999);
  });
});

describe('dueDateMs', () => {
  it('usa el plazo pactado o 15 días', () => {
    expect(dueDateMs(0, 30)).toBe(30 * 86400e3);
    expect(dueDateMs(0, null)).toBe(15 * 86400e3);
    expect(dueDateMs(0, -3)).toBe(15 * 86400e3);
  });
});

describe('placeLabel', () => {
  it('prefiere el nombre y descarta códigos plus', () => {
    expect(placeLabel({ name: 'Equipetrol', address: '6RH4+M7W, Santa Cruz de la Sierra' })).toBe('Equipetrol');
    expect(placeLabel({ name: 'Ventura Mall', address: 'Av. San Martín 1500' })).toBe('Ventura Mall · Av. San Martín 1500');
    expect(placeLabel({ name: '', address: 'Av. Busch 200' })).toBe('Av. Busch 200');
    expect(placeLabel(null)).toBe('');
  });
});
