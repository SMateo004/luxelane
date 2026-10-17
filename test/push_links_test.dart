import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/app_gate/global_config.dart';
import 'package:luxelane/core/services/push_links.dart';
import 'package:luxelane/l10n/l10n.dart';

RemoteMessage _msg(String? link, {String? title, String? body}) => RemoteMessage(
      data: {if (link != null) 'link': link},
      notification: title == null ? null : RemoteNotification(title: title, body: body),
    );

void main() {
  test('each app only opens its own screens', () {
    expect(pushLink(LuxApp.rider, {'link': '/ride/b1'}), '/ride/b1');
    expect(pushLink(LuxApp.rider, {'link': '/viajes/b1/recibo'}), '/viajes/b1/recibo');
    expect(pushLink(LuxApp.rider, {'link': '/driver/queue'}), isNull);
    expect(pushLink(LuxApp.driver, {'link': '/driver/documents'}), '/driver/documents');
    expect(pushLink(LuxApp.driver, {'link': '/ride/b1'}), isNull);
    expect(pushLink(LuxApp.rider, {'link': 'https://evil.example'}), isNull);
    expect(pushLink(LuxApp.rider, {'link': '/ride/../admin'}), isNull);
    expect(pushLink(LuxApp.rider, {}), isNull);
  });

  testWidgets('a tap opens the screen; one received in the app shows a banner with "Ver"', (tester) async {
    final opened = StreamController<RemoteMessage>();
    final foreground = StreamController<RemoteMessage>();
    final messenger = GlobalKey<ScaffoldMessengerState>();
    final links = <String>[];
    final push = PushLinks(
      app: LuxApp.rider,
      open: links.add,
      messenger: messenger,
      opened: opened.stream,
      foreground: foreground.stream,
      initial: () async => _msg('/viajes/b0/recibo'),
    );
    await tester.pumpWidget(MaterialApp(
      scaffoldMessengerKey: messenger,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('es')],
      locale: const Locale('es'),
      home: const Scaffold(body: SizedBox()),
    ));
    await push.start();
    expect(links, ['/viajes/b0/recibo']); // opened the app from a notification

    opened.add(_msg('/ride/b1'));
    await tester.pump();
    expect(links.last, '/ride/b1');

    foreground.add(_msg('/ride/b2', title: 'Tu chófer llegó', body: 'Te espera en la puerta.'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // slide-in animation
    expect(find.text('Tu chófer llegó'), findsOneWidget);
    expect(find.text('Ver'), findsOneWidget);
    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    expect(links.last, '/ride/b2');
    unawaited(push.dispose());
  });
}
