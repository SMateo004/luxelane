import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/services/pricing_catalog.dart';
import 'package:luxelane/features/booking/presentation/pages/booking_screen.dart';

// Tarifas de prueba (no son las de negocio).
PricingRule _rule(VehicleClass vc, ServiceType st) =>
    PricingRule.unconfigured(vc, st);

void main() {
  final catalog = PricingCatalog.instance;

  tearDown(() {
    catalog.setRules(const []);
    catalog.setMaintenanceMode(false);
  });

  test('sin tarifas en Firestore no hay ninguna cifra (D20)', () {
    expect(catalog.estimate(VehicleClass.business, ServiceType.oneWay, km: 10),
        isNull);
    expect(catalog.startingPrice(VehicleClass.business, ServiceType.oneWay),
        isNull);
    expect(formatPriceOrQuote(null), 'Cotiza al reservar');
    // Sin tarifa no se bloquea aquí: decide el servidor al cotizar.
    expect(
        catalog.isAvailable(VehicleClass.business, ServiceType.oneWay), isTrue);
  });

  test('aplica la tarifa del admin y respeta el mínimo', () {
    catalog.setRules([
      _rule(VehicleClass.business, ServiceType.oneWay)
          .copyWith(basePriceUsd: 20, pricePerKmUsd: 5, minimumPriceUsd: 60),
    ]);
    expect(
        catalog.estimate(VehicleClass.business, ServiceType.oneWay, km: 2), 60);
    expect(catalog.estimate(VehicleClass.business, ServiceType.oneWay, km: 10),
        70);
    expect(formatPriceOrQuote(70, from: true), 'desde Bs 70');
    // Las demás combinaciones siguen sin cifra.
    expect(
        catalog.estimate(VehicleClass.firstClass, ServiceType.oneWay), isNull);
  });

  test('por horas: base + horas × precio/hora', () {
    catalog.setRules([
      _rule(VehicleClass.firstClass, ServiceType.byTheHour)
          .copyWith(basePriceUsd: 30, pricePerHourUsd: 100),
    ]);
    expect(
        catalog.estimate(VehicleClass.firstClass, ServiceType.byTheHour,
            hours: 4),
        430);
  });

  test('servicio desactivado o mantenimiento bloquean la reserva', () {
    catalog.setRules([
      _rule(VehicleClass.businessVan, ServiceType.byTheHour)
          .copyWith(isActive: false),
    ]);
    expect(catalog.isAvailable(VehicleClass.businessVan, ServiceType.byTheHour),
        isFalse);
    expect(catalog.isAvailable(VehicleClass.businessVan, ServiceType.oneWay),
        isTrue);

    catalog.setMaintenanceMode(true);
    expect(catalog.unavailableReason(VehicleClass.business, ServiceType.oneWay),
        contains('mantenimiento'));
  });

  test('PricingRule.validate rechaza importes inválidos', () {
    final r = _rule(VehicleClass.business, ServiceType.byTheHour)
        .copyWith(pricePerHourUsd: 80, minimumPriceUsd: 160);
    expect(r.validate(), isEmpty);
    expect(r.copyWith(pricePerHourUsd: 0).validate(), isNotEmpty);
    expect(r.copyWith(minimumPriceUsd: -1).validate(), isNotEmpty);
    // Una combinación sin configurar no se puede guardar tal cual.
    expect(
        PricingRule.unconfigured(VehicleClass.business, ServiceType.oneWay)
            .validate(),
        isNotEmpty);
  });
}
