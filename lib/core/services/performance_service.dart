import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class PerformanceService {
  static Future<void> init() async {
    if (kIsWeb) return;
    await FirebasePerformance.instance
        .setPerformanceCollectionEnabled(!kDebugMode);
  }

  static Trace? startTrace(String name) {
    if (kIsWeb) return null;
    final trace = FirebasePerformance.instance.newTrace(name);
    trace.start();
    return trace;
  }

  static Future<void> stopTrace(Trace? trace) async {
    await trace?.stop();
  }

  static HttpMetric? newHttpMetric(String url, HttpMethod method) {
    if (kIsWeb) return null;
    return FirebasePerformance.instance.newHttpMetric(url, method);
  }
}
