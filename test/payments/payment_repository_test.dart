import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockResult extends Mock implements HttpsCallableResult<dynamic> {}

class _MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late _MockFunctions functions;
  late _MockCallable callable;
  late PaymentRepositoryImpl repo;

  setUp(() {
    functions = _MockFunctions();
    callable = _MockCallable();
    repo = PaymentRepositoryImpl(
        firestore: _MockFirestore(), functions: functions);
  });

  void stubCall(String name, Object? data) {
    final result = _MockResult();
    when(() => result.data).thenReturn(data);
    when(() => functions.httpsCallable(name)).thenReturn(callable);
    when(() => callable.call<dynamic>(any())).thenAnswer((_) async => result);
  }

  group('Payment', () {
    test('amount está en centavos y amountBs en bolivianos', () {
      final p = Payment(
        id: 'p',
        bookingId: 'b',
        riderId: 'r',
        stripePaymentIntentId: 'pi',
        amount: 12550,
        currency: 'bob',
        status: PaymentStatus.captured,
        createdAt: DateTime(2026),
      );
      expect(p.amountBs, 125.5);
      expect(Payment.toCents(125.5), 12550);
      expect(Payment.toCents(0.1 + 0.2), 30);
    });
  });

  group('PaymentRepositoryImpl', () {
    test(
        'createPaymentIntent solo envía la reserva (el importe lo fija el '
        'servidor)', () async {
      stubCall('createPaymentIntent', {'clientSecret': 'secret'});
      final r = await repo.createPaymentIntent(bookingId: 'b1');
      expect(r.getOrElse(() => ''), 'secret');
      final sent = verify(() => callable.call<dynamic>(captureAny()))
          .captured
          .single as Map;
      expect(sent, {'bookingId': 'b1'});
    });

    test('capturePayment delega en la Cloud Function sin enviar el importe',
        () async {
      stubCall('capturePayment', {
        'paymentId': 'pay-1',
        'status': 'captured',
        'amount': 12550,
        'currency': 'bob',
      });
      final r = await repo.capturePayment(
        bookingId: 'b-1',
        riderId: 'r-1',
        stripePaymentIntentId: 'pi_1',
        amount: 999,
        currency: 'bob',
      );
      final sent = verify(() => callable.call<dynamic>(captureAny()))
          .captured
          .single as Map;
      expect(sent, {'bookingId': 'b-1', 'stripePaymentIntentId': 'pi_1'});
      final payment = r.getOrElse(() => throw StateError('falló'));
      expect(payment.id, 'pay-1');
      expect(payment.amount, 12550);
      expect(payment.amountBs, 125.5);
      expect(payment.status, PaymentStatus.captured);
    });
  });
}
