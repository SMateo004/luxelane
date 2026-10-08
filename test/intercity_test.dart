import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/features/services/domain/intercity.dart';
import 'package:luxelane/features/services/presentation/pages/intercity_page.dart';

import 'helpers/l10n.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    GoogleFonts.config.allowRuntimeFetching = false;
    if (!sl.isRegistered<MapsService>()) sl.registerLazySingleton(MapsService.new);
  });

  group('estimates', () {
    test('road distance from Santa Cruz, rounded to 5 km', () {
      for (final d in IntercityDestination.values) {
        expect(Intercity.estimatedKm(d) % 5, 0);
      }
      // Real road distances: Samaipata ≈ 120 km, Cochabamba ≈ 470 km.
      expect(Intercity.estimatedKm(IntercityDestination.samaipata), inInclusiveRange(100, 140));
      expect(Intercity.estimatedKm(IntercityDestination.cochabamba), inInclusiveRange(420, 520));
      expect(Intercity.estimatedKm(IntercityDestination.montero), lessThan(Intercity.estimatedKm(IntercityDestination.buenaVista)));
    });

    test('fare uses the regular one-way pricing', () {
      final km = Intercity.estimatedKm(IntercityDestination.samaipata);
      expect(Intercity.estimatedFare(IntercityDestination.samaipata), (50 + km * 3.0).ceilToDouble());
      expect(
        Intercity.estimatedFare(IntercityDestination.samaipata, vehicleClass: VehicleClass.firstClass),
        greaterThan(Intercity.estimatedFare(IntercityDestination.samaipata)),
      );
    });

    test('destination places carry their coordinates', () {
      final p = IntercityDestination.cochabamba.place;
      expect(p.name, 'Cochabamba');
      expect(p.lat, closeTo(-17.39, 0.01));
    });
  });

  for (final size in const [Size(360, 2400), Size(1280, 1600)]) {
    testWidgets('lists destinations and opens the trip form (${size.width.toInt()}px)', (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(localizedApp(IntercityPage(routeLookup: (_, __) async => null)));
      await tester.pumpAndSettle();

      expect(find.text('Viajes privados desde Santa Cruz'), findsOneWidget);
      for (final d in IntercityDestination.values) {
        expect(find.text(d.name), findsOneWidget);
      }
      expect(find.textContaining('desde Bs'), findsNWidgets(IntercityDestination.values.length));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Samaipata'));
      await tester.pumpAndSettle();
      expect(find.text('A Samaipata'), findsOneWidget);
      await tester.tap(find.text('VER VEHÍCULOS Y PRECIO'));
      await tester.pumpAndSettle();
      expect(find.text('Indica dónde te recogemos.'), findsOneWidget);
    });
  }

  testWidgets('English and Portuguese copy', (tester) async {
    await tester.pumpWidget(localizedApp(const IntercityPage(), locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Private trips from Santa Cruz'), findsOneWidget);
    expect(find.textContaining('from Bs'), findsWidgets);

    await tester.pumpWidget(localizedApp(const IntercityPage(), locale: const Locale('pt')));
    await tester.pumpAndSettle();
    expect(find.text('Viagens privadas a partir de Santa Cruz'), findsOneWidget);
  });
}
