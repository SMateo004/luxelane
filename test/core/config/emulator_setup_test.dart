import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/emulator_setup.dart';

const _real = FirebaseOptions(
  apiKey: 'k',
  appId: '1:1:web:1',
  messagingSenderId: '1',
  projectId: 'proyecto-real',
);

/// Modo emuladores (A1): apagado por omisión y solo con el proyecto demo.
void main() {
  test('sin USE_EMULATORS la app usa las opciones reales', () {
    expect(kUseEmulators, isFalse);
    expect(startupOptions(() => _real).projectId, 'proyecto-real');
  });

  test('en modo emuladores usa demo-luxelane y no lee las reales', () {
    final o = startupOptions(
      () => throw StateError('no debe leerse'),
      useEmulators: true,
    );
    expect(o.projectId, 'demo-luxelane');
  });

  test('en modo emuladores rechaza cualquier otro proyecto', () {
    expect(
      () => startupOptions(() => _real, useEmulators: true, emulator: _real),
      throwsStateError,
    );
  });
}
