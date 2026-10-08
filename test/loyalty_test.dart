import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/booking/domain/booking_error_codes.dart';
import 'package:luxelane/features/booking/presentation/booking_error_l10n.dart';
import 'package:luxelane/features/loyalty/data/loyalty_repository.dart';
import 'package:luxelane/features/loyalty/domain/loyalty.dart';
import 'package:luxelane/features/loyalty/presentation/loyalty_widgets.dart';
import 'package:luxelane/features/trips/presentation/pages/receipt_page.dart';
import 'package:luxelane/l10n/gen/app_localizations_es.dart';

import 'helpers/l10n.dart';

const _tiers = [
  LoyaltyTier(id: LoyaltyTierId.silver, minRides: 5, discountPct: 3),
  LoyaltyTier(id: LoyaltyTierId.gold, minRides: 15, discountPct: 7),
  LoyaltyTier(id: LoyaltyTierId.platinum, minRides: 40, discountPct: 10),
];

class _FakeRepo implements LoyaltyRepository {
  _FakeRepo({this.enabled = false, this.tiers = const [], this.status = LoyaltyStatus.off});
  final bool enabled;
  final List<LoyaltyTier> tiers;
  final LoyaltyStatus status;
  final saved = <({bool enabled, List<LoyaltyTier> tiers})>[];

  @override
  Stream<({bool enabled, List<LoyaltyTier> tiers})> watchConfig() => Stream.value((enabled: enabled, tiers: tiers));
  @override
  Future<void> saveConfig({required bool enabled, required List<LoyaltyTier> tiers}) async =>
      saved.add((enabled: enabled, tiers: tiers));
  @override
  Future<LoyaltyStatus> myStatus() async => status;
}

