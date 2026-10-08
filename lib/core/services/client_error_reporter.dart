import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Sends app errors on the web (where Crashlytics isn't available) to the
/// reportClientError Cloud Function, which groups them for the admin panel.
///
/// Each session sends at most [maxPerSession] reports and never the same
/// error twice, so a render loop can't flood the backend.
class ClientErrorReporter {
  ClientErrorReporter({Future<void> Function(Map<String, dynamic> payload)? send, this.platform = 'web'})
      : _send = send ?? _callFunction;

  static const maxPerSession = 10;
  static const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

  final Future<void> Function(Map<String, dynamic>) _send;
  final String platform;
  final Set<String> _seen = {};
  int _sent = 0;
  bool _sending = false;

  /// Current route, set by the router so reports say where it happened.
  String? route;

  static Future<void> _callFunction(Map<String, dynamic> payload) async {
    await FirebaseFunctions.instance.httpsCallable('reportClientError').call(payload);
  }

  /// Key used to skip duplicates: message plus the first stack line.
  static String dedupeKey(Object error, StackTrace? stack) {
    final first = (stack?.toString() ?? '').split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    return '$error|$first';
  }

  Future<void> report(Object error, StackTrace? stack) async {
    if (_sending || _sent >= maxPerSession) return;
    if (!_seen.add(dedupeKey(error, stack))) return;
    _sent++;
    _sending = true;
    try {
      final message = error.toString();
      final trace = stack?.toString() ?? '';
      await _send({
        'platform': platform,
        'message': message.length > 300 ? message.substring(0, 300) : message,
        'stack': trace.length > 2000 ? trace.substring(0, 2000) : trace,
        if (route != null) 'route': route,
        'appVersion': appVersion,
      });
    } catch (e) {
      // Reporting must never crash the app or report itself.
      debugPrint('[ClientErrorReporter] could not report: $e');
    } finally {
      _sending = false;
    }
  }
}
