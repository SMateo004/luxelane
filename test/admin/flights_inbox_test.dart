import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/data/flights_admin_repository.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_flights_tab.dart';

import 'flights_fakes.dart';

/// Panel, vuelos (B3): las tres bandejas («Por verificar», «Sin datos»,
/// «Cancelados o desviados»), vacía, con error y recortada.
void main() {
  late FakeFlightsRepo repo;

  setUp(() => repo = FakeFlightsRepo());

  /// Una de cada caso, más las que no van en ninguna.
  final all = [
    // Por verificar: lo declaró el pasajero (y sin datos en vivo).
    fakeFlightBooking(
      'verify0001',
      flight: fakeFlight(
        source: FlightSource.passenger,
        quality: FlightDataQuality.none,
        number: 'PV1',
        readyAt: DateTime.utc(2026, 11, 20, 20),
      ),
    ),
    // Sin datos: dato viejo de la fuente automática.
    fakeFlightBooking(
      'stale00002',
      flight: fakeFlight(quality: FlightDataQuality.stale, number: 'ST2'),
    ),
    // Al día y automático: en ninguna.
    fakeFlightBooking('okay000003', flight: fakeFlight(number: 'OK3')),
    // Cancelado, reserva viva (flightActive ya es false).
    fakeFlightBooking(
      'cancel0004',
      active: false,
      flight: fakeFlight(status: FlightStatus.cancelled, number: 'CX4'),
    ),
    // Desviado, chófer en el punto.
    fakeFlightBooking(
      'divert0005',
      active: false,
      bookingStatus: BookingStatus.driverArrived,
      flight: fakeFlight(status: FlightStatus.diverted, number: 'DV5'),
    ),
    // Cancelado pero la reserva ya terminó: no va.
    fakeFlightBooking(
      'finish0006',
      active: false,
      bookingStatus: BookingStatus.cancelled,
      flight: fakeFlight(status: FlightStatus.cancelled, number: 'FN6'),
    ),
    // Pasajero pero ya no se vigila: no va.
    fakeFlightBooking(
      'inactive07',
      active: false,
      flight: fakeFlight(source: FlightSource.passenger, number: 'IN7'),
    ),
  ];

  final opened = <String>[];

  Future<void> pump(WidgetTester t, {double width = 1280}) => pumpPanel(
        t,
        FlightsTab(
          repository: repo,
          onOpenBooking: (_, id, __) async => opened.add(id),
        ),
        width: width,
      );

  Iterable<String> numbersShown() => [
        for (final n in ['PV1', 'ST2', 'OK3', 'CX4', 'DV5', 'FN6', 'IN7'])
          if (find.textContaining(n).evaluate().isNotEmpty) n,
      ];

  setUp(opened.clear);

  testWidgets('las tres bandejas filtran y cuentan', (t) async {
    repo.inboxAnswer = Right(FlightInbox(items: all));
    await pump(t);
    expect(repo.inboxCalls, 1);
    expect(find.text('Por verificar · 1'), findsOneWidget);
    expect(find.text('Sin datos · 2'), findsOneWidget);
    expect(find.text('Cancelados o desviados · 2'), findsOneWidget);
    expect(numbersShown(), ['PV1']);
    expect(
        find.text('Chófer en el punto: 20 nov 2026 · 16:00'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('flights-kind-noData')));
    await t.pumpAndSettle();
    expect(numbersShown(), ['PV1', 'ST2']);

    await t.tap(find.byKey(const ValueKey('flights-kind-disrupted')));
    await t.pumpAndSettle();
    expect(numbersShown(), ['CX4', 'DV5']);
    expect(find.text('Cancelado'), findsOneWidget);
    expect(find.text('Desviado'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('flights-row-divert0005')));
    await t.pumpAndSettle();
    expect(opened, ['divert0005']);
    // Al volver, la bandeja se lee de nuevo.
    expect(repo.inboxCalls, 2);
  });

  testWidgets('sin la función de abrir, la fila abre la tarjeta del vuelo',
      (t) async {
    repo.inboxAnswer = Right(FlightInbox(items: all));
    repo.initial['verify0001'] = all.first;
    await pumpPanel(t, FlightsTab(repository: repo));
    await t.tap(find.byKey(const ValueKey('flights-row-verify0001')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('flight-booking-dialog')), findsOneWidget);
    expect(find.byKey(const ValueKey('flight-card')), findsOneWidget);
    expect(find.text('Pasajero'), findsOneWidget);
  });

  testWidgets('vacía: lo dice en cada bandeja', (t) async {
    await pump(t);
    expect(find.byKey(const ValueKey('flights-inbox-empty')), findsOneWidget);
    expect(find.text('No hay vuelos por verificar'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('flights-kind-noData')));
    await t.pumpAndSettle();
    expect(find.text('No hay vuelos sin datos'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('flights-kind-disrupted')));
    await t.pumpAndSettle();
    expect(find.text('No hay vuelos cancelados ni desviados'), findsOneWidget);
  });

  testWidgets('error: mensaje y reintentar vuelve a pedir', (t) async {
    repo.inboxAnswer = const Left(FlightAdminFailure('Sin conexión de prueba'));
    await pump(t);
    expect(find.byKey(const ValueKey('flights-inbox-error')), findsOneWidget);
    expect(find.text('No se pudo cargar la bandeja de vuelos'), findsOneWidget);
    expect(find.text('Sin conexión de prueba'), findsOneWidget);
    repo.inboxAnswer = Right(FlightInbox(items: all));
    await t.tap(find.byKey(const ValueKey('flights-retry')));
    await t.pumpAndSettle();
    expect(repo.inboxCalls, 2);
    expect(numbersShown(), ['PV1']);
  });

  testWidgets('recortada: lo dice', (t) async {
    repo.inboxAnswer = Right(FlightInbox(items: all, truncated: true));
    await pump(t, width: 768);
    expect(
      find.text(
        'Se leyeron las primeras 200 reservas con vuelo: puede haber más.',
      ),
      findsOneWidget,
    );
  });

  test('filtro puro: orden por readyAt', () {
    final a = fakeFlightBooking(
      'a',
      flight: fakeFlight(
        source: FlightSource.passenger,
        readyAt: DateTime.utc(2026, 11, 21),
      ),
    );
    final b = fakeFlightBooking(
      'b',
      flight: fakeFlight(
        source: FlightSource.passenger,
        readyAt: DateTime.utc(2026, 11, 20),
      ),
    );
    expect(
      FlightInboxKind.toVerify.pick([a, b]).map((x) => x.bookingId),
      ['b', 'a'],
    );
  });
}
