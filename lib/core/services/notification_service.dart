import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../repositories/repositories.dart';

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

  static const _vapidKey = String.fromEnvironment('FCM_VAPID_KEY');

  String? _initializedFor;
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;

  /// Registers this device's push token for [userId]. Runs on every sign-in
  /// (signing out removes the token); the listeners are set up only once.
  Future<void> init({required String userId}) async {
    // Web push needs a VAPID key (pass --dart-define=FCM_VAPID_KEY=...).
    if (kIsWeb && _vapidKey.isEmpty) return;
    _initializedFor = userId;

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

    _refreshSub ??= _messaging.onTokenRefresh.listen((newToken) {
      final uid = _initializedFor;
      if (uid != null) _userRepo.updateFcmToken(userId: uid, token: newToken);
    });

    _messageSub ??= FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  Future<void> dispose() async {
    await _refreshSub?.cancel();
    await _messageSub?.cancel();
    _refreshSub = null;
    _messageSub = null;
    _initializedFor = null;
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
