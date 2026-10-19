import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/firebase_env.dart';

void main() {
  group('FirebaseEnv.parse', () {
    test('sin FIREBASE_ENV usa staging, nunca producción', () {
      expect(FirebaseEnv.parse(''), FirebaseEnv.staging);
    });

    test('acepta staging y production', () {
      expect(FirebaseEnv.parse('staging'), FirebaseEnv.staging);
      expect(FirebaseEnv.parse('production'), FirebaseEnv.production);
    });

    test('rechaza cualquier otro valor', () {
      for (final raw in ['prod', 'dev', 'PRODUCTION', 'luxelane-4e7ae']) {
        expect(() => FirebaseEnv.parse(raw), throwsArgumentError);
      }
    });
  });

  test('esta compilación de tests no apunta a producción', () {
    expect(FirebaseEnv.current, FirebaseEnv.staging);
  });
}
