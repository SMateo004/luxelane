import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/function_errors.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../l10n/l10n.dart';

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
      return Left(TripFailure(TripIssue.network, _kNetwork));
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
      return Left(TripFailure(TripIssue.network, _kNetwork));
    }
  }
}

String get _kNetwork => L10n.current.rideErrorNetwork;

/// Traduce el error de una callable del viaje (details.reason) a lo que la
/// pantalla muestra.
Failure tripFailureFor(String code, Object? details) {
  final d = details is Map ? details : const {};
  final t = L10n.current;
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
      return TripFailure(
        TripIssue.notAtPickup,
        t.rideErrorNotAtPickup,
      );
    case 'wrong_code':
      final left = (d['attemptsLeft'] as num?)?.toInt();
      return TripFailure(
        TripIssue.wrongCode,
        left == null
            ? t.rideErrorWrongCode
            : left == 1
                ? t.rideErrorWrongCodeOne
                : t.rideErrorWrongCodeMany(left),
        attemptsLeft: left,
      );
    case 'pickup_locked':
      return TripFailure(
        TripIssue.locked,
        t.rideErrorLocked,
      );
    case 'code_expired':
      return TripFailure(
        TripIssue.expired,
        t.rideErrorExpired,
      );
    case 'pickup_unavailable':
      return TripFailure(
        TripIssue.unavailable,
        t.rideErrorUnavailable,
      );
    case 'not_your_booking':
    case 'not_assigned':
    case 'inactive_driver':
      return TripFailure(
        TripIssue.notAllowed,
        t.rideErrorNotYours,
      );
    case 'no_show_too_early':
      return TripFailure(
        TripIssue.tooEarly,
        t.rideErrorTooEarly,
      );
    case 'no_show_disabled':
      return TripFailure(
        TripIssue.notAllowed,
        t.rideErrorNoShowDisabled,
      );
    case 'location_required':
      return TripFailure(
        TripIssue.locationRequired,
        t.rideErrorLocationRequired,
      );
    case 'not_releasable':
      return TripFailure(
        TripIssue.invalidTransition,
        t.rideErrorNotReleasable,
      );
    case 'invalid_transition':
      return TripFailure(
        TripIssue.invalidTransition,
        t.rideErrorInvalidTransition,
      );
  }
  if (code == 'unavailable' || code == 'deadline-exceeded') {
    return TripFailure(TripIssue.network, _kNetwork);
  }
  final common = commonFunctionError(code, details);
  if (common != null) return TripFailure(TripIssue.other, common);
  return TripFailure(
    TripIssue.other,
    t.rideErrorGeneric,
  );
}
