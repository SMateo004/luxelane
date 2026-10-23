import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/incidents/presentation/bloc/incident_bloc.dart';
import 'package:luxelane/features/incidents/presentation/help_contacts.dart';
import 'package:luxelane/features/incidents/presentation/widgets/incident_help_sheet.dart';
import 'package:luxelane/features/incidents/presentation/widgets/sos_button.dart';
import 'package:luxelane/features/incidents/presentation/widgets/sos_entry.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements IncidentRepository {}

const _offline = IncidentFailure(IncidentIssue.offline, 'Sin conexión.');

Incident _incident(IncidentStatus s, {int count = 1, bool cancelled = false}) =>
    Incident(
      cancelledByReporter: cancelled,
      id: 'inc1',
      bookingId: 'abcdef123',
      reporterId: 'ana',
      reporterRole: 'rider',
      status: s,
      count: count,
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool screenReader = false,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          accessibleNavigation: screenReader,
          disableAnimations: reduceMotion,
        ),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  late _Repo repo;
  late StreamController<Incident?> mine;

  setUp(() {
    repo = _Repo();
    mine = StreamController<Incident?>.broadcast();
    when(() => repo.watchMine(any(), any())).thenAnswer((_) => mine.stream);
    when(
      () => repo.publishLocation(any(), any(), any()),
    ).thenAnswer((_) async {});
  });
  tearDown(() => mine.close());

  IncidentBloc bloc({Future<LatLngLite?> Function()? where}) => IncidentBloc(
        repository: repo,
        bookingId: 'abcdef123',
        uid: 'ana',
        currentLocation: where ?? () async => (lat: -17.78, lng: -63.18),
        publishEvery: const Duration(milliseconds: 30),
      );

  group('IncidentBloc', () {
    blocTest<IncidentBloc, IncidentState>(
      'SOS con red: envía con la ubicación y queda sin error',
      build: () {
        when(
          () => repo.raise('abcdef123', location: any(named: 'location')),
        ).thenAnswer(
          (_) async => const Right(IncidentRaise(incidentId: 'inc1')),
        );
        return bloc();
      },
      act: (b) => b.add(const IncidentRaised()),
      verify: (b) {
        verify(
          () => repo.raise('abcdef123', location: (lat: -17.78, lng: -63.18)),
        ).called(1);
        expect(b.state.sending, isFalse);
        expect(b.state.failure, isNull);
      },
    );

    blocTest<IncidentBloc, IncidentState>(
      'sin red: falla offline y guarda la última ubicación para el SMS',
      build: () {
        when(
          () => repo.raise(any(), location: any(named: 'location')),
        ).thenAnswer((_) async => const Left(_offline));
        return bloc();
      },
      act: (b) => b.add(const IncidentRaised()),
      verify: (b) {
        expect(b.state.offline, isTrue);
        expect(b.state.lastLocation, (lat: -17.78, lng: -63.18));
      },
    );

    blocTest<IncidentBloc, IncidentState>(
      'repetición: cada pulsación llega al servidor (que suma el contador)',
      build: () {
        when(
          () => repo.raise(any(), location: any(named: 'location')),
        ).thenAnswer(
          (_) async =>
              const Right(IncidentRaise(incidentId: 'inc1', alreadyOpen: true)),
        );
        return bloc();
      },
      act: (b) async {
        b.add(const IncidentRaised());
        await Future<void>.delayed(Duration.zero);
        b.add(const IncidentRaised());
      },
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        verify(
          () => repo.raise(any(), location: any(named: 'location')),
        ).called(2);
        expect(b.state.presses, 2);
      },
    );

    blocTest<IncidentBloc, IncidentState>(
      'ubicación en vivo solo mientras esté abierto; al cerrarse deja de compartir',
      build: bloc,
      act: (b) async {
        b.add(const IncidentWatched());
        await Future<void>.delayed(Duration.zero);
        mine.add(_incident(IncidentStatus.open));
        await Future<void>.delayed(const Duration(milliseconds: 80));
        mine.add(_incident(IncidentStatus.closed));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        clearInteractions(repo);
        await Future<void>.delayed(const Duration(milliseconds: 80));
      },
      verify: (_) =>
          verifyNever(() => repo.publishLocation(any(), any(), any())),
    );

    blocTest<IncidentBloc, IncidentState>(
      'mientras está abierto publica en el incidente propio',
      build: bloc,
      act: (b) async {
        b.add(const IncidentWatched());
        await Future<void>.delayed(Duration.zero);
        mine.add(_incident(IncidentStatus.open));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      verify: (_) => verify(
        () => repo.publishLocation('inc1', -17.78, -63.18),
      ).called(greaterThanOrEqualTo(1)),
    );

    blocTest<IncidentBloc, IncidentState>(
      'falsa alarma: cancela el incidente propio',
      build: () {
        when(
          () => repo.cancel('inc1'),
        ).thenAnswer((_) async => const Right(null));
        return bloc();
      },
      seed: () => IncidentState(incident: _incident(IncidentStatus.open)),
      act: (b) => b.add(const IncidentCancelled()),
      verify: (_) => verify(() => repo.cancel('inc1')).called(1),
    );
  });

  group('cancelación (cancel_requested)', () {
    blocTest<IncidentBloc, IncidentState>(
      'cancelado por el usuario: deja de publicar su ubicación aunque central lo reconozca',
      build: bloc,
      act: (b) async {
        b.add(const IncidentWatched());
        await Future<void>.delayed(Duration.zero);
        mine.add(_incident(IncidentStatus.cancelRequested, cancelled: true));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        mine.add(_incident(IncidentStatus.acknowledged, cancelled: true));
        await Future<void>.delayed(const Duration(milliseconds: 80));
      },
      verify: (b) {
        verifyNever(() => repo.publishLocation(any(), any(), any()));
        expect(b.state.live, isFalse);
      },
    );

    testWidgets('la pantalla dice que central llamará para verificar',
        (tester) async {
      final b = bloc()
        ..emit(IncidentState(
            incident:
                _incident(IncidentStatus.cancelRequested, cancelled: true)));
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: BlocProvider.value(
                      value: b,
                      child: const IncidentHelpSheet(bookingId: 'b'))))));
      expect(find.text('Aviso cancelado'), findsOneWidget);
      expect(find.textContaining('Central te llamará para verificar'),
          findsOneWidget);
      expect(find.text('Fue una falsa alarma'), findsNothing);
    });
  });

  group('SosButton', () {
    testWidgets('mantener 2 s lo activa; soltar antes no', (tester) async {
      var hits = 0;
      await _pump(tester, SosButton(onActivated: () => hits++));
      final g = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('sos-button'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      await g.up();
      await tester.pumpAndSettle();
      expect(hits, 0);
      final g2 = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('sos-button'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 1100));
      await g2.up();
      await tester.pumpAndSettle();
      expect(hits, 1);
    });

    testWidgets('un toque corto no hace nada', (tester) async {
      var hits = 0;
      await _pump(tester, SosButton(onActivated: () => hits++));
      await tester.tap(find.byKey(const ValueKey('sos-button')));
      await tester.pumpAndSettle();
      expect(hits, 0);
    });

    testWidgets('con lector de pantalla: toque + confirmación', (tester) async {
      var hits = 0;
      await _pump(
        tester,
        SosButton(onActivated: () => hits++),
        screenReader: true,
      );
      await tester.tap(find.byKey(const ValueKey('sos-button')));
      await tester.pumpAndSettle();
      expect(find.text('¿Avisar a central?'), findsOneWidget);
      await tester.tap(find.text('Avisar a central'));
      await tester.pumpAndSettle();
      expect(hits, 1);
    });

    testWidgets('etiqueta accesible con la indicación de uso', (tester) async {
      await _pump(tester, SosButton(onActivated: () {}));
      expect(find.bySemanticsLabel(RegExp('Ayuda SOS')), findsOneWidget);
    });

    testWidgets('con «reducir movimiento» funciona igual', (tester) async {
      var hits = 0;
      await _pump(
        tester,
        SosButton(onActivated: () => hits++),
        reduceMotion: true,
      );
      final g = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('sos-button'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2100));
      await g.up();
      await tester.pumpAndSettle();
      expect(hits, 1);
    });
  });

  group('IncidentHelpSheet', () {
    Widget sheet(
      IncidentBloc b, {
      String? phone,
      Map<String, String> numbers = const {},
      List<Uri>? opened,
    }) =>
        BlocProvider.value(
          value: b,
          child: IncidentHelpSheet(
            bookingId: 'abcdef123',
            dispatchPhone: phone,
            emergencyNumbers: numbers,
            launch: (u) async => opened?.add(u),
          ),
        );

    testWidgets('sin red: llamar y SMS prellenado a central', (tester) async {
      final b = bloc()
        ..emit(
          const IncidentState(
            failure: _offline,
            lastLocation: (lat: -17.7, lng: -63.1),
          ),
        );
      final opened = <Uri>[];
      await _pump(tester, sheet(b, phone: '+000', opened: opened));
      expect(find.text('No pudimos avisar a central'), findsOneWidget);
      await tester.tap(find.text('Llamar a central'));
      await tester.tap(find.text('Enviar SMS a central'));
      expect(opened.first.toString(), 'tel:+000');
      expect(
        Uri.decodeComponent(opened.last.toString()),
        contains(
          'Reserva #ABCDEF. Ubicación: https://maps.google.com/?q=-17.700000,-63.100000',
        ),
      );
      expect(find.text('Reintentar el aviso'), findsOneWidget);
    });

    testWidgets(
      'sin números configurados: «Contacta con las autoridades locales»',
      (tester) async {
        final b = bloc()..emit(const IncidentState(failure: _offline));
        await _pump(tester, sheet(b));
        expect(find.text(kNoNumbersHelp), findsOneWidget);
        expect(find.text('Llamar a central'), findsNothing);
      },
    );

    testWidgets('con números de emergencia: botón por número', (tester) async {
      final b = bloc()
        ..emit(IncidentState(incident: _incident(IncidentStatus.open)));
      final opened = <Uri>[];
      await _pump(
        tester,
        sheet(b, numbers: {'Línea de prueba': '000'}, opened: opened),
      );
      await tester.tap(find.text('Línea de prueba'));
      expect(opened.single.toString(), 'tel:000');
      expect(find.text(kNoNumbersHelp), findsNothing);
    });

    testWidgets('estados: avisamos, reconocida, cerrada; repetición visible', (
      tester,
    ) async {
      final b = bloc()
        ..emit(
          IncidentState(incident: _incident(IncidentStatus.open, count: 3)),
        );
      await _pump(tester, sheet(b));
      expect(find.text('Avisamos a central'), findsOneWidget);
      expect(find.text('Aviso enviado 3 veces.'), findsOneWidget);
      b.emit(IncidentState(incident: _incident(IncidentStatus.acknowledged)));
      await tester.pumpAndSettle();
      expect(find.text('Central recibió tu aviso'), findsOneWidget);
      b.emit(IncidentState(incident: _incident(IncidentStatus.closed)));
      await tester.pumpAndSettle();
      expect(find.text('Aviso cerrado'), findsOneWidget);
      expect(find.text('Fue una falsa alarma'), findsNothing);
    });

    testWidgets('falsa alarma pide confirmación', (tester) async {
      when(
        () => repo.cancel('inc1'),
      ).thenAnswer((_) async => const Right(null));
      final b = bloc()
        ..emit(IncidentState(incident: _incident(IncidentStatus.open)));
      await _pump(tester, sheet(b));
      await tester.ensureVisible(find.text('Fue una falsa alarma'));
      await tester.tap(find.text('Fue una falsa alarma'));
      await tester.pumpAndSettle();
      expect(find.text('¿Fue una falsa alarma?'), findsOneWidget);
      await tester.tap(find.text('Cancelar aviso'));
      await tester.pumpAndSettle();
      verify(() => repo.cancel('inc1')).called(1);
    });
  });

  group('SosEntry', () {
    test('ventana: de driver_arriving a in_progress', () {
      expect(BookingStatus.values.where(sosAvailable).toSet(), {
        BookingStatus.driverArriving,
        BookingStatus.driverArrived,
        BookingStatus.verified,
        BookingStatus.inProgress,
      });
    });

    testWidgets('fuera de la ventana no hay botón', (tester) async {
      await _pump(
        tester,
        SosEntry(
          bookingId: 'b',
          uid: 'ana',
          status: BookingStatus.confirmed,
          repository: repo,
        ),
      );
      await tester.pump();
      expect(find.byType(SosButton), findsNothing);
    });

    testWidgets('en la ventana: botón; con aviso abierto, «Ayuda en curso»', (
      tester,
    ) async {
      await _pump(
        tester,
        SosEntry(
          bookingId: 'b',
          uid: 'ana',
          status: BookingStatus.inProgress,
          repository: repo,
          openHelp: (_, __) async {},
        ),
      );
      await tester.pump();
      expect(find.byType(SosButton), findsOneWidget);
      mine.add(_incident(IncidentStatus.open));
      await tester.pump();
      await tester.pump();
      expect(find.text('Ayuda en curso'), findsOneWidget);
    });
  });
}
