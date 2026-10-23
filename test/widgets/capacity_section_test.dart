import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luxelane/core/design/vehicle_catalog.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/features/booking/presentation/widgets/vehicle_details.dart';

/// Hosts the section with the same state wiring as the booking screen.
class _Host extends StatefulWidget {
  const _Host(this.vc);
  final VehicleClass vc;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int tab = 0, li = 0, si = 0;
  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: CapacitySection(
          vehicleClass: widget.vc,
          tab: tab,
          luggageIndex: li,
          seatingIndex: si,
          onTab: (t) => setState(() => tab = t),
          onLuggage: (i) => setState(() => li = i),
          onSeating: (i) => setState(() => si = i),
        ),
      ),
    ),
  );
}

void main() {
  test('luggage per class', () {
    List<String> titles(VehicleClass vc) =>
        VehicleCatalog.luggage(vc).map((o) => o.title).toList();
    expect(titles(VehicleClass.business), [
      '4 maletas de mano',
      '3 maletas facturadas',
      '2 maletas extra grandes',
    ]);
    expect(titles(VehicleClass.businessSuv), [
      '8 maletas de mano',
      '4 maletas facturadas',
      '2 maletas extra grandes',
    ]);
    expect(titles(VehicleClass.businessVan), [
      '4 maletas de mano',
      '2 maletas facturadas',
      '1 maleta extra grande',
    ]);
    expect(VehicleClass.business.assetKey, 'business_class');
  });

  testWidgets('the caption follows the photo when the arrow is tapped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _Host(VehicleClass.businessSuv));
    await tester.pumpAndSettle();
    expect(find.text('8 maletas de mano'), findsOneWidget);

    await tester.tap(find.byTooltip('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('4 maletas facturadas'), findsOneWidget);
    expect(find.text('8 maletas de mano'), findsNothing);

    await tester.tap(find.byTooltip('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('8 maletas de mano'), findsOneWidget);
  });
}