void main() {
  setUpAll(() => initializeDateFormatting());

  group('Loyalty domain', () {
    test('discount in whole Bs, rounded down (same as the server)', () {
      expect(Loyalty.discount(333, 7), 23);
      expect(Loyalty.discount(333, 0), 0);
      expect(Loyalty.discount(10, 20), 2);
    });

    test('config checks mirror the server', () {
      expect(Loyalty.configError(_tiers), isNull);
      expect(Loyalty.configError(const []), 'loyalty/no-tiers');
      expect(
        Loyalty.configError(const [
          LoyaltyTier(id: LoyaltyTierId.silver, minRides: 5, discountPct: 3),
          LoyaltyTier(id: LoyaltyTierId.gold, minRides: 5, discountPct: 4),
        ]),
        'loyalty/thresholds-order',
      );
      expect(
        Loyalty.configError(const [
          LoyaltyTier(id: LoyaltyTierId.silver, minRides: 5, discountPct: 8),
          LoyaltyTier(id: LoyaltyTierId.gold, minRides: 10, discountPct: 5),
        ]),
        'loyalty/discounts-order',
      );
      expect(Loyalty.configError(const [LoyaltyTier(id: LoyaltyTierId.silver, minRides: 5, discountPct: 25)]),
          'loyalty/discount-range');
    });

    test('status parses the callable and computes progress', () {
      final s = LoyaltyStatus.fromJson({
        'enabled': true,
        'rides': 10,
        'tier': {'id': 'silver', 'minRides': 5, 'discountPct': 3},
        'next': {'id': 'gold', 'minRides': 15, 'discountPct': 7},
        'tiers': [
          {'id': 'silver', 'minRides': 5, 'discountPct': 3},
          {'id': 'bogus', 'minRides': 1, 'discountPct': 1},
        ],
      });
      expect(s.tier!.id, LoyaltyTierId.silver);
      expect(s.ridesToNext, 5);
      expect(s.progress, 0.5);
      expect(s.tiers, hasLength(1));
      expect(LoyaltyStatus.fromJson(const {}).enabled, isFalse);
    });

    test('loyalty-better is a friendly message', () {
      final l = AppLocalizationsEs();
      expect(localizedBookingError(l, PromoErrorCodes.loyaltyBetter), contains('Circle'));
    });
  });

  group('LoyaltyAdminTab', () {
    testWidgets('validates and saves the tiers', (tester) async {
      tester.view
        ..physicalSize = const Size(390, 1600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _FakeRepo();
      await tester.pumpWidget(localizedApp(Scaffold(body: LoyaltyAdminTab(repository: repo))));
      await tester.pumpAndSettle();
      expect(find.text('Apagado: nadie ve el programa ni recibe descuentos.'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      for (final (i, v) in ['5', '3', '5', '7', '40', '10'].indexed) {
        await tester.enterText(fields.at(i), v);
      }
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();
      expect(find.text('Cada nivel debe pedir más viajes que el anterior.'), findsOneWidget);
      expect(repo.saved, isEmpty);

      await tester.enterText(fields.at(2), '15');
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();
      expect(repo.saved.single.enabled, isTrue);
      expect(repo.saved.single.tiers.map((t) => (t.minRides, t.discountPct)), [(5, 3.0), (15, 7.0), (40, 10.0)]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loads the saved configuration', (tester) async {
      tester.view
        ..physicalSize = const Size(1280, 1400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(localizedApp(
        Scaffold(body: LoyaltyAdminTab(repository: _FakeRepo(enabled: true, tiers: _tiers))),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Riders see their tier in their profile and the discount applies when quoting.'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('Platinum'), findsOneWidget);
    });
  });

  group('LoyaltyProfileCard', () {
    testWidgets('hidden while the program is off', (tester) async {
      await tester.pumpWidget(localizedApp(Scaffold(body: LoyaltyProfileCard(repository: _FakeRepo()))));
      await tester.pumpAndSettle();
      expect(find.text('Luxelane Circle'), findsNothing);
    });

    for (final width in const [360.0, 1280.0]) {
      testWidgets('shows tier and progress (${width.toInt()}px)', (tester) async {
        tester.view
          ..physicalSize = Size(width, 900)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repo = _FakeRepo(
          status: const LoyaltyStatus(enabled: true, rides: 12, tier: _tierSilver, next: _tierGold, tiers: _tiers),
        );
        await tester.pumpWidget(localizedApp(Scaffold(body: LoyaltyProfileCard(repository: repo))));
        await tester.pumpAndSettle();
        expect(find.text('Silver'), findsOneWidget);
        expect(find.text('Tienes 3 % de descuento en cada viaje.'), findsOneWidget);
        expect(find.text('3 viajes más para Gold (7 %)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('top tier (pt)', (tester) async {
      final repo = _FakeRepo(status: const LoyaltyStatus(enabled: true, rides: 52, tier: _tierPlatinum, tiers: _tiers));
      await tester.pumpWidget(
          localizedApp(Scaffold(body: LoyaltyProfileCard(repository: repo)), locale: const Locale('pt')));
      await tester.pumpAndSettle();
      expect(find.text('Nível máximo · 52 viagens em 12 meses'), findsOneWidget);
    });
  });

  testWidgets('receipt labels a Circle discount', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final at = DateTime(2026, 10, 7, 9, 30);
    final booking = Booking(
      id: 'RCPT1234XYZ',
      riderId: 'r',
      origin: const Place(address: 'Hotel Los Tajibos', lat: 0, lng: 0),
      destination: const Place(address: 'Aeropuerto Viru Viru', lat: 0, lng: 0),
      scheduledAt: at,
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: BookingStatus.completed,
      estimatedPrice: 372,
      createdAt: at,
      updatedAt: at,
      discount: 28,
      baseAmount: 400,
      loyaltyTier: 'gold',
    );
    await tester.pumpWidget(localizedApp(ReceiptPage(bookingId: 'x', booking: booking)));
    expect(find.text('Descuento Circle Gold'), findsOneWidget);
    expect(find.text('−Bs 28,00'), findsOneWidget);
  });
}

const _tierSilver = LoyaltyTier(id: LoyaltyTierId.silver, minRides: 5, discountPct: 3);
const _tierGold = LoyaltyTier(id: LoyaltyTierId.gold, minRides: 15, discountPct: 7);
const _tierPlatinum = LoyaltyTier(id: LoyaltyTierId.platinum, minRides: 40, discountPct: 10);
