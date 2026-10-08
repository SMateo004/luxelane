import 'package:cloud_firestore/cloud_firestore.dart';

/// Summary written by the opsWatch Cloud Function every 5 minutes.
class SystemHealth {
  const SystemHealth({
    required this.checkedAt,
    this.pendingNext2h = 0,
    this.unassignedSoon = 0,
    this.onlineDrivers = 0,
    this.urgentTickets = 0,
    this.clientErrors24h = 0,
  });

  final DateTime? checkedAt;
  final int pendingNext2h;
  final int unassignedSoon;
  final int onlineDrivers;
  final int urgentTickets;
  final int clientErrors24h;

  /// The monitor runs every 5 minutes; older than 15 means it stopped.
  static const staleAfter = Duration(minutes: 15);
  bool staleAt(DateTime now) => checkedAt == null || now.difference(checkedAt!) > staleAfter;

  factory SystemHealth.fromJson(Map<String, dynamic> j) => SystemHealth(
        checkedAt: (j['checkedAt'] as Timestamp?)?.toDate(),
        pendingNext2h: (j['pendingNext2h'] as num?)?.toInt() ?? 0,
        unassignedSoon: (j['unassignedSoon'] as num?)?.toInt() ?? 0,
        onlineDrivers: (j['onlineDrivers'] as num?)?.toInt() ?? 0,
        urgentTickets: (j['urgentTickets'] as num?)?.toInt() ?? 0,
        clientErrors24h: (j['clientErrors24h'] as num?)?.toInt() ?? 0,
      );
}

/// One grouped app error (clientErrors/{fingerprint}).
class ClientErrorGroup {
  const ClientErrorGroup({
    required this.id,
    required this.platform,
    required this.message,
    required this.count,
    this.stack = '',
    this.lastRoute,
    this.lastAppVersion,
    this.firstSeen,
    this.lastSeen,
    this.resolved = false,
  });

  final String id;
  final String platform;
  final String message;
  final int count;
  final String stack;
  final String? lastRoute;
  final String? lastAppVersion;
  final DateTime? firstSeen;
  final DateTime? lastSeen;
  final bool resolved;

  factory ClientErrorGroup.fromJson(String id, Map<String, dynamic> j) => ClientErrorGroup(
        id: id,
        platform: j['platform'] as String? ?? 'web',
        message: j['message'] as String? ?? '',
        count: (j['count'] as num?)?.toInt() ?? 0,
        stack: j['stack'] as String? ?? '',
        lastRoute: j['lastRoute'] as String?,
        lastAppVersion: j['lastAppVersion'] as String?,
        firstSeen: (j['firstSeen'] as Timestamp?)?.toDate(),
        lastSeen: (j['lastSeen'] as Timestamp?)?.toDate(),
        resolved: j['resolved'] as bool? ?? false,
      );
}

abstract class HealthRepository {
  Stream<SystemHealth?> watchHealth();
  Stream<List<ClientErrorGroup>> watchErrors();
  Future<void> setResolved(String id, bool resolved);
}

class HealthRepositoryImpl implements HealthRepository {
  HealthRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<SystemHealth?> watchHealth() => _db
      .collection('system')
      .doc('health')
      .snapshots()
      .map((d) => d.exists ? SystemHealth.fromJson(d.data()!) : null);

  @override
  Stream<List<ClientErrorGroup>> watchErrors() => _db
      .collection('clientErrors')
      .orderBy('lastSeen', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => ClientErrorGroup.fromJson(d.id, d.data())).toList());

  @override
  Future<void> setResolved(String id, bool resolved) =>
      _db.collection('clientErrors').doc(id).update({'resolved': resolved});
}
