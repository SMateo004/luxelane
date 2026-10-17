import { buildPush, deadTokens, links } from './push';

describe('push', () => {
  it('carries the link and rings on Android and iOS', () => {
    const m = buildPush(['t1'], 'Hola', 'Tu chófer llegó', links.ride('b1'));
    expect(m.data).toEqual({ link: '/ride/b1' });
    expect(m.android).toEqual({ priority: 'high', notification: { channelId: 'trips', sound: 'default' } });
    expect(m.apns.payload.aps.sound).toBe('default');
    expect(buildPush(['t1'], 'a', 'b').data).toBeUndefined();
  });

  it('finds the tokens of uninstalled apps only', () => {
    expect(
      deadTokens(['a', 'b', 'c', 'd'], [
        { success: true },
        { success: false, error: { code: 'messaging/registration-token-not-registered' } },
        { success: false, error: { code: 'messaging/internal-error' } },
        { success: false, error: { code: 'messaging/invalid-registration-token' } },
      ]),
    ).toEqual(['b', 'd']);
  });
});
