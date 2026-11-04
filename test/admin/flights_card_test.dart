import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/data/flights_admin_repository.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_flight_card.dart';

import 'flights_fakes.dart';

/// Panel, vuelos (B3): tarjeta «Vuelo» del detalle de la reserva, el
/// formulario de adminSetFlightInfo, quitar el bloqueo y «no se presentó».
void main() {
  late FakeFlightsRepo repo;
  final picked = <DateTime>[];

  setUp(() {
    repo = FakeFlightsRepo();
    picked.clear();
  });

  /// Elige siempre esta hora de pared de La Paz.
  Future<DateTime?> picker(BuildContext _, DateTime initial) async {
    picked.add(initial);
    return DateTime.utc(2026, 11, 20, 14, 50);
  }

  Future<void> pump(WidgetTester t, FlightBooking? b) async {
    repo.initial['b1'] = b;
    await pumpPanel(
      t,
      SingleChildScrollView(
        child: AdminFlightCard(
          bookingId: 'b1',
          repository: repo,
          picker: picker,
        ),
      ),
    );
  }

  Future<void> scrollTap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  testWidgets('sin vuelo no muestra nada', (t) async {
    await pump(t, null);
    expect(find.byKey(const ValueKey('flight-card')), findsNothing);
  });

  testWidgets('muestra el vuelo, la fuente, el bloqueo y quién lo fijó',
      (t) async {
    repo.changeAnswer = Right(
      FlightManualChange(
        clearedLock: false,
        adminEmail: 'central@example.com',
        at: DateTime.utc(2026, 11, 20, 13, 5),
        reason: 'Llamada a la aerolínea',
      ),
    );
    await pump(
      t,
      fakeFlightBooking(
        'b1',
        flight: fakeFlight(
          status: FlightStatus.delayed,
          source: FlightSource.manual,
          manualLock: true,
          estimated: DateTime.utc(2026, 11, 20, 18, 20),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('flight-card')), findsOneWidget);
    expect(find.text('Vuelo'), findsOneWidget);
    expect(find.text('El chófer debe estar a las 14:35'), findsOneWidget);
    expect(find.text('Aerolínea Prueba'), findsOneWidget);
    expect(find.text('OB760'), findsOneWidget);
    expect(find.text('Internacional'), findsOneWidget);
    expect(find.text('2026-11-20'), findsOneWidget);
    // Programada 18:00 UTC = 14:00 en La Paz; estimada 14:20.
    expect(find.text('20 nov 2026 · 14:00'), findsOneWidget);
    expect(find.text('20 nov 2026 · 14:20'), findsOneWidget);
    expect(find.text('Retrasado'), findsWidgets);
    expect(find.text('Central'), findsOneWidget);
    expect(find.text('Al día'), findsOneWidget);
    expect(find.text('Bloqueo manual'), findsOneWidget);
    expect(
      find.text(
        'Bloqueo manual: las fuentes automáticas no cambian estos datos.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Fijado por central@example.com el 20 nov 2026 · 09:05'),
      findsOneWidget,
    );
    expect(find.text('Motivo: Llamada a la aerolínea'), findsOneWidget);
    expect(find.byKey(const ValueKey('flight-clear-lock')), findsOneWidget);
    // La reserva está confirmada: no se puede marcar «no se presentó».
    expect(find.byKey(const ValueKey('flight-force-no-show')), findsNothing);
  });

  testWidgets('fuente pasajero y sin datos en vivo, sin bloqueo', (t) async {
    await pump(
      t,
      fakeFlightBooking(
        'b1',
        flight: fakeFlight(
          source: FlightSource.passenger,
          quality: FlightDataQuality.none,
        ),
      ),
    );
    expect(find.text('Pasajero'), findsOneWidget);
    expect(find.text('Sin datos en vivo'), findsOneWidget);
    expect(find.text('Sin bloqueo manual'), findsOneWidget);
    expect(find.byKey(const ValueKey('flight-clear-lock')), findsNothing);
  });

  testWidgets('se actualiza en vivo', (t) async {
    await pump(t, fakeFlightBooking('b1'));
    expect(find.text('Automático'), findsOneWidget);
    repo.flights['b1']!.add(
      fakeFlightBooking(
        'b1',
        flight: fakeFlight(readyAt: DateTime.utc(2026, 11, 20, 19, 10)),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('El chófer debe estar a las 15:10'), findsOneWidget);
  });

  group('fijar datos del vuelo', () {
    Future<void> open(WidgetTester t) async {
      await pump(t, fakeFlightBooking('b1'));
      await scrollTap(t, find.byKey(const ValueKey('flight-set')));
      expect(find.byKey(const ValueKey('flight-set-dialog')), findsOneWidget);
    }

    FilledButton confirm(WidgetTester t) => t.widget<FilledButton>(
          find.byKey(const ValueKey('flight-set-confirm')),
        );

    Future<void> chooseStatus(WidgetTester t, String label) async {
      await t.tap(find.byKey(const ValueKey('flight-set-status')));
      await t.pumpAndSettle();
      await t.tap(find.text(label).last);
      await t.pumpAndSettle();
    }

    testWidgets('el motivo necesita al menos 10 caracteres', (t) async {
      await open(t);
      expect(confirm(t).onPressed, isNull);
      await t.enterText(find.byKey(const ValueKey('flight-reason')), 'corto');
      await t.pump();
      expect(
        find.text('El motivo necesita al menos 10 caracteres'),
        findsOneWidget,
      );
      expect(confirm(t).onPressed, isNull);
      await t.enterText(
        find.byKey(const ValueKey('flight-reason')),
        'Confirmado con la aerolínea',
      );
      await t.pump();
      expect(confirm(t).onPressed, isNotNull);
    });

    testWidgets('con «Aterrizó» exige la llegada real y manda ms', (t) async {
      await open(t);
      await t.enterText(
        find.byKey(const ValueKey('flight-reason')),
        'Confirmado con la aerolínea',
      );
      await chooseStatus(t, 'Aterrizó');
      expect(
        find.text('Con «Aterrizó» la llegada real es obligatoria'),
        findsOneWidget,
      );
      expect(confirm(t).onPressed, isNull);

      await scrollTap(t, find.byKey(const ValueKey('flight-set-actual')));
      // Parte de la hora programada (14:00 en La Paz).
      expect(picked.single, DateTime.utc(2026, 11, 20, 14));
      expect(
        find.text('Con «Aterrizó» la llegada real es obligatoria'),
        findsNothing,
      );
      expect(find.text('20 nov 2026 · 14:50'), findsOneWidget);
      await scrollTap(t, find.byKey(const ValueKey('flight-set-confirm')));

      expect(find.byKey(const ValueKey('flight-set-dialog')), findsNothing);
      expect(find.text('Datos del vuelo fijados'), findsOneWidget);
      final (id, input) = repo.setCalls.single;
      expect(id, 'b1');
      // 14:50 en La Paz = 18:50 UTC.
      expect(input.toPayload(id), {
        'bookingId': 'b1',
        'status': 'landed',
        'estimatedArrival': null,
        'actualArrival':
            DateTime.utc(2026, 11, 20, 18, 50).millisecondsSinceEpoch,
        'reason': 'Confirmado con la aerolínea',
      });
      // Tras guardar, vuelve a leer quién lo fijó.
      expect(repo.changeCalls, 2);
    });

    testWidgets('quitar la hora estimada manda null', (t) async {
      await pump(
        t,
        fakeFlightBooking(
          'b1',
          flight: fakeFlight(estimated: DateTime.utc(2026, 11, 20, 18, 20)),
        ),
      );
      await scrollTap(t, find.byKey(const ValueKey('flight-set')));
      await chooseStatus(t, 'Retrasado');
      await scrollTap(
        t,
        find.byKey(const ValueKey('flight-set-estimated-clear')),
      );
      await t.enterText(
        find.byKey(const ValueKey('flight-reason')),
        'Sin hora estimada fiable',
      );
      await t.pump();
      await scrollTap(t, find.byKey(const ValueKey('flight-set-confirm')));
      final (_, input) = repo.setCalls.single;
      expect(input.status, FlightStatus.delayed);
      expect(input.toPayload('b1')['estimatedArrival'], isNull);
      expect(input.toPayload('b1').containsKey('estimatedArrival'), isTrue);
    });

    testWidgets('un error del servidor se ve en el diálogo', (t) async {
      repo.writeAnswer = Left(
        FlightAdminFailure(
          flightAdminErrorMessage('failed-precondition', {
            'reason': 'flight_config_missing',
          }),
        ),
      );
      await open(t);
      await t.enterText(
        find.byKey(const ValueKey('flight-reason')),
        'Confirmado con la aerolínea',
      );
      await t.pump();
      await scrollTap(t, find.byKey(const ValueKey('flight-set-confirm')));
      expect(find.byKey(const ValueKey('flight-set-dialog')), findsOneWidget);
      expect(
        find.text(
          'Faltan los minutos de salida del aeropuerto en la configuración '
          'de operaciones.',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('quitar el bloqueo manual pide motivo y lo manda', (t) async {
    await pump(
      t,
      fakeFlightBooking('b1', flight: fakeFlight(manualLock: true)),
    );
    await scrollTap(t, find.byKey(const ValueKey('flight-clear-lock')));
    expect(find.byKey(const ValueKey('flight-reason-dialog')), findsOneWidget);
    final confirm = find.byKey(const ValueKey('flight-reason-confirm'));
    expect(t.widget<FilledButton>(confirm).onPressed, isNull);
    await t.enterText(
      find.byKey(const ValueKey('flight-reason')),
      '  La fuente ya es fiable  ',
    );
    await t.pump();
    await t.tap(confirm);
    await t.pumpAndSettle();
    expect(repo.clearCalls, [('b1', 'La fuente ya es fiable')]);
    expect(find.text('Bloqueo manual quitado'), findsOneWidget);
  });

  group('marcar no se presentó', () {
    for (final s in BookingStatus.values) {
      testWidgets('botón ${s.label}', (t) async {
        await pump(t, fakeFlightBooking('b1', bookingStatus: s));
        expect(
          find.byKey(const ValueKey('flight-force-no-show')),
          s == BookingStatus.driverArrived ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('desde driver_arrived pide motivo y llama', (t) async {
      await pump(
        t,
        fakeFlightBooking('b1', bookingStatus: BookingStatus.driverArrived),
      );
      await scrollTap(t, find.byKey(const ValueKey('flight-force-no-show')));
      await t.enterText(
        find.byKey(const ValueKey('flight-reason')),
        'Pasajero sin aparecer tras la espera',
      );
      await t.pump();
      await t.tap(find.byKey(const ValueKey('flight-reason-confirm')));
      await t.pumpAndSettle();
      expect(
          repo.noShowCalls, [('b1', 'Pasajero sin aparecer tras la espera')]);
      expect(find.text('Reserva marcada como no se presentó'), findsOneWidget);
    });
  });
}
