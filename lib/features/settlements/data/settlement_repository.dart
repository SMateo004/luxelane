import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/models.dart';
import '../domain/settlement.dart';

/// Settlement data: the commission (config/finance), the week's completed
/// rides and the weeks already marked as settled (settlements/{id}).
abstract class SettlementRepository {
  /// Luxelane's commission in %, or null while it hasn't been set.
  Stream<double?> watchCommission();
  Future<void> setCommission(double pct, {required String adminId});

  /// Completed rides with pickup in the week (admin view).
  Stream<List<Booking>> watchCompleted(DateTime weekStart);

  /// Settled weeks: every chauffeur's for [weekStart] (admin) or one
  /// chauffeur's recent ones ([driverId]).
  Stream<List<SettlementRecord>> watchRecords({DateTime? weekStart, String? driverId});

  Future<void> markPaid(DriverSettlement s, DateTime weekStart, double commissionPct, {required String adminId});
  Future<void> unmarkPaid(String driverId, DateTime weekStart);
}

class SettlementRepositoryImpl implements SettlementRepository {
  SettlementRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _finance => _db.collection('config').doc('finance');
  CollectionReference<Map<String, dynamic>> get _records => _db.collection('settlements');

  @override
  Stream<double?> watchCommission() =>
      _finance.snapshots().map((d) => (d.data()?['commissionPct'] as num?)?.toDouble());

  @override
  Future<void> setCommission(double pct, {required String adminId}) => _finance.set({
        'commissionPct': pct,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminId,
      }, SetOptions(merge: true));

  @override
  Stream<List<Booking>> watchCompleted(DateTime weekStart) => _db
      .collection('bookings')
      .where('status', isEqualTo: 'completed')
      .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart.subtract(const Duration(days: 1))))
      .where('scheduledAt', isLessThan: Timestamp.fromDate(Settlements.weekEnd(weekStart)))
      .snapshots()
      // A day of margin before the week catches flight-delayed pickups;
      // Settlements.compute filters by the effective pickup.
      .map((s) => s.docs.map((d) => Booking.fromJson({...d.data(), 'id': d.id})).toList());

  @override
  Stream<List<SettlementRecord>> watchRecords({DateTime? weekStart, String? driverId}) {
    Query<Map<String, dynamic>> q = _records;
    if (weekStart != null) q = q.where('weekStart', isEqualTo: Timestamp.fromDate(weekStart));
    if (driverId != null) q = q.where('driverId', isEqualTo: driverId).orderBy('weekStart', descending: true).limit(12);
    return q.snapshots().map((s) => s.docs.map((d) => SettlementRecord.fromJson(d.data())).toList());
  }

  @override
  Future<void> markPaid(DriverSettlement s, DateTime weekStart, double commissionPct, {required String adminId}) =>
      _records.doc(Settlements.recordId(s.driverId, weekStart)).set({
        'driverId': s.driverId,
        'weekStart': Timestamp.fromDate(weekStart),
        'trips': s.trips,
        'gross': s.gross,
        'commission': s.commission,
        'commissionPct': commissionPct,
        'balance': s.balance,
        'paidAt': FieldValue.serverTimestamp(),
        'paidBy': adminId,
      });

  @override
  Future<void> unmarkPaid(String driverId, DateTime weekStart) =>
      _records.doc(Settlements.recordId(driverId, weekStart)).delete();
}
