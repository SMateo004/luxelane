import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../repositories/repositories.dart';

class NotificationService {
  NotificationService({required UserRepository userRepository})
      : _userRepo = userRepository;

  final UserRepository _userRepo;
  final _messaging = FirebaseMessaging.instance;

  Future<void> init({required String userId}) async {
    if (kIsWeb) return; // FCM background + token not supported on web without vapid setup

    await _messaging.requestPermission(
      
    );

    try {
      final token = kIsWeb
          ? await _messaging.getToken(
              vapidKey: const String.fromEnvironment('FCM_VAPID_KEY'),
            )
          : await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        await _userRepo.updateFcmToken(userId: userId, token: token);
      }
    } catch (_) {
      // Token unavailable in emulator / web without vapid key
    }

    _messaging.onTokenRefresh.listen((newToken) {
      _userRepo.updateFcmToken(userId: userId, token: newToken);
    });

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  void _onForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint(
        '[FCM] foreground: ${message.notification?.title} — ${message.notification?.body}',
      );
    }
  }

  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}
