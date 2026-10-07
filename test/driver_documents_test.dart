import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/driver/data/driver_documents_repository.dart';
import 'package:luxelane/features/driver/domain/driver_document.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_documents_review_page.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_documents_screen.dart';

import 'helpers/l10n.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

final _now = DateTime(2026, 10, 7, 12);

DriverDocument _doc(DriverDocType t, DriverDocStatus s, {DateTime? expires, String? reason}) => DriverDocument(
      type: t,
      status: s,
      storagePath: 'driver_documents/d1/${t.name}.pdf',
      fileName: '${t.name}.pdf',
      expiresAt: expires,
      uploadedAt: DateTime(2026, 10, 1),
      rejectionReason: reason,
    );

class _FakeRepo implements DriverDocumentsRepository {
  _FakeRepo(Map<DriverDocType, DriverDocument> docs) : _docs = Map.of(docs);

  final Map<DriverDocType, DriverDocument> _docs;
  final _ctrl = StreamController<Map<DriverDocType, DriverDocument>>.broadcast();
  final calls = <String>[];
  String? nextError;

  @override
  Stream<Map<DriverDocType, DriverDocument>> watch(String driverId) async* {
    yield Map.of(_docs);
    yield* _ctrl.stream;
  }

  @override
  Future<String?> upload({
    required String driverId,
    required DriverDocType type,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    DateTime? expiresAt,
  }) async {
    calls.add('upload:$driverId:${type.name}:$fileName:$contentType:${expiresAt?.year}');
    _docs[type] = DriverDocument(type: type, status: DriverDocStatus.pending, fileName: fileName, expiresAt: expiresAt);
    _ctrl.add(Map.of(_docs));
    return null;
  }

  @override
  Future<String?> downloadUrl(String storagePath) async => 'https://files.example/$storagePath';

  @override
  Future<String?> review({
    required String driverId,
    required DriverDocType type,
    required bool approve,
    String? reason,
    DateTime? expiresAt,
  }) async {
    calls.add('review:${type.name}:$approve:${reason ?? ''}:${expiresAt != null}');
    final e = nextError;
    nextError = null;
    return e;
  }
}

final _driver = User(
  id: 'd1',
  email: 'carlos@x.bo',
  phone: '',
  displayName: 'Carlos',
  role: UserRole.driver,
  createdAt: DateTime(2025),
  isVerified: true,
  isActive: true,
  fcmTokens: const [],
);

Widget _app(Widget child, {Locale locale = const Locale('es')}) {
  final auth = _MockAuthBloc();
  whenListen(auth, const Stream<AuthState>.empty(), initialState: AuthAuthenticated(_driver));
  return BlocProvider<AuthBloc>.value(value: auth, child: localizedApp(child, locale: locale));
}

