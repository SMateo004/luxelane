/**
 * Tipo real de un archivo por sus primeros bytes (registro de chóferes, A3):
 * no se confía en la extensión ni en el contentType que declara quien sube.
 * Solo reconoce lo que admite el registro: JPEG, PNG, WebP y PDF.
 *
 * NO es un antivirus ni un análisis de contenido: un PDF o una imagen con
 * cabecera válida pero contenido malicioso pasa esta comprobación.
 */
export type SniffedType = 'image/jpeg' | 'image/png' | 'image/webp' | 'application/pdf';

/** Bytes que hacen falta para decidir. */
export const SNIFF_BYTES = 16;

const startsWith = (b: Uint8Array, sig: number[], at = 0) =>
  b.length >= at + sig.length && sig.every((v, i) => b[at + i] === v);

export function sniffType(head: Uint8Array): SniffedType | null {
  if (startsWith(head, [0xff, 0xd8, 0xff])) return 'image/jpeg';
  if (startsWith(head, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) return 'image/png';
  // RIFF....WEBP
  if (startsWith(head, [0x52, 0x49, 0x46, 0x46]) && startsWith(head, [0x57, 0x45, 0x42, 0x50], 8)) return 'image/webp';
  // %PDF-
  if (startsWith(head, [0x25, 0x50, 0x44, 0x46, 0x2d])) return 'application/pdf';
  return null;
}
