/**
 * Catálogo de textos del servidor (idiomas, A4 y A7): paridad de claves y
 * marcadores entre es, en y pt, t() estricto con los marcadores, importes
 * que no cambian de sentido y ningún aviso con texto fijo.
 */
import { describe, it, expect } from '@jest/globals';
import { readdirSync, readFileSync } from 'fs';
import { join } from 'path';
import * as ts from 'typescript';
import {
  APP_LOCALES, formatMoney, localeOf, MESSAGES, MessageKey, notice, NOTICES, placeholdersOf, t, vehicleClassName,
} from './i18n';

describe('catálogo', () => {
  it('cada clave tiene es, en y pt, sin textos vacíos', () => {
    const problems: string[] = [];
    for (const [key, texts] of Object.entries(MESSAGES)) {
      for (const l of APP_LOCALES) {
        const v = (texts as Record<string, string>)[l];
        if (typeof v !== 'string' || !v.trim()) problems.push(`${key}: falta ${l}`);
      }
      if (Object.keys(texts).length !== APP_LOCALES.length) problems.push(`${key}: idiomas de más`);
    }
    expect(problems).toEqual([]);
  });

  it('los marcadores son los mismos en los tres idiomas', () => {
    const problems: string[] = [];
    for (const [key, texts] of Object.entries(MESSAGES)) {
      const es = placeholdersOf(texts.es).join(',');
      for (const l of ['en', 'pt'] as const) {
        const other = placeholdersOf(texts[l]).join(',');
        if (other !== es) problems.push(`${key}: ${l} {${other}} ≠ es {${es}}`);
      }
    }
    expect(problems).toEqual([]);
  });

  it('cada aviso apunta a claves que existen, con título y cuerpo', () => {
    for (const [type, [title, body]] of Object.entries(NOTICES)) {
      expect([type, title in MESSAGES, body in MESSAGES]).toEqual([type, true, true]);
    }
  });

  it('lista de avisos del servidor (si cambia, actualiza docs/GLOSARIO_IDIOMAS.md)', () => {
    expect(Object.keys(NOTICES).sort()).toEqual([
      'booking_cancelled', 'booking_cancelled_by_rider', 'booking_confirmed', 'booking_driver_released',
      'driver_arrived', 'driver_arriving', 'driver_assigned', 'incident_cancel_requested', 'incident_raised',
      'incident_unacknowledged', 'new_trip_available', 'payment_confirmed', 'payment_confirmed_cancelled',
      'payment_expired', 'payment_receipt', 'payment_rejected', 'refund_recorded', 'ride_completed',
      'ride_started', 'rider_no_show', 'trip_cancelled_by_rider',
    ]);
  });
});

describe('t()', () => {
  it('sustituye los marcadores en el idioma pedido', () => {
    expect(t('incident_raised.body', 'en', { ref: 'ABC123' }))
      .toBe('Booking #ABC123: open the dashboard and acknowledge the incident.');
    expect(notice('payment_receipt', 'pt', { amount: 'Bs 86' }).body).toBe('Foram cobrados Bs 86 pela sua viagem.');
  });

  it('falla si falta o sobra un marcador', () => {
    expect(() => t('incident_raised.body', 'es')).toThrow('espera {ref}');
    expect(() => t('incident_raised.body', 'es', { ref: 'A', extra: 'x' })).toThrow();
    expect(() => t('ride_started.title', 'es', { ref: 'A' })).toThrow();
    expect(() => notice('new_trip_available', 'es', { vehicleClass: 'Business Class' })).toThrow();
  });

  it('sin users.locale o con uno no soportado: español', () => {
    expect(localeOf(undefined)).toBe('es');
    expect(localeOf({})).toBe('es');
    expect(localeOf({ locale: 'fr' })).toBe('es');
    expect(localeOf({ locale: 'pt' })).toBe('pt');
    expect(notice('ride_started', localeOf({ locale: 'de' })).title).toBe('Viaje iniciado');
  });

  it('clase del vehículo en el idioma; desconocida, el nombre de la marca', () => {
    expect(vehicleClassName('electric', 'pt')).toBe('Elétrico');
    expect(vehicleClassName('nada', 'en')).toBe('Luxelane');
  });
});

