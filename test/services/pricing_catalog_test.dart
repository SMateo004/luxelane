import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/services/pricing_catalog.dart';

void main() {
  final catalog = PricingCatalog.instance;

  tearDown(() {
    catalog.setRules(const []);
    catalog.setMaintenanceMode(false);
  });

  test('sin tarifas guardadas usa las de fábrica', () {
    expect(
      catalog.estimate(VehicleClass.business, ServiceType.oneWay, km: 10),
      DefaultPricing.estimate(VehicleClass.business, ServiceType.oneWay,
          km: 10),
    );
    expect(catalog.estimate(VehicleClass.business, ServiceType.oneWay, km: 10),
        80); // 50 + 10 × 3
  });

  test('aplica la tarifa del admin y respeta el mínimo', () {
    catalog.setRules([
      PricingRule.fallback(VehicleClass.business, ServiceType.oneWay)
          .copyWith(basePriceUsd: 20, pricePerKmUsd: 5, minimumPriceUsd: 60),
    ]);
    expect(
        catalog.estimate(VehicleClass.business, ServiceType.oneWay, km: 2), 60);
    expect(catalog.estimate(VehicleClass.business, ServiceType.oneWay, km: 10),
        70);
    // Las demás combinaciones siguen con su tarifa de fábrica.
    expect(catalog.estimate(VehicleClass.firstClass, ServiceType.oneWay, km: 0),
        80);
  });

  test('por horas: base + horas × precio/hora', () {
    catalog.setRules([
      PricingRule.fallback(VehicleClass.firstClass, ServiceType.byTheHour)
          .copyWith(basePriceUsd: 30, pricePerHourUsd: 100),
    ]);
    expect(
        catalog.estimate(VehicleClass.firstClass, ServiceType.byTheHour,
            hours: 4),
        430);
  });

  test('servicio desactivado o mantenimiento bloquean la reserva', () {
    catalog.setRules([
      PricingRule.fallback(VehicleClass.businessVan, ServiceType.byTheHour)
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
    final r =
        PricingRule.fallback(VehicleClass.business, ServiceType.byTheHour);
    expect(r.validate(), isEmpty);
    expect(r.copyWith(pricePerHourUsd: 0).validate(), isNotEmpty);
    expect(r.copyWith(minimumPriceUsd: -1).validate(), isNotEmpty);
  });
}
