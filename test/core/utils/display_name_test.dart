import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/utils/display_name.dart';

void main() {
  group('profileDisplayName (alta con Google)', () {
    test('usa el nombre de la cuenta, sin espacios sobrantes', () {
      expect(
          profileDisplayName('  Ana Pérez ', 'ana@example.com'), 'Ana Pérez');
    });

    test('sin nombre, la parte del correo antes de la arroba', () {
      expect(profileDisplayName(null, 'Ana.Perez@Example.com'), 'ana.perez');
      expect(profileDisplayName('   ', 'beto@example.com'), 'beto');
    });

    test('un nombre de más de 80 caracteres se recorta a 80', () {
      final largo = 'x' * 120;
      final r = profileDisplayName(largo, 'x@example.com');
      expect(r.runes.length, kDisplayNameMaxLength);
    });

    test('80 caracteres exactos se dejan igual', () {
      final justo = 'y' * 80;
      expect(profileDisplayName(justo, 'y@example.com'), justo);
    });

    test('recorta por puntos de código, sin partir un emoji', () {
      final conEmoji = '😀' * 90;
      final r = profileDisplayName(conEmoji, 'e@example.com');
      expect(r.runes.length, kDisplayNameMaxLength);
      expect(r, '😀' * 80);
    });
  });
}
