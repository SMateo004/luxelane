import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/models/place_model.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/core/utils/service_area.dart';
import 'package:luxelane/core/widgets/place_autocomplete_field.dart';

/// Lugares FICTICIOS: solo para esta prueba.
class _FakeMaps extends MapsService {
  @override
  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    String? sessionToken,
    SearchArea? restrictTo,
  }) async =>
      const [
        PlaceSuggestion(
          placeId: 'plaza',
          description: 'Centro (ficticio)',
          mainText: 'Plaza de prueba',
          secondaryText: 'Centro (ficticio)',
        ),
      ];

  @override
  Future<Place?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String? address,
  }) async =>
      const Place(
        name: 'Plaza de prueba',
        address: 'Centro (ficticio)',
        lat: -17.78,
        lng: -63.18,
      );
}

/// E34: con la capa de accesibilidad activa, la sugerencia debe ser un botón
/// con su propia acción de toque (antes solo escuchaba onTapDown y el toque
/// iba al chip de debajo).
void main() {
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<MapsService>(_FakeMaps());
  });

  testWidgets('la sugerencia es un botón accesible que elige el lugar',
      (tester) async {
    final handle = tester.ensureSemantics();
    Place? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PlaceAutocompleteField(
                label: 'A dónde vas',
                onPlaceSelected: (p) => picked = p,
              ),
              // Algo tocable justo debajo, como los chips de recientes.
              TextButton(onPressed: () {}, child: const Text('Reciente')),
            ],
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'plaza');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // El nodo de la lista va después de los de la página (en web, cuanto más
    // tarde en el árbol, más arriba): antes iba justo tras el campo y el
    // botón «Reciente» de debajo le quedaba encima.
    final order = <String>[];
    void visit(SemanticsNode n) {
      final label = n.getSemanticsData().label;
      if (label.isNotEmpty) order.add(label);
      n.visitChildren((c) {
        visit(c);
        return true;
      });
    }

    visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
    final iSugg = order.indexWhere((l) => l.contains('Plaza de prueba'));
    final iChip = order.indexWhere((l) => l.contains('Reciente'));
    expect(iSugg, greaterThan(iChip), reason: order.join(' | '));

    final node = tester.getSemantics(find.text('Plaza de prueba').first);
    // El botón es el propio nodo (la etiqueta junta los dos textos) o un padre.
    SemanticsNode? button = node;
    while (button != null &&
        !button.getSemanticsData().hasAction(SemanticsAction.tap)) {
      button = button.parent;
    }
    expect(button, isNotNull, reason: 'sin acción de toque accesible');
    expect(button!.getSemanticsData().label, contains('Plaza de prueba'));

    tester.binding.pipelineOwner.semanticsOwner!
        .performAction(button.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(picked?.name, 'Plaza de prueba');
    await tester.pump(const Duration(milliseconds: 600));
    handle.dispose();
  });
}
