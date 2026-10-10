import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/driver/presentation/widgets/declared_vehicle_card.dart';

import 'package:luxelane/l10n/gen/app_localizations_es.dart';
import 'package:luxelane/l10n/l10n.dart';

import 'helpers/l10n.dart';

class _FakeVehicles implements VehicleRepository {
  _FakeVehicles(this.vehicle);
  Vehicle? vehicle;
  final updates = <Vehicle>[];

  @override
  Future<Either<Failure, Vehicle>> getVehicleByDriver(String driverId) async =>
      vehicle == null ? const Left(NotFoundFailure()) : Right(vehicle!);
  @override
  Future<Either<Failure, void>> updateVehicle(Vehicle v) async {
    updates.add(v);
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _car = Vehicle(
  id: 'v1',
  driverId: 'd1',
  make: 'Toyota',
  model: 'Corolla',
  year: 2019,
  plate: '1234-ABC',
  vehicleClass: VehicleClass.firstClass,
  color: 'Negro',
  capacity: 3,
  isActive: true,
);

void main() {
  for (final width in const [360.0, 1280.0]) {
    testWidgets('shows the declared class and lets the admin correct it (${width.toInt()}px)', (tester) async {
      tester.view
        ..physicalSize = Size(width, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _FakeVehicles(_car);
      await tester.pumpWidget(localizedApp(Scaffold(body: DeclaredVehicleCard(driverId: 'd1', repository: repo))));
      await tester.pumpAndSettle();
      expect(find.text('Toyota Corolla 2019 · placa 1234-ABC'), findsOneWidget);
      expect(find.text('GUARDAR CATEGORÍA'), findsNothing); // nothing changed yet
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(VehicleClass.business.localizedLabel(AppLocalizationsEs())));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GUARDAR CATEGORÍA'));
      await tester.pumpAndSettle();
      expect(repo.updates.single.vehicleClass, VehicleClass.business);
      expect(repo.updates.single.plate, '1234-ABC');
      expect(find.text('Categoría actualizada'), findsOneWidget);
    });
  }

  testWidgets('hidden when the chauffeur has no vehicle yet', (tester) async {
    await tester.pumpWidget(localizedApp(Scaffold(body: DeclaredVehicleCard(driverId: 'd1', repository: _FakeVehicles(null)))));
    await tester.pumpAndSettle();
    expect(find.textContaining('placa'), findsNothing);
  });
}
