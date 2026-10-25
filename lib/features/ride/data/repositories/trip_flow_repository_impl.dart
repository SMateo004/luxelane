import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/function_errors.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

/// Pasos del viaje desde la recogida: todo pasa por callables del servidor,
/// que valida el grafo, quién lo pide y deja el registro de eventos.
class TripFlowRepositoryImpl implements TripFlowRepository {
  TripFlowRepositoryImpl({
    FirebaseFunctions? functions,
    Future<String?> Function()? appVersion,
  })  : _functionsOverride = functions,
        _appVersion = appVersion ?? _installedVersion;

  final FirebaseFunctions? _functionsOverride;

  /// Versión instalada (x.y.z) que el servidor compara con
  /// minDriverAppVersion.
  final Future<String?> Function() _appVersion;

  static Future<String?> _installedVersion() async {
    try {
      return (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      return null;
    }
  }

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

  @override
  Future<Either<Failure, void>> advance({
    required String bookingId,
    required BookingStatus to,
    ({double lat, double lng})? location,
  }) =>
      _call('advanceBooking', {
        'bookingId': bookingId,
        'to': to.label,
        if (location != null) 'location': _loc(location),
      });

  @override
  Future<Either<Failure, void>> release({
    required String bookingId,
    required String reason,
    ({double lat, double lng})? location,
  }) =>
      _call('releaseBooking', {
        'bookingId': bookingId,
        'reason': reason,
        if (location != null) 'location': _loc(location),
      });

  @override
  Future<Either<Failure, void>> verifyPickup({
    required String bookingId,
    required String code,
    ({double lat, double lng})? location,
  }) =>
      _call('verifyPickup', {
        'bookingId': bookingId,
        'code': code,
        if (location != null) 'location': _loc(location),
      });

  static Map<String, double> _loc(({double lat, double lng}) l) => {
        'lat': l.lat,
        'lng': l.lng,
      };

  Future<Either<Failure, void>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final version = await _appVersion();
      await _functions.httpsCallable(name).call<Map<String, dynamic>>({
        ...data,
        if (version != null) 'appVersion': version,
      });
      return const Right(null);
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
    case 'app_update_required':
      String? url(Object? v) =>
          v is String && v.startsWith('https://') ? v : null;
      return AppUpdateRequiredFailure(
        androidStoreUrl: url(d['androidStoreUrl']),
        iosStoreUrl: url(d['iosStoreUrl']),
        forDriver: true,
      );
    case 'not_at_pickup':
      return const TripFailure(
        TripIssue.notAtPickup,
        'El código aparece cuando tu chófer llega a la recogida.',
      );
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
      return const TripFailure(
        TripIssue.locked,
        'Por seguridad, la verificación quedó bloqueada. Contacta con central.',
      );
    case 'code_expired':
      return const TripFailure(
        TripIssue.expired,
        'El código venció. Contacta con central para continuar.',
      );
    case 'pickup_unavailable':
      return const TripFailure(
        TripIssue.unavailable,
        'El código no está disponible ahora. Contacta con central.',
      );
    case 'not_your_booking':
    case 'not_assigned':
    case 'inactive_driver':
      return const TripFailure(
        TripIssue.notAllowed,
        'Este viaje ya no está a tu cargo.',
      );
    case 'no_show_too_early':
      return const TripFailure(
        TripIssue.tooEarly,
        'Aún no terminó el tiempo de espera. Espera un poco más.',
      );
    case 'no_show_disabled':
      return const TripFailure(
        TripIssue.notAllowed,
        'Esta opción no está disponible. Contacta con central.',
      );
    case 'location_required':
      return const TripFailure(
        TripIssue.locationRequired,
        'Activa la ubicación: central necesita saber dónde esperaste.',
      );
    case 'not_releasable':
      return const TripFailure(
        TripIssue.invalidTransition,
        'Ya no puedes liberar este viaje. Contacta con central.',
      );
    case 'invalid_transition':
      return const TripFailure(
        TripIssue.invalidTransition,
        'El viaje cambió de estado. Actualizamos la pantalla.',
      );
  }
  if (code == 'unavailable' || code == 'deadline-exceeded') {
    return const TripFailure(TripIssue.network, _kNetwork);
  }
  final common = commonFunctionError(code, details);
  if (common != null) return TripFailure(TripIssue.other, common);
  return const TripFailure(
    TripIssue.other,
    'No se pudo completar. Inténtalo de nuevo.',
  );
}
