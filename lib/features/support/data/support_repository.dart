import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/models.dart';
import '../domain/support_ticket.dart';

/// Support conversations, written directly to Firestore under the security
/// rules (see firestore.rules → supportTickets). The backend trigger keeps
/// each ticket's status, preview and unread flags in sync.
abstract class SupportRepository {
  Stream<List<SupportTicket>> watchMyTickets(String userId);
  Stream<List<SupportTicket>> watchAllTickets();
  Stream<SupportTicket?> watchTicket(String ticketId);
  Stream<List<SupportMessage>> watchMessages(String ticketId);

  /// Opens a request with its first message; returns the ticket id.
  Future<String> createTicket({
    required User user,
    required TicketCategory category,
    required String subject,
    required String message,
    String? bookingId,
  });

  Future<void> sendMessage({
    required String ticketId,
    required User author,
    required String text,
    required bool asTeam,
  });

  /// Clears the unread flag for the customer or for the team.
  Future<void> markRead(String ticketId, {required bool asTeam});
  Future<void> setStatus(String ticketId, TicketStatus status);
}

class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _tickets => _db.collection('supportTickets');

  List<SupportTicket> _list(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => SupportTicket.fromJson(d.id, d.data())).toList();

  @override
  Stream<List<SupportTicket>> watchMyTickets(String userId) => _tickets
      .where('userId', isEqualTo: userId)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map(_list);

  @override
  Stream<List<SupportTicket>> watchAllTickets() =>
      _tickets.orderBy('lastMessageAt', descending: true).limit(200).snapshots().map(_list);

  @override
  Stream<SupportTicket?> watchTicket(String ticketId) =>
      _tickets.doc(ticketId).snapshots().map((d) => d.exists ? SupportTicket.fromJson(d.id, d.data()!) : null);

  @override
  Stream<List<SupportMessage>> watchMessages(String ticketId) => _tickets
      .doc(ticketId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map((d) => SupportMessage.fromJson(d.id, d.data())).toList());

  @override
  Future<String> createTicket({
    required User user,
    required TicketCategory category,
    required String subject,
    required String message,
    String? bookingId,
  }) async {
    final ticket = _tickets.doc();
    final now = FieldValue.serverTimestamp();
    final text = message.trim();
    final batch = _db.batch()
      ..set(ticket, {
        'userId': user.id,
        'userName': user.displayName,
        'userRole': user.role.name,
        'category': category.name,
        'subject': subject.trim(),
        'bookingId': bookingId,
        'status': TicketStatus.open.name,
        'priority': category == TicketCategory.safety ? 'urgent' : 'normal',
        'createdAt': now,
        'updatedAt': now,
        'lastMessageAt': now,
        'lastMessagePreview': text.length > 120 ? '${text.substring(0, 119)}…' : text,
        'lastAuthorRole': 'user',
        'unreadForUser': false,
        'unreadForAdmin': true,
      })
      ..set(ticket.collection('messages').doc(), {
        'authorId': user.id,
        'authorRole': 'user',
        'authorName': user.displayName,
        'text': text,
        'createdAt': now,
      });
    await batch.commit();
    return ticket.id;
  }

  @override
  Future<void> sendMessage({
    required String ticketId,
    required User author,
    required String text,
    required bool asTeam,
  }) =>
      _tickets.doc(ticketId).collection('messages').add({
        'authorId': author.id,
        'authorRole': asTeam ? 'admin' : 'user',
        'authorName': author.displayName,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> markRead(String ticketId, {required bool asTeam}) =>
      _tickets.doc(ticketId).update({asTeam ? 'unreadForAdmin' : 'unreadForUser': false});

  @override
  Future<void> setStatus(String ticketId, TicketStatus status) =>
      _tickets.doc(ticketId).update({'status': status.name, 'updatedAt': FieldValue.serverTimestamp()});
}
