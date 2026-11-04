import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/error/function_errors.dart';

/// Reserva pagada sin chófer cerca de la hora (alerta booking_unassigned del
/// servidor, config/ops.unassignedAlertMinutes).
class UnassignedAlert {
  const UnassignedAlert(
      {required this.alertId, required this.bookingId, this.createdAt});
  final String alertId;
  final String bookingId;
  final DateTime? createdAt;
}

/// Panel (Prompt 18, C3): enlace de seguimiento y bandeja de reservas sin
/// chófer.
abstract class AdminShareRepository {
  Future<Either<Failure, bool>> isShareActive(String bookingId);
  Future<Either<Failure, void>> revokeShare(String bookingId, String reason);
  Stream<List<UnassignedAlert>> watchUnassigned();
}

class FirebaseAdminShareRepository implements AdminShareRepository {
  FirebaseAdminShareRepository(
      {FirebaseFunctions? functions, FirebaseFirestore? db})
      : _functionsOverride = functions,
        _dbOverride = db;
  final FirebaseFunctions? _functionsOverride;
  final FirebaseFirestore? _dbOverride;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  Future<Either<Failure, T>> _call<T>(String name, Map<String, dynamic> data,
      T Function(Map<String, dynamic>) read) async {
    try {
      final r =
          await _functions.httpsCallable(name).call<Map<String, dynamic>>(data);
      return Right(read(Map<String, dynamic>.from(r.data)));
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(functionErrorMessage(e.code, e.details)));
    } catch (e) {
      return Left(ServerFailure(unexpectedErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, bool>> isShareActive(String bookingId) => _call(
      'getTripShare', {'bookingId': bookingId}, (d) => d['active'] == true);

  @override
  Future<Either<Failure, void>> revokeShare(String bookingId, String reason) =>
      _call('adminRevokeTripShare', {'bookingId': bookingId, 'reason': reason},
          (_) {});

  @override
  Stream<List<UnassignedAlert>> watchUnassigned() => _db
      .collection('adminAlerts')
      .where('type', isEqualTo: 'booking_unassigned')
      .where('resolved', isEqualTo: false)
      .snapshots()
      .map((s) => [
            for (final d in s.docs)
              UnassignedAlert(
                alertId: d.id,
                bookingId: d.data()['bookingId'] as String? ?? '',
                createdAt: (d.data()['createdAt'] as Timestamp?)?.toDate(),
              ),
          ]);
}
