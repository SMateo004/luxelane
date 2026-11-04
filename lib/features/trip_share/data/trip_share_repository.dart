import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/error/function_errors.dart';

/// Viaje compartido (Prompt 18, C1): enlace de seguimiento de la reserva.
abstract class TripShareRepository {
  /// Si hay un enlace activo (el servidor no devuelve el token).
  Future<Either<Failure, bool>> isActive(String bookingId);

  /// Crea un enlace (revoca el anterior). Devuelve la ruta `/t#<token>`.
  Future<Either<Failure, String>> create(String bookingId);

  Future<Either<Failure, void>> revoke(String bookingId);
}

class FunctionsTripShareRepository implements TripShareRepository {
  FunctionsTripShareRepository({FirebaseFunctions? functions})
      : _override = functions;
  final FirebaseFunctions? _override;
  FirebaseFunctions get _functions => _override ?? FirebaseFunctions.instance;

  Future<Either<Failure, T>> _call<T>(
    String name,
    String bookingId,
    T Function(Map<String, dynamic>) read,
  ) async {
    try {
      final r = await _functions
          .httpsCallable(name)
          .call<Map<String, dynamic>>({'bookingId': bookingId});
      return Right(read(Map<String, dynamic>.from(r.data)));
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(functionErrorMessage(e.code, e.details)));
    } catch (e) {
      return Left(ServerFailure(unexpectedErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, bool>> isActive(String bookingId) =>
      _call('getTripShare', bookingId, (d) => d['active'] == true);

  @override
  Future<Either<Failure, String>> create(String bookingId) =>
      _call('createTripShare', bookingId, (d) => d['path'] as String);

  @override
  Future<Either<Failure, void>> revoke(String bookingId) =>
      _call('revokeTripShare', bookingId, (_) {});
}
