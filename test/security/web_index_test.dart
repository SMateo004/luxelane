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
}
