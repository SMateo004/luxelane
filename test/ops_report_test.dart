import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/domain/ops_report.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:luxelane/features/admin/presentation/widgets/reports_tab.dart';

import 'helpers/l10n.dart';

class _MockAdminBloc extends MockBloc<AdminEvent, AdminState> implements AdminBloc {}

final _now = DateTime(2026, 10, 7, 15);

Booking _b(
  String id,
  DateTime at, {
  BookingStatus status = BookingStatus.completed,
  double price = 100,
  double? finalPrice,
  String? driverId,
  String? driverName,
  int? rating,
  VehicleClass vehicle = VehicleClass.business,
  ServiceType service = ServiceType.oneWay,
  String? cancelledBy,
  bool late = false,
  String? cancelReason,
  DateTime? pickupAt,
}) =>
    Booking(
      id: id,
      riderId: 'r1',
      driverId: driverId,
      origin: const Place(address: 'A', lat: 0, lng: 0),
      destination: const Place(address: 'B', lat: 0, lng: 0),
      scheduledAt: at,
      pickupAt: pickupAt,
      vehicleClass: vehicle,
      serviceType: service,
      status: status,
      estimatedPrice: price,
      finalPrice: finalPrice,
      createdAt: at,
      updatedAt: at,
      riderRating: rating,
      chauffeur: driverName == null
          ? null
          : Chauffeur(driverId: driverId!, name: driverName, vehicle: 'S', plate: 'X'),
      cancelledBy: cancelledBy,
      lateCancellation: late,
      cancelReason: cancelReason,
    );

final _bookings = [
  _b('1', DateTime(2026, 10, 7, 8), price: 300, finalPrice: 350, driverId: 'd1', driverName: 'Carlos', rating: 5),
  _b('2', DateTime(2026, 10, 6, 8, 30), price: 200, driverId: 'd1', driverName: 'Carlos', rating: 4,
      vehicle: VehicleClass.firstClass),
  _b('3', DateTime(2026, 10, 5, 19), price: 500, driverId: 'd2', service: ServiceType.byTheHour),
  _b('4', DateTime(2026, 10, 7, 8), status: BookingStatus.cancelled, cancelledBy: 'rider', late: true),
  _b('5', DateTime(2026, 10, 4, 22), status: BookingStatus.cancelled, cancelReason: 'no_driver_assigned'),
  _b('6', DateTime(2026, 10, 7, 12), status: BookingStatus.pending),
  // Outside the 7-day window (and in the previous one).
  _b('7', DateTime(2026, 9, 28, 10), price: 1000, driverId: 'd2'),
  // Tomorrow: not in the window yet.
  _b('8', DateTime(2026, 10, 8, 10), price: 999),
  // Booked for the 30th but moved into the window by a flight delay.
  _b('9', DateTime(2026, 9, 30, 23), pickupAt: DateTime(2026, 10, 1, 1), price: 50),
];

