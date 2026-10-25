import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:luxelane/features/admin/domain/admin_operations.dart';
import 'package:mocktail/mocktail.dart';

class _Functions extends Mock implements FirebaseFunctions {}

class _Callable extends Mock implements HttpsCallable {}

class _Result extends Mock implements HttpsCallableResult<void> {}

class _Firestore extends Mock implements FirebaseFirestore {}

class _Auth extends Mock implements fb.FirebaseAuth {}

class _User extends Mock implements fb.User {}

const _why = 'Pedido por el pasajero';

Booking _booking(String status) => Booking.fromJson({
      'id': 'b1',
      'riderId': 'ana',
      'origin': {'address': 'A', 'coordinates': const GeoPoint(-17.78, -63.18)},
      'destination': {
        'address': 'B',
        'coordinates': const GeoPoint(-17.64, -63.13),
      },
      'status': status,
      'estimatedPrice': 100,
    });

/// Parte A: el panel no escribe Firestore; cada cambio va a una callable
/// con su motivo, y el servidor audita en la misma transacción.
void main() {
  late _Functions functions;
  late _Callable callable;
  late _Firestore db;
  late AdminRepositoryImpl repo;

  setUp(() {
    functions = _Functions();
    callable = _Callable();
    db = _Firestore();
    final auth = _Auth();
    final me = _User();
    when(() => me.uid).thenReturn('jefa');
    when(() => auth.currentUser).thenReturn(me);
    repo = AdminRepositoryImpl(db, auth: auth, functions: functions);
    when(() => functions.httpsCallable(any())).thenReturn(callable);
    when(() => callable.call<void>(any())).thenAnswer((_) async => _Result());
  });

  Future<void> expectCall(
    Future<Object> Function() action,
    String name,
    Map<String, dynamic> data,
  ) async {
    final r = await action();
    expect((r as dynamic).isRight(), isTrue, reason: name);
    verify(() => functions.httpsCallable(name)).called(1);
    verify(() => callable.call<void>(data)).called(1);
    verifyZeroInteractions(db);
  }

  test('cancelar, mover el estado, asignar y ajustar: adminUpdateBooking',
      () async {
    await expectCall(
      () => repo.changeBookingStatus(
        _booking('confirmed'),
        BookingStatus.cancelled,
        _why,
      ),
      'adminUpdateBooking',
      {'bookingId': 'b1', 'action': 'cancel', 'reason': _why},
    );
    await expectCall(
      () => repo.changeBookingStatus(
        _booking('in_progress'),
        BookingStatus.completed,
        _why,
      ),
      'adminUpdateBooking',
      {
        'bookingId': 'b1',
        'action': 'status',
        'to': 'completed',
        'reason': _why
      },
    );
    await expectCall(
      () => repo.assignDriver(_booking('pending'), 'luis', _why),
      'adminUpdateBooking',
      {
        'action': 'assign',
        'bookingId': 'b1',
        'driverId': 'luis',
        'reason': _why
      },
    );
    await expectCall(
      () => repo.adjustFinalPrice(_booking('confirmed'), 95, _why),
      'adminUpdateBooking',
      {
        'action': 'adjust_price',
        'bookingId': 'b1',
        'finalPrice': 95.0,
        'reason': _why
      },
    );
  });

  test('cobros manuales: adminRecordPayment', () async {
    await expectCall(
      () => repo.markPaymentCollected(_booking('completed'), 'qr', 'R-1', _why),
      'adminRecordPayment',
      {
        'action': 'record',
        'bookingId': 'b1',
        'method': 'qr',
        'reference': 'R-1',
        'reason': _why
      },
    );
    final p =
        Payment.fromJson({'id': 'p1', 'amount': 10000, 'status': 'captured'});
    await expectCall(
      () => repo.correctPayment(p, amountBs: 90, reason: _why),
      'adminRecordPayment',
      {
        'action': 'correct',
        'paymentId': 'p1',
        'amountBs': 90.0,
        'reason': _why
      },
    );
  });

  test('configuración: adminUpdateConfig (global y finance)', () async {
    await expectCall(
      () => repo.toggleMaintenanceMode(true, _why),
      'adminUpdateConfig',
      {
        'doc': 'global',
        'changes': {'isMaintenanceMode': true},
        'reason': _why
      },
    );
    await expectCall(
      () => repo.updateFinanceSettings({'platformCommissionPct': 12}, _why),
      'adminUpdateConfig',
      {
        'doc': 'finance',
        'changes': {'platformCommissionPct': 12},
        'reason': _why
      },
    );
  });

  test('tarifas: guardar y desactivar (ya no se borra)', () async {
    final rule = PricingRule.fromJson({
      'id': 'business_oneWay',
      'vehicleClass': 'business',
      'serviceType': 'oneWay',
      'basePriceUsd': 1,
      'pricePerKmUsd': 2,
      'pricePerHourUsd': 0,
      'minimumPriceUsd': 3,
      'isActive': true,
    });
    await expectCall(
      () => repo.updatePricingRule(rule, _why),
      'adminUpdatePricingRule',
      {
        'action': 'upsert',
        'vehicleClass': 'business',
        'serviceType': 'oneWay',
        'basePriceUsd': 1.0,
        'pricePerKmUsd': 2.0,
        'pricePerHourUsd': 0.0,
        'minimumPriceUsd': 3.0,
        'isActive': true,
        'reason': _why,
      },
    );
    await expectCall(
      () => repo.deactivatePricingRule(rule, _why),
      'adminUpdatePricingRule',
      {
        'action': 'deactivate',
        'vehicleClass': 'business',
        'serviceType': 'oneWay',
        'reason': _why
      },
    );
  });

  test('chóferes, vehículos y solicitudes', () async {
    await expectCall(
      () => repo.verifyDriver('luis', vehicleReviewed: true, reason: _why),
      'adminVerifyDriver',
      {
        'driverId': 'luis',
        'vehicleReviewed': true,
        'vehicleNote': '',
        'reason': _why
      },
    );
    await expectCall(
      () => repo.toggleVehicleStatus('v1', false, _why),
      'adminSetVehicleActive',
      {'vehicleId': 'v1', 'active': false, 'reason': _why},
    );
    await expectCall(
      () => repo.setLeadHandled('l1', true),
      'adminSetLeadHandled',
      {'leadId': 'l1', 'handled': true},
    );
    final profile =
        DriverProfile.fromJson({'userId': 'luis', 'licenseNumber': 'L-1'});
    final vehicle = Vehicle.fromJson(
        {'id': 'v1', 'driverId': 'luis', 'plate': 'ABC', 'class': 'business'});
    await expectCall(
      () => repo.updateDriverDocuments(
        profile,
        vehicle,
        const DriverDocumentsEdit(
            licenseNumber: 'L-2', vehicleClass: VehicleClass.businessVan),
        _why,
      ),
      'adminUpdateDriverSensitive',
      {
        'driverId': 'luis',
        'profile': {'licenseNumber': 'L-2'},
        'vehicle': {'vehicleId': 'v1', 'vehicleClass': 'businessVan'},
        'reason': _why,
      },
    );
  });

  group('errores del servidor, sin texto técnico', () {
    test('ajuste fuera de límite muestra el límite', () {
      expect(
        adminErrorMessage('failed-precondition',
            {'reason': 'price_adjustment_too_large', 'maxPercent': 10}),
        'El ajuste supera el límite permitido (10 %).',
      );
    });

    test('sin límite configurado lo explica', () {
      expect(
        adminErrorMessage(
            'failed-precondition', {'reason': 'price_adjustment_disabled'}),
        contains('no está habilitado'),
      );
    });

    test('motivo corto y segundo factor', () {
      expect(
          adminErrorMessage('invalid-argument', {'reason': 'invalid_request'}),
          contains('10 caracteres'));
      expect(adminErrorMessage('unauthenticated', {'reason': 'mfa_required'}),
          contains('dos pasos'));
      expect(
          adminErrorMessage('unauthenticated', {'reason': 'reauth_required'}),
          contains('vuelve a iniciar sesión'));
    });
  });

  group('qué ofrece el panel', () {
    test('el importe se ajusta solo antes de completar', () {
      expect(
          AdminOperations.canAdjustFinalPrice(_booking('confirmed')), isTrue);
      expect(
          AdminOperations.canAdjustFinalPrice(_booking('completed')), isFalse);
      expect(
          AdminOperations.canAdjustFinalPrice(_booking('cancelled')), isFalse);
    });

    test('solo se corrigen cobros manuales cobrados', () {
      Payment p(String intent, String status) => Payment.fromJson(
            {'id': 'p', 'stripePaymentIntentId': intent, 'status': status},
          );
      expect(AdminOperations.canCorrectPayment(p('', 'captured')), isTrue);
      expect(AdminOperations.canCorrectPayment(p('pi_1', 'captured')), isFalse);
      expect(AdminOperations.canCorrectPayment(p('', 'refunded')), isFalse);
      expect(AdminOperations.canCorrectPayment(null), isFalse);
    });
  });
}
