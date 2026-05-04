import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection('users').doc(userId).collection('notifications');

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _col(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromJson({...d.data(), 'id': d.id}))
            .toList());
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    final snap = await _col(userId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();
    return snap.count ?? 0;
  }

  @override
  Future<void> createNotification(AppNotification notification) async {
    final ref = _col(notification.userId).doc();
    await ref.set({...notification.toJson(), 'id': ref.id});
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    await _col(userId).doc(notificationId).update({'isRead': true});
  }

  @override
  Future<void> markAllRead(String userId) async {
    final snap = await _col(userId).where('isRead', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
