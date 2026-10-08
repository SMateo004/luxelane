import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:luxelane/features/support/data/support_hours_repository.dart';
import 'package:luxelane/features/support/domain/support_hours.dart';
import 'package:luxelane/features/support/presentation/widgets/support_hours_widgets.dart';
import 'package:luxelane/l10n/gen/app_localizations_en.dart';
import 'package:luxelane/l10n/gen/app_localizations_es.dart';

import 'helpers/l10n.dart';

const _weekdays = SupportHours(days: {1, 2, 3, 4, 5}, openMin: 8 * 60, closeMin: 20 * 60);

class _FakeRepo implements SupportHoursRepository {
  _FakeRepo(this.hours);
  final SupportHours? hours;
  final saved = <SupportHours?>[];
  @override
  Stream<SupportHours?> watch() => Stream.value(hours);
  @override
  Future<void> save(SupportHours? hours) async => saved.add(hours);
}

void main() {
  setUpAll(() => initializeDateFormatting());

  group('SupportHours', () {
    test('Bolivia time is UTC−4', () {
      expect(SupportHours.boliviaTime(DateTime.utc(2026, 10, 8, 14)), DateTime(2026, 10, 8, 10));
      expect(SupportHours.boliviaTime(DateTime.utc(2026, 10, 9, 2)), DateTime(2026, 10, 8, 22));
    });

    test('open and next opening', () {
      // Thursday 8 Oct 2026.
      expect(_weekdays.isOpenAt(DateTime(2026, 10, 8, 10)), isTrue);
      expect(_weekdays.isOpenAt(DateTime(2026, 10, 8, 20)), isFalse);
      expect(_weekdays.nextOpening(DateTime(2026, 10, 8, 10)), isNull);
      expect(_weekdays.nextOpening(DateTime(2026, 10, 8, 6)), DateTime(2026, 10, 8, 8));
      expect(_weekdays.nextOpening(DateTime(2026, 10, 8, 21)), DateTime(2026, 10, 9, 8));
      // Friday night → Monday.
      expect(_weekdays.nextOpening(DateTime(2026, 10, 9, 22)), DateTime(2026, 10, 12, 8));
    });

    test('day ranges, validation and json', () {
      expect(const SupportHours(days: {1, 2, 3, 5, 7}, openMin: 0, closeMin: 60).dayRanges, [(1, 3), (5, 5), (7, 7)]);
      expect(SupportHours.validate({}, 0, 60), 'support-hours/days');
      expect(SupportHours.validate({1}, 600, 600), 'support-hours/times');
      expect(SupportHours.validate({1}, 0, 1440), isNull);
      expect(SupportHours.fromJson(_weekdays.toJson())!.days, {1, 2, 3, 4, 5});
      expect(SupportHours.fromJson(const {'days': [1], 'openMin': 900, 'closeMin': 100}), isNull);
      expect(SupportHours.fromJson(null), isNull);
    });

    test('summary', () {
      Intl.defaultLocale = 'es';
      expect(supportHoursSummary(AppLocalizationsEs(), _weekdays), 'Atención: lun–vie, 8:00–20:00 (hora de Bolivia)');
      expect(supportHoursSummary(AppLocalizationsEs(), const SupportHours(days: {1, 2, 3, 4, 5, 6, 7}, openMin: 0, closeMin: 1440)),
          'Atención todos los días, las 24 horas');
      Intl.defaultLocale = 'en';
      expect(supportHoursSummary(AppLocalizationsEn(), const SupportHours(days: {1, 2, 3, 4, 5, 6, 7}, openMin: 420, closeMin: 1440)),
          'Support: Every day, 7:00 AM–midnight (Bolivia time)');
      Intl.defaultLocale = null;
    });
  });

  group('SupportHoursLine', () {
    testWidgets('hidden until hours are set', (tester) async {
      await tester.pumpWidget(localizedApp(Scaffold(body: SupportHoursLine(repository: _FakeRepo(null)))));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.schedule_outlined), findsNothing);
    });

    testWidgets('open now', (tester) async {
      await tester.pumpWidget(localizedApp(
          Scaffold(body: SupportHoursLine(repository: _FakeRepo(_weekdays), now: DateTime.utc(2026, 10, 8, 14)))));
      await tester.pumpAndSettle();
      expect(find.text('Atención: lun–vie, 8:00–20:00 (hora de Bolivia)'), findsOneWidget);
      expect(find.text('Ahora estamos atendiendo'), findsOneWidget);
    });

    testWidgets('outside hours says when we answer', (tester) async {
      // Friday 22:00 in Bolivia → Monday 8:00.
      await tester.pumpWidget(localizedApp(
          Scaffold(body: SupportHoursLine(repository: _FakeRepo(_weekdays), now: DateTime.utc(2026, 10, 10, 2)))));
      await tester.pumpAndSettle();
      expect(find.text('Fuera de horario: respondemos desde lun 8:00. Puedes escribirnos igual.'), findsOneWidget);
    });
  });

  group('SupportHoursAdminCard', () {
    for (final width in const [390.0, 1280.0]) {
      testWidgets('sets the hours (${width.toInt()}px)', (tester) async {
        tester.view
          ..physicalSize = Size(width, 1000)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repo = _FakeRepo(null);
        await tester.pumpWidget(localizedApp(Scaffold(body: SupportHoursAdminCard(repository: repo))));
        await tester.pumpAndSettle();
        expect(find.text('Sin definir: la app no muestra ningún horario.'), findsOneWidget);
        await tester.tap(find.text('Definir'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilterChip, 'sáb'));
        await tester.pumpAndSettle();
        expect(find.text('Atención: lun–sáb, 8:00–20:00 (hora de Bolivia)'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();
        expect(repo.saved.single!.days, {1, 2, 3, 4, 5, 6});
      });
    }

    testWidgets('validates and clears', (tester) async {
      final repo = _FakeRepo(const SupportHours(days: {1}, openMin: 480, closeMin: 1200));
      await tester.pumpWidget(localizedApp(Scaffold(body: SupportHoursAdminCard(repository: repo))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'lun'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Elige al menos un día.'), findsOneWidget);
      expect(repo.saved, isEmpty);
      await tester.tap(find.text('Quitar horario'));
      await tester.pumpAndSettle();
      expect(repo.saved, [null]);
    });
  });
}
