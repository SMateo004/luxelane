// Validación y plan de carga de tarifas (tools/pricing). Sin I/O: lo usan
// check.mjs, seed.mjs y los tests.

export const CLASSES = ['business', 'firstClass', 'businessVan', 'electric', 'businessSuv'];
export const SERVICES = ['oneWay', 'byTheHour'];
export const PRICE_FIELDS = ['basePriceUsd', 'pricePerKmUsd', 'pricePerHourUsd', 'minimumPriceUsd'];
export const FORBIDDEN_PROJECTS = ['luxelane-4e7ae'];

const isNum = (v) => typeof v === 'number' && Number.isFinite(v);

/**
 * Errores (bloquean la carga) y avisos de un archivo de tarifas. Mismas
 * reglas que PricingRule.validate en la app y que fare.ts en el servidor.
 */
export function validatePricing(doc) {
  const errors = [];
  const warnings = [];
  const missing = [];
  if (!doc || typeof doc !== 'object') return { errors: ['El archivo no es un objeto JSON'], warnings, missing };

  const rules = doc.pricingRules ?? {};
  if (typeof rules !== 'object') errors.push('pricingRules debe ser un objeto');
  for (const id of Object.keys(rules)) {
    const [vc, st, extra] = id.split('_');
    if (extra !== undefined || !CLASSES.includes(vc) || !SERVICES.includes(st)) {
      errors.push(`${id}: id desconocido (debe ser <clase>_<servicio>, p. ej. business_oneWay)`);
    }
  }
  for (const vc of CLASSES) {
    for (const st of SERVICES) {
      const id = `${vc}_${st}`;
      const r = rules[id];
      if (r === undefined) {
        missing.push(`${id} (sin tarifa: no se mostrará precio ni se podrá reservar)`);
        continue;
      }
      if (r.vehicleClass !== vc || r.serviceType !== st) {
        errors.push(`${id}: vehicleClass/serviceType deben ser "${vc}"/"${st}"`);
      }
      for (const f of [...PRICE_FIELDS, 'isActive']) {
        if (r[f] === 'REEMPLAZAR' || r[f] === undefined) missing.push(`${id}.${f}`);
      }
      for (const f of PRICE_FIELDS) {
        if (r[f] === 'REEMPLAZAR' || r[f] === undefined) continue;
        if (!isNum(r[f])) errors.push(`${id}.${f}: debe ser un número`);
        else if (r[f] < 0) errors.push(`${id}.${f}: no puede ser negativo`);
      }
      if (r.isActive !== 'REEMPLAZAR' && r.isActive !== undefined && typeof r.isActive !== 'boolean') {
        errors.push(`${id}.isActive: debe ser true o false`);
      }
      const nums = PRICE_FIELDS.every((f) => isNum(r[f]));
      if (nums && st === 'oneWay' && r.basePriceUsd === 0 && r.pricePerKmUsd === 0 && r.minimumPriceUsd === 0) {
        errors.push(`${id}: un traslado no puede costar Bs 0`);
      }
      if (nums && st === 'byTheHour' && r.pricePerHourUsd <= 0) {
        errors.push(`${id}: el servicio por horas necesita pricePerHourUsd > 0`);
      }
      if (nums && r.minimumPriceUsd <= 0) warnings.push(`${id}: minimumPriceUsd es 0`);
    }
  }

  const cfg = doc.config_pricing ?? {};
  if (cfg.routeFactor === undefined || cfg.routeFactor === 'REEMPLAZAR') {
    missing.push('config_pricing.routeFactor');
  } else if (!isNum(cfg.routeFactor) || cfg.routeFactor < 1) {
    errors.push('config_pricing.routeFactor: debe ser un número >= 1 (la ruta nunca es más corta que la recta)');
  } else if (cfg.routeFactor > 2) {
    warnings.push(`config_pricing.routeFactor ${cfg.routeFactor} es alto: revisa la calibración`);
  }
  for (const k of ['nightSurchargePct', 'nightStartHour', 'nightEndHour', 'fixedAirportFares']) {
    if (k in cfg) warnings.push(`config_pricing.${k}: recargo opcional presente (en el piloto está decidido apagado)`);
  }
  return { errors, warnings, missing };
}

/** Documentos a escribir (sin campos de comentario). */
export function seedPlan(doc) {
  const writes = [];
  for (const [id, r] of Object.entries(doc.pricingRules ?? {})) {
    const data = {};
    for (const [k, v] of Object.entries(r)) if (!k.startsWith('_')) data[k] = v;
    writes.push({ path: `pricingRules/${id}`, data });
  }
  const cfg = {};
  for (const [k, v] of Object.entries(doc.config_pricing ?? {})) if (!k.startsWith('_')) cfg[k] = v;
  if (Object.keys(cfg).length) writes.push({ path: 'config/pricing', data: cfg, merge: true });
  return writes;
}

/** Comprueba a qué proyecto se va a escribir; lanza si no se permite. */
export function assertTarget({ project, emulatorHost }) {
  if (!project) throw new Error('Falta --project <id>. No hay proyecto por defecto.');
  if (FORBIDDEN_PROJECTS.includes(project)) {
    throw new Error(`Este script no escribe nunca en ${project}. Carga las tarifas de producción desde el panel admin o con el responsable.`);
  }
  if (project.startsWith('demo-') && !emulatorHost) {
    throw new Error('Un proyecto demo-* solo existe en el emulador: define FIRESTORE_EMULATOR_HOST.');
  }
}
