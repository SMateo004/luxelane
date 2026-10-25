// web/index.html (D15): zoom permitido y sin scripts externos que la web no usa.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final html = File('web/index.html').readAsStringSync();

  test('no bloquea el zoom', () {
    expect(html, isNot(contains('maximum-scale')));
    expect(html, isNot(contains('user-scalable=no')));
  });

  test('no carga Stripe.js (la web no acepta tarjetas)', () {
    expect(html, isNot(contains('js.stripe.com')));
  });

  test('sin scripts en línea (la CSP no permite unsafe-inline en scripts)', () {
    final inline = RegExp(r'<script(?![^>]*\bsrc=)[^>]*>');
    expect(inline.hasMatch(html), isFalse);
  });

  test('no importa el SDK de Firebase a mano (lo carga FlutterFire)', () {
    expect(html, isNot(contains('firebase-app.js')));
  });

  test('pantalla de carga de la marca mientras arranca Flutter (E4)', () {
    expect(html, contains('id="lux-splash"'));
    // Decorativa: si fuera un progressbar seguiría «cargando» para el lector
    // de pantalla después de que Flutter pinte.
    expect(html, contains('<div id="lux-splash" aria-hidden="true">'));
    // Debajo de Flutter, sin JavaScript: Flutter la tapa al primer fotograma.
    // Ocultarla al aparecer <flutter-view> dejaba la pantalla en blanco.
    expect(html, contains('z-index: -1;'));
    expect(html,
        isNot(contains('body:has(flutter-view) #lux-splash { display: none')));
    expect(html, contains('prefers-reduced-motion'));
  });
}
