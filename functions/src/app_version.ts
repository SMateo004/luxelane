/**
 * Versión mínima de la app para cotizar y reservar (config/global.minAppVersion).
 * Si el mínimo está activo y la app no manda versión o manda una menor, el
 * servidor responde app_update_required.
 */

const SEMVER = /^(\d+)\.(\d+)\.(\d+)(?:[+-].*)?$/;

/** a < b → negativo; iguales → 0; null si alguna no es x.y.z. */
export function compareVersions(a: string, b: string): number | null {
  const pa = SEMVER.exec(a.trim());
  const pb = SEMVER.exec(b.trim());
  if (!pa || !pb) return null;
  for (let i = 1; i <= 3; i++) {
    const d = Number(pa[i]) - Number(pb[i]);
    if (d !== 0) return d;
  }
  return 0;
}

const storeUrl = (v: unknown) => (typeof v === 'string' && v.startsWith('https://') ? v : undefined);

/** Enlaces a las tiendas de config/global, para el aviso «Actualiza la app». */
export function storeLinks(global: Record<string, unknown>): { androidStoreUrl?: string; iosStoreUrl?: string } {
  return { androidStoreUrl: storeUrl(global.androidStoreUrl), iosStoreUrl: storeUrl(global.iosStoreUrl) };
}

/**
 * Si hace falta actualizar, los enlaces a las tiendas (config/global) para
 * que la app los muestre; si no, null. Un mínimo mal escrito no bloquea.
 */
export function updateRequired(
  global: Record<string, unknown>,
  appVersion: unknown,
  // La app del chófer tiene su propio mínimo (minDriverAppVersion).
  key: 'minAppVersion' | 'minDriverAppVersion' = 'minAppVersion',
): { minAppVersion: string; androidStoreUrl?: string; iosStoreUrl?: string } | null {
  const min = global[key];
  if (typeof min !== 'string' || compareVersions(min, min) === null) return null;
  const cmp = typeof appVersion === 'string' ? compareVersions(appVersion, min) : null;
  if (cmp !== null && cmp >= 0) return null;
  return { minAppVersion: min, ...storeLinks(global) };
}
