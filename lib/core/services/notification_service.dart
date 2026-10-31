import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../config/env.dart';
import '../enums/enums.dart';
import '../repositories/repositories.dart';

/// Quién registra el token de push. En móvil, todos. En web solo el admin
/// (para recibir los SOS en el panel) y solo con la clave VAPID: el push del
/// navegador no llega con el navegador cerrado, así que la guardia usa la
/// app móvil, pero el panel web también recibe los avisos.
bool shouldRegisterPushToken({
  required bool web,
  required UserRole role,
  required String vapidKey,
}) =>
    !web || (role == UserRole.admin && vapidKey.isNotEmpty);

/// Mensajes push con la app cerrada: el sistema muestra la notificación. Tiene
/// que ser una función de nivel superior (Android la invoca en su propio
/// isolate).
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService({required UserRepository userRepository})
      : _userRepo = userRepository;

  final UserRepository _userRepo;
  final _messaging = FirebaseMessaging.instance;

  String? _initializedFor;
  bool _listening = false;

  Future<void> init({
    required String userId,
    UserRole role = UserRole.rider,
  }) async {
    if (!shouldRegisterPushToken(
      web: kIsWeb,
      role: role,
      vapidKey: AppConfig.fcmVapidKey,
    )) {
      return;
    }
    // El token se registra en cada entrada (al salir se quita); los
    // listeners, una sola vez.
    _initializedFor = userId;

    await _messaging.requestPermission();

    try {
      final token = kIsWeb
          ? await _messaging.getToken(vapidKey: AppConfig.fcmVapidKey)
          : await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        await _userRepo.updateFcmToken(userId: userId, token: token);
      }
    } catch (_) {
      // Token unavailable in emulator / web without vapid key
    }

    if (_listening) return;
    _listening = true;
    _messaging.onTokenRefresh.listen((newToken) {
      final uid = _initializedFor;
      if (uid != null) _userRepo.updateFcmToken(userId: uid, token: newToken);
    });

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  void _onForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint(
        '[FCM] foreground: ${message.notification?.title} — ${message.notification?.body}', // i18n-ignore: registro de depuración
      );
    }
  }

  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// Reservas de los avisos que el usuario toca (con la app en segundo plano
  /// o cerrada), para abrirlas.
  Stream<String> get openedBookings async* {
    if (kIsWeb) return;
    final initial = await _messaging.getInitialMessage();
    final first = initial?.data['bookingId'];
    if (first is String && first.isNotEmpty) yield first;
    yield* FirebaseMessaging.onMessageOpenedApp
        .map((m) => m.data['bookingId'])
        .where((id) => id is String && id.isNotEmpty)
        .cast<String>();
  }
}
