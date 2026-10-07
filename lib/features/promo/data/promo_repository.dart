import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/promo_code.dart';

/// Admin management of promo codes. Codes are read from Firestore (admins
/// only) and saved through the savePromoCode Cloud Function, which validates
/// them and owns the redemption counter.
abstract class PromoRepository {
  Stream<List<PromoCode>> watchAll();

  /// Null on success, else a [PromoAdminErrorCodes] value.
  Future<String?> save(PromoCode promo, {required bool create});
}

class PromoRepositoryImpl implements PromoRepository {
  PromoRepositoryImpl(this._db, this._fn);

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  @override
  Stream<List<PromoCode>> watchAll() => _db
      .collection('promoCodes')
      .orderBy('code')
      .snapshots()
      .map((s) => s.docs.map((d) => PromoCode.fromJson(d.id, d.data())).toList());

  @override
  Future<String?> save(PromoCode promo, {required bool create}) async {
    try {
      await _fn.httpsCallable('savePromoCode').call(promo.toCallable(create: create));
      return null;
    } on FirebaseFunctionsException catch (e) {
      return PromoAdminErrorCodes.fromMessage(e.message);
    } catch (_) {
      return PromoAdminErrorCodes.failed;
    }
  }
}
