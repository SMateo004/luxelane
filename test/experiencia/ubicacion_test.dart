import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/widgets/map_picker_dialog.dart';
import 'package:luxelane/features/home/presentation/pages/home_screen.dart';

/// E22: sin dirección se mostraban coordenadas en crudo («-17.78330,
/// -63.18210») y no se explicaba el permiso de ubicación.
void main() {
  test('sin dirección: texto legible, sin cifras', () {
    expect(mapPickerLabel(null), 'Punto elegido en el mapa');
    expect(mapPickerLabel(null), isNot(matches(RegExp(r'\d'))));
    const sinDireccion = Place(address: ' ', lat: -17.7833, lng: -63.1821);
    expect(mapPickerLabel(sinDireccion), 'Punto elegido en el mapa');
  });

  test('con dirección: la dirección', () {
    const p = Place(
      name: 'Plaza',
      address: 'Plaza 24 de Septiembre',
      lat: -17.7833,
      lng: -63.1821,
    );
    expect(mapPickerLabel(p), 'Plaza 24 de Septiembre');
  });

  test('sin ubicación se explica qué hacer', () {
    expect(kLocationUnavailableMessage, contains('Permite el acceso'));
    expect(kLocationUnavailableMessage, contains('elige el punto en el mapa'));
  });
}
