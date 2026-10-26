import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/error/function_errors.dart';
import 'package:luxelane/features/booking/data/repositories/vehicle_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

/// E6: la persona veía el texto de la excepción («HttpException: Invalid
/// HTTP date Invalid Date»). Los `catch` generales dan un mensaje humano.
void main() {
  const technical = 'HttpException: Invalid HTTP date Invalid Date';

  test('una excepción cualquiera no llega con su texto técnico', () {
    final m = unexpectedErrorMessage(
      const HttpException('Invalid HTTP date Invalid Date'),
    );
    expect(m, isNot(contains('Exception')));
    expect(m, 'No se pudo completar. Inténtalo de nuevo.');
  });

  test('sin red o tiempo agotado: mensaje de conexión', () {
    expect(unexpectedErrorMessage(TimeoutException('x')), kNoConnectionMessage);
    expect(
      unexpectedErrorMessage(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      ),
      kNoConnectionMessage,
    );
  });

  test('permiso denegado en Firestore', () {
    expect(
      unexpectedErrorMessage(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      ),
      'No tienes permiso para hacer esto.',
    );
  });

  test('error de una Cloud Function: el mensaje por código de siempre', () {
    expect(
      unexpectedErrorMessage(
        FirebaseFunctionsException(message: 'x', code: 'resource-exhausted'),
      ),
      kTooManyAttemptsMessage,
    );
  });

  test('un repositorio devuelve el mensaje humano, no el de la excepción',
      () async {
    final db = _MockFirestore();
    when(() => db.collection(any()))
        .thenThrow(const HttpException('Invalid HTTP date Invalid Date'));
    final r = await VehicleRepositoryImpl(firestore: db).getVehicleById('v1');
    final message = r.fold((f) => f.message, (_) => '');
    expect(message, isNot(contains('HttpException')));
    expect(message, isNot(technical));
  });

  test('ningún catch de lib/ muestra e.toString() a la persona', () {
    final offenders = <String>[];
    final pattern = RegExp(
      r'(Failure|BookingError|_AdminStreamFailed\(what,|showLuxSnackbar\(context,)'
      r'\s*\(?\s*e\.toString\(\)',
    );
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) offenders.add('${f.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
