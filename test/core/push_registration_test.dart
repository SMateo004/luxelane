import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/services/notification_service.dart';

void main() {
  group('registro del token de push', () {
    test('en móvil se registra para todos los roles', () {
      for (final role in UserRole.values) {
        expect(
          shouldRegisterPushToken(web: false, role: role, vapidKey: ''),
          isTrue,
        );
      }
    });

    test('en web solo el admin, y solo con FCM_VAPID_KEY', () {
      expect(
        shouldRegisterPushToken(
          web: true,
          role: UserRole.admin,
          vapidKey: 'clave-de-prueba',
        ),
        isTrue,
      );
      expect(
        shouldRegisterPushToken(web: true, role: UserRole.admin, vapidKey: ''),
        isFalse,
      );
      for (final role in [UserRole.rider, UserRole.driver]) {
        expect(
          shouldRegisterPushToken(
            web: true,
            role: role,
            vapidKey: 'clave-de-prueba',
          ),
          isFalse,
        );
      }
    });
  });
}
