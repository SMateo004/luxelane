import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/services/client_error_reporter.dart';
import 'package:luxelane/features/health/data/health_repository.dart';
import 'package:luxelane/features/health/presentation/health_admin_tab.dart';

import 'helpers/l10n.dart';

class _FakeRepo implements HealthRepository {
  _FakeRepo(this.health, this.errors);
  final SystemHealth? health;
  final List<ClientErrorGroup> errors;
  final resolved = <String, bool>{};

  @override
  Stream<SystemHealth?> watchHealth() => Stream.value(health);
  @override
  Stream<List<ClientErrorGroup>> watchErrors() => Stream.value(errors);
  @override
  Future<void> setResolved(String id, bool value) async => resolved[id] = value;
}

final _now = DateTime(2026, 10, 8, 12);

void main() {
  setUpAll(() => initializeDateFormatting());

  group('ClientErrorReporter', () {
    test('dedupes, truncates and caps reports per session', () async {
      final sent = <Map<String, dynamic>>[];
      final r = ClientErrorReporter(send: (p) async => sent.add(p))..route = '/booking';
      final stack = StackTrace.fromString('#0 Foo (package:luxelane/a.dart:1:2)\n#1 Bar');
      await r.report(StateError('x' * 500), stack);
      await r.report(StateError('x' * 500), stack); // duplicate
      expect(sent, hasLength(1));
      expect((sent.single['message'] as String).length, 300);
      expect(sent.single['route'], '/booking');
      expect(sent.single['platform'], 'web');

      for (var i = 0; i < 20; i++) {
        await r.report(StateError('error $i'), stack);
      }
      expect(sent, hasLength(ClientErrorReporter.maxPerSession));
    });

    test('a failing backend never throws into the app', () async {
      final r = ClientErrorReporter(send: (_) async => throw Exception('offline'));
      await expectLater(r.report(Exception('boom'), null), completes);
    });
  });

  test('health is stale after 15 minutes without a check', () {
    expect(SystemHealth(checkedAt: _now.subtract(const Duration(minutes: 5))).staleAt(_now), isFalse);
    expect(SystemHealth(checkedAt: _now.subtract(const Duration(minutes: 16))).staleAt(_now), isTrue);
    expect(const SystemHealth(checkedAt: null).staleAt(_now), isTrue);
  });

  final errors = [
    ClientErrorGroup(
      id: 'e1',
      platform: 'web',
      message: 'Null check operator used on a null value',
      count: 12,
      stack: '#0 RideScreen.build (package:luxelane/ride.dart:12:3)',
      lastRoute: '/ride/abc',
      lastAppVersion: '6b5619b',
      lastSeen: DateTime(2026, 10, 8, 11, 40),
    ),
    const ClientErrorGroup(id: 'e2', platform: 'web', message: 'Old bug', count: 2, resolved: true),
  ];

  for (final size in const [Size(360, 1800), Size(1280, 1200)]) {
    testWidgets('summary, alerts and errors (${size.width.toInt()}px)', (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _FakeRepo(
        SystemHealth(
          checkedAt: _now.subtract(const Duration(minutes: 3)),
          pendingNext2h: 4,
          unassignedSoon: 1,
          onlineDrivers: 0,
          urgentTickets: 0,
          clientErrors24h: 1,
        ),
        errors,
      );
      await tester.pumpWidget(localizedApp(Scaffold(body: HealthAdminTab(repository: repo, now: _now))));
      await tester.pumpAndSettle();

      expect(find.textContaining('Monitor activo'), findsOneWidget);
      expect(find.text('Requiere atención'), findsNWidgets(2)); // nobody online + unassigned soon
      expect(find.text('Null check operator used on a null value'), findsOneWidget);
      expect(find.text('Old bug'), findsNothing);
      expect(find.textContaining('12 veces'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Null check operator used on a null value'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar resuelto'));
      await tester.pumpAndSettle();
      expect(repo.resolved, {'e1': true});

      await tester.tap(find.text('Ver resueltos'));
      await tester.pumpAndSettle();
      expect(find.text('Old bug'), findsOneWidget);
    });
  }

  testWidgets('stale monitor warns (en)', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo(SystemHealth(checkedAt: _now.subtract(const Duration(hours: 1))), const []);
    await tester.pumpWidget(localizedApp(Scaffold(body: HealthAdminTab(repository: repo, now: _now)), locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.textContaining("hasn't reported for over 15 minutes"), findsOneWidget);
    expect(find.text('No pending errors.'), findsOneWidget);
  });
}
