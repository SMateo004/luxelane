import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/error/auth_errors.dart';

/// B8: los mensajes no revelan si existe una cuenta con ese correo.
void main() {
  test('entrar: «no existe» y «contraseña incorrecta» dicen lo mismo', () {
    final notFound = loginErrorMessage('user-not-found');
    expect(loginErrorMessage('wrong-password'), notFound);
    expect(loginErrorMessage('invalid-credential'), notFound);
    expect(notFound, kBadCredentialsMessage);
  });

  test('registro: no confirma que el correo ya tenga cuenta', () {
    final m = registerErrorMessage('email-already-in-use');
    expect(m, isNot(contains('Ya existe')));
    expect(m, contains('Si ya te registraste'));
  });

  test('recuperar: sin cuenta se responde como enviado', () {
    expect(passwordResetErrorMessage('user-not-found'), isNull);
    expect(
      passwordResetSentMessage('ana@example.com'),
      startsWith('Si hay una cuenta con ana@example.com'),
    );
    expect(passwordResetErrorMessage('invalid-email'), isNotNull);
  });
}
