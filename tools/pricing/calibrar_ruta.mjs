#!/usr/bin/env node
/*
 * Calibra routeFactor a partir de trayectos reales medidos por calle.
 *   node calibrar_ruta.mjs <archivo.csv>
 * CSV con cabecera: origen_lat,origen_lng,destino_lat,destino_lng,km_reales_por_calle
 * No llama a ninguna API: compara cada km real con la línea recta.
 */
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';

export function straightKm(lat1, lng1, lat2, lng2) {
  const rad = (d) => (d * Math.PI) / 180;
  const a = Math.sin(rad(lat2 - lat1) / 2) ** 2 +
    Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(rad(lng2 - lng1) / 2) ** 2;
  return 2 * 6371 * Math.asin(Math.sqrt(a));
}

/** Percentil p (0–100) por interpolación lineal sobre valores ordenados. */
export function percentile(sorted, p) {
  if (!sorted.length) return NaN;
  const pos = ((sorted.length - 1) * p) / 100;
  const lo = Math.floor(pos);
  const hi = Math.ceil(pos);
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
}

export function calibrate(csv) {
  // [número de línea en el archivo, contenido], sin vacías ni comentarios.
  const lines = csv.split(/\r?\n/)
    .map((l, i) => [i + 1, l.trim()])
    .filter(([, l]) => l && !l.startsWith('#'));
  const header = lines.shift()?.[1].split(',').map((h) => h.trim());
  const cols = ['origen_lat', 'origen_lng', 'destino_lat', 'destino_lng', 'km_reales_por_calle'];
  if (!header || cols.some((c, i) => header[i] !== c)) {
    throw new Error(`La cabecera debe ser: ${cols.join(',')}`);
  }
  const rows = [];
  const skipped = [];
  lines.forEach(([lineNo, line]) => {
    const v = line.split(',').map(Number);
    const straight = straightKm(v[0], v[1], v[2], v[3]);
    if (v.length !== 5 || v.some((x) => !Number.isFinite(x)) || straight < 0.5 || v[4] <= 0) {
      skipped.push(lineNo);
      return;
    }
    rows.push({ line: lineNo, straight, real: v[4], ratio: v[4] / straight });
  });
  const ratios = rows.map((r) => r.ratio).sort((a, b) => a - b);
  const median = percentile(ratios, 50);
  const p90 = percentile(ratios, 90);
  return {
    rows,
    skipped,
    median,
    p90,
    // Conservador: con el p90 la línea recta × factor rara vez queda por
    // debajo de la distancia real, así que el respaldo casi nunca cobra de
    // menos. Redondeado hacia arriba a 2 decimales.
    suggestedRouteFactor: Number.isFinite(p90) ? Math.ceil(p90 * 100) / 100 : NaN,
  };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const file = process.argv[2];
  if (!file) {
    console.error('Uso: node calibrar_ruta.mjs <archivo.csv>');
    process.exit(2);
  }
  const r = calibrate(readFileSync(file, 'utf8'));
  for (const row of r.rows) {
    console.log(`línea ${row.line}: recta ${row.straight.toFixed(2)} km, calle ${row.real} km, razón ${row.ratio.toFixed(3)}`);
  }
  if (r.skipped.length) console.log(`Ignoradas (datos inválidos o trayecto < 0,5 km): líneas ${r.skipped.join(', ')}`);
  console.log(`\nFilas usadas: ${r.rows.length}`);
  console.log(`Mediana calle/recta: ${r.median.toFixed(3)}`);
  console.log(`Percentil 90:        ${r.p90.toFixed(3)}`);
  console.log(`routeFactor sugerido (p90, redondeado hacia arriba): ${r.suggestedRouteFactor}`);
  if (r.rows.length < 20) console.log('Aviso: con menos de 20 trayectos la estimación es poco fiable.');
}
