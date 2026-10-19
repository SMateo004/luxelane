// Cabeceras de seguridad del hosting (D13), en los dos sitios.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, String> _headersForAll(Map<String, dynamic> site) {
  final rules = (site['headers'] as List).cast<Map<String, dynamic>>();
  final all = rules.firstWhere((r) => r['source'] == '**');
  return {
    for (final h in (all['headers'] as List).cast<Map<String, dynamic>>())
      h['key'] as String: h['value'] as String,
  };
}

void main() {
  final config = jsonDecode(File('firebase.json').readAsStringSync())
      as Map<String, dynamic>;
  final sites = (config['hosting'] as List).cast<Map<String, dynamic>>();

  test('hay dos sitios: rider y driver', () {
    expect(sites.map((s) => s['target']), containsAll(['rider', 'driver']));
  });

  for (final site in sites) {
    group('sitio ${site['target']}', () {
      test('cabeceras básicas', () {
        final h = _headersForAll(site);
        expect(h['X-Content-Type-Options'], 'nosniff');
        expect(h['X-Frame-Options'], 'DENY');
        expect(h['Referrer-Policy'], 'strict-origin-when-cross-origin');
        expect(h['Permissions-Policy'], contains('geolocation=(self)'));
        expect(h['Permissions-Policy'], contains('camera=()'));
        expect(h['Permissions-Policy'], contains('microphone=()'));
      });

      test('HSTS de al menos un año', () {
        final h = _headersForAll(site);
        final m = RegExp(r'max-age=(\d+)')
            .firstMatch(h['Strict-Transport-Security'] ?? '');
        expect(m, isNotNull);
        expect(int.parse(m!.group(1)!), greaterThanOrEqualTo(31536000));
      });

      test('CSP Report-Only, sin unsafe-inline ni unsafe-eval en scripts', () {
        final csp = _headersForAll(site)['Content-Security-Policy-Report-Only'];
        expect(csp, isNotNull);
        expect(csp, contains("frame-ancestors 'none'"));
        expect(csp, contains("object-src 'none'"));
        final scriptSrc = csp!
            .split(';')
            .map((d) => d.trim())
            .firstWhere((d) => d.startsWith('script-src '));
        expect(scriptSrc, isNot(contains("'unsafe-inline'")));
        expect(scriptSrc, isNot(contains("'unsafe-eval'")));
      });

      test('mantiene el Cache-Control existente', () {
        final rules = (site['headers'] as List).cast<Map<String, dynamic>>();
        expect(rules.map((r) => r['source']),
            containsAll(['**/*.@(js|css|json|html)', '/', 'canvaskit/**']));
      });
    });
  }
}
