/**
 * Las claves de config/global del SOS: bien escritas en el código, iguales
 * en DEPLOY.md y sin variantes mal escritas en el repositorio.
 */
import { describe, it, expect } from '@jest/globals';
import { readFileSync, readdirSync, statSync } from 'fs';
import { join } from 'path';
import { DEFAULT_ACK_SECONDS, DEFAULT_ESCALATE_EVERY_SECONDS, INCIDENT_CONFIG_KEYS } from './incidents';

const root = join(__dirname, '..', '..');

function files(dir: string, out: string[] = []): string[] {
  for (const name of readdirSync(dir)) {
    if (['node_modules', '.git', 'build', 'lib', '.dart_tool'].includes(name)) continue;
    const p = join(dir, name);
    if (statSync(p).isDirectory()) files(p, out);
    else if (/\.(ts|dart|md|json)$/.test(name)) out.push(p);
  }
  return out;
}

describe('claves de configuración del SOS', () => {
  it('están escritas exactamente así', () => {
    expect(INCIDENT_CONFIG_KEYS).toEqual({
      ackSeconds: 'incidentAckSeconds',
      escalateEverySeconds: 'incidentEscalateEverySeconds',
      locationRetentionDays: 'incidentLocationRetentionDays',
    });
    expect([DEFAULT_ACK_SECONDS, DEFAULT_ESCALATE_EVERY_SECONDS]).toEqual([120, 120]);
  });

  it('DEPLOY.md documenta las mismas claves', () => {
    const deploy = readFileSync(join(root, 'DEPLOY.md'), 'utf8');
    for (const key of Object.values(INCIDENT_CONFIG_KEYS)) expect(deploy).toMatch(new RegExp(`[.\`]${key}\``));
  });

  it('ninguna variante mal escrita en el repositorio', () => {
    const bad = /incident(Encalate|Escalte|Esclate|Escalate(?!EverySeconds)\w*Seconds)/;
    const hits = [...files(join(root, 'functions', 'src')), ...files(join(root, 'lib')), join(root, 'DEPLOY.md'),
      join(root, 'docs', 'AUDITORIA_LUXLANE.md')]
      .filter((p) => bad.test(readFileSync(p, 'utf8')));
    expect(hits).toEqual([]);
  });
});
