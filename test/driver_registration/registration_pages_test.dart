import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/driver_registration/data/driver_registration_repository.dart';
import 'package:luxelane/features/driver_registration/data/image_prep.dart';
import 'package:luxelane/features/driver_registration/data/photo_picker.dart';
import 'package:luxelane/features/driver_registration/presentation/bloc/registration_cubit.dart';
import 'package:luxelane/features/driver_registration/presentation/pages/document_capture_page.dart';
import 'package:luxelane/features/driver_registration/presentation/pages/driver_application_intro_page.dart';
import 'package:luxelane/features/driver_registration/presentation/pages/driver_registration_page.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

import 'fakes.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

Future<void> _pump(
  WidgetTester t,
  Widget home, {
  Locale locale = const Locale('es'),
  double width = 390,
  double scale = 1,
}) {
  final auth = _MockAuthBloc();
  when(() => auth.state).thenReturn(const AuthUnauthenticated());
  t.view.physicalSize = Size(width, 1800);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  L10n.use(locale);
  return t.pumpWidget(BlocProvider<AuthBloc>.value(
    value: auth,
    child: MaterialApp(
      locale: locale,
      supportedLocales: LuxLocale.supportedLocales,
      localizationsDelegates: LuxLocale.delegates,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    ),
  ));
}

Widget _registration(FakeRegistrationRepository repo, {PhotoPicker? picker}) =>
    BlocProvider(
      create: (_) =>
          RegistrationCubit(repository: repo, imagePrep: FakeImagePrep())
            ..load(),
      child: DriverRegistrationPage(picker: picker ?? FakePicker()),
    );

