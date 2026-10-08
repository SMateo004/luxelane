import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/settlements/data/settlement_repository.dart';
import 'package:luxelane/features/settlements/domain/settlement.dart';
import 'package:luxelane/features/settlements/presentation/driver_week_settlement.dart';
import 'package:luxelane/features/settlements/presentation/settlements_admin_tab.dart';

import 'helpers/l10n.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

// Wednesday 8 Oct 2026 → week of Monday 5 Oct.
final _now = DateTime(2026, 10, 8, 12);
final _week = DateTime(2026, 10, 5);

Booking _b(String id, DateTime at,
        {String driver = 'd1',
        String? name = 'Carlos',
        double price = 100,
        double? finalPrice,
        String? method,
        String? companyId,
        BookingStatus status = BookingStatus.completed}) =>
    Booking(
      id: id,
      riderId: 'r',
      driverId: driver,
      origin: const Place(address: 'A', lat: 0, lng: 0),
      destination: const Place(address: 'B', lat: 0, lng: 0),
      scheduledAt: at,
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: status,
      estimatedPrice: price,
      finalPrice: finalPrice,
      createdAt: at,
      updatedAt: at,
      paymentMethod: method,
      companyId: companyId,
      chauffeur: name == null ? null : Chauffeur(driverId: driver, name: name, vehicle: 'S', plate: 'X'),
    );

final _bookings = [
  _b('cash1', DateTime(2026, 10, 5, 9), price: 200), // chauffeur collected
  _b('cash2', DateTime(2026, 10, 7, 9), price: 100, finalPrice: 150, method: 'pay_later'),
  _b('corp', DateTime(2026, 10, 6, 9), price: 500, method: 'corporate', companyId: 'acme'),
  _b('other', DateTime(2026, 10, 6, 10), driver: 'd2', name: 'Ana', price: 300),
  _b('cancel', DateTime(2026, 10, 6, 11), status: BookingStatus.cancelled),
  _b('prevWeek', DateTime(2026, 10, 4, 23), price: 999),
  _b('nextWeek', DateTime(2026, 10, 12, 0, 30), price: 999),
];

class _FakeRepo implements SettlementRepository {
  _FakeRepo({this.commission, this.records = const []});
  double? commission;
  final List<SettlementRecord> records;
  final calls = <String>[];

  @override
  Stream<double?> watchCommission() => Stream.value(commission);
  @override
  Future<void> setCommission(double pct, {required String adminId}) async => calls.add('commission:$pct:$adminId');
  @override
  Stream<List<Booking>> watchCompleted(DateTime weekStart) => Stream.value(_bookings);
  @override
  Stream<List<SettlementRecord>> watchRecords({DateTime? weekStart, String? driverId}) => Stream.value(records);
  @override
  Future<void> markPaid(DriverSettlement s, DateTime weekStart, double commissionPct, {required String adminId}) async =>
      calls.add('paid:${s.driverId}:${s.balance}:$commissionPct:$adminId');
  @override
  Future<void> unmarkPaid(String driverId, DateTime weekStart) async => calls.add('undo:$driverId');
}

Widget _app(Widget child, {Locale locale = const Locale('es')}) {
  final auth = _MockAuthBloc();
  whenListen(auth, const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(User(
        id: 'boss',
        email: 'a@a.bo',
        phone: '',
        displayName: 'Admin',
        role: UserRole.admin,
        createdAt: DateTime(2025),
        isVerified: true,
        isActive: true,
        fcmTokens: const [],
      )));
  return BlocProvider<AuthBloc>.value(value: auth, child: localizedApp(child, locale: locale));
}

