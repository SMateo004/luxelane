import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/error/function_errors.dart';
import 'package:luxelane/l10n/l10n.dart';

/// Registro de chóferes (B1): cada motivo que lanza el servidor tiene su
/// texto en el catálogo del cliente, en español, inglés y portugués.
void main() {
  final src = [
    File('functions/src/driver_application.ts').readAsStringSync(),
    File('functions/src/index.ts').readAsStringSync(),
  ].join('\n');

  Set<String> serverReasons() {
    final reasons = <String>{
      for (final m
          in RegExp(r"regError\('[a-z-]+', '([a-z_]+)'").allMatches(src))
        m.group(1)!,
    };
    // Las del alta y del bloqueo que viven en index.ts.
    for (final r in ['driver_account', 'driver_docs_blocked']) {
      expect(src, contains("'$r'"));
      reasons.add(r);
    }
    return reasons;
  }

  test('todos los motivos del servidor tienen texto propio', () {
    final missing = serverReasons().difference(kRegistrationReasons.toSet());
    expect(missing, isEmpty);
  });

  for (final code in ['es', 'en', 'pt']) {
    test('$code: ningún motivo cae en el texto genérico', () {
      L10n.use(Locale(code));
      final generic = L10n.current.regErrorGeneric;
      for (final r in kRegistrationReasons) {
        final m =
            registrationErrorMessage('failed-precondition', {'reason': r});
        expect(m, isNot(generic), reason: r);
        expect(m.trim(), isNotEmpty, reason: r);
      }
      expect(registrationErrorMessage('internal', {'reason': 'otra'}), generic);
      L10n.use(const Locale('es'));
    });
  }
}
