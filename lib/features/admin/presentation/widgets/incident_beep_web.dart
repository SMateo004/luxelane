import 'dart:js_interop';

// Web Audio sin paquetes: un tono corto con un oscilador.
@JS('AudioContext')
extension type _AudioContext._(JSObject _) implements JSObject {
  external factory _AudioContext();
  external _Oscillator createOscillator();
  external _Gain createGain();
  external JSObject get destination;
  external double get currentTime;
}

extension type _Oscillator._(JSObject _) implements JSObject {
  external _AudioParam get frequency;
  external void connect(JSObject node);
  external void start([double when]);
  external void stop([double when]);
}

extension type _Gain._(JSObject _) implements JSObject {
  external _AudioParam get gain;
  external void connect(JSObject node);
}

extension type _AudioParam._(JSObject _) implements JSObject {
  external set value(double v);
}

_AudioContext? _ctx;

/// Dos tonos breves. El navegador puede bloquear el audio hasta que la
/// persona interactúe con la página.
void playIncidentBeep() {
  try {
    final ctx = _ctx ??= _AudioContext();
    for (final (offset, hz) in [(0.0, 880.0), (0.25, 660.0)]) {
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.frequency.value = hz;
      gain.gain.value = 0.15;
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(ctx.currentTime + offset);
      osc.stop(ctx.currentTime + offset + 0.18);
    }
  } catch (_) {
    // Sin audio disponible: el destacado visual sigue.
  }
}
