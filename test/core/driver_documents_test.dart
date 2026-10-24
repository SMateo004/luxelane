import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/driver_documents.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/domain/admin_operations.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_sections.dart';
import 'package:luxelane/features/profile/presentation/widgets/driver_documents_group.dart';

DriverProfile _profile({bool verified = true}) => DriverProfile.fromJson({
      'userId': 'asig',
      'licenseNumber': 'LIC-1',
      'licenseExpiry': Timestamp.fromDate(DateTime(2030, 5)),
      'vehicleId': 'v_asig',
      'documentsVerified': verified,
      'rating': 5,
      'totalRides': 3,
      'isAvailable': true,
    });

const _vehicle = Vehicle(
  id: 'v_asig',
  driverId: 'asig',
  make: 'Toyota',
  model: 'Camry',
  year: 2022,
  plate: 'ABC123',
  vehicleClass: VehicleClass.business,
  color: 'Negro',
  capacity: 3,
  isActive: true,
);

/// Lista de una función de firestore.rules: `function nombre() { return [..]; }`.
List<String> _rulesList(String rules, String pattern) {
  final m = RegExp(pattern).firstMatch(rules)!;
  return RegExp(r"'([^']+)'")
      .allMatches(m.group(1)!)
      .map((x) => x.group(1)!)
      .toList();
}

void main() {
  final rules = File('firestore.rules').readAsStringSync();

  test('las reglas bloquean los mismos campos de licencia', () {
    expect(
      _rulesList(
          rules, r'function driverLockedFields\(\) \{\s*return \[([^\]]*)\]'),
      kLockedDriverProfileFields,
    );
  });

  test('las reglas dejan al chófer los mismos campos de su perfil', () {
    expect(
      _rulesList(rules, r'function driverOwnerFields\(\) \{\s*return \[([^\]]*)\]'),
      kDriverOwnerFields,
    );
  });

  test('el chófer solo edita color y foto del vehículo en las reglas', () {
    final vehicles =
        rules.substring(rules.indexOf('match /vehicles/{vehicleId}'));
    expect(_rulesList(vehicles, r'onlyUpdating\(\[([^\]]*)\]\)'),
        kEditableVehicleFields);
  });

  testWidgets('chófer verificado: licencia y vehículo bloqueados, con el aviso',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DriverDocumentsGroup(
          profile: _profile(),
          vehicle: _vehicle,
          onEditColor: () {},
        ),
      ),
    ));
    expect(find.text(kLockedDocumentsMessage), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(2));
    expect(find.text('Toyota Camry 2022'), findsOneWidget);
    expect(find.text('Color'), findsOneWidget);
  });

  testWidgets('sin verificar: nada bloqueado', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DriverDocumentsGroup(
          profile: _profile(verified: false),
          vehicle: _vehicle,
        ),
      ),
    ));
    expect(find.text(kLockedDocumentsMessage), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
  });

  test('el cambio del admin solo lleva lo que cambió, con los nombres reales',
      () {
    const edit = DriverDocumentsEdit(
      licenseNumber: 'LIC-2',
      plate: 'ABC123',
      vehicleClass: VehicleClass.businessVan,
      year: 2022,
    );
    expect(edit.profileChanges(_profile()), {'licenseNumber': 'LIC-2'});
    expect(edit.vehicleChanges(_vehicle), {
      'class': 'businessVan',
      'capacity': VehicleClass.businessVan.capacity,
    });
    expect(edit.vehicleChanges(null), isEmpty);
  });

  testWidgets('el diálogo del admin exige motivo y devuelve el cambio',
      (tester) async {
    DriverDocumentsResult? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showDialog(
            context: context,
            builder: (_) =>
                DriverDocumentsDialog(profile: _profile(), vehicle: _vehicle),
          ),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('doc-plate')), 'xyz789');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Escribe el motivo'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('doc-reason')), 'Cambio de placa por robo');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(result!.reason, 'Cambio de placa por robo');
    expect(result!.edit.vehicleChanges(_vehicle), {'plate': 'XYZ789'});
    expect(result!.edit.profileChanges(_profile()), isEmpty);
  });
}
