// Support tickets: state transitions and notification copy helpers, pure so
// they can be unit-tested. Tickets live in supportTickets/{id} with their
// conversation in supportTickets/{id}/messages/{messageId}.

export const TICKET_CATEGORIES = ['trip', 'lostItem', 'billing', 'chauffeur', 'safety', 'app', 'other'] as const;
export type TicketCategory = (typeof TICKET_CATEGORIES)[number];
export type TicketStatus = 'open' | 'answered' | 'resolved';
export type AuthorRole = 'user' | 'admin';

export function isTicketCategory(v: unknown): v is TicketCategory {
  return typeof v === 'string' && (TICKET_CATEGORIES as readonly string[]).includes(v);
}

/** Safety reports jump the queue. */
export function priorityFor(category: TicketCategory): 'urgent' | 'normal' {
  return category === 'safety' ? 'urgent' : 'normal';
}

/**
 * Status after a new message: the team answering leaves it "answered"
 * (waiting on the customer); the customer writing (re)opens it, also after
 * it was resolved.
 */
export function statusAfterMessage(author: AuthorRole): TicketStatus {
  return author === 'admin' ? 'answered' : 'open';
}

/** One-line preview for lists and push notifications. */
export function preview(text: string, max = 120): string {
  const t = text.replace(/\s+/g, ' ').trim();
  return t.length <= max ? t : `${t.slice(0, max - 1).trimEnd()}…`;
}
