import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/driver_registration/data/driver_registration_repository.dart';
import 'package:luxelane/features/driver_registration/data/image_prep.dart';
import 'package:luxelane/features/driver_registration/data/photo_picker.dart';

/// Requisitos FICTICIOS de prueba (los reales salen de config/ops).
const kFakeRequirements = [
  {'type': 'profile_photo', 'required': true, 'expires': false},
  {'type': 'live_photo', 'required': true, 'expires': false},
  {'type': 'license_front', 'required': true, 'expires': true},
  {'type': 'vehicle_photo_front', 'required': false, 'expires': false},
];

Map<String, dynamic> fakeApplication({
  String status = 'draft',
  bool configured = true,
  bool personal = true,
  bool vehicle = true,
  List<Map<String, dynamic>> documents = const [],
  bool mfaEnforced = false,
}) =>
    {
      'status': status,
      'step': 'documents',
      'requirementsConfigured': configured,
      'requirements': configured ? kFakeRequirements : const [],
      'mfaEnforced': mfaEnforced,
      'personal': personal
          ? {
              'fullName': 'Chófer De Prueba',
              'nationalIdNumber': '0000000-FIC',
              'licenseNumber': 'LIC-FICTICIA',
              'licenseExpiry': DateTime(2030).millisecondsSinceEpoch,
            }
          : null,
      'vehicle': vehicle
          ? {
              'make': 'Marca',
              'model': 'Modelo',
              'year': 2022,
              'color': 'black',
              'colorOther': null,
              'plate': 'FIC123',
              'bodyType': 'sedan',
              'passengers': 3,
              'vehicleClass': 'business',
            }
          : null,
      'documents': documents,
    };

class FakeRegistrationRepository implements DriverRegistrationRepository {
  FakeRegistrationRepository(this.data);

  Map<String, dynamic> data;
  SecondFactorState factor = SecondFactorState.none;
  Failure? uploadFailure;
  Failure? saveFailure;
  Failure? startFailure;
  final saved = <Map<String, dynamic>>[];
  final uploads =
      <({DriverDocType type, int version, int bytes, DateTime? expiresAt})>[];
  int submits = 0;
  int starts = 0;
  int gets = 0;

  @override
  Future<Either<Failure, DriverApplicationView>> getApplication() async {
    gets++;
    return Right(DriverApplicationView(
      DriverApplication.fromJson(data),
      mfaEnforced: data['mfaEnforced'] == true,
    ));
  }

  @override
  Future<Either<Failure, void>> saveStep(Map<String, dynamic> step) async {
    if (saveFailure != null) return Left(saveFailure!);
    saved.add(step);
    return const Right(null);
  }

  @override
  Future<Either<Failure, DriverDocStatus>> uploadDocument({
    required DriverDocType type,
    required int version,
    required Uint8List bytes,
    required String contentType,
    DateTime? expiresAt,
  }) async {
    uploads.add((
      type: type,
      version: version,
      bytes: bytes.length,
      expiresAt: expiresAt
    ));
    if (uploadFailure != null) return Left(uploadFailure!);
    final docs = [
      for (final d in (data['documents'] as List))
        Map<String, dynamic>.from(d as Map),
    ]..removeWhere((d) => d['type'] == type.wire);
    docs.add({'type': type.wire, 'status': 'uploaded', 'version': version});
    data = {...data, 'documents': docs};
    return const Right(DriverDocStatus.uploaded);
  }

  @override
  Future<Either<Failure, DriverAppStatus>> submit() async {
    submits++;
    data = {...data, 'status': 'submitted'};
    return const Right(DriverAppStatus.submitted);
  }

  @override
  Future<Either<Failure, DriverAppStatus>> startApplication() async {
    starts++;
    if (startFailure != null) return Left(startFailure!);
    return const Right(DriverAppStatus.draft);
  }

  @override
  Future<SecondFactorState> secondFactor() async => factor;
}

/// Preparación de imagen sin códecs: el «tamaño» viene fijado.
class FakeImagePrep extends ImagePrep {
  FakeImagePrep({this.width = 1600, this.height = 1200});
  int width;
  int height;
  int compressions = 0;

  @override
  Future<({int width, int height})?> size(Uint8List bytes) async =>
      bytes.isEmpty ? null : (width: width, height: height);

  @override
  Future<Uint8List> compressWithoutMetadata(Uint8List bytes) async {
    compressions++;
    return Uint8List.fromList([0xff, 0xd8, 0xff, ...bytes.take(4)]);
  }
}

class FakePicker implements PhotoPicker {
  FakePicker([PickResult? result])
      : result = result ?? Picked(Uint8List.fromList([1, 2, 3, 4]));
  PickResult result;
  final calls = <({PhotoSource source, bool front})>[];

  @override
  Future<PickResult> pick(PhotoSource source,
      {bool frontCamera = false}) async {
    calls.add((source: source, front: frontCamera));
    return result;
  }
}
