import { describe, it, expect } from '@jest/globals';
import { readFileSync } from 'fs';
import { join } from 'path';
import { parseOperator } from './pricing_updated_by';

const SCRIPT = readFileSync(join(__dirname, '../../scripts/migrate-pricing-updated-by.js'), 'utf8');

describe('migración de updatedBy en pricingRules (C3)', () => {
  it('exige --operator para la auditoría', () => {
    expect(parseOperator(['--operator', 'Responsable'])).toBe('Responsable');
    expect(() => parseOperator([])).toThrow('--operator');
    expect(() => parseOperator(['--operator', '--apply'])).toThrow('--operator');
  });

  it('el script pasa por la guarda de producción y escribe solo con --apply', () => {
    expect(SCRIPT).toContain('checkTarget(argv, process.env.FIRESTORE_EMULATOR_HOST)');
    expect(SCRIPT).toContain('removePricingUpdatedBy(admin.firestore(), apply, operator)');
    expect(SCRIPT).not.toMatch(/projectId:\s*'/);
  });
});