void main() {
  setUpAll(() => initializeDateFormatting());

  group('OpsReport', () {
    final r = OpsReport.lastDays(_bookings, 7, now: _now, driverName: (id) => 'User $id');

    test('window is the last 7 calendar days, today included', () {
      expect(r.from, DateTime(2026, 10, 1));
      expect(r.to, DateTime(2026, 10, 8));
      expect(r.days, hasLength(7));
      expect(r.days.first.day, DateTime(2026, 10, 1));
    });

    test('counts, revenue and rates', () {
      expect(r.total, 7); // 1,2,3,4,5,6,9
      expect(r.completed, 4); // 1,2,3,9
      expect(r.revenue, 350 + 200 + 500 + 50); // final price wins over quote
      expect(r.avgTicket, closeTo(1100 / 4, 0.001));
      expect(r.cancelled, 2);
      expect(r.cancellationRate, closeTo(2 / 7, 0.001));
      expect(r.lateCancellations, 1);
      expect(r.unserved, 1);
      expect(r.cancelledBy, {'rider': 1, 'system': 1});
      expect(r.avgRating, 4.5);
      expect(r.ratingCount, 2);
    });

    test('per day, per hour and mix', () {
      final oct7 = r.days.last;
      expect(oct7.trips, 1);
      expect(oct7.revenue, 350);
      expect(r.days.first.trips, 1); // flight-delayed booking 9
      expect(r.demandByHour[8], 3); // 1, 2 and the cancelled 4
      expect(r.demandByHour.reduce((a, b) => a + b), r.total);
      expect(r.byVehicle[VehicleClass.firstClass], 1);
      expect(r.byVehicle[VehicleClass.electric], 0);
      expect(r.byService[ServiceType.byTheHour], 1);
    });

    test('chauffeurs ranked by trips, name from snapshot or users', () {
      expect(r.drivers.map((d) => d.driverId), ['d1', 'd2']);
      expect(r.drivers.first.name, 'Carlos');
      expect(r.drivers.first.revenue, 550);
      expect(r.drivers.first.avgRating, 4.5);
      expect(r.drivers.last.name, 'User d2');
      expect(r.drivers.last.avgRating, isNull);
    });

    test('previous window has the same length and ends where this starts', () {
      final p = r.previous(_bookings);
      expect(p.from, DateTime(2026, 9, 24));
      expect(p.to, r.from);
      expect(p.completed, 1);
      expect(p.revenue, 1000);
    });

    test('CSV export is escaped and formula-safe', () {
      final rows = OpsReport.compute(
        [_b('x', DateTime(2026, 10, 7, 9), driverId: 'd9', driverName: '=HYPERLINK("x"), Inc')],
        DateTime(2026, 10, 7),
        DateTime(2026, 10, 8),
      );
      expect(
        rows.driversCsv(nameHeader: 'Chófer', tripsHeader: 'Viajes', revenueHeader: 'Bs', ratingHeader: 'Nota'),
        'Chófer,Viajes,Bs,Nota\n"\'=HYPERLINK(""x""), Inc",1,100.00,\n',
      );
      expect(
        rows.dailyCsv(dateHeader: 'Fecha', tripsHeader: 'Viajes', revenueHeader: 'Bs'),
        'Fecha,Viajes,Bs\n2026-10-07,1,100.00\n',
      );
    });

    test('empty input gives a zeroed report', () {
      final e = OpsReport.lastDays(const [], 30, now: _now);
      expect(e.total, 0);
      expect(e.avgTicket, 0);
      expect(e.cancellationRate, 0);
      expect(e.avgRating, isNull);
      expect(e.days, hasLength(30));
    });
  });

  group('ReportsTab', () {
    Widget app(Locale locale, List<Booking> bookings) {
      final bloc = _MockAdminBloc();
      whenListen(bloc, const Stream<AdminState>.empty(),
          initialState: AdminState(bookings: bookings));
      return BlocProvider<AdminBloc>.value(
        value: bloc,
        child: localizedApp(Scaffold(body: ReportsTab(now: _now)), locale: locale),
      );
    }

    for (final size in const [Size(390, 900), Size(1440, 1000)]) {
      testWidgets('renders KPIs and switches period (${size.width.toInt()}px)', (tester) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(app(const Locale('es'), _bookings));
        await tester.pump();
        expect(find.text('Reportes de operaciones'), findsOneWidget);
        expect(find.text('Viajes completados'), findsOneWidget);
        expect(find.text('2 de 7 reservas'), findsNothing); // 30 days → 8 total
        expect(find.text('2 de 8 reservas'), findsOneWidget);

        await tester.tap(find.text('7 días'));
        await tester.pump();
        expect(find.text('2 de 7 reservas'), findsOneWidget);
        expect(find.text('Carlos'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('English and Portuguese labels', (tester) async {
      await tester.pumpWidget(app(const Locale('en'), _bookings));
      await tester.pump();
      expect(find.text('Operations reports'), findsOneWidget);
      expect(find.text('Average fare'), findsOneWidget);
      expect(find.text('30 days'), findsOneWidget);

      await tester.pumpWidget(app(const Locale('pt'), _bookings));
      await tester.pump();
      expect(find.text('Relatórios de operações'), findsOneWidget);
      expect(find.text('Taxa de cancelamento'), findsOneWidget);
    });

    testWidgets('empty period shows the empty state', (tester) async {
      await tester.pumpWidget(app(const Locale('es'), const []));
      await tester.pump();
      expect(find.text('No hay reservas con recogida en este período.'), findsOneWidget);
    });
  });
}
