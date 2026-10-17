import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../app_gate/global_config.dart';

/// Paths each app accepts from a notification's `link`
/// (functions/src/push.ts). Anything else is ignored.
const _allowed = {
  LuxApp.rider: ['/ride/', '/viajes/', '/profile', '/ayuda', '/trips', '/admin'],
  LuxApp.driver: ['/driver', '/ayuda'],
};

/// The in-app path a push opens, or null when it has none this app accepts.
String? pushLink(LuxApp app, Map<String, dynamic> data) {
  final link = data['link'];
  if (link is! String || !link.startsWith('/') || link.contains('..') || link.length > 200) return null;
  return _allowed[app]!.any(link.startsWith) ? link : null;
}

/// Opens the right screen when a notification is tapped (app closed or in
/// the background) and shows a banner for those that arrive while the app
/// is open — the system doesn't show them then.
class PushLinks {
  PushLinks({
    required this.app,
    required this.open,
    required this.messenger,
    Stream<RemoteMessage>? opened,
    Stream<RemoteMessage>? foreground,
    Future<RemoteMessage?> Function()? initial,
  })  : _opened = opened ?? FirebaseMessaging.onMessageOpenedApp,
        _foreground = foreground ?? FirebaseMessaging.onMessage,
        _initial = initial ?? FirebaseMessaging.instance.getInitialMessage;

  final LuxApp app;
  final void Function(String link) open;
  final GlobalKey<ScaffoldMessengerState> messenger;
  final Stream<RemoteMessage> _opened;
  final Stream<RemoteMessage> _foreground;
  final Future<RemoteMessage?> Function() _initial;
  final _subs = <StreamSubscription<RemoteMessage>>[];

  Future<void> start() async {
    _subs
      ..add(_opened.listen(_openFrom))
      ..add(_foreground.listen(_banner));
    try {
      final first = await _initial();
      if (first != null) _openFrom(first);
    } catch (e) {
      debugPrint('[Luxelane] initial push unavailable: $e');
    }
  }

  void _openFrom(RemoteMessage m) {
    final link = pushLink(app, m.data);
    if (link != null) open(link);
  }

  void _banner(RemoteMessage m) {
    final state = messenger.currentState;
    final n = m.notification;
    if (state == null || n == null) return;
    final link = pushLink(app, m.data);
    final l = Localizations.of<AppLocalizations>(state.context, AppLocalizations);
    state.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (n.title != null) Text(n.title!, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (n.body != null) Text(n.body!),
      ]),
      action: link == null || l == null ? null : SnackBarAction(label: l.pushOpen, onPressed: () => open(link)),
    ));
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
  }
}
