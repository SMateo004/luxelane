type LogLevel = 'info' | 'warn' | 'error';

interface LogEntry {
  level: LogLevel;
  fn: string;
  message: string;
  data?: unknown;
  timestamp: string;
}

export const REDACTED = '[redacted]';

/**
 * Campos que nunca se registran, por nombre: contacto, credenciales, el
 * código de recogida y la ubicación.
 */
const SENSITIVE_KEY = new RegExp(
  '^(e-?mail|phone(number)?|tel|whatsapp|password|secret|client_?secret|' +
  '(fcm|id|access|refresh|app_?check)?_?tokens?|authorization|api_?key|' +
  'code|pickup_?code|lat|lng|lon|latitude|longitude|location|last_?location|' +
  'coords?|address|card(_?number)?|pan|cvc)$', 'i');

/** Algoritmo de Luhn: distingue una tarjeta de un número largo cualquiera. */
function luhn(digits: string): boolean {
  let sum = 0;
  for (let i = 0; i < digits.length; i++) {
    let d = Number(digits[digits.length - 1 - i]);
    if (i % 2 === 1) d = d * 2 > 9 ? d * 2 - 9 : d * 2;
    sum += d;
  }
  return sum % 10 === 0;
}

/** Lo que se tacha dentro de cualquier texto (mensajes de error incluidos). */
const PATTERNS: [RegExp, string | ((m: string) => string)][] = [
  // Claves de Stripe y de Google.
  [/\b(sk|pk|rk)_(live|test)_[A-Za-z0-9]+/g, '[stripe-key]'],
  [/\bwhsec_[A-Za-z0-9]+/g, '[stripe-key]'],
  [/\bAIza[0-9A-Za-z_-]{20,}/g, '[api-key]'],
  // Secreto de cliente de un intent y JWT (tokens de Firebase y App Check).
  [/\b(pi|seti)_[A-Za-z0-9]+_secret_[A-Za-z0-9]+/g, '[client-secret]'],
  [/\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g, '[token]'],
  [/\bBearer\s+[A-Za-z0-9._~+/=-]+/gi, 'Bearer [token]'],
  [/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, '[email]'],
  // Pares de coordenadas con decimales («-17.7834, -63.1821»).
  [/-?\d{1,3}\.\d{3,}\s*[,;/ ]\s*-?\d{1,3}\.\d{3,}/g, '[coords]'],
  // Tarjetas: 13 a 19 cifras (con espacios o guiones) que pasan Luhn.
  [/\b\d(?:[ -]?\d){12,18}\b/g, (m) => (luhn(m.replace(/\D/g, '')) ? '[card]' : m)],
  // Teléfonos con prefijo internacional.
  [/\+\d[\d ().-]{6,18}\d/g, '[phone]'],
];

export function redactText(s: string): string {
  return PATTERNS.reduce(
    (acc, [re, by]) => (typeof by === 'string' ? acc.replace(re, by) : acc.replace(re, by)),
    s,
  );
}

/** Copia de `value` sin datos personales ni secretos. */
export function redact(value: unknown, depth = 0): unknown {
  if (typeof value === 'string') return redactText(value);
  if (value instanceof Error) return redactText(`${value.name}: ${value.message}`);
  if (value === null || typeof value !== 'object') return value;
  if (depth > 6) return '[…]';
  if (Array.isArray(value)) return value.map((v) => redact(v, depth + 1));
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(value)) {
    out[k] = SENSITIVE_KEY.test(k) ? REDACTED : redact(v, depth + 1);
  }
  return out;
}

function log(level: LogLevel, fn: string, message: string, data?: unknown): void {
  const entry: LogEntry = {
    level,
    fn,
    message: redactText(message),
    timestamp: new Date().toISOString(),
    ...(data !== undefined && { data: redact(data) }),
  };
  if (level === 'error') {
    console.error(JSON.stringify(entry));
  } else if (level === 'warn') {
    console.warn(JSON.stringify(entry));
  } else {
    console.log(JSON.stringify(entry));
  }
}

export const logger = {
  info: (fn: string, message: string, data?: unknown) => log('info', fn, message, data),
  warn: (fn: string, message: string, data?: unknown) => log('warn', fn, message, data),
  error: (fn: string, message: string, data?: unknown) => log('error', fn, message, data),
};
