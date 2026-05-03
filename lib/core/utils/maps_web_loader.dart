// Web-only implementation — loaded via conditional import.
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Injects the Google Maps JS API script once and waits for it to be ready.
/// Safe to call multiple times — subsequent calls are no-ops if Maps is
/// already loaded (prevents the "gmp-pin already defined" browser warning).
Future<void> initMapsForWeb(String apiKey) async {
  if (apiKey.isEmpty) return;

  // Guard: if window.google.maps already exists, Maps is loaded — skip.
  try {
    final google = js.context['google'];
    if (google != null) {
      final maps = (google as js.JsObject)['maps'];
      if (maps != null) return;
    }
  } catch (_) {
    // context access may throw in some environments — proceed to load.
  }

  // Remove stale script tags that might carry a placeholder key.
  final existing = html.document
      .querySelectorAll('script[src*="maps.googleapis.com"]');
  for (final el in existing) {
    el.remove();
  }

  final completer = Completer<void>();

  js.context['_luxelaneMapsReady'] = js.allowInterop(() {
    if (!completer.isCompleted) completer.complete();
  });

  final script = html.ScriptElement()
    ..async = true
    ..src = 'https://maps.googleapis.com/maps/api/js'
        '?key=$apiKey'
        '&libraries=places'
        '&callback=_luxelaneMapsReady';

  html.document.head!.append(script);

  await completer.future.timeout(
    const Duration(seconds: 10),
    onTimeout: () {},
  );
}
