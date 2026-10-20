import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'fs';
import { assertTarget, CLASSES, SERVICES, seedPlan, validatePricing } from './pricing_lib.mjs';
import { calibrate, percentile } from './calibrar_ruta.mjs';

const example = JSON.parse(readFileSync(new URL('./pricing.seed.example.json', import.meta.url), 'utf8'));

// Tarifas de prueba (no son las de negocio).
function filled() {
  const doc = structuredClone(example);
  for (const r of Object.values(doc.pricingRules)) {
    Object.assign(r, { basePriceUsd: 10, pricePerKmUsd: 1, pricePerHourUsd: 5, minimumPriceUsd: 20, isActive: true });
  }
  doc.config_pricing.routeFactor = 1.3;
  return doc;
}

test('la plantilla no tiene ningún valor real: todo es REEMPLAZAR', () => {
  for (const r of Object.values(example.pricingRules)) {
    for (const f of ['basePriceUsd', 'pricePerKmUsd', 'pricePerHourUsd', 'minimumPriceUsd', 'isActive']) {
      assert.equal(r[f], 'REEMPLAZAR');
    }
  }
  assert.equal(example.config_pricing.routeFactor, 'REEMPLAZAR');
  assert.equal(Object.keys(example.pricingRules).length, CLASSES.length * SERVICES.length);
});

test('pricing:check lista todo lo que falta en la plantilla', () => {
  const { errors, missing } = validatePricing(example);
  assert.deepEqual(errors, []);
  assert.equal(missing.length, CLASSES.length * SERVICES.length * 5 + 1);
  assert.ok(missing.includes('config_pricing.routeFactor'));
});

test('pricing:check acepta un archivo completo y válido', () => {
  const r = validatePricing(filled());
  assert.deepEqual([r.errors, r.missing], [[], []]);
});

test('pricing:check rechaza tipos, rangos e ids inválidos', () => {
  const doc = filled();
  doc.pricingRules.business_oneWay.basePriceUsd = '50';
  doc.pricingRules.business_byTheHour.pricePerHourUsd = 0;
  doc.pricingRules.electric_oneWay.minimumPriceUsd = -1;
  doc.pricingRules.limusina_oneWay = { vehicleClass: 'limusina', serviceType: 'oneWay' };
  doc.config_pricing.routeFactor = 0.9;
  const { errors } = validatePricing(doc);
  assert.ok(errors.some((e) => e.startsWith('business_oneWay.basePriceUsd: debe ser un número')));
  assert.ok(errors.some((e) => e.startsWith('business_byTheHour: el servicio por horas')));
  assert.ok(errors.some((e) => e.startsWith('electric_oneWay.minimumPriceUsd: no puede ser negativo')));
  assert.ok(errors.some((e) => e.startsWith('limusina_oneWay: id desconocido')));
  assert.ok(errors.some((e) => e.startsWith('config_pricing.routeFactor')));
});

test('una combinación borrada se lista como faltante (no se venderá)', () => {
  const doc = filled();
  delete doc.pricingRules.firstClass_byTheHour;
  assert.ok(validatePricing(doc).missing[0].startsWith('firstClass_byTheHour'));
});

test('pricing:seed se niega con el proyecto real y exige proyecto explícito', () => {
  assert.throws(() => assertTarget({ project: 'luxelane-4e7ae' }), /no escribe nunca en luxelane-4e7ae/);
  assert.throws(() => assertTarget({ project: null }), /Falta --project/);
  assert.throws(() => assertTarget({ project: 'demo-luxelane' }), /emulador/);
  assert.doesNotThrow(() => assertTarget({ project: 'demo-luxelane', emulatorHost: '127.0.0.1:8080' }));
  assert.doesNotThrow(() => assertTarget({ project: 'mi-staging' }));
});

test('el plan de carga no escribe los comentarios', () => {
  const plan = seedPlan(filled());
  assert.equal(plan.length, CLASSES.length * SERVICES.length + 1);
  for (const w of plan) assert.ok(!Object.keys(w.data).some((k) => k.startsWith('_')));
  assert.deepEqual(plan.at(-1), { path: 'config/pricing', data: { routeFactor: 1.3 }, merge: true });
});

test('percentil con interpolación', () => {
  assert.equal(percentile([1, 2, 3, 4, 5], 50), 3);
  assert.ok(Math.abs(percentile([1, 2, 3, 4, 5], 90) - 4.6) < 1e-9);
});

test('calibrar_ruta: razón calle/recta, mediana, p90 y factor sugerido con el CSV ficticio', () => {
  const r = calibrate(readFileSync(new URL('./ejemplo_rutas.csv', import.meta.url), 'utf8'));
  assert.equal(r.rows.length, 6);
  assert.deepEqual(r.skipped, [9]); // línea 9 del archivo: el trayecto de 0 km
  for (const row of r.rows) assert.ok(row.ratio > 1 && row.ratio < 2);
  assert.ok(r.median <= r.p90);
  assert.equal(r.suggestedRouteFactor, Math.ceil(r.p90 * 100) / 100);
});

test('calibrar_ruta exige la cabecera esperada', () => {
  assert.throws(() => calibrate('a,b,c\n1,2,3'), /cabecera/);
});