void main() {
  setUpAll(() => initializeDateFormatting());

  group('Settlements', () {
    test('week starts on Monday', () {
      expect(Settlements.weekStart(_now), _week);
      expect(Settlements.weekStart(DateTime(2026, 10, 11, 23)), _week); // Sunday
      expect(Settlements.weekStart(DateTime(2026, 10, 12)), DateTime(2026, 10, 12));
    });

    test('who collected the fare', () {
      expect(collectorOf(_bookings[0]), FareCollector.chauffeur);
      expect(collectorOf(_bookings[2]), FareCollector.luxelane);
      expect(collectorOf(_b('card', _now, method: 'card')), FareCollector.luxelane);
    });

    test('balance: Luxelane share of corporate minus commission on cash', () {
      final rows = Settlements.compute(_bookings, _week, 20);
      expect(rows.map((r) => r.driverId), ['d1', 'd2']);
      final d1 = rows.first;
      expect(d1.trips, 3);
      expect(d1.gross, 200 + 150 + 500); // final price wins
      expect(d1.collectedByChauffeur, 350);
      expect(d1.collectedByLuxelane, 500);
      expect(d1.commission, 170);
      expect(d1.earnings, 680);
      expect(d1.balance, 330); // Luxelane pays 500 − 170
      final d2 = rows.last;
      expect(d2.balance, -60); // owes 20 % of 300
    });

    test('zero commission and empty weeks', () {
      expect(Settlements.compute(_bookings, _week, 0).first.balance, 500);
      expect(Settlements.compute(_bookings, DateTime(2027, 1, 4), 20), isEmpty);
    });

    test('csv and record ids', () {
      final csv = Settlements.csv(Settlements.compute(_bookings, _week, 20), headers: const ['a', 'b', 'c', 'd', 'e', 'f', 'g']);
      expect(csv.split('\n')[1], 'Carlos,3,850.00,350.00,500.00,170.00,330.00');
      expect(Settlements.recordId('d1', _week), 'd1_20261005');
    });
  });

  group('SettlementsAdminTab', () {
    testWidgets('asks for the commission before calculating', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(_app(Scaffold(body: SettlementsAdminTab(repository: repo, now: _now))));
      await tester.pumpAndSettle();
      expect(find.textContaining('Aún no definiste la comisión'), findsOneWidget);
      expect(find.text('Define la comisión para ver las liquidaciones.'), findsOneWidget);

      await tester.tap(find.text('Definir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '80');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa un porcentaje entre 0 y 50.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '20');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['commission:20.0:boss']);
    });

    for (final size in const [Size(390, 2000), Size(1280, 1600)]) {
      testWidgets('shows who pays whom and marks a week settled (${size.width.toInt()}px)', (tester) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repo = _FakeRepo(commission: 20);
        await tester.pumpWidget(_app(Scaffold(body: SettlementsAdminTab(repository: repo, now: _now))));
        await tester.pumpAndSettle();
        expect(find.text('Luxelane paga Bs 330,00'), findsOneWidget);
        expect(find.text('El chófer debe Bs 60,00'), findsOneWidget);
        expect(find.text('Bs 230,00'), findsOneWidget); // total commission
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Marcar liquidado').first);
        await tester.pumpAndSettle();
        expect(repo.calls.single, 'paid:d1:330.0:20.0:boss');
      });
    }

    testWidgets('warns when a settled week changed (en)', (tester) async {
      tester.view
        ..physicalSize = const Size(1280, 1600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _FakeRepo(commission: 20, records: [
        SettlementRecord(driverId: 'd1', weekStart: _week, balance: 300, commissionPct: 20, paidAt: DateTime(2026, 10, 7)),
      ]);
      await tester.pumpWidget(_app(Scaffold(body: SettlementsAdminTab(repository: repo, now: _now)), locale: const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text('Settled on Oct 7'), findsOneWidget);
      expect(find.textContaining('Changed since it was settled'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(repo.calls.single, 'undo:d1');
    });
  });

  testWidgets('chauffeur sees earnings and balance for the week (pt)', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(
      Scaffold(body: SingleChildScrollView(child: DriverWeekSettlement(driverId: 'd1', bookings: _bookings, repository: _FakeRepo(commission: 20), now: _now))),
      locale: const Locale('pt'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Seus ganhos: Bs 680,00'), findsOneWidget);
    expect(find.text('A Luxelane paga a você Bs 330,00'), findsOneWidget);
    expect(find.text('Semana passada'), findsOneWidget);
  });
}
