import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/app_gate/app_gate.dart';
import 'package:luxelane/core/app_gate/global_config.dart';
import 'package:luxelane/features/admin/presentation/widgets/min_version_card.dart';
import 'package:luxelane/l10n/l10n.dart';

class _FakeRepo implements GlobalConfigRepository {
  final controller = StreamController<GlobalConfig>.broadcast();
  @override
  Stream<GlobalConfig> watch() => controller.stream;
}

/// The gate sits in MaterialApp.builder, above the navigator, like in the apps.
Widget _app(Widget Function(Widget child) gate, {Widget home = const Scaffold(body: Text('home'))}) => MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedAppLocales,
      builder: (context, child) => gate(child!),
      home: home,
    );

class _Counter extends StatefulWidget {
  const _Counter();
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int n = 0;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: TextButton(onPressed: () => setState(() => n++), child: Text('count $n')));
}

void main() {
  group('GlobalConfig', () {
    test('parses config/global defensively', () {
      final c = GlobalConfig.fromJson(const {
        'isMaintenanceMode': true,
        'riderMinBuild': 7,
        'driverMinBuild': -2,
        'riderIosUrl': 'https://apps.apple.com/app/id1',
        'driverIosUrl': 'http://insecure',
        'twoFactorEnabled': true,
      });
      expect(c.maintenance, isTrue);
      expect(c.riderMinBuild, 7);
      expect(c.driverMinBuild, 0);
      expect(c.riderIosUrl, 'https://apps.apple.com/app/id1');
      expect(c.driverIosUrl, isNull);
      expect(GlobalConfig.fromJson(null).maintenance, isFalse);
      expect(GlobalConfig.fromJson(const {'isMaintenanceMode': 'true'}).maintenance, isFalse);
    });

    test('update required only for a known, older build', () {
      const c = GlobalConfig(riderMinBuild: 5);
      expect(c.updateRequired(LuxApp.rider, 4), isTrue);
      expect(c.updateRequired(LuxApp.rider, 5), isFalse);
      expect(c.updateRequired(LuxApp.rider, 0), isFalse); // unknown build (debug, web)
      expect(c.updateRequired(LuxApp.driver, 1), isFalse);
    });

    test('store links', () {
      const c = GlobalConfig(driverIosUrl: 'https://apps.apple.com/app/id2');
      expect(c.storeUrl(LuxApp.rider, ios: false), 'https://play.google.com/store/apps/details?id=com.luxelane.rider');
      expect(c.storeUrl(LuxApp.driver, ios: false), 'https://play.google.com/store/apps/details?id=com.luxelane.driver');
      expect(c.storeUrl(LuxApp.rider, ios: true), isNull);
      expect(c.storeUrl(LuxApp.driver, ios: true), 'https://apps.apple.com/app/id2');
    });
  });

  group('AppGate', () {
    testWidgets('an old build sees the update screen instead of the app', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(_app((child) => AppGate(app: LuxApp.driver, repository: repo, build: 3, ios: false, child: child)));
      expect(find.text('home'), findsOneWidget);

      repo.controller.add(const GlobalConfig(driverMinBuild: 4));
      await tester.pump();
      expect(find.text('home'), findsNothing);
      expect(find.text('Actualiza Luxelane'), findsOneWidget);
      expect(find.text('ACTUALIZAR'), findsOneWidget);

      repo.controller.add(const GlobalConfig(driverMinBuild: 3));
      await tester.pump();
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('without an App Store link, iOS says where to update', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(_app((child) => AppGate(app: LuxApp.rider, repository: repo, build: 1, ios: true, child: child)));
      repo.controller.add(const GlobalConfig(riderMinBuild: 2));
      await tester.pump();
      expect(find.text('ACTUALIZAR'), findsNothing);
      expect(find.text('Búscala en la App Store para actualizarla.'), findsOneWidget);
    });

    testWidgets('an unknown build is never blocked', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(_app((child) => AppGate(app: LuxApp.rider, repository: repo, build: 0, child: child)));
      repo.controller.add(const GlobalConfig(riderMinBuild: 99));
      await tester.pump();
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('maintenance notice: riders only, not admins or chauffeurs; pages keep their state', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(
          _app((child) => AppGate(app: LuxApp.rider, repository: repo, child: child), home: const _Counter()));
      await tester.tap(find.text('count 0'));
      await tester.pump();

      repo.controller.add(const GlobalConfig(maintenance: true));
      await tester.pump();
      expect(find.byType(MaintenanceBar), findsOneWidget);
      expect(find.textContaining('Las reservas nuevas están pausadas'), findsOneWidget);
      expect(find.text('count 1'), findsOneWidget); // the open page survived

      repo.controller.add(const GlobalConfig());
      await tester.pump();
      expect(find.byType(MaintenanceBar), findsNothing);
      expect(find.text('count 1'), findsOneWidget);

      final admin = _FakeRepo();
      await tester.pumpWidget(
          _app((child) => AppGate(app: LuxApp.rider, repository: admin, showMaintenance: false, child: child)));
      admin.controller.add(const GlobalConfig(maintenance: true));
      await tester.pump();
      expect(find.byType(MaintenanceBar), findsNothing);

      final driver = _FakeRepo();
      await tester.pumpWidget(_app((child) => AppGate(app: LuxApp.driver, repository: driver, child: child)));
      driver.controller.add(const GlobalConfig(maintenance: true));
      await tester.pump();
      expect(find.byType(MaintenanceBar), findsNothing);
    });

    testWidgets('fits a 360px phone in Portuguese', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _FakeRepo();
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: supportedAppLocales,
        builder: (context, child) => AppGate(app: LuxApp.rider, repository: repo, build: 1, ios: true, child: child!),
        home: const Scaffold(body: Text('home')),
      ));
      repo.controller.add(const GlobalConfig(maintenance: true));
      await tester.pump();
      expect(find.byType(MaintenanceBar), findsOneWidget);
      repo.controller.add(const GlobalConfig(riderMinBuild: 2));
      await tester.pump();
      await tester.pump();
      expect(find.text('Atualize o Luxelane'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a config read error never locks anyone out', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(_app((child) => AppGate(app: LuxApp.rider, repository: repo, build: 1, child: child)));
      repo.controller.addError(Exception('permission-denied'));
      await tester.pump();
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('Admin minimum version', () {
    test('validates like the rules', () {
      expect(minVersionFields(riderBuild: '7', driverBuild: '', riderIosUrl: '', driverIosUrl: ' https://apps.apple.com/app/id9 '),
          {'riderMinBuild': 7, 'driverMinBuild': 0, 'riderIosUrl': '', 'driverIosUrl': 'https://apps.apple.com/app/id9'});
      expect(minVersionFields(riderBuild: 'x', driverBuild: '0', riderIosUrl: '', driverIosUrl: ''), isNull);
      expect(minVersionFields(riderBuild: '1', driverBuild: '0', riderIosUrl: 'https://evil.example', driverIosUrl: ''), isNull);
    });

    testWidgets('card shows the current minimums and saves edits', (tester) async {
      Map<String, dynamic>? saved;
      await tester.pumpWidget(_app((c) => c,
          home: Scaffold(body: MinVersionCard(settings: const {'riderMinBuild': 4}, onSave: (f) => saved = f))));
      expect(find.text('Pasajero: 4 · Chófer: sin mínimo'), findsOneWidget);

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Chófer: compilación mínima'), '6');
      await tester.enterText(find.widgetWithText(TextField, 'Pasajero: enlace de App Store'), 'nope');
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(saved, isNull);
      expect(find.textContaining('Revisa los valores'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Pasajero: enlace de App Store'), '');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(saved, {'riderMinBuild': 4, 'driverMinBuild': 6, 'riderIosUrl': '', 'driverIosUrl': ''});
    });
  });
}
