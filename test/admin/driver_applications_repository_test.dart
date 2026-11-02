import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/error/function_errors.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/data/driver_applications_repository.dart';
import 'package:luxelane/features/admin/domain/admin_driver_applications.dart';
import 'package:mocktail/mocktail.dart';

import 'driver_applications_fakes.dart';

class _Functions extends Mock implements FirebaseFunctions {}

class _Callable extends Mock implements HttpsCallable {}

class _Result extends Mock implements HttpsCallableResult<Object?> {}

/// Panel, solicitudes de chófer (B2): la carga de cada callable y los
/// motivos del servidor en texto del panel.
void main() {
  late _Functions fn;
  late _Callable callable;
  late FirebaseDriverApplicationsRepository repo;
  final names = <String>[];

  setUp(() {
    names.clear();
    fn = _Functions();
    callable = _Callable();
    repo = FirebaseDriverApplicationsRepository(functions: fn);
    when(() => fn.httpsCallable(any())).thenAnswer((i) {
      names.add(i.positionalArguments.first as String);
      return callable;
    });
  });

  void answer(Object? data) {
    final r = _Result();
    when(() => r.data).thenReturn(data);
    when(() => callable.call<Object?>(any())).thenAnswer((_) async => r);
  }

  void fail(String code, Map<String, Object?> details) =>
      when(() => callable.call<Object?>(any())).thenThrow(
        FirebaseFunctionsException(
          code: code,
          message: code,
          details: details,
        ),
      );

  Map<String, dynamic> sent() =>
      verify(() => callable.call<Object?>(captureAny())).captured.single
          as Map<String, dynamic>;

  test('adminDecideApplication: decisión en formato del servidor y motivo',
      () async {
    answer({'status': 'needs_changes'});
    final r = await repo.decide(
      driverId: 'chofer-1',
      decision: DriverAppDecision.needsChanges,
      reason: '  Falta la foto del interior  ',
    );
    expect(r.isRight(), isTrue);
    expect(names, ['adminDecideApplication']);
    expect(sent(), {
      'driverId': 'chofer-1',
      'decision': 'needs_changes',
      'reason': 'Falta la foto del interior',
    });
  });

  test('adminReviewDocument: rechazo con motivo y nota', () async {
    answer({'status': 'rejected'});
    await repo.reviewDocument(
      driverId: 'chofer-1',
      type: DriverDocType.licenseFront,
      version: 3,
      approve: false,
      rejectReason: DocRejectReason.lowQuality,
      note: ' borrosa ',
    );
    expect(names, ['adminReviewDocument']);
    expect(sent(), {
      'driverId': 'chofer-1',
      'type': 'license_front',
      'version': 3,
      'decision': 'reject',
      'rejectReason': 'low_quality',
      'note': 'borrosa',
    });
  });

  test('adminReviewDocument: aprobar no manda motivo', () async {
    answer({'status': 'approved'});
    await repo.reviewDocument(
      driverId: 'chofer-1',
      type: DriverDocType.criminalRecord,
      version: 1,
      approve: true,
    );
    expect(sent(), {
      'driverId': 'chofer-1',
      'type': 'criminal_record',
      'version': 1,
      'decision': 'approve',
    });
  });

  test('adminGetDocumentUrl: el enlace no aparece en toString', () async {
    answer({
      'url': kFakeSignedUrl,
      'expiresAt': 1893456000000,
      'contentType': 'image/jpeg',
    });
    final r = await repo.documentUrl('chofer-1', DriverDocType.livePhoto);
    expect(names, ['adminGetDocumentUrl']);
    expect(sent(), {'driverId': 'chofer-1', 'type': 'live_photo'});
    final link = r.getOrElse(() => throw StateError('sin enlace'));
    expect(link.url, kFakeSignedUrl);
    expect(link.isPdf, isFalse);
    expect(link.toString(), isNot(contains('https')));
    expect('$r', isNot(contains('https')));
  });

  test('adminAllowDriverOnline y adminListDocExpiries', () async {
    answer({'driverId': 'd1', 'docsBlocked': false});
    await repo.allowOnline(driverId: 'd1', reason: 'Renovación en trámite');
    expect(sent(), {'driverId': 'd1', 'reason': 'Renovación en trámite'});

    answer({'items': <Object>[], 'truncated': false});
    final r = await repo.expiries(30);
    expect(sent(), {'days': 30});
    expect(r.getOrElse(() => throw StateError('')).items, isEmpty);
    expect(names, ['adminAllowDriverOnline', 'adminListDocExpiries']);
  });

  group('errores', () {
    test('documents_not_approved nombra los documentos', () async {
      fail('failed-precondition', {
        'reason': 'documents_not_approved',
        'fields': ['criminal_record', 'license_front'],
      });
      final r = await repo.decide(
        driverId: 'chofer-1',
        decision: DriverAppDecision.approve,
        reason: 'Todo revisado y en orden',
      );
      final f = r.fold((f) => f, (_) => null)!;
      expect(f.message, contains('No se puede aprobar'));
      expect(f.message, contains('Certificado de antecedentes'));
      expect(f.message, contains('Licencia de conducir (anverso)'));
      expect(f.needsReauth, isFalse);
    });

    test('reauth_required pide volver a identificarse', () async {
      fail('failed-precondition', {'reason': 'reauth_required'});
      final r = await repo.allowOnline(driverId: 'd1', reason: 'x' * 12);
      final f = r.fold((f) => f, (_) => null)!;
      expect(f.needsReauth, isTrue);
      expect(f.message, kReauthRequiredMessage);
    });

    test('mfa_required usa el mensaje común del segundo factor', () async {
      fail('permission-denied', {'reason': 'mfa_required'});
      final r = await repo.documentUrl('d1', DriverDocType.licenseBack);
      expect(r.fold((f) => f.message, (_) => ''), kMfaRequiredMessage);
    });

    test('motivos propios sin texto técnico', () {
      expect(
        driverAppErrorMessage(
            'failed-precondition', {'reason': 'stale_version'}),
        'El chófer subió una versión nueva; recarga la solicitud.',
      );
      expect(
        driverAppErrorMessage('permission-denied', null),
        'Permiso denegado: se necesita rol de administrador.',
      );
      expect(
        driverAppErrorMessage('internal', {'reason': 'algo_raro'}),
        'No se pudo completar. Inténtalo de nuevo en unos minutos.',
      );
    });
  });
}
