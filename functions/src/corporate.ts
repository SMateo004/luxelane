// Corporate accounts: validation and billing rules, kept pure so they can be
// unit-tested without Firestore.

export type CompanyRole = 'admin' | 'member';

export interface CompanyDoc {
  name: string;
  taxId: string;
  billingEmail: string;
  active: boolean;
  costCenters: string[];
  requireCostCenter: boolean;
}

export interface CompanyInput {
  name?: unknown;
  taxId?: unknown;
  billingEmail?: unknown;
  costCenters?: unknown;
  requireCostCenter?: unknown;
}

export interface BillingInput {
  type?: unknown;
  costCenter?: unknown;
  reference?: unknown;
}

export interface CorporateBilling {
  companyId: string;
  companyName: string;
  costCenter: string | null;
  billingReference: string | null;
}

export const MAX_COST_CENTERS = 50;

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function normalizeEmail(v: unknown): string | null {
  if (typeof v !== 'string') return null;
  const e = v.trim().toLowerCase();
  return EMAIL.test(e) && e.length <= 254 ? e : null;
}

export function isCompanyRole(v: unknown): v is CompanyRole {
  return v === 'admin' || v === 'member';
}

function cleanText(v: unknown, max: number): string {
  return typeof v === 'string' ? v.replace(/\s+/g, ' ').trim().slice(0, max) : '';
}

/** Trimmed, de-duplicated (case-insensitive), at most [MAX_COST_CENTERS]. */
export function sanitizeCostCenters(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  const seen = new Set<string>();
  const out: string[] = [];
  for (const raw of v) {
    const c = cleanText(raw, 40);
    if (!c || seen.has(c.toLowerCase())) continue;
    seen.add(c.toLowerCase());
    out.push(c);
    if (out.length >= MAX_COST_CENTERS) break;
  }
  return out;
}

/**
 * Validates the fields of a new company (all required) or an update
 * (only the given ones). Returns the cleaned fields or an error code.
 */
export function validateCompany(
  input: CompanyInput,
  partial: boolean,
): { ok: true; value: Partial<CompanyDoc> } | { ok: false; error: string } {
  const value: Partial<CompanyDoc> = {};

  if (!partial || input.name !== undefined) {
    const name = cleanText(input.name, 80);
    if (name.length < 2) return { ok: false, error: 'company/invalid-name' };
    value.name = name;
  }
  if (!partial || input.taxId !== undefined) {
    // Bolivian NIT: digits only, 5–15 long.
    const taxId = typeof input.taxId === 'string' ? input.taxId.replace(/[\s.-]/g, '') : '';
    if (!/^\d{5,15}$/.test(taxId)) return { ok: false, error: 'company/invalid-tax-id' };
    value.taxId = taxId;
  }
  if (!partial || input.billingEmail !== undefined) {
    const email = normalizeEmail(input.billingEmail);
    if (!email) return { ok: false, error: 'company/invalid-email' };
    value.billingEmail = email;
  }
  if (!partial || input.costCenters !== undefined) {
    value.costCenters = sanitizeCostCenters(input.costCenters);
  }
  if (!partial || input.requireCostCenter !== undefined) {
    value.requireCostCenter = input.requireCostCenter === true;
  }
  if (value.requireCostCenter && value.costCenters && value.costCenters.length === 0) {
    return { ok: false, error: 'company/cost-center-required-without-list' };
  }
  return { ok: true, value };
}

/**
 * Decides how a booking is billed. Personal bookings return null; corporate
 * ones need an active company the rider belongs to and, when the company
 * asks for it, one of its cost centers.
 */
export function resolveBilling(
  input: BillingInput | undefined,
  companyId: string | null | undefined,
  company: CompanyDoc | null,
  isMember: boolean,
): { ok: true; value: CorporateBilling | null } | { ok: false; error: string } {
  if (!input || input.type === undefined || input.type === 'personal') return { ok: true, value: null };
  if (input.type !== 'corporate') return { ok: false, error: 'billing/invalid-type' };
  if (!companyId || !company || !isMember) return { ok: false, error: 'billing/not-a-member' };
  if (!company.active) return { ok: false, error: 'billing/company-inactive' };

  const wanted = cleanText(input.costCenter, 40);
  let costCenter: string | null = null;
  if (wanted) {
    costCenter = company.costCenters.find((c) => c.toLowerCase() === wanted.toLowerCase()) ?? null;
    if (!costCenter) return { ok: false, error: 'billing/unknown-cost-center' };
  } else if (company.requireCostCenter) {
    return { ok: false, error: 'billing/cost-center-required' };
  }

  const reference = cleanText(input.reference, 60);
  return {
    ok: true,
    value: {
      companyId,
      companyName: company.name,
      costCenter,
      billingReference: reference || null,
    },
  };
}

/** A company must always keep at least one admin. */
export function leavesAdmin(adminUids: string[], changingUid: string, newRole: CompanyRole | null): boolean {
  if (newRole === 'admin') return true;
  return adminUids.some((u) => u !== changingUid);
}
