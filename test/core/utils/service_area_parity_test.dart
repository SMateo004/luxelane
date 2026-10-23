import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/models/place_model.dart';
import 'package:luxelane/core/utils/service_area.dart';

/// Paridad con functions/src/service_area.ts: ambos lados leen las mismas
/// entradas (test/fixtures/service_area_inputs.json) y deben dar la salida
/// guardada en test/fixtures/service_area_expected.json.
Map<String, dynamic> serviceAreaOutputs() {
  final inputs =
      jsonDecode(
            File('test/fixtures/service_area_inputs.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final places = {
    for (final p in inputs['places'] as List)
      (p as Map)['id'] as String: Place(
        name: p['name'] as String,
        address: p['address'] as String,
        lat: (p['lat'] as num).toDouble(),
        lng: (p['lng'] as num).toDouble(),
      ),
  };
  return {
    'places': {
      for (final e in places.entries)
        e.key: {
          'city': ServiceArea.cityOf(e.value)?.name,
          'airport': ServiceArea.airportFor(e.value)?.iata,
          'areaLabel': ServiceArea.areaLabel(e.value),
          'originOk': ServiceArea.originError(e.value) == null,
        },
    },
    'trips': [
      for (final t in inputs['trips'] as List)
        {
          'from': t[0],
          'to': t[1],
          'destinationOk':
              ServiceArea.destinationError(places[t[0]]!, places[t[1]]!) ==
              null,
        },
    ],
  };
}

void main() {
  test('ServiceArea da la misma salida que el servidor', () {
    final expected = jsonDecode(
      File('test/fixtures/service_area_expected.json').readAsStringSync(),
    );
    expect(serviceAreaOutputs(), expected);
  });
}
