import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/booking/domain/booking_error_codes.dart';
import 'package:luxelane/features/booking/presentation/booking_error_l10n.dart';
import 'package:luxelane/features/promo/data/promo_repository.dart';
import 'package:luxelane/features/promo/domain/promo_code.dart';
import 'package:luxelane/features/promo/presentation/promos_admin_tab.dart';
import 'package:luxelane/features/trips/presentation/pages/receipt_page.dart';
import 'package:luxelane/l10n/gen/app_localizations_en.dart';
import 'package:luxelane/l10n/gen/app_localizations_es.dart';

import 'helpers/l10n.dart';

class _FakeRepo implements PromoRepository {
  _FakeRepo(this.promos);
  final List<PromoCode> promos;
  final saved = <(String, bool, Map<String, dynamic>)>[];
  String? nextError;

  @override
  Stream<List<PromoCode>> watchAll() => Stream.value(promos);

  @override
  Future<String?> save(PromoCode promo, {required bool create}) async {
    saved.add((promo.code, create, promo.toCallable(create: create)));
    final e = nextError;
    nextError = null;
    return e;
  }
}

final _now = DateTime(2026, 10, 7, 12);

final _promos = [
  PromoCode(
    code: 'BIENVENIDO',
    type: PromoType.percent,
    value: 20,
    maxDiscount: 100,
    description: 'Lanzamiento',
    maxRedemptions: 50,
    redemptions: 12,
    firstRideOnly: true,
    validUntil: DateTime(2026, 12, 31),
  ),
  const PromoCode(code: 'AEROPUERTO', type: PromoType.fixed, value: 40, active: false),
  PromoCode(code: 'VIEJO', type: PromoType.fixed, value: 10, validUntil: DateTime(2026, 1, 1)),
];

Booking _booking({double discount = 0, String? code}) {
  final at = DateTime(2026, 10, 7, 9, 30);
  return Booking(
    id: 'RCPT1234XYZ',
    riderId: 'r',
    origin: const Place(address: 'Hotel Los Tajibos', lat: 0, lng: 0),
    destination: const Place(address: 'Aeropuerto Viru Viru', lat: 0, lng: 0),
    scheduledAt: at,
    vehicleClass: VehicleClass.business,
    serviceType: ServiceType.oneWay,
    status: BookingStatus.completed,
    estimatedPrice: 400,
    createdAt: at,
    updatedAt: at,
    discount: discount,
    baseAmount: discount > 0 ? 400 + discount : null,
    promoCode: code,
  );
}

void main() {
  setUpAll(() => initializeDateFormatting());

  test('Quote parses the promo fields', () {
    final q = Quote.fromJson({
      'quoteId': 'q1',
      'amount': 400,
      'expiresAt': 0,
      'baseAmount': 500,
      'discount': 100,
      'promoCode': 'BIENVENIDO',
      'promoError': null,
    });
    expect((q.amount, q.baseAmount, q.discount, q.promoCode), (400.0, 500.0, 100.0, 'BIENVENIDO'));
    final plain = Quote.fromJson({'quoteId': 'q2', 'amount': 300, 'expiresAt': 0, 'promoError': 'promo/expired'});
    expect((plain.discount, plain.promoCode, plain.promoError), (0.0, null, 'promo/expired'));
  });

  test('promo errors are translated', () {
    final es = AppLocalizationsEs();
    expect(localizedBookingError(es, PromoErrorCodes.alreadyUsed), 'Ya usaste este código.');
    expect(localizedBookingError(AppLocalizationsEn(), PromoErrorCodes.expired), 'That code has expired.');
    expect(localizedBookingError(es, BookingErrorCodes.promoNoLongerValid), contains('dejó de ser válido'));
  });

  test('PromoCode round-trips to the Cloud Function payload', () {
    final p = _promos.first;
    final m = p.toCallable(create: true);
    expect(m['code'], 'BIENVENIDO');
    expect(m['type'], 'percent');
    expect(m['maxDiscount'], 100);
    expect(m['firstRideOnly'], true);
    expect(m['validUntil'], DateTime(2026, 12, 31).millisecondsSinceEpoch);
    expect(PromoCode.fromJson('X', {'type': 'fixed', 'value': 40, 'vehicleClasses': ['firstClass', 'bogus']}).vehicleClasses,
        [VehicleClass.firstClass]);
  });

  group('PromosAdminTab', () {
    testWidgets('lists codes with state and usage', (tester) async {
      tester.view
        ..physicalSize = const Size(1280, 1000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(localizedApp(Scaffold(body: PromosAdminTab(repository: _FakeRepo(_promos), now: _now))));
      await tester.pumpAndSettle();
      expect(find.text('Códigos promocionales'), findsOneWidget);
      expect(find.text('BIENVENIDO'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
      expect(find.text('Pausado'), findsOneWidget);
      expect(find.text('Vencido'), findsOneWidget);
      expect(find.textContaining('12 de 50 usos'), findsOneWidget);
      expect(find.textContaining('20 % (máx. Bs 100)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('creates a code and shows server validation errors', (tester) async {
      tester.view
        ..physicalSize = const Size(390, 1600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _FakeRepo(const []);
      await tester.pumpWidget(localizedApp(Scaffold(body: PromosAdminTab(repository: repo, now: _now))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NUEVO CÓDIGO'));
      await tester.pumpAndSettle();

      final fields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
      await tester.enterText(fields.at(0), 'verano26');
      await tester.enterText(fields.at(2), '15');
      await tester.tap(find.text('Monto fijo'));
      await tester.pump();

      repo.nextError = PromoAdminErrorCodes.exists;
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Ya existe un código con ese nombre.'), findsOneWidget);
      expect(repo.saved.single.$1, 'VERANO26');
      expect(repo.saved.single.$2, isTrue);
      expect(repo.saved.single.$3['type'], 'fixed');
      expect(repo.saved.single.$3['value'], 15);

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Código guardado'), findsOneWidget);
    });

    testWidgets('pausing saves the same code inactive (en)', (tester) async {
      tester.view
        ..physicalSize = const Size(1280, 1000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _FakeRepo(_promos);
      await tester.pumpWidget(localizedApp(Scaffold(body: PromosAdminTab(repository: repo, now: _now)),
          locale: const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text('Promo codes'), findsOneWidget);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(repo.saved.single.$1, 'BIENVENIDO');
      expect(repo.saved.single.$2, isFalse);
      expect(repo.saved.single.$3['active'], false);
    });
  });

  testWidgets('receipt shows the price before discount and the discount', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(localizedApp(ReceiptPage(bookingId: 'x', booking: _booking(discount: 100, code: 'BIENVENIDO'))));
    expect(find.text('Bs 500,00'), findsOneWidget);
    expect(find.text('Descuento BIENVENIDO'), findsOneWidget);
    expect(find.text('−Bs 100,00'), findsOneWidget);
    expect(find.text('Bs 400,00'), findsWidgets);
  });
}
