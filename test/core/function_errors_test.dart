import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/app_check_setup.dart';
import 'package:luxelane/core/error/function_errors.dart';
import 'package:luxelane/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:luxelane/features/incidents/data/incident_repository_impl.dart';
import 'package:luxelane/features/ride/data/repositories/trip_flow_repository_impl.dart';

/// Lo que manda el servidor tras el traductor de errores: código y motivo.
Map<String, Object> d(String code, String reason) =>
    {'code': code, 'reason': reason};

void main() {
  group('functionErrorMessage: un mensaje en español por código', () {
    final codes = {
      'invalid-argument': 'Revisa los datos e inténtalo de nuevo.',
      'unauthenticated': kSessionExpiredMessage,
      'permission-denied': 'No tienes permiso para hacer esto.',
      'failed-precondition': 'Esto no se puede hacer en este momento.',
      'resource-exhausted': kTooManyAttemptsMessage,
      'not-found': 'No encontramos el registro.',
      'internal': 'No se pudo completar. Inténtalo de nuevo.',
      'unavailable': kNoConnectionMessage,
    };
    codes.forEach((code, msg) {
      test(code, () => expect(functionErrorMessage(code, null), msg));
    });

    test('App Check rechazado: el mensaje de verificación de la app', () {
      expect(
        functionErrorMessage(
            'unauthenticated', d('unauthenticated', 'app_check_required')),
        kAppCheckFailedMessage,
      );
    });

    test('nunca muestra el texto que venga del servidor', () {
      const leaky = 'payment/capture-failed: sk_test_falsa';
      expect(functionErrorMessage('internal', {'reason': leaky}),
          isNot(contains('sk_test')));
    });
  });

  group('pantallas', () {
    test('reserva: límite de intentos y App Check', () {
      expect(
          bookingFailureFor(
                  'resource-exhausted', d('resource_exhausted', 'rate_limited'))
              .message,
          kTooManyAttemptsMessage);
      expect(
          bookingFailureFor(
                  'unauthenticated', d('unauthenticated', 'app_check_required'))
              .message,
          kAppCheckFailedMessage);
    });

    test('viaje: App Check rechazado', () {
      expect(
          tripFailureFor(
                  'unauthenticated', d('unauthenticated', 'app_check_required'))
              .message,
          kAppCheckFailedMessage);
    });

    test('SOS: conserva su texto propio para el límite', () {
      expect(
          incidentFailureFor(
                  'resource-exhausted', d('resource_exhausted', 'rate_limited'))
              .message,
          'Ya enviaste varios avisos. Llama a central si lo necesitas.');
    });

    test('eliminar cuenta: motivos por details.reason, no por el mensaje', () {
      expect(
          deleteAccountErrorMessage('failed-precondition',
              d('failed_precondition', 'active-bookings')),
          startsWith('Tienes viajes activos'));
      expect(
          deleteAccountErrorMessage(
              'failed-precondition', d('failed_precondition', 'admin_account')),
          'Las cuentas de administración se eliminan desde la consola.');
      expect(deleteAccountErrorMessage('internal', d('internal', 'internal')),
          'No pudimos eliminar tu cuenta. Inténtalo de nuevo.');
    });
  });
}
