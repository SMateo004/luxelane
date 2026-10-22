import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

/// Pasos del viaje desde la recogida: todo pasa por callables del servidor,
/// que valida el grafo, quién lo pide y deja el registro de eventos.
class TripFlowRepositoryImpl implements TripFlowRepository {
  TripFlowRepositoryImpl({FirebaseFunctions? functions})
      : _functionsOverride = functions;

  final FirebaseFunctions? _functionsOverride;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  @override
  Future<Either<Failure, PickupCode>> getPickupCode(String bookingId) async {
    try {
      final res = await _functions
          .httpsCallable('getPickupCode')
          .call<Map<String, dynamic>>({'bookingId': bookingId});
      return Right(PickupCode.fromJson(res.data));
    } on FirebaseFunctionsException catch (e) {
      return Left(tripFailureFor(e.code, e.details));
    } catch (_) {
      return const Left(TripFailure(TripIssue.network, _kNetwork));
    }
  }
}

const _kNetwork = 'Sin conexión. Revisa tu red e inténtalo de nuevo.';

/// Traduce el error de una callable del viaje (details.reason) a lo que la
/// pantalla muestra.
Failure tripFailureFor(String code, Object? details) {
  final d = details is Map ? details : const {};
  final reason = d['reason'] as String?;
  switch (reason) {
    case 'not_at_pickup':
      return const TripFailure(TripIssue.notAtPickup,
          'El código aparece cuando tu chófer llega a la recogida.');
    case 'wrong_code':
      final left = (d['attemptsLeft'] as num?)?.toInt();
      return TripFailure(
        TripIssue.wrongCode,
        left == null
            ? 'Código incorrecto.'
            : left == 1
                ? 'Código incorrecto. Te queda 1 intento.'
                : 'Código incorrecto. Te quedan $left intentos.',
        attemptsLeft: left,
      );
    case 'pickup_locked':
      return const TripFailure(TripIssue.locked,
          'Por seguridad, la verificación quedó bloqueada. Contacta con central.');
    case 'code_expired':
      return const TripFailure(TripIssue.expired,
          'El código venció. Contacta con central para continuar.');
    case 'pickup_unavailable':
      return const TripFailure(TripIssue.unavailable,
          'El código no está disponible ahora. Contacta con central.');
    case 'not_your_booking':
    case 'not_assigned':
    case 'inactive_driver':
      return const TripFailure(
          TripIssue.notAllowed, 'Este viaje ya no está a tu cargo.');
    case 'invalid_transition':
      return const TripFailure(TripIssue.invalidTransition,
          'El viaje cambió de estado. Actualizamos la pantalla.');
  }
  if (code == 'unavailable' || code == 'deadline-exceeded') {
    return const TripFailure(TripIssue.network, _kNetwork);
  }
  return const TripFailure(
      TripIssue.other, 'No se pudo completar. Inténtalo de nuevo.');
}
