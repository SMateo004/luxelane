import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/error/failures.dart';
import '../../../core/error/function_errors.dart';
import '../../../core/models/models.dart';
import '../../../l10n/l10n.dart';

/// Error del registro con el motivo del servidor (para decidir en pantalla).
class RegistrationFailure extends Failure {
  const RegistrationFailure(super.message, {this.reason, this.fields});
  final String? reason;
  final List<String>? fields;
}

/// Segundo factor del chófer: si lo tiene dado de alta y si la sesión
/// actual entró con él (acceptBooking y submitApplication lo exigen con
/// config/security.mfaEnforced).
enum SecondFactorState { none, enrolledNotInSession, inSession }

/// El registro de chóferes (B1): todo por las callables del servidor y
/// Cloud Storage (driverDocs/{uid}/{tipo}/{versión}, solo crear).
abstract class DriverRegistrationRepository {
  /// startDriverApplication y, si cambió el rol, token nuevo con el claim.
  Future<Either<Failure, DriverAppStatus>> startApplication();

  Future<Either<Failure, DriverApplicationView>> getApplication();

  Future<Either<Failure, void>> saveStep(Map<String, dynamic> step);

  /// Sube la versión [version] de [type] y la registra. Reintentar con la
  /// misma versión no duplica: si el objeto ya existe (las reglas no dejan
  /// sobrescribir) solo se registra.
  Future<Either<Failure, DriverDocStatus>> uploadDocument({
    required DriverDocType type,
    required int version,
    required Uint8List bytes,
    required String contentType,
    DateTime? expiresAt,
  });

  Future<Either<Failure, DriverAppStatus>> submit();

  Future<SecondFactorState> secondFactor();
}

/// La solicitud y lo que la app necesita saber de la seguridad.
class DriverApplicationView {
  const DriverApplicationView(this.application, {required this.mfaEnforced});
  final DriverApplication application;
  final bool mfaEnforced;
}

RegistrationFailure registrationFailure(FirebaseFunctionsException e) {
  final d = e.details;
  final fields = d is Map && d['fields'] is List
      ? [for (final f in d['fields'] as List) '$f']
      : null;
  return RegistrationFailure(
    registrationErrorMessage(e.code, d),
    reason: functionErrorReason(d),
    fields: fields,
  );
}

class DriverRegistrationRepositoryImpl implements DriverRegistrationRepository {
  DriverRegistrationRepositoryImpl({
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
    fb.FirebaseAuth? auth,
  })  : _functionsOverride = functions,
        _storageOverride = storage,
        _authOverride = auth;

  final FirebaseFunctions? _functionsOverride;
  final FirebaseStorage? _storageOverride;
  final fb.FirebaseAuth? _authOverride;

  FirebaseFunctions get _fn => _functionsOverride ?? FirebaseFunctions.instance;
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;
  fb.FirebaseAuth get _auth => _authOverride ?? fb.FirebaseAuth.instance;

  Future<Either<Failure, Map<String, dynamic>>> _call(
    String name, [
    Object? data,
  ]) async {
    try {
      final r = await _fn.httpsCallable(name).call<dynamic>(data);
      final v = r.data;
      return Right(v is Map ? Map<String, dynamic>.from(v) : const {});
    } on FirebaseFunctionsException catch (e) {
      return Left(registrationFailure(e));
    } catch (e) {
      return Left(RegistrationFailure(unexpectedErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, DriverAppStatus>> startApplication() async {
    final r = await _call('startDriverApplication');
    return r.fold(Left.new, (data) async {
      // El claim role=driver llega con un token nuevo (sin él las reglas
      // aún ven al pasajero).
      try {
        await _auth.currentUser?.getIdToken(true);
      } catch (_) {
        // Sin red: el token se renueva solo en menos de una hora.
      }
      return Right(DriverAppStatus.fromWire(data['status']));
    });
  }

  @override
  Future<Either<Failure, DriverApplicationView>> getApplication() async {
    final r = await _call('getDriverApplication');
    return r.map((d) => DriverApplicationView(
          DriverApplication.fromJson(d),
          mfaEnforced: d['mfaEnforced'] == true,
        ));
  }

  @override
  Future<Either<Failure, void>> saveStep(Map<String, dynamic> step) async =>
      (await _call('saveDriverStep', step)).map((_) {});

  @override
  Future<Either<Failure, DriverDocStatus>> uploadDocument({
    required DriverDocType type,
    required int version,
    required Uint8List bytes,
    required String contentType,
    DateTime? expiresAt,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Left(RegistrationFailure(L10n.current.errorSessionExpired));
    }
    final ref = _storage.ref('driverDocs/$uid/${type.wire}/$version');
    try {
      await ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
    } on FirebaseException catch (e) {
      // Ya subido en un intento anterior (no se puede sobrescribir): se
      // registra. Cualquier otro error se muestra y se puede reintentar.
      if (e.code != 'unauthorized') {
        return Left(RegistrationFailure(L10n.current.regUploadFailed));
      }
    } catch (_) {
      return Left(RegistrationFailure(L10n.current.regUploadFailed));
    }
    final r = await _call('registerDocumentUpload', {
      'type': type.wire,
      'version': version,
      if (expiresAt != null) 'expiresAt': expiresAt.millisecondsSinceEpoch,
    });
    return r.map((d) => DriverDocStatus.fromWire(d['status']));
  }

  @override
  Future<Either<Failure, DriverAppStatus>> submit() async =>
      (await _call('submitApplication'))
          .map((d) => DriverAppStatus.fromWire(d['status']));

  @override
  Future<SecondFactorState> secondFactor() async {
    final user = _auth.currentUser;
    if (user == null) return SecondFactorState.none;
    try {
      final enrolled = (await user.multiFactor.getEnrolledFactors()).isNotEmpty;
      if (!enrolled) return SecondFactorState.none;
      final claims = (await user.getIdTokenResult()).claims ?? const {};
      final fb = claims['firebase'];
      final second = fb is Map ? fb['sign_in_second_factor'] : null;
      return second is String && second.isNotEmpty
          ? SecondFactorState.inSession
          : SecondFactorState.enrolledNotInSession;
    } catch (_) {
      return SecondFactorState.none;
    }
  }
}
