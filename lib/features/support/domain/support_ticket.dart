import 'package:cloud_firestore/cloud_firestore.dart';

/// What the request is about (mirrors functions/src/support.ts).
enum TicketCategory { trip, lostItem, billing, chauffeur, safety, app, other }

/// open: waiting on the team · answered: waiting on the customer · resolved.
enum TicketStatus { open, answered, resolved }

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.category,
    required this.subject,
    required this.status,
    this.bookingId,
    this.urgent = false,
    this.createdAt,
    this.lastMessageAt,
    this.lastMessagePreview = '',
    this.unreadForUser = false,
    this.unreadForAdmin = false,
  });

  final String id;
  final String userId;
  final String userName;

  /// 'rider' or 'driver'.
  final String userRole;
  final TicketCategory category;
  final String subject;
  final TicketStatus status;
  final String? bookingId;
  final bool urgent;
  final DateTime? createdAt;
  final DateTime? lastMessageAt;
  final String lastMessagePreview;
  final bool unreadForUser;
  final bool unreadForAdmin;

  factory SupportTicket.fromJson(String id, Map<String, dynamic> j) => SupportTicket(
        id: id,
        userId: j['userId'] as String? ?? '',
        userName: j['userName'] as String? ?? '',
        userRole: j['userRole'] as String? ?? 'rider',
        category: TicketCategory.values.firstWhere((c) => c.name == j['category'], orElse: () => TicketCategory.other),
        subject: j['subject'] as String? ?? '',
        status: TicketStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => TicketStatus.open),
        bookingId: j['bookingId'] as String?,
        urgent: j['priority'] == 'urgent',
        createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
        lastMessageAt: (j['lastMessageAt'] as Timestamp?)?.toDate(),
        lastMessagePreview: j['lastMessagePreview'] as String? ?? '',
        unreadForUser: j['unreadForUser'] as bool? ?? false,
        unreadForAdmin: j['unreadForAdmin'] as bool? ?? false,
      );
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.authorId,
    required this.fromTeam,
    required this.authorName,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String authorId;

  /// Written by the Luxelane team (admin).
  final bool fromTeam;
  final String authorName;
  final String text;
  final DateTime? createdAt;

  factory SupportMessage.fromJson(String id, Map<String, dynamic> j) => SupportMessage(
        id: id,
        authorId: j['authorId'] as String? ?? '',
        fromTeam: j['authorRole'] == 'admin',
        authorName: j['authorName'] as String? ?? '',
        text: j['text'] as String? ?? '',
        createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
      );
}

/// Admin queue order: open urgent first, then open, answered, resolved;
/// newest activity first inside each group.
List<SupportTicket> sortForQueue(Iterable<SupportTicket> tickets) {
  int rank(SupportTicket t) => switch (t.status) {
        TicketStatus.open => t.urgent ? 0 : 1,
        TicketStatus.answered => 2,
        TicketStatus.resolved => 3,
      };
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  return tickets.toList()
    ..sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      return (b.lastMessageAt ?? epoch).compareTo(a.lastMessageAt ?? epoch);
    });
}
