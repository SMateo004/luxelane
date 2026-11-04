import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/features/driver/presentation/widgets/driver_trip_share_notice.dart';
import 'package:luxelane/l10n/l10n.dart';

/// Prompt 18, C2: el chófer sabe, sin sorpresas, que el pasajero puede
/// compartir el seguimiento del viaje.
void main() {
  tearDown(() => L10n.use(const Locale('es')));

  for (final (locale, start) in [
    (const Locale('es'), 'El pasajero puede compartir el seguimiento'),
    (const Locale('en'), 'The passenger can share tracking'),
    (const Locale('pt'), 'O passageiro pode compartilhar o acompanhamento'),
  ]) {
    testWidgets('${locale.languageCode}: una línea sobria, sin promesas',
        (t) async {
      L10n.use(locale);
      await t.pumpWidget(MaterialApp(
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: const Scaffold(body: DriverTripShareNotice()),
      ));
      expect(find.textContaining(start), findsOneWidget);
      expect(
          L10n.current.driverTripShareNotice,
          isNot(matches(RegExp('seguro|garantiz|guarantee|garanti',
              caseSensitive: false))));
    });
  }

  test('la pantalla del viaje del chófer la muestra', () {
    final src = File(
            'lib/features/driver/presentation/pages/driver_active_ride_screen.dart')
        .readAsStringSync();
    expect(src, contains('const DriverTripShareNotice()'));
  });
}
