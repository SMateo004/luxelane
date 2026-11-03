import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/driver_registration/data/driver_registration_repository.dart';
import 'package:luxelane/features/driver_registration/data/image_prep.dart';
import 'package:luxelane/features/driver_registration/presentation/bloc/registration_cubit.dart';
import 'package:luxelane/l10n/l10n.dart';

import 'fakes.dart';

void main() {
  late FakeRegistrationRepository repo;
  late FakeImagePrep prep;
  RegistrationCubit cubit() =>
      RegistrationCubit(repository: repo, imagePrep: prep);
  final photo = Uint8List.fromList(List.filled(64, 7));

  setUp(() {
    repo = FakeRegistrationRepository(fakeApplication());
    prep = FakeImagePrep();
    debugUploadsSupported = true;
  });
  tearDown(() => debugUploadsSupported = null);

  group('modelo (getDriverApplication)', () {
    test('lee requisitos, documentos y lo que falta; la versión siguiente', () {
      final a = DriverApplication.fromJson(fakeApplication(documents: [
        {'type': 'profile_photo', 'status': 'approved', 'version': 1},
        {
          'type': 'license_front',
          'status': 'rejected',
          'version': 2,
          'rejectReason': 'illegible',
          'rejectNote': 'Se ve borrosa',
        },
      ]));
      expect(a.requestedTypes.first, DriverDocType.profilePhoto);
      expect(a.nextVersion(DriverDocType.licenseFront), 3);
      expect(a.nextVersion(DriverDocType.livePhoto), 1);
      expect(a.doc(DriverDocType.licenseFront)!.rejectReason,
          DocRejectReason.illegible);
      // Opcional (vehicle_photo_front) no cuenta; rechazado sí.
      expect(a.missingRequired,
          [DriverDocType.livePhoto, DriverDocType.licenseFront]);
      expect(a.canSubmit, isFalse);
    });

    test('sin requisitos configurados no se puede enviar', () {
      final a = DriverApplication.fromJson(fakeApplication(configured: false));
      expect(a.requirementsConfigured, isFalse);
      expect(a.missingRequired, isEmpty);
      expect(a.canSubmit, isFalse);
    });
  });

  test('carga y abre el primer paso pendiente (reanudable)', () async {
    repo.data = fakeApplication(vehicle: false);
    final c = cubit();
    await c.load();
    expect(c.state.page, RegistrationStep.vehicle);
    repo.data = fakeApplication(personal: false, vehicle: false);
    await c.load();
    expect(c.state.page, RegistrationStep.personal);
  });

  test('con mfaEnforced hay un paso de segundo factor antes del resumen',
      () async {
    repo.data = fakeApplication(mfaEnforced: true);
    final c = cubit();
    await c.load();
    expect(c.state.steps, [
      RegistrationStep.personal,
      RegistrationStep.vehicle,
      RegistrationStep.documents,
      RegistrationStep.security,
      RegistrationStep.summary,
    ]);
    repo.data = fakeApplication();
    await c.load();
    expect(c.state.steps, isNot(contains(RegistrationStep.security)));
  });

  test('guardar un paso manda el paso al servidor y avanza', () async {
    repo.data = fakeApplication(personal: false, vehicle: false);
    final c = cubit();
    await c.load();
    final ok = await c.savePersonal(DriverPersonalData(
      fullName: 'Chófer De Prueba',
      nationalIdNumber: '0000000-FIC',
      licenseNumber: 'LIC-FICTICIA',
      licenseExpiry: DateTime(2030),
    ));
    expect(ok, isTrue);
    expect(repo.saved.single['step'], 'personal');
    expect(c.state.page, RegistrationStep.vehicle);
  });

  test('placa en uso: el mensaje del servidor y el campo marcado', () async {
    repo.saveFailure = const RegistrationFailure('x',
        reason: 'plate_in_use', fields: ['plate']);
    final c = cubit();
    await c.load();
    await c.saveVehicle(DriverApplication.fromJson(fakeApplication()).vehicle!);
    expect(c.state.fieldErrors, ['plate']);
    expect(c.state.page, RegistrationStep.documents);
  });

  test('foto pequeña: se avisa y no se sube', () async {
    prep.width = 600;
    prep.height = 400;
    final c = cubit();
    await c.load();
    expect(await c.uploadPhoto(DriverDocType.profilePhoto, photo), isFalse);
    expect(repo.uploads, isEmpty);
    expect(c.state.uploadErrors[DriverDocType.profilePhoto],
        L10n.current.regPhotoTooSmall);
  });

  test('sube el JPEG recomprimido con la versión siguiente y recarga',
      () async {
    repo.data = fakeApplication(documents: [
      {'type': 'license_front', 'status': 'rejected', 'version': 1},
    ]);
    final c = cubit();
    await c.load();
    final exp = DateTime(2031, 5, 2);
    expect(
        await c.uploadPhoto(DriverDocType.licenseFront, photo, expiresAt: exp),
        isTrue);
    expect(prep.compressions, 1);
    expect(repo.uploads.single.version, 2);
    expect(repo.uploads.single.expiresAt, exp);
    expect(c.state.app.doc(DriverDocType.licenseFront)!.status,
        DriverDocStatus.uploaded);
  });

  test('reintento tras un fallo: la misma versión (no se duplica)', () async {
    final c = cubit();
    await c.load();
    repo.uploadFailure = RegistrationFailure(L10n.current.regUploadFailed);
    await c.uploadPhoto(DriverDocType.profilePhoto, photo);
    expect(c.state.uploadErrors[DriverDocType.profilePhoto],
        L10n.current.regUploadFailed);
    repo.uploadFailure = null;
    await c.uploadPhoto(DriverDocType.profilePhoto, photo);
    expect(repo.uploads.map((u) => u.version), [1, 1]);
    expect(c.state.uploadErrors, isEmpty);
  });

  test('un segundo toque mientras sube no sube otra vez', () async {
    final c = cubit();
    await c.load();
    final first = c.uploadPhoto(DriverDocType.profilePhoto, photo);
    final second = await c.uploadPhoto(DriverDocType.profilePhoto, photo);
    await first;
    expect(second, isFalse);
    expect(repo.uploads, hasLength(1));
  });

  test('en la web no se sube nada', () async {
    debugUploadsSupported = false;
    final c = cubit();
    await c.load();
    expect(await c.uploadPhoto(DriverDocType.profilePhoto, photo), isFalse);
    expect(repo.uploads, isEmpty);
    expect(c.state.message, L10n.current.regWebUploadBlocked);
  });

  test('con mfaEnforced no envía sin el segundo factor en la sesión', () async {
    repo.data = fakeApplication(mfaEnforced: true, documents: [
      for (final t in ['profile_photo', 'live_photo', 'license_front'])
        {'type': t, 'status': 'uploaded', 'version': 1},
    ]);
    final c = cubit();
    await c.load();
    expect(c.state.app.canSubmit, isTrue);
    expect(c.state.canSubmit, isFalse);
    expect(await c.submit(), isFalse);
    expect(repo.submits, 0);
    repo.factor = SecondFactorState.inSession;
    await c.refreshSecondFactor();
    expect(await c.submit(), isTrue);
    expect(repo.submits, 1);
    expect(c.state.waitingReview, isTrue);
  });
}
