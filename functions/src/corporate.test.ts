import {
  CompanyDoc,
  leavesAdmin,
  normalizeEmail,
  resolveBilling,
  sanitizeCostCenters,
  validateCompany,
} from './corporate';

const company: CompanyDoc = {
  name: 'Acme SRL',
  taxId: '1234567',
  billingEmail: 'cuentas@acme.bo',
  active: true,
  costCenters: ['Ventas', 'Gerencia'],
  requireCostCenter: false,
};

describe('validateCompany', () => {
  it('accepts and cleans a full company', () => {
    const r = validateCompany(
      { name: '  Acme   SRL ', taxId: '123.456-7', billingEmail: ' Cuentas@ACME.bo ', costCenters: ['Ventas', 'ventas', ' '] },
      false,
    );
    expect(r).toEqual({
      ok: true,
      value: { name: 'Acme SRL', taxId: '1234567', billingEmail: 'cuentas@acme.bo', costCenters: ['Ventas'], requireCostCenter: false },
    });
  });

  it('rejects bad name, NIT and email', () => {
    expect(validateCompany({ name: 'A', taxId: '12345', billingEmail: 'a@b.co' }, false)).toEqual({ ok: false, error: 'company/invalid-name' });
    expect(validateCompany({ name: 'Acme', taxId: 'ABC', billingEmail: 'a@b.co' }, false)).toEqual({ ok: false, error: 'company/invalid-tax-id' });
    expect(validateCompany({ name: 'Acme', taxId: '12345', billingEmail: 'nope' }, false)).toEqual({ ok: false, error: 'company/invalid-email' });
  });

  it('partial updates only touch given fields', () => {
    expect(validateCompany({ costCenters: ['A'], requireCostCenter: true }, true)).toEqual({
      ok: true,
      value: { costCenters: ['A'], requireCostCenter: true },
    });
    expect(validateCompany({ costCenters: [], requireCostCenter: true }, true)).toEqual({
      ok: false,
      error: 'company/cost-center-required-without-list',
    });
  });
});

describe('resolveBilling', () => {
  it('personal when nothing or personal is asked', () => {
    expect(resolveBilling(undefined, 'c1', company, true)).toEqual({ ok: true, value: null });
    expect(resolveBilling({ type: 'personal' }, null, null, false)).toEqual({ ok: true, value: null });
  });

  it('corporate needs an active company the rider belongs to', () => {
    expect(resolveBilling({ type: 'corporate' }, null, null, false)).toEqual({ ok: false, error: 'billing/not-a-member' });
    expect(resolveBilling({ type: 'corporate' }, 'c1', company, false)).toEqual({ ok: false, error: 'billing/not-a-member' });
    expect(resolveBilling({ type: 'corporate' }, 'c1', { ...company, active: false }, true)).toEqual({
      ok: false,
      error: 'billing/company-inactive',
    });
  });

  it('matches cost centers case-insensitively and keeps the company spelling', () => {
    expect(resolveBilling({ type: 'corporate', costCenter: 'ventas', reference: ' PO-77 ' }, 'c1', company, true)).toEqual({
      ok: true,
      value: { companyId: 'c1', companyName: 'Acme SRL', costCenter: 'Ventas', billingReference: 'PO-77' },
    });
    expect(resolveBilling({ type: 'corporate', costCenter: 'Marketing' }, 'c1', company, true)).toEqual({
      ok: false,
      error: 'billing/unknown-cost-center',
    });
  });

  it('enforces a required cost center', () => {
    const strict = { ...company, requireCostCenter: true };
    expect(resolveBilling({ type: 'corporate' }, 'c1', strict, true)).toEqual({ ok: false, error: 'billing/cost-center-required' });
    expect(resolveBilling({ type: 'bogus' }, 'c1', strict, true)).toEqual({ ok: false, error: 'billing/invalid-type' });
  });
});

describe('helpers', () => {
  it('normalizeEmail', () => {
    expect(normalizeEmail(' Ana@Mail.COM ')).toBe('ana@mail.com');
    expect(normalizeEmail('ana@mail')).toBeNull();
    expect(normalizeEmail(3)).toBeNull();
  });

  it('sanitizeCostCenters caps the list', () => {
    expect(sanitizeCostCenters(Array.from({ length: 80 }, (_, i) => `CC${i}`))).toHaveLength(50);
    expect(sanitizeCostCenters('x')).toEqual([]);
  });

  it('a company always keeps an admin', () => {
    expect(leavesAdmin(['a'], 'a', 'member')).toBe(false);
    expect(leavesAdmin(['a'], 'a', null)).toBe(false);
    expect(leavesAdmin(['a', 'b'], 'a', null)).toBe(true);
    expect(leavesAdmin([], 'x', 'admin')).toBe(true);
  });
});
