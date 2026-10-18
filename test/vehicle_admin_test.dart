import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/vehicles/vehicle_catalog.dart';
import 'package:luxelane/features/vehicles/data/vehicle_class_repository.dart';
import 'package:luxelane/features/vehicles/presentation/vehicle_classes_admin_tab.dart';

import 'helpers/l10n.dart';

class _FakeRepo implements VehicleClassRepository {
  final saved = <(VehicleClassInfo, bool)>[];
  final uploads = <String>[];
  String? saveError;

  @override
  Future<String?> save(VehicleClassInfo v, {required bool create}) async {
    saved.add((v, create));
    return saveError;
  }

  @override
  Future<String?> uploadImage(String classId, Uint8List bytes, String contentType) async {
    uploads.add('$classId:$contentType');
    return 'https://storage.example/$classId/${uploads.length}.png';
  }
}

Future<({Uint8List bytes, String contentType})?> _pick() async => (bytes: Uint8List(4), contentType: 'image/png');

Future<_FakeRepo> _pump(WidgetTester tester, {Size size = const Size(1280, 1400)}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = _FakeRepo();
  await tester.pumpWidget(localizedApp(Scaffold(body: VehicleClassesAdminTab(repository: repo, pickImage: _pick))));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final f = find.widgetWithText(TextField, label);
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => VehicleCatalog.instance.setDocs({}));

  testWidgets('lists every type with its state, capacity and prices', (tester) async {
    await _pump(tester);
    expect(find.text('Tipos de vehículo y precios'), findsOneWidget);
    expect(find.text('Business Class'), findsOneWidget);
    expect(find.text('Eléctrico'), findsOneWidget);
    expect(find.text('Archivado'), findsOneWidget); // electric
    expect(find.text('Activo'), findsNWidgets(3));
    expect(find.text('Valores predeterminados'), findsNWidgets(4));
    expect(find.textContaining('Traslado: Bs 50'), findsOneWidget);
    expect(find.textContaining('Por horas: Bs 80/h'), findsOneWidget);
  });

  testWidgets('creates a new type with names, photo, gallery, capacity and prices', (tester) async {
    final repo = await _pump(tester);
    await tester.tap(find.text('Nuevo tipo'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo tipo de vehículo'), findsOneWidget);

    // Saving without names says what's missing.
    await _tap(tester, find.text('Guardar'));
    expect(find.textContaining('El identificador debe empezar'), findsOneWidget);
    expect(repo.saved, isEmpty);

    // Photos need the identifier first.
    await _tap(tester, find.text('Subir foto'));
    expect(find.textContaining('identificador válido antes de subir'), findsOneWidget);

    await _enter(tester, 'Identificador', 'suvPremium');
    await _enter(tester, 'Nombre · Español', 'SUV Premium');
    await _enter(tester, 'Nombre · Inglés', 'Premium SUV');
    await _tap(tester, find.text('Guardar'));
    expect(find.text('Completa el nombre en los tres idiomas.'), findsOneWidget);

    await _enter(tester, 'Nombre · Portugués', 'SUV Premium');
    await _enter(tester, 'Descripción · Español', 'BMW X5 o similar');
    await _tap(tester, find.text('Subir foto'));
    await _tap(tester, find.text('Agregar foto'));
    await _enter(tester, 'Texto · Español', 'Amplia y silenciosa');
    await _enter(tester, 'Pasajeros', '5');
    await _tap(tester, find.text('Chófer por horas')); // offer transfers only
    await _enter(tester, 'Tarifa base', '70');
    await _enter(tester, 'Por km', '4,5');
    await _enter(tester, 'Mínimo', '70');
    await _tap(tester, find.text('Guardar'));

    expect(repo.uploads, ['suvPremium:image/png', 'suvPremium:image/png']);
    final (v, create) = repo.saved.single;
    expect(create, isTrue);
    expect(v.id, 'suvPremium');
    expect(v.name, {'es': 'SUV Premium', 'en': 'Premium SUV', 'pt': 'SUV Premium'});
    expect(v.description, {'es': 'BMW X5 o similar'});
    expect(v.capacity, 5);
    expect(v.imageUrl, 'https://storage.example/suvPremium/1.png');
    expect(v.slides.single.url, 'https://storage.example/suvPremium/2.png');
    expect(v.slides.single.caption, {'es': 'Amplia y silenciosa'});
    expect(v.oneWay, const PriceRule(base: 70, perKm: 4.5, min: 70));
    expect(v.byTheHour, isNull);
    expect(v.active, isTrue);
    expect(v.order, 4); // after the built-ins
    expect(find.text('Nuevo tipo de vehículo'), findsNothing);
    expect(find.text('Tipo de vehículo guardado'), findsOneWidget);
  });

  testWidgets('edits a built-in (id fixed), archives it, and shows server errors', (tester) async {
    final repo = await _pump(tester);
    await tester.tap(find.text('Editar').first);
    await tester.pumpAndSettle();
    expect(find.text('Editar Business Class'), findsOneWidget);
    expect(find.text('Identificador: business'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Identificador'), findsNothing);

    await _enter(tester, 'Por hora', '95');
    await _tap(tester, find.text('Disponible para reservar'));
    repo.saveError = 'vehicle/price';
    await _tap(tester, find.text('Guardar'));
    expect(find.textContaining('Revisa los precios'), findsOneWidget); // dialog stays open

    repo.saveError = null;
    await _tap(tester, find.text('Guardar'));
    final (v, create) = repo.saved.last;
    expect(create, isFalse);
    expect(v.id, 'business');
    expect(v.active, isFalse);
    expect(v.byTheHour, const PriceRule(perHour: 95, min: 160));
    expect(v.oneWay, const PriceRule(base: 50, perKm: 3, min: 50));
  });

  testWidgets('the tab reflects catalog changes live', (tester) async {
    await _pump(tester);
    VehicleCatalog.instance.setDocs({
      'electric': {'active': true},
    });
    await tester.pumpAndSettle();
    expect(find.text('Archivado'), findsNothing);
    expect(find.text('Valores predeterminados'), findsNWidgets(3));
  });

  testWidgets('the editor fits a narrow screen in Portuguese', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 720)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(localizedApp(
      Scaffold(body: VehicleClassesAdminTab(repository: _FakeRepo(), pickImage: _pick)),
      locale: const Locale('pt'),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Novo tipo'));
    await tester.pumpAndSettle();
    expect(find.text('Novo tipo de veículo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
