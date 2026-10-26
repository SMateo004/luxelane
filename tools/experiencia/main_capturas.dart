// Punto de entrada SOLO del entorno de capturas (F5): la app del pasajero
// de siempre (lib/main.dart) con MapsService sustituido por lugares y rutas
// ficticios. Se compila con -t tools/experiencia/main_capturas.dart y
// --dart-define=USE_EMULATORS=true (levantar.sh); nunca para producción.
import 'package:flutter/widgets.dart';
import 'package:luxelane/core/config/emulator_setup.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/core/widgets/lux_map.dart';
import 'package:luxelane/main.dart' as app;

import 'fake_maps_service.dart';

void main() {
  // Sin emuladores no arranca: los lugares ficticios no pueden llegar a una
  // build que hable con un proyecto real.
  if (!kUseEmulators) {
    throw StateError('main_capturas.dart solo con USE_EMULATORS=true');
  }
  WidgetsFlutterBinding.ensureInitialized();
  // Antes de configureDependencies: injection.dart respeta el registrado.
  sl.registerLazySingleton<MapsService>(FakeMapsService.new);
  // ignore: invalid_use_of_visible_for_testing_member
  LuxMap.routeLoader = (o, d) async => fakeRoute(o, d);
  app.main();
}
