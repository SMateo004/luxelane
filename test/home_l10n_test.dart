import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/features/home/presentation/pages/home_web_page.dart';

import 'helpers/l10n.dart';

const _widths = [390.0, 1024.0, 1440.0];

Future<void> _pumpSection(
  WidgetTester tester,
  WebHomeSection section, {
  required Locale locale,
  required double width,
  double height = 900,
  DateTime? date,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(localizedApp(
    Scaffold(
      body: SingleChildScrollView(
        child: WebHomeSectionPreview(section, date: date),
      ),
    ),
    locale: locale,
  ));
  // Let reveal-on-scroll animations finish (some loop forever, so no settle).
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    GoogleFonts.config.allowRuntimeFetching = false;
    if (!sl.isRegistered<MapsService>()) sl.registerLazySingleton(MapsService.new);
  });

  // google_fonts can't load fonts in tests; it reports that asynchronously.
  // Ignore those reports (layout still uses the fallback font metrics).
  void ignoreFontErrors() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if ('${details.exception}'.contains('google_fonts') ||
          '${details.exception}'.contains('allowRuntimeFetching')) {
        return;
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
  }

  group('hero booking bar', () {
    final date = DateTime(2026, 10, 7, 14, 30);
    for (final width in [800.0, 1024.0, 1440.0]) {
      testWidgets('English at ${width.toInt()} px', (tester) async {
        ignoreFontErrors();
        await _pumpSection(tester, WebHomeSection.hero,
            locale: const Locale('en'), width: width, date: date);
        expect(find.text('PICKUP'), findsOneWidget);
        expect(find.text('DATE & TIME'), findsOneWidget);
        expect(find.text('SEE OPTIONS'), findsOneWidget);
        expect(find.textContaining('Oct 7, 2:30'), findsOneWidget);
        expect(find.text('One way'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Portuguese at ${width.toInt()} px', (tester) async {
        ignoreFontErrors();
        await _pumpSection(tester, WebHomeSection.hero,
            locale: const Locale('pt'), width: width, date: date);
        expect(find.text('EMBARQUE'), findsOneWidget);
        expect(find.text('DATA E HORA'), findsOneWidget);
        expect(find.text('VER OPÇÕES'), findsOneWidget);
        expect(find.text('Por hora'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('trust section', () {
    for (final width in _widths) {
      testWidgets('English at ${width.toInt()} px', (tester) async {
        ignoreFontErrors();
        await _pumpSection(tester, WebHomeSection.trust,
            locale: const Locale('en'), width: width, height: 3200);
        expect(find.text('THE LUXELANE PROMISE'), findsOneWidget);
        expect(find.text('Free cancellation'), findsOneWidget);
        expect(find.textContaining('Includes 60 min of waiting time at the airport and 15 in the city'), findsOneWidget);
        expect(find.text('HOW IT WORKS'), findsOneWidget);
        expect(find.text('Your chauffeur awaits'), findsOneWidget);
        expect(find.text('BOOK A RIDE'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Portuguese at ${width.toInt()} px', (tester) async {
        ignoreFontErrors();
        await _pumpSection(tester, WebHomeSection.trust,
            locale: const Locale('pt'), width: width, height: 3200);
        expect(find.text('A PROMESSA LUXELANE'), findsOneWidget);
        expect(find.text('Cancelamento grátis'), findsOneWidget);
        expect(find.text('COMO FUNCIONA'), findsOneWidget);
        expect(find.text('RESERVAR UMA VIAGEM'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('fleet section', () {
    for (final width in _widths) {
      testWidgets('English and Portuguese at ${width.toInt()} px', (tester) async {
        ignoreFontErrors();
        await _pumpSection(tester, WebHomeSection.fleet,
            locale: const Locale('en'), width: width);
        expect(find.text('OUR FLEET'), findsOneWidget);
        expect(find.text('Business Class'), findsOneWidget);
        expect(find.text('Vetted chauffeur'), findsOneWidget);
        expect(find.text('3 passengers'), findsWidgets);
        // Only bookable classes are advertised.
        expect(find.text('Electric'), findsNothing);
        expect(tester.takeException(), isNull);

        await _pumpSection(tester, WebHomeSection.fleet,
            locale: const Locale('pt'), width: width);
        expect(find.text('NOSSA FROTA'), findsOneWidget);
        expect(find.text('Motorista verificado'), findsOneWidget);
        expect(find.text('3 passageiros'), findsWidgets);
        expect(find.text('Mercedes Classe E ou similar'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('footer', () {
    for (final width in _widths) {
      testWidgets('translated links at ${width.toInt()} px', (tester) async {
        ignoreFontErrors();
        await _pumpSection(tester, WebHomeSection.footer,
            locale: const Locale('en'), width: width);
        expect(find.text('PRIVACY'), findsOneWidget);
        expect(find.textContaining('All rights reserved.'), findsOneWidget);

        await _pumpSection(tester, WebHomeSection.footer,
            locale: const Locale('pt'), width: width);
        expect(find.text('CONTATO'), findsOneWidget);
        expect(find.textContaining('Todos os direitos reservados.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('book showcase cover at ${width.toInt()} px', (tester) async {
      ignoreFontErrors();
      await _pumpSection(tester, WebHomeSection.book,
          locale: const Locale('pt'), width: width);
      expect(find.text('NOSSA EXPERIÊNCIA EXCLUSIVA'), findsOneWidget);
      expect(find.text('Serviço de motorista premium'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('marquee is translated', (tester) async {
    ignoreFontErrors();
    await _pumpSection(tester, WebHomeSection.marquee,
        locale: const Locale('en'), width: 1440);
    expect(find.text('FIXED PRICES IN BS'), findsWidgets);
    expect(find.text('CHAUFFEUR BY THE HOUR'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  group('inline date panel', () {
    final date = DateTime(2026, 10, 7, 14, 30); // Wednesday

    testWidgets('English: month name and Sunday-first week', (tester) async {
      ignoreFontErrors();
      await _pumpSection(tester, WebHomeSection.datePanel,
          locale: const Locale('en'), width: 320, date: date);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('CONFIRM'), findsOneWidget);
      // Week starts on Sunday: first header cell is "S", Oct 1st is a Thursday.
      final headers = tester.widgetList<Text>(find.text('S')).length;
      expect(headers, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Portuguese month name', (tester) async {
      ignoreFontErrors();
      await _pumpSection(tester, WebHomeSection.datePanel,
          locale: const Locale('pt'), width: 320, date: date);
      expect(find.text('Outubro de 2026'), findsOneWidget);
      expect(find.text('CONFIRMAR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Spanish keeps Monday-first week', (tester) async {
      ignoreFontErrors();
      await _pumpSection(tester, WebHomeSection.datePanel,
          locale: const Locale('es'), width: 320, date: date);
      expect(find.text('Octubre de 2026'), findsOneWidget);
      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where((d) => d != null && d.length == 1 && RegExp('[A-Z]').hasMatch(d))
          .toList();
      expect(labels.first, 'L');
      expect(tester.takeException(), isNull);
    });
  });
}
