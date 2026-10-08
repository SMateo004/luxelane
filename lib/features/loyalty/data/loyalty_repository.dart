import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/loyalty.dart';

/// Loyalty program settings (config/loyalty, admins) and the rider's
/// standing (myLoyalty Cloud Function, computed server-side).
abstract class LoyaltyRepository {
  Stream<({bool enabled, List<LoyaltyTier> tiers})> watchConfig();
  Future<void> saveConfig({required bool enabled, required List<LoyaltyTier> tiers});
  Future<LoyaltyStatus> myStatus();
}

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  LoyaltyRepositoryImpl(this._db, this._fn);
  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  DocumentReference<Map<String, dynamic>> get _doc => _db.collection('config').doc('loyalty');

  @override
  Stream<({bool enabled, List<LoyaltyTier> tiers})> watchConfig() => _doc.snapshots().map((d) {
        final j = d.data() ?? const {};
        return (
          enabled: j['enabled'] == true,
          tiers: (j['tiers'] as List? ?? const []).map(LoyaltyTier.fromJson).whereType<LoyaltyTier>().toList(),
        );
      });

  @override
  Future<void> saveConfig({required bool enabled, required List<LoyaltyTier> tiers}) => _doc.set({
        'enabled': enabled,
        'tiers': tiers.map((t) => t.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<LoyaltyStatus> myStatus() async {
    try {
      final r = await _fn.httpsCallable('myLoyalty').call();
      return LoyaltyStatus.fromJson(Map<String, dynamic>.from(r.data as Map));
    } catch (_) {
      return LoyaltyStatus.off;
    }
  }
}
