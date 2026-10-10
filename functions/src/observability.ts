// Observability helpers: client error grouping and operational alert rules,
// kept pure for unit tests.

import { createHash } from 'crypto';

export const MAX_MESSAGE = 300;
export const MAX_STACK = 2000;

/** Pending bookings this close to pickup without a chauffeur page the team. */
export const NO_DRIVER_ALERT_MS = 30 * 60 * 1000;

/** "No chauffeur online" is repeated at most once per hour. */
export const NO_DRIVERS_ONLINE_THROTTLE_MS = 60 * 60 * 1000;

/** An urgent (safety) ticket the team hasn't answered in this long pages again. */
export const URGENT_ESCALATION_MS = 10 * 60 * 1000;

export interface UrgentTicketState {
  status?: string;
  priority?: string;
  lastAuthorRole?: string;
  lastMessageAt?: Date | null;
  escalatedAt?: Date | null;
}

/**
 * True once per unanswered customer message on an open urgent ticket, after
 * [URGENT_ESCALATION_MS] without a reply from the team.
 */
export function needsEscalation(t: UrgentTicketState, now: Date): boolean {
  if (t.status !== 'open' || t.priority !== 'urgent' || t.lastAuthorRole === 'admin') return false;
  if (!t.lastMessageAt || now.getTime() - t.lastMessageAt.getTime() < URGENT_ESCALATION_MS) return false;
  return !t.escalatedAt || t.escalatedAt.getTime() < t.lastMessageAt.getTime();
}

/** The monitor runs every 5 minutes; older than this means it stopped. */
export const HEALTH_STALE_MS = 15 * 60 * 1000;

export function clip(v: unknown, max: number): string {
  return typeof v === 'string' ? v.slice(0, max) : '';
}

/**
 * Groups the same error from many users: numbers, ids, URLs and quoted
 * values are masked so "Booking abc123 not found" and "Booking xyz789 not
 * found" share a fingerprint.
 */
export function normalizeMessage(message: string): string {
  return message
    .replace(/https?:\/\/\S+/g, '<url>')
    .replace(/(["'`]).*?\1/g, '<str>')
    .replace(/\b[0-9a-f]{8,}\b/gi, '<id>')
    .replace(/\b[A-Za-z0-9]{20,}\b/g, '<id>')
    .replace(/\d+/g, '<n>')
    .replace(/\s+/g, ' ')
    .trim();
}

/** First stack line that points at app code, normalized (no line numbers). */
export function topFrame(stack: string): string {
  const lines = stack.split('\n').map((l) => l.trim()).filter(Boolean);
  const app = lines.find((l) => l.includes('package:luxelane/') || l.includes('lib/')) ?? lines[0] ?? '';
  return app.replace(/:\d+(:\d+)?/g, '').replace(/\s+/g, ' ').slice(0, 200);
}

export function fingerprint(platform: string, message: string, stack: string): string {
  return createHash('sha1')
    .update(`${platform}|${normalizeMessage(message)}|${topFrame(stack)}`)
    .digest('hex')
    .slice(0, 20);
}

export function isPlatform(v: unknown): v is 'web' | 'android' | 'ios' {
  return v === 'web' || v === 'android' || v === 'ios';
}

/** Should the team be paged about this pending booking now? */
export function needsNoDriverAlert(
  b: { status: string; driverId?: string | null; pickup: Date | null; alertedNoDriver?: boolean },
  now: Date,
): boolean {
  if (b.status !== 'pending' || b.driverId || b.alertedNoDriver || !b.pickup) return false;
  const until = b.pickup.getTime() - now.getTime();
  // Past pickups are handled by scheduledCleanup.
  return until > 0 && until <= NO_DRIVER_ALERT_MS;
}

export function throttled(lastAt: Date | null | undefined, now: Date, windowMs: number): boolean {
  return !!lastAt && now.getTime() - lastAt.getTime() < windowMs;
}
