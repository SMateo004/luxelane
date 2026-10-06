import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../repositories/repositories.dart';

class NotificationService {
  NotificationService({required UserRepository userRepository})
      : _userRepo = userRepository;

  final UserRepository _userRepo;
  final _messaging = FirebaseMessaging.instance;

  static const _vapidKey = String.fromEnvironment('FCM_VAPID_KEY');

  String? _registeredUserId;
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;

  /// Registers this device's push token for [userId]. Safe to call on every
  /// sign-in: it only does work once per user.
  Future<void> init({required String userId}) async {
    if (_registeredUserId == userId) return;
    // Web push needs a VAPID key (pass --dart-define=FCM_VAPID_KEY=...).
    if (kIsWeb && _vapidKey.isEmpty) return;
    _registeredUserId = userId;

    try {
      await _messaging.requestPermission();
    } catch (_) {
      // Permission prompt unavailable (tests, unsupported browsers).
    }

    try {
      final token = kIsWeb
          ? await _messaging.getToken(vapidKey: _vapidKey)
          : await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        await _userRepo.updateFcmToken(userId: userId, token: token);
      }
    } catch (_) {
      // Token unavailable in emulator / web without vapid key
    }

    await _refreshSub?.cancel();
    _refreshSub = _messaging.onTokenRefresh.listen((newToken) {
      _userRepo.updateFcmToken(userId: userId, token: newToken);
    });

    _messageSub ??= FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  Future<void> dispose() async {
    await _refreshSub?.cancel();
    await _messageSub?.cancel();
    _registeredUserId = null;
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
