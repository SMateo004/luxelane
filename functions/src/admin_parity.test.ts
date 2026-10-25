/**
 * Lo que el panel ofrece y lo que admite el servidor (Parte A) no deben
 * separarse: estas pruebas leen el código del panel.
 */
import { describe, it, expect } from '@jest/globals';
import { readFileSync } from 'fs';
import { join } from 'path';
import { MANUAL_METHODS } from './admin_ops';

const lib = join(__dirname, '..', '..', 'lib');
const read = (p: string) => readFileSync(join(lib, p), 'utf8');

describe('paridad panel ↔ servidor', () => {
  it('métodos de cobro manual', () => {
    const src = read('features/admin/presentation/widgets/admin_finance_tab.dart');
    const start = src.indexOf('const kManualPaymentMethods = {');
    expect(start).toBeGreaterThanOrEqual(0);
    const block = src.slice(start, src.indexOf('};', start));
    const keys = [...block.matchAll(/'([a-z_]+)':/g)].map((m) => m[1]).sort();
    expect(keys).toEqual([...MANUAL_METHODS].sort());
  });
});