describe('importes (decisión 5)', () => {
  it('siempre «Bs» delante; separadores según el idioma', () => {
    expect(formatMoney(1234.5, 'es')).toBe('Bs 1.234,50');
    expect(formatMoney(1234.5, 'pt')).toBe('Bs 1.234,50');
    expect(formatMoney(1234.5, 'en')).toBe('Bs 1,234.50');
    expect(formatMoney(86, 'en')).toBe('Bs 86');
    expect(formatMoney(-0.5, 'es')).toBe('-Bs 0,50');
  });

  it('«1.234,50» no se lee distinto en inglés: cada idioma vuelve a la misma cifra', () => {
    const read = (s: string, decimal: string) =>
      Number(s.replace(/^-?Bs /, '').split(decimal === ',' ? '.' : ',').join('').replace(decimal, '.'));
    for (const v of [1234.5, 1_000_000, 0.05, 999.99]) {
      expect(read(formatMoney(v, 'es'), ',')).toBeCloseTo(v);
      expect(read(formatMoney(v, 'pt'), ',')).toBeCloseTo(v);
      expect(read(formatMoney(v, 'en'), '.')).toBeCloseTo(v);
    }
    // Lo que se evita: la forma española leída como inglesa sería 1,2345.
    expect(Number('1.234,50'.replace(',', ''))).not.toBeCloseTo(1234.5);
  });
});

describe('ningún aviso usa texto fijo', () => {
  const dir = __dirname;
  const files = readdirSync(dir).filter((f) => f.endsWith('.ts') && !f.endsWith('.test.ts') && f !== 'i18n.ts');
  const isText = (n: ts.Node) =>
    ts.isStringLiteral(n) || ts.isNoSubstitutionTemplateLiteral(n) || ts.isTemplateExpression(n);
  const SENDERS: Record<string, number[]> = { sendPush: [1, 2], push: [1, 2] };

  function problemsIn(file: string, src: string): string[] {
    const out: string[] = [];
    const sf = ts.createSourceFile(file, src, ts.ScriptTarget.Latest, true);
    const visit = (n: ts.Node) => {
      if (ts.isCallExpression(n)) {
        const callee = n.expression;
        const name = ts.isIdentifier(callee) ? callee.text
          : ts.isPropertyAccessExpression(callee) ? callee.name.text : '';
        for (const i of Object.prototype.hasOwnProperty.call(SENDERS, name) ? SENDERS[name] : []) {
          const a = n.arguments[i];
          if (a && isText(a)) out.push(`${file}: ${name}() con texto fijo: ${a.getText(sf).slice(0, 60)}`);
        }
      }
      // Avisos escritos a mano: { title: '…', body: '…' }.
      if (ts.isObjectLiteralExpression(n)) {
        const props = new Map(n.properties.filter(ts.isPropertyAssignment)
          .map((p) => [p.name.getText(sf), p.initializer]));
        const title = props.get('title');
        const body = props.get('body');
        if (title && body && (isText(title) || isText(body))) out.push(`${file}: aviso con texto fijo`);
      }
      ts.forEachChild(n, visit);
    };
    visit(sf);
    return out;
  }

  it('sendPush, push y los avisos de la bandeja solo reciben textos del catálogo', () => {
    const problems = files.flatMap((f) => problemsIn(f, readFileSync(join(dir, f), 'utf8')));
    expect(problems).toEqual([]);
  });

  it('la comprobación detecta un aviso con texto fijo', () => {
    expect(problemsIn('x.ts', "await sendPush(tokens, 'Viaje iniciado', 'Tu trayecto ha comenzado.');")).toHaveLength(2);
    expect(problemsIn('x.ts', "tx.set(ref, { title: 'Hola', body: `Adiós ${x}` });")).toHaveLength(1);
    expect(problemsIn('x.ts', "await sendPush(tokens, n.title, n.body);")).toEqual([]);
  });

  it('las claves usadas existen (MessageKey es un tipo cerrado)', () => {
    const k: MessageKey = 'ride_started.title';
    expect(MESSAGES[k].en).toBe('Trip started');
  });
});