void main() {
  setUp(() => debugUploadsSupported = true);
  tearDown(() => debugUploadsSupported = null);

  testWidgets('pantalla previa: explica el cambio y confirma antes de llamar',
      (t) async {
    final repo = FakeRegistrationRepository(fakeApplication());
    var started = 0;
    await _pump(
        t,
        DriverApplicationIntroPage(
            repository: repo, onStarted: () => started++));
    final l = L10n.current;
    expect(find.text(l.regIntroPointOneWay), findsOneWidget);
    expect(find.text(l.regIntroPointBookings), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('reg-intro-start')));
    await t.pumpAndSettle();
    expect(find.text(l.regIntroConfirmBody), findsOneWidget);
    expect(repo.starts, 0);
    await t.tap(find.byKey(const ValueKey('reg-intro-confirm')));
    await t.pumpAndSettle();
    expect(repo.starts, 1);
    expect(started, 1);
  });

  testWidgets('pantalla previa: con reservas, el motivo y sin seguir',
      (t) async {
    final repo = FakeRegistrationRepository(fakeApplication())
      ..startFailure = RegistrationFailure(L10n.current.regErrorHasBookings,
          reason: 'has_bookings');
    var started = 0;
    await _pump(
        t,
        DriverApplicationIntroPage(
            repository: repo, onStarted: () => started++));
    await t.tap(find.byKey(const ValueKey('reg-intro-start')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('reg-intro-confirm')));
    await t.pumpAndSettle();
    expect(find.text(L10n.current.regErrorHasBookings), findsOneWidget);
    expect(started, 0);
  });

  testWidgets('documentos: estado, motivo de rechazo y «Volver a subir»',
      (t) async {
    final repo = FakeRegistrationRepository(fakeApplication(
      status: 'needs_changes',
      documents: [
        {
          'type': 'license_front',
          'status': 'rejected',
          'version': 1,
          'rejectReason': 'illegible',
        },
      ],
    ));
    await _pump(t, _registration(repo));
    await t.pumpAndSettle();
    final l = L10n.current;
    expect(find.text(l.regStatusNeedsChanges), findsOneWidget);
    expect(find.text(DriverDocType.licenseFront.label), findsOneWidget);
    expect(find.text(l.regDocRejectedReason(DocRejectReason.illegible.label)),
        findsOneWidget);
    expect(find.text(l.regDocReupload), findsOneWidget);
    expect(find.text(l.regDocUpload), findsNWidgets(3));
  });

  testWidgets('sin requisitos configurados: aviso y sin documentos', (t) async {
    final repo = FakeRegistrationRepository(fakeApplication(configured: false));
    await _pump(t, _registration(repo));
    await t.pumpAndSettle();
    expect(find.text(L10n.current.regDocsNotConfigured), findsOneWidget);
    expect(find.text(L10n.current.regDocUpload), findsNothing);
  });

  testWidgets('en la web: aviso de usar el teléfono y sin botones de subir',
      (t) async {
    debugUploadsSupported = false;
    final repo = FakeRegistrationRepository(fakeApplication());
    await _pump(t, _registration(repo));
    await t.pumpAndSettle();
    expect(find.text(L10n.current.regWebUploadBlocked), findsOneWidget);
    expect(find.text(L10n.current.regDocUpload), findsNothing);
  });

  testWidgets('enviada: «En revisión» sin plazos ni pasos', (t) async {
    final repo =
        FakeRegistrationRepository(fakeApplication(status: 'submitted'));
    await _pump(t, _registration(repo));
    await t.pumpAndSettle();
    expect(find.text(L10n.current.regStatusReviewTitle), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(
        find.textContaining(RegExp(r'\d+\s*(días|horas|h)\b')), findsNothing);
  });

  group('captura', () {
    Widget capture(DriverRequirement r, FakePicker picker,
            FakeRegistrationRepository repo) =>
        BlocProvider(
          create: (_) =>
              RegistrationCubit(repository: repo, imagePrep: FakeImagePrep())
                ..load(),
          child: DocumentCapturePage(requirement: r, picker: picker),
        );

    testWidgets('foto en vivo: solo cámara frontal, sin galería', (t) async {
      final picker = FakePicker();
      final repo = FakeRegistrationRepository(fakeApplication());
      await _pump(
          t,
          capture(
              const DriverRequirement(
                  type: DriverDocType.livePhoto,
                  required: true,
                  expires: false),
              picker,
              repo));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('reg-from-gallery')), findsNothing);
      expect(find.text(L10n.current.regLiveCameraOnly), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('reg-take-photo')));
      await t.pumpAndSettle();
      expect(picker.calls.single, (source: PhotoSource.camera, front: true));
    });

    testWidgets(
        'revisión antes de enviar: repetir o usar; con vencimiento, la fecha es obligatoria',
        (t) async {
      final picker = FakePicker();
      final repo = FakeRegistrationRepository(fakeApplication());
      await _pump(
          t,
          capture(
              const DriverRequirement(
                  type: DriverDocType.licenseFront,
                  required: true,
                  expires: true),
              picker,
              repo));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('reg-from-gallery')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('reg-take-photo')));
      await t.pumpAndSettle();
      final l = L10n.current;
      expect(find.text(l.regReviewTitle), findsOneWidget);
      expect(find.text(l.regRetake), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('reg-use-photo')));
      await t.pumpAndSettle();
      expect(find.text(l.regExpiryRequired), findsOneWidget);
      expect(repo.uploads, isEmpty);
      await t.tap(find.text(l.regRetake));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('reg-take-photo')), findsOneWidget);
    });
  });

  for (final w in [390.0, 768.0, 1280.0]) {
    for (final loc in const [Locale('es'), Locale('en'), Locale('pt')]) {
      testWidgets('sin desbordes a $w px, ${loc.languageCode}, texto al 200 %',
          (t) async {
        final repo = FakeRegistrationRepository(fakeApplication(
          status: 'needs_changes',
          mfaEnforced: true,
          documents: [
            {
              'type': 'license_front',
              'status': 'rejected',
              'version': 1,
              'rejectReason': 'data_mismatch',
              'expiresAt': DateTime(2030).millisecondsSinceEpoch,
            },
          ],
        ));
        await _pump(t, _registration(repo), locale: loc, width: w, scale: 2);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await _pump(
            t, DriverApplicationIntroPage(repository: repo, onStarted: () {}),
            locale: loc, width: w, scale: 2);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }
  }

  testWidgets('lector de pantalla: progreso con etiqueta y botones de 48 px',
      (t) async {
    final handle = t.ensureSemantics();
    final repo = FakeRegistrationRepository(fakeApplication());
    await _pump(t, _registration(repo));
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel(L10n.current.regProgressLabel(3, 4)),
        findsOneWidget);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
