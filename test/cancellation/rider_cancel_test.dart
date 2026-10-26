// Los stubs nombran los argumentos que la app manda explícitamente, aunque
// coincidan con el valor por defecto (si no, mocktail no los empareja).
// ignore_for_file: avoid_redundant_argument_values

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:luxelane/features/ride/presentation/widgets/cancel_booking_dialog.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements BookingRepository {}

class _Functions extends Mock implements FirebaseFunctions {}

class _Callable extends Mock implements HttpsCallable {}

class _Result extends Mock
    implements HttpsCallableResult<Map<String, dynamic>> {}

class _Firestore extends Mock implements FirebaseFirestore {}

/// B6: el pasajero cancela por el servidor (cancelBooking) y ve el recargo
/// solo si es mayor que cero.
void main() {
  group('runCancelBookingFlow', () {
    late _Repo repo;
    bool? result;
    var confirmed = 0;

    setUp(() {
      repo = _Repo();
      result = null;
      confirmed = 0;
    });

    void quote(double fee, {double refund = 0}) =>
        when(() => repo.previewCancellation('b1')).thenAnswer((_) async =>
            Right(CancellationQuote(fee: fee, basis: 'late', refund: refund)));

    Future<void> open(WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await runCancelBookingFlow(
                  context,
                  repo,
                  'b1',
                  onConfirmed: () => confirmed++,
                ),
                child: const Text('cancelar'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('cancelar'));
      await t.pumpAndSettle();
    }

    testWidgets('sin recargo: no se menciona y acepta 0', (t) async {
      quote(0);
      when(() => repo.cancelBooking('b1', reason: 'other', acceptedFee: 0))
          .thenAnswer((_) async => const Right(null));
      await open(t);
      expect(find.byKey(const Key('cancel-fee')), findsNothing);
      expect(find.textContaining('retiene'), findsNothing);
      expect(find.textContaining('recargo'), findsNothing);
      // Sin pago no hay devolución que mencionar.
      expect(find.byKey(const Key('cancel-refund')), findsNothing);
      await t.tap(find.byKey(const Key('confirm-cancel')));
      await t.pumpAndSettle();
      expect(result, isTrue);
      verify(() => repo.cancelBooking('b1', reason: 'other', acceptedFee: 0))
          .called(1);
    });

    testWidgets('«Cancelando…» solo al confirmar, no con el diálogo (E29)', (
      t,
    ) async {
      quote(0);
      when(() => repo.cancelBooking('b1', reason: 'other', acceptedFee: 0))
          .thenAnswer((_) async => const Right(null));
      await open(t);
      expect(confirmed, 0);
      await t.tap(find.byKey(const Key('confirm-cancel')));
      await t.pumpAndSettle();
      expect(confirmed, 1);
    });

    testWidgets('con recargo: lo muestra y manda el motivo elegido', (t) async {
      quote(30);
      when(
        () => repo.cancelBooking(
          'b1',
          reason: 'changed_plans',
          acceptedFee: 30,
        ),
      ).thenAnswer((_) async => const Right(null));
      await open(t);
      expect(find.byKey(const Key('cancel-fee')), findsOneWidget);
      expect(find.textContaining('Bs\u00A030'), findsOneWidget);
      expect(find.text('Cancelar con retención'), findsOneWidget);
      await t.tap(find.text('Cambié de planes'));
      await t.pump();
      await t.tap(find.byKey(const Key('confirm-cancel')));
      await t.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets(
        'pagada: dice lo pendiente de devolver, sin plazos ni promesas '
        'de tarjeta (B1, B4)', (t) async {
      quote(20, refund: 60);
      await open(t);
      expect(find.byKey(const Key('cancel-refund')), findsOneWidget);
      expect(find.textContaining('Bs\u00A060'), findsOneWidget);
      for (final w in ['tarjeta', 'inmediat', 'monedero', 'saldo a favor']) {
        expect(find.textContaining(w), findsNothing, reason: w);
      }
    });

    testWidgets('si el recargo cambió, se vuelve a mostrar el nuevo',
        (t) async {
      quote(0);
      when(() => repo.cancelBooking('b1', reason: 'other', acceptedFee: 0))
          .thenAnswer(
        (_) async => const Left(CancellationFeeChangedFailure(45)),
      );
      when(() => repo.cancelBooking('b1', reason: 'other', acceptedFee: 45))
          .thenAnswer((_) async => const Right(null));
      await open(t);
      await t.tap(find.byKey(const Key('confirm-cancel')));
      await t.pumpAndSettle();
      expect(find.textContaining('La retención cambió'), findsOneWidget);
      expect(find.textContaining('Bs\u00A045'), findsOneWidget);
      await t.tap(find.byKey(const Key('confirm-cancel')));
      await t.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('error al consultar: lo dice y no abre el diálogo', (t) async {
      when(() => repo.previewCancellation('b1')).thenAnswer(
        (_) async => const Left(ServerFailure('Sin conexión.')),
      );
      await open(t);
      expect(find.text('Sin conexión.'), findsOneWidget);
      expect(find.byType(CancelBookingDialog), findsNothing);
      expect(result, isFalse);
      verifyNever(
        () => repo.cancelBooking(
          any(),
          reason: any(named: 'reason'),
          acceptedFee: any(named: 'acceptedFee'),
        ),
      );
    });

    testWidgets('Volver no cancela', (t) async {
      quote(0);
      await open(t);
      await t.tap(find.text('Volver'));
      await t.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets(
        'accesible: el aviso del recargo es región en vivo y sin '
        'animaciones se puede usar', (t) async {
      quote(12.5);
      when(
        () => repo.cancelBooking('b1', reason: 'other', acceptedFee: 12.5),
      ).thenAnswer((_) async => const Right(null));
      final handle = t.ensureSemantics();
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async =>
                      result = await runCancelBookingFlow(context, repo, 'b1'),
                  child: const Text('cancelar'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('cancelar'));
      await t.pumpAndSettle();
      final fee = find.ancestor(
        of: find.byKey(const Key('cancel-fee')),
        matching: find.byType(Semantics),
      );
      expect(
        t
            .widgetList<Semantics>(fee)
            .any((s) => s.properties.liveRegion == true),
        isTrue,
      );
      await t.tap(find.byKey(const Key('confirm-cancel')));
      await t.pumpAndSettle();
      expect(result, isTrue);
      handle.dispose();
    });
  });

  group('BookingRepositoryImpl: cancelar pasa por el servidor', () {
    late _Functions functions;
    late _Callable callable;
    late _Firestore db;
    late BookingRepositoryImpl repo;

    setUp(() {
      functions = _Functions();
      callable = _Callable();
      db = _Firestore();
      repo = BookingRepositoryImpl(firestore: db, functions: functions);
      when(() => functions.httpsCallable('cancelBooking')).thenReturn(callable);
    });

    test('cancelBooking manda motivo y recargo aceptado; no escribe Firestore',
        () async {
      final res = _Result();
      when(() => res.data).thenReturn({'status': 'cancelled'});
      when(() => callable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => res);
      final r = await repo.cancelBooking(
        'b1',
        reason: 'payment_failed',
        acceptedFee: 0,
      );
      expect(r.isRight(), isTrue);
      verify(
        () => callable.call<Map<String, dynamic>>({
          'bookingId': 'b1',
          'reason': 'payment_failed',
          'acceptedFee': 0.0,
        }),
      ).called(1);
      verifyZeroInteractions(db);
    });

    test('previewCancellation usa dryRun y lee el recargo', () async {
      final res = _Result();
      when(() => res.data).thenReturn(
          {'cancellationFee': 30, 'feeBasis': 'late', 'refund': 5000});
      when(() => callable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => res);
      final r = await repo.previewCancellation('b1');
      final q = r.getOrElse(() => throw StateError('falló'));
      expect(q.fee, 30);
      expect(q.basis, 'late');
      expect(q.hasFee, isTrue);
      // La devolución llega en céntimos.
      expect(q.refund, 50);
      verify(
        () => callable.call<Map<String, dynamic>>(
          {'bookingId': 'b1', 'reason': 'other', 'dryRun': true},
        ),
      ).called(1);
    });

    test('errores del servidor sin texto técnico', () {
      final changed = cancelFailureFor('failed-precondition', {
        'reason': 'cancellation_fee_changed',
        'cancellationFee': 45,
      });
      expect(changed, isA<CancellationFeeChangedFailure>());
      expect((changed as CancellationFeeChangedFailure).fee, 45);
      expect(
        cancelFailureFor('failed-precondition', {'reason': 'not_cancellable'})
            .message,
        contains('ya no se puede cancelar'),
      );
      expect(
        cancelFailureFor('unavailable', null).message,
        contains('Revisa tu red'),
      );
    });
  });
}
