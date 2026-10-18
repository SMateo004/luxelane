import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/vehicles/vehicle_catalog.dart';
import 'package:luxelane/l10n/gen/app_localizations_en.dart';
import 'package:luxelane/l10n/gen/app_localizations_es.dart';
import 'package:luxelane/l10n/l10n.dart';

final _catalog = VehicleCatalog.instance;

Map<String, dynamic> _suv({bool active = true, Map<String, dynamic>? services}) => {
      'name': {'es': 'SUV Premium', 'en': 'Premium SUV', 'pt': 'SUV Premium'},
      'description': {'es': 'BMW X5 o similar', 'en': 'BMW X5 or similar'},
      'active': active,
      'order': 1,
      'capacity': 5,
      'carryOn': 4,
      'checked': 3,
      'extraLarge': 2,
      'childSeat': true,
      'icon': 'suv',
      'color': '#1A2B3C',
      'imageUrl': 'https://example.com/suv.png',
      'slides': [
        {'url': 'https://example.com/1.jpg', 'caption': {'es': 'Amplia', 'en': 'Roomy'}},
        {'url': 'http-not-a-slide'},
      ],
      'services': services ?? {'oneWay': {'base': 70, 'perKm': 4, 'min': 70}},
    };

void main() {
  tearDown(() {
    _catalog.setDocs({});
    _catalog.setLegacyRules({});
  });

  test('built-in types keep what the app offered before', () {
    final b = _catalog.info(VehicleClass.business);
    expect(b.capacity, 3);
    expect(b.oneWay, const PriceRule(base: 50, perKm: 3, min: 50));
    expect(b.byTheHour, const PriceRule(perHour: 80, min: 160));
    expect(_catalog.info(VehicleClass.businessVan).capacity, 7);
    expect(_catalog.info(VehicleClass.businessVan).childSeat, isFalse);
    // Electric existed but riders couldn't pick it.
    expect(_catalog.active.map((v) => v.id), ['business', 'firstClass', 'businessVan']);
    expect(_catalog.info(VehicleClass.electric).active, isFalse);
    expect(_catalog.info(VehicleClass.business).nameIn('pt'), 'Business Class');
    expect(_catalog.info(VehicleClass.electric).nameIn('en'), 'Electric');
  });

  test('estimates match the old fixed prices', () {
    final b = _catalog.info(VehicleClass.business);
    expect(b.estimate(ServiceType.oneWay, km: 10), 80);
    expect(b.estimate(ServiceType.oneWay, km: 0), 50); // minimum
    expect(b.estimate(ServiceType.byTheHour, hours: 8, days: 3), 1920);
    expect(b.estimate(ServiceType.byTheHour, hours: 1), 160); // minimum per day
  });

  test('an admin document adds a new type, between the built-ins by order', () {
    _catalog.setDocs({'suvPremium': _suv()});
    // Same order as First Class (1): ties go alphabetically.
    expect(_catalog.active.map((v) => v.id), ['business', 'firstClass', 'suvPremium', 'businessVan']);
    final s = _catalog.info(const VehicleClass('suvPremium'));
    expect(s.capacity, 5);
    expect(s.color, const Color(0xFF1A2B3C));
    expect(s.slides.single.captionIn('en'), 'Roomy');
    expect(s.slides.single.captionIn('pt'), 'Amplia'); // falls back to Spanish
    expect(s.builtIn, isFalse);
    // Offers only transfers.
    expect(_catalog.activeFor(ServiceType.byTheHour).map((v) => v.id), isNot(contains('suvPremium')));
    expect(_catalog.activeFor(ServiceType.oneWay).map((v) => v.id), contains('suvPremium'));
    expect(VehicleClass.fromId('suvPremium').capacity, 5);
    expect(const VehicleClass('suvPremium').localizedLabel(AppLocalizationsEn()), 'Premium SUV');
  });

  test('admins can archive or re-price a built-in; old pricing-tab rules apply only until then', () {
    _catalog.setLegacyRules({
      'business_oneWay': {'basePriceUsd': 60, 'pricePerKmUsd': 3.5, 'pricePerHourUsd': 0, 'minimumPriceUsd': 60},
    });
    expect(_catalog.info(VehicleClass.business).oneWay, const PriceRule(base: 60, perKm: 3.5, min: 60));
    _catalog.setDocs({
      'business': {
        'active': false,
        'services': {'oneWay': {'base': 55, 'perKm': 3, 'min': 55}},
      },
    });
    final b = _catalog.info(VehicleClass.business);
    expect(b.oneWay, const PriceRule(base: 55, perKm: 3, min: 55));
    expect(b.byTheHour, isNull); // the admin's list of services wins
    expect(b.active, isFalse);
    expect(b.nameIn('es'), 'Business Class'); // unset fields keep the defaults
    expect(b.asset, 'assets/images/vehicles/business/car.png');
    expect(_catalog.isCustomized('business'), isTrue);
    expect(_catalog.active.map((v) => v.id), isNot(contains('business')));
  });

  test('unknown types on old bookings still show something', () {
    final u = _catalog.info(const VehicleClass('limousine'));
    expect(u.nameIn('es'), 'limousine');
    expect(u.active, isFalse);
    expect(VehicleClass.fromId(null), VehicleClass.business);
    expect(VehicleClass.fromId('limousine').name, 'limousine');
  });

  test('validation and saving round-trip', () {
    final s = VehicleClassInfo.fromJson('suvPremium', _suv());
    expect(validateVehicleClass(s), isNull);
    final again = VehicleClassInfo.fromJson('suvPremium', s.toJson());
    expect(again.toJson(), s.toJson());
    expect(validateVehicleClass(s.copyWith(name: {'es': 'SUV'})), 'name');
    expect(validateVehicleClass(s.copyWith(capacity: 0)), 'capacity');
    expect(validateVehicleClass(s.copyWith(clearOneWay: true)), 'services');
    expect(validateVehicleClass(s.copyWith(oneWay: const PriceRule(min: 0))), 'price');
    expect(validateVehicleClass(s.copyWith(byTheHour: const PriceRule(perHour: 0, min: 100))), 'price');
    expect(validateVehicleClass(VehicleClassInfo.fromJson('1bad', _suv())), 'id');
    expect(hexColor(const Color(0xFF1A2B3C)), '#1A2B3C');
    expect(parseHexColor('nope'), isNull);
  });

  test('labels use the app language', () {
    expect(VehicleClass.firstClass.localizedDescription(AppLocalizationsEs()), 'Mercedes S-Class o similar');
  });
}
