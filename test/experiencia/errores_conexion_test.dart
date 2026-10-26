// Simulacros de Firestore para el stream de una reserva: sus clases son
// «sealed» solo para impedir implementaciones reales, no simulacros.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:luxelane/features/ride/presentation/ride_load_error.dart';
import 'package:mocktail/mocktail.dart';

class _Db extends Mock implements FirebaseFirestore {}

class _Col extends Mock implements CollectionReference<Map<String, dynamic>> {}

class _Doc extends Mock implements DocumentReference<Map<String, dynamic>> {}

class _Snap extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

class _Fns extends Mock implements FirebaseFunctions {}

/// E13: «Revisa tu conexión» cuando no era la red (reserva inexistente,
/// error 500 al cancelar).
void main() {
  group('abrir una reserva', () {
    test('si no existe, el stream da error (antes esperaba para siempre)', () {
      final db = _Db(), col = _Col(), doc = _Doc(), snap = _Snap();
      when(() => db.collection('bookings')).thenReturn(col);
      when(() => col.doc('x')).thenReturn(doc);
      when(() => snap.exists).thenReturn(false);
      when(doc.snapshots).thenAnswer((_) => Stream.value(snap));
      final repo = BookingRepositoryImpl(firestore: db, functions: _Fns());
      expect(
        repo.watchBooking('x'),
        emitsError(isA<BookingNotFoundException>()),
      );
    });

    test('no existe o no es tuya: lo dice, sin culpar a la red', () {
      for (final e in <Object>[
        const BookingNotFoundException('x'),
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      ]) {
        final m = rideLoadErrorMessage(e);
        expect(m, 'No encontramos esta reserva en tu cuenta.');
        expect(m, isNot(contains('conexión')));
      }
    });

    test('sin red: sí habla de la conexión', () {
      expect(
        rideLoadErrorMessage(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ),
        contains('conexión'),
      );
    });

    test('otro error: genérico, sin culpar a la red', () {
      expect(
        rideLoadErrorMessage(StateError('x')),
        isNot(contains('conexión')),
      );
    });
  });

  group('cancelar', () {
    test('error del servidor (internal): no culpa a la red', () {
      expect(
        cancelFailureFor('internal', null).message,
        isNot(contains('conexión')),
      );
    });

    test('sin red (unavailable): sí', () {
      expect(cancelFailureFor('unavailable', null).message, contains('red'));
    });
  });
}
