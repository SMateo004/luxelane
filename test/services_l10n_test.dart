// Renders the service landing pages in English and Portuguese at phone and
// desktop widths, checking translated headlines and that nothing overflows.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/features/services/presentation/pages/airport_transfer_page.dart';
import 'package:luxelane/features/services/presentation/pages/hourly_charter_page.dart';
import 'package:luxelane/features/services/presentation/pages/immediate_pickup_page.dart';

import 'helpers/l10n.dart';

const _sizes = {'390x844': Size(390, 844), '1440x900': Size(1440, 900)};

/// page → locale → headline expected on screen.
final _cases = <String, (Widget, Map<String, String>)>{
  'AirportTransferPage': (
    const AirportTransferPage(),
    {'en': 'To the airport,\nwithout the stress', 'pt': 'Ao aeroporto sem\nestresse nem espera'},
  ),
  'HourlyCharterPage': (
    const HourlyCharterPage(),
    {'en': 'Chauffeur hire\nby the hour or day', 'pt': 'Motorista particular\npor hora ou por dia'},
  ),
  'ImmediatePickupPage': (
    const ImmediatePickupPage(),
    {'en': 'Instant\nPickup Service', 'pt': 'Motorista\nna hora!'},
  ),
};

/// Everything except missing image assets (the pages show a placeholder).
bool _isRealError(FlutterErrorDetails d) =>
    d.library != 'image resource service' && !d.exceptionAsString().contains('Unable to load asset');

void main() {
  for (final MapEntry(key: name, value: (page, headlines)) in _cases.entries) {
    for (final MapEntry(key: lang, value: headline) in headlines.entries) {
      for (final MapEntry(key: sizeName, value: size) in _sizes.entries) {
        testWidgets('$name renders in $lang at $sizeName without overflow', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          final errors = <FlutterErrorDetails>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (d) {
            if (_isRealError(d)) errors.add(d);
          };
          try {
            await tester.pumpWidget(localizedApp(page, locale: Locale(lang)));
            await tester.pump(const Duration(milliseconds: 300));
            await tester.pump(const Duration(milliseconds: 300));
          } finally {
            FlutterError.onError = previous;
          }

          expect(errors.map((e) => e.exceptionAsString()).toList(), isEmpty);
          expect(find.text(headline), findsOneWidget);
          // No Spanish leftovers in the shared chrome.
          expect(find.text('RESERVAR UN VIAJE'), findsNothing);
        });
      }
    }
  }
}
