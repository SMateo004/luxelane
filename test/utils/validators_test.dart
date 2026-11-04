import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/utils/validators.dart';

void main() {
  test('correo', () {
    expect(LuxValidators.email('ana@luxelane.com'), isNull);
    expect(LuxValidators.email(' ana@luxelane.com '), isNull);
    expect(LuxValidators.email('ana@'), isNotNull);
    expect(LuxValidators.email('ana luxelane.com'), isNotNull);
    expect(LuxValidators.email(''), isNotNull);
  });

  test('nombre dentro de los límites de las reglas', () {
    expect(LuxValidators.name('Ana'), isNull);
    expect(LuxValidators.name('   '), isNotNull);
    expect(LuxValidators.name('x' * 81), isNotNull);
  });

  test('teléfono', () {
    expect(LuxValidators.phone('+591 700 00000'), isNull);
    expect(LuxValidators.phone('70000000'), isNull);
    expect(LuxValidators.phone('123'), isNotNull);
    expect(LuxValidators.phone('llámame'), isNotNull);
    expect(LuxValidators.phone('+591 7000000000000000000'), isNotNull);
  });

  test('contraseña nueva', () {
    expect(LuxValidators.newPassword('luxe2026'), isNull);
    expect(LuxValidators.newPassword('12345678'), isNotNull);
    expect(LuxValidators.newPassword('abc1'), isNotNull);
  });
}
