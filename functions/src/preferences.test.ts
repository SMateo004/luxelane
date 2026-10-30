/**
 * Preferencias del pasajero (A1, A7): listas cerradas, nota saneada y URL
 * de la lista solo https y de un host de config/ops.playlistHosts.
 */
import { describe, it, expect } from '@jest/globals';
import { HttpsError } from 'firebase-functions/v2/https';
import {
  cleanNote, EMPTY_PREFERENCES, legacyPreferences, parsePreferences, playlistHostsOf, profilePreferences,
  validPlaylistUrl,
} from './preferences';

const HOSTS = ['music.example.com'];

function rejected(data: unknown, hosts: string[] = HOSTS): { reason: string; fields: string[] } {
  try {
    parsePreferences(data, hosts);
  } catch (e) {
    const d = (e as HttpsError).details as { reason: string; fields: string[] };
    return { reason: d.reason, fields: d.fields };
  }
  throw new Error('se esperaba un rechazo');
}

describe('parsePreferences', () => {
  it('entrada válida: saneada, listas en orden fijo y sin duplicados', () => {
    expect(parsePreferences({
      preferredDriverLanguages: ['pt', 'es'], cabinTemperature: 'cool', conversation: 'quiet',
      musicStyle: 'jazz', playlistUrl: 'https://music.example.com/list/1', needs: ['child_seat', 'extra_luggage'],
      note: '  Llevo  un carrito  ',
    }, HOSTS)).toEqual({
      preferredDriverLanguages: ['es', 'pt'], cabinTemperature: 'cool', conversation: 'quiet',
      musicStyle: 'jazz', playlistUrl: 'https://music.example.com/list/1', needs: ['extra_luggage', 'child_seat'],
      note: 'Llevo un carrito',
    });
  });

  it('vacía: todo sin preferencia', () => {
    expect(parsePreferences({}, HOSTS)).toEqual(EMPTY_PREFERENCES);
  });

  it('campo extra: rechazado', () => {
    expect(rejected({ conversation: 'quiet', phone: '+59170000000' }).reason).toBe('invalid_request');
  });

  it('valor fuera de la lista: rechazado con el campo', () => {
    expect(rejected({ preferredDriverLanguages: ['fr'] }).fields).toEqual(['preferredDriverLanguages']);
    expect(rejected({ cabinTemperature: 'warm' }).fields).toEqual(['cabinTemperature']);
    expect(rejected({ conversation: 'loud' }).fields).toEqual(['conversation']);
    expect(rejected({ musicStyle: 'reggaeton' }).fields).toEqual(['musicStyle']);
    expect(rejected({ needs: ['valet'] }).fields).toEqual(['needs']);
    expect(rejected({ needs: ['child_seat', 'child_seat'] }).fields).toEqual(['needs']);
  });

  it('URL que no es https: rechazada', () => {
    for (const u of ['http://music.example.com/l', 'javascript:alert(1)', 'ftp://music.example.com/l', 'music.example.com/l']) {
      expect(rejected({ playlistUrl: u })).toEqual({ reason: 'playlist_not_allowed', fields: ['playlistUrl'] });
    }
  });

  it('host fuera de la lista (y parecidos): rechazado', () => {
    for (const u of ['https://otro.example.com/l', 'https://music.example.com.evil.test/l',
      'https://evil.test/music.example.com', 'https://sub.music.example.com/l']) {
      expect(rejected({ playlistUrl: u }).reason).toBe('playlist_not_allowed');
    }
  });

  it('URL con credenciales o puerto: rechazada', () => {
    expect(rejected({ playlistUrl: 'https://user:clave@music.example.com/l' }).reason).toBe('playlist_not_allowed');
    expect(rejected({ playlistUrl: 'https://user@music.example.com/l' }).reason).toBe('playlist_not_allowed');
    expect(rejected({ playlistUrl: 'https://music.example.com:8443/l' }).reason).toBe('playlist_not_allowed');
  });

  it('sin config/ops.playlistHosts (o vacía): cualquier URL se rechaza', () => {
    expect(rejected({ playlistUrl: 'https://music.example.com/l' }, []).reason).toBe('playlist_not_allowed');
  });

  it('URL demasiado larga: rechazada', () => {
    expect(rejected({ playlistUrl: `https://music.example.com/${'a'.repeat(300)}` }).fields).toEqual(['playlistUrl']);
  });

  it('nota de más de 200 caracteres: rechazada; de 200 justos, aceptada', () => {
    expect(rejected({ note: 'a'.repeat(201) }).fields).toEqual(['note']);
    expect(parsePreferences({ note: 'a'.repeat(200) }, HOSTS).note).toHaveLength(200);
  });

  it('nota con enlaces: rechazada', () => {
    for (const n of ['mira https://x.test/a', 'www.ejemplo.test', 'escribe a mi.sitio.com', 'mailto:yo']) {
      expect(rejected({ note: n }).fields).toEqual(['note']);
    }
  });

  it('nota con saltos de línea y caracteres de control: quedan en espacios', () => {
    expect(parsePreferences({ note: 'Línea 1\r\nLínea 2\u0007\u202Efin\u2028' }, HOSTS).note)
      .toBe('Línea 1 Línea 2 fin');
    expect(parsePreferences({ note: '\n\t ' }, HOSTS).note).toBeNull();
  });
});

describe('piezas', () => {
  it('cleanNote', () => {
    expect(cleanNote(' a\u0000b ')).toBe('a b');
  });

  it('playlistHostsOf: solo cadenas de host, en minúsculas', () => {
    expect(playlistHostsOf({ playlistHosts: [' Music.Example.com ', 3, 'mal host', ''] })).toEqual(['music.example.com']);
    expect(playlistHostsOf({})).toEqual([]);
  });

  it('validPlaylistUrl devuelve la URL normalizada', () => {
    expect(validPlaylistUrl('https://MUSIC.example.com/l?x=1', HOSTS)).toBe('https://music.example.com/l?x=1');
  });

  it('perfil: se revalida y una URL que ya no está permitida se descarta', () => {
    const user = { tripPreferences: { conversation: 'quiet', playlistUrl: 'https://music.example.com/l', updatedAt: 1 } };
    expect(profilePreferences(user, HOSTS)).toMatchObject({ conversation: 'quiet', playlistUrl: 'https://music.example.com/l' });
    expect(profilePreferences(user, [])).toMatchObject({ conversation: 'quiet', playlistUrl: null });
  });

  it('perfil con datos inválidos: nada', () => {
    expect(profilePreferences({ tripPreferences: { conversation: 'quiet', phone: 'x' } }, HOSTS)).toEqual(EMPTY_PREFERENCES);
  });

  it('ridePreferences de las apps anteriores → lista cerrada', () => {
    expect(legacyPreferences({ quiet: true, temperature: 'warm', music: false, luggageHelp: true, openDoor: true }))
      .toEqual({ ...EMPTY_PREFERENCES, conversation: 'quiet', musicStyle: 'none', needs: ['luggage_assistance'] });
    expect(profilePreferences({ ridePreferences: { temperature: 'cool' } }, HOSTS).cabinTemperature).toBe('cool');
    expect(profilePreferences(undefined, HOSTS)).toEqual(EMPTY_PREFERENCES);
  });
});
