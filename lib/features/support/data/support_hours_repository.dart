import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/support_hours.dart';

/// Support hours in config/support (admins write; signed-in users read).
abstract class SupportHoursRepository {
  Stream<SupportHours?> watch();
  Future<void> save(SupportHours? hours);
}

class SupportHoursRepositoryImpl implements SupportHoursRepository {
  SupportHoursRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _doc => _db.collection('config').doc('support');

  @override
  Stream<SupportHours?> watch() => _doc.snapshots().map((d) => SupportHours.fromJson(d.data()));

  /// Null clears the hours (the app stops showing them).
  @override
  Future<void> save(SupportHours? hours) => hours == null ? _doc.delete() : _doc.set(hours.toJson());
}
