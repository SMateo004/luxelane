// What every push carries besides its text: where tapping it opens in the
// app, and the delivery settings that make ride alerts ring.

/** Android notification channel created by the app (MainActivity.kt). */
export const TRIPS_CHANNEL = 'trips';

/** In-app paths a notification may open (lib/core/services/push_links.dart). */
export const links = {
  ride: (bookingId: string) => `/ride/${bookingId}`,
  receipt: (bookingId: string) => `/viajes/${bookingId}/recibo`,
  driverHome: '/driver',
  driverQueue: '/driver/queue',
  driverEarnings: '/driver/earnings',
  driverDocuments: '/driver/documents',
  profile: '/profile',
  help: '/ayuda',
  admin: '/admin',
} as const;

export interface PushMessage {
  tokens: string[];
  notification: { title: string; body: string };
  data?: { link: string };
  android: { priority: 'high'; notification: { channelId: string; sound: string } };
  apns: { payload: { aps: { sound: string } } };
}

export function buildPush(tokens: string[], title: string, body: string, link?: string): PushMessage {
  return {
    tokens,
    notification: { title, body },
    ...(link ? { data: { link } } : {}),
    android: { priority: 'high', notification: { channelId: TRIPS_CHANNEL, sound: 'default' } },
    apns: { payload: { aps: { sound: 'default' } } },
  };
}

const DEAD = new Set(['messaging/registration-token-not-registered', 'messaging/invalid-registration-token']);

/** Tokens FCM says no longer exist (app uninstalled, data cleared). */
export function deadTokens(tokens: string[], responses: { success: boolean; error?: { code?: string } }[]): string[] {
  return tokens.filter((_, i) => {
    const r = responses[i];
    return r != null && !r.success && DEAD.has(r.error?.code ?? '');
  });
}
