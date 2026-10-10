import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/firebase_env.dart';
import 'package:luxelane/core/widgets/environment_banner.dart';

import 'helpers/l10n.dart';

const _prod = FirebaseOptions(apiKey: 'p', appId: '1:1:web:1', messagingSenderId: '1', projectId: 'luxelane-4e7ae');

void main() {
  group('FirebaseEnv', () {
    test('production unless a project is given', () {
      expect(FirebaseEnv.fromDefines(projectId: '', apiKey: '', appId: '', messagingSenderId: '', fallback: _prod), _prod);
      // Tests run without dart-defines: production.
      expect(FirebaseEnv.isProduction, isTrue);
      expect(FirebaseEnv.options(() => _prod), _prod);
    });

    test('a staging project from dart-defines, with derived domains', () {
      final o = FirebaseEnv.fromDefines(
        projectId: 'luxelane-staging',
        apiKey: 'AIzaX',
        appId: '1:99:web:abc',
        messagingSenderId: '99',
        fallback: _prod,
      );
      expect(o.projectId, 'luxelane-staging');
      expect(o.authDomain, 'luxelane-staging.firebaseapp.com');
      expect(o.storageBucket, 'luxelane-staging.firebasestorage.app');
    });

    test('an incomplete config fails loudly instead of using production', () {
      expect(
        () => FirebaseEnv.fromDefines(projectId: 'luxelane-staging', apiKey: '', appId: 'x', messagingSenderId: '9', fallback: _prod),
        throwsStateError,
      );
    });
  });

  test('the generated options are only read when no project is given', () {
    // On Android/iOS the generated getter throws (web-only file).
    expect(() => FirebaseEnv.options(() => throw UnsupportedError('android')), throwsUnsupportedError);
    final o = FirebaseEnv.fromDefines(
      projectId: 'luxelane-4e7ae',
      apiKey: 'k',
      appId: '1:51157842817:android:abc',
      messagingSenderId: '51157842817',
      iosBundleId: '',
    );
    expect(o.appId, contains('android'));
    expect(o.iosBundleId, isNull);
  });

  testWidgets('STAGING ribbon only outside production', (tester) async {
    await tester.pumpWidget(localizedApp(const EnvironmentBanner(show: true, child: Scaffold())));
    final staging = find.byWidgetPredicate((w) => w is Banner && w.message == 'STAGING');
    expect(staging, findsOneWidget);
    await tester.pumpWidget(localizedApp(const EnvironmentBanner(child: Scaffold())));
    expect(staging, findsNothing);
  });
}