void main() {
  setUpAll(() => initializeDateFormatting());

  group('DriverDocument', () {
    test('approved past its date counts as expired; 30-day window', () {
      final d = _doc(DriverDocType.soat, DriverDocStatus.approved, expires: DateTime(2026, 10, 1));
      expect(d.statusAt(_now), DriverDocStatus.expired);
      expect(d.needsUpload(_now), isTrue);
      final soon = _doc(DriverDocType.soat, DriverDocStatus.approved, expires: DateTime(2026, 10, 20));
      expect(soon.expiringSoon(_now), isTrue);
      expect(soon.needsUpload(_now), isTrue);
      final later = _doc(DriverDocType.soat, DriverDocStatus.approved, expires: DateTime(2027, 6, 1));
      expect(later.expiringSoon(_now), isFalse);
      expect(_doc(DriverDocType.vehicleRegistration, DriverDocStatus.approved).statusAt(_now), DriverDocStatus.approved);
    });

    test('summary counts every required document', () {
      final s = DocumentsSummary({
        DriverDocType.license: _doc(DriverDocType.license, DriverDocStatus.approved, expires: DateTime(2028)),
        DriverDocType.soat: _doc(DriverDocType.soat, DriverDocStatus.pending),
        DriverDocType.idCard: _doc(DriverDocType.idCard, DriverDocStatus.rejected),
      }, _now);
      expect(s.documents, hasLength(5));
      expect(s.approved, 1);
      expect(s.pending, 1);
      expect(s.toUpload, 3); // rejected + 2 missing
      expect(s.complete, isFalse);
    });

    test('server error codes', () {
      expect(DriverDocErrorCodes.fromMessage('documents/expiry-required'), DriverDocErrorCodes.expiryRequired);
      expect(DriverDocErrorCodes.fromMessage('x'), DriverDocErrorCodes.failed);
    });
  });

  group('DriverDocumentsScreen', () {
    for (final size in const [Size(360, 1800), Size(1280, 1800)]) {
      testWidgets('lists statuses and uploads with expiry (${size.width.toInt()}px)', (tester) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repo = _FakeRepo({
          DriverDocType.license: _doc(DriverDocType.license, DriverDocStatus.approved, expires: DateTime(2026, 10, 25)),
          DriverDocType.idCard: _doc(DriverDocType.idCard, DriverDocStatus.rejected, reason: 'foto borrosa'),
        });
        await tester.pumpWidget(_app(DriverDocumentsScreen(
          repository: repo,
          now: _now,
          pickFile: () async => (bytes: Uint8List.fromList([1, 2, 3]), name: 'soat.jpg', contentType: 'image/jpeg'),
          pickExpiry: (_, __) async => DateTime(2027, 3, 1),
        )));
        await tester.pumpAndSettle();

        expect(find.text('Verificación pendiente'), findsOneWidget);
        expect(find.text('Por vencer'), findsOneWidget);
        expect(find.text('Rechazado'), findsOneWidget);
        expect(find.text('Motivo: foto borrosa'), findsOneWidget);
        expect(find.text('Falta'), findsNWidgets(3));
        expect(tester.takeException(), isNull);

        // SOAT is the 4th card; its button reads "Subir".
        await tester.tap(find.text('Subir').at(1));
        await tester.pumpAndSettle();
        expect(repo.calls, ['upload:d1:soat:soat.jpg:image/jpeg:2027']);
        expect(find.text('Documento enviado a revisión'), findsOneWidget);
        expect(find.text('En revisión'), findsOneWidget);
      });
    }

    testWidgets('fully verified (en)', (tester) async {
      final repo = _FakeRepo({
        for (final t in DriverDocType.values)
          t: _doc(t, DriverDocStatus.approved, expires: t.expires ? DateTime(2028) : null),
      });
      await tester.pumpWidget(_app(DriverDocumentsScreen(repository: repo, now: _now), locale: const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text('Verified chauffeur'), findsOneWidget);
      expect(find.text('5 of 5 approved'), findsOneWidget);
    });
  });

  testWidgets('home banner tells what is missing or expiring (pt)', (tester) async {
    final repo = _FakeRepo({
      DriverDocType.license: _doc(DriverDocType.license, DriverDocStatus.approved, expires: DateTime(2026, 10, 20)),
    });
    await tester.pumpWidget(_app(
      Scaffold(body: DriverVerificationBanner(driverId: 'd1', verified: false, repository: repo, now: _now)),
      locale: const Locale('pt'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Faltam 4 documentos para você receber viagens.'), findsOneWidget);

    await tester.pumpWidget(_app(
      Scaffold(body: DriverVerificationBanner(driverId: 'd1', verified: true, repository: repo, now: _now)),
      locale: const Locale('pt'),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('vence em breve'), findsOneWidget);
  });

  testWidgets('admin review: open, reject with reason, approve with expiry', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = <String>[];
    final repo = _FakeRepo({
      DriverDocType.criminalRecord: _doc(DriverDocType.criminalRecord, DriverDocStatus.pending, expires: DateTime(2027, 1, 1)),
      DriverDocType.vehicleRegistration: _doc(DriverDocType.vehicleRegistration, DriverDocStatus.pending),
    });
    await tester.pumpWidget(_app(DriverDocumentsReviewPage(
      driverId: 'd1',
      driverName: 'Carlos',
      repository: repo,
      now: _now,
      openUrl: (u) async => opened.add(u),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Documentos de Carlos'), findsOneWidget);

    await tester.tap(find.text('Ver archivo').first);
    await tester.pumpAndSettle();
    expect(opened.single, contains('criminalRecord.pdf'));

    // Reject without a reason is refused locally, then with one.
    await tester.tap(find.text('Rechazar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Rechazar')));
    await tester.pumpAndSettle();
    expect(find.text('Escribe el motivo del rechazo.'), findsOneWidget);
    expect(repo.calls, isEmpty);

    await tester.tap(find.text('Rechazar').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), 'Vencido');
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Rechazar')));
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'review:criminalRecord:false:Vencido:false');

    // RUAT has no expiry: approve goes straight through.
    await tester.tap(find.text('Aprobar').last);
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'review:vehicleRegistration:true::false');
    expect(find.text('Documento aprobado'), findsOneWidget);
  });
}
