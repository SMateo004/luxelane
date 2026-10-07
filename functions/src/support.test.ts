import { isTicketCategory, preview, priorityFor, statusAfterMessage } from './support';

describe('support', () => {
  it('categories and priority', () => {
    expect(isTicketCategory('lostItem')).toBe(true);
    expect(isTicketCategory('refund-now')).toBe(false);
    expect(priorityFor('safety')).toBe('urgent');
    expect(priorityFor('billing')).toBe('normal');
  });

  it('status follows who wrote last', () => {
    expect(statusAfterMessage('admin')).toBe('answered');
    expect(statusAfterMessage('user')).toBe('open');
  });

  it('preview collapses whitespace and truncates', () => {
    expect(preview('  Hola\n\n  equipo  ')).toBe('Hola equipo');
    const long = 'a'.repeat(200);
    expect(preview(long, 10)).toBe('aaaaaaaaa…');
    expect(preview(long, 10)).toHaveLength(10);
  });
});
