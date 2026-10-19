import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'firebase_env.dart';

/// Resultado de iniciar Firebase al arrancar la app.
sealed class FirebaseStartup {
  const FirebaseStartup();
}

class FirebaseReady extends FirebaseStartup {
  const FirebaseReady();
}

/// Release: la app no arranca sin Firebase.
class FirebaseFatal extends FirebaseStartup {
  const FirebaseFatal(this.error);
  final Object error;
}

/// Debug: la app sigue, con un aviso visible de lo que falta.
class FirebaseDegraded extends FirebaseStartup {
  const FirebaseDegraded(this.message);
  final String message;
}

/// Ejecuta [initialize] y decide qué hacer si falla. En release cualquier
/// fallo es fatal; en debug se avisa en consola y en pantalla.
Future<FirebaseStartup> startFirebase(
  Future<void> Function() initialize, {
  bool release = kReleaseMode,
  void Function(String)? log,
}) async {
  log ??= (m) => debugPrint(m);
  try {
    await initialize();
    return const FirebaseReady();
  } catch (e) {
    if (release) {
      log('[Luxelane] Firebase no se pudo iniciar: $e');
      return FirebaseFatal(e);
    }
    final message = e is StagingNotConfiguredError
        ? e.message
        : 'Firebase no se pudo iniciar: $e';
    log('[Luxelane] AVISO: $message');
    return FirebaseDegraded(message);
  }
}

/// Envuelve la app según el resultado: pantalla de error si es fatal, aviso
/// en pantalla si falta configuración, o la app tal cual.
Widget appForStartup(FirebaseStartup startup, Widget app) => switch (startup) {
      FirebaseReady() => app,
      FirebaseFatal() => const FirebaseStartupErrorApp(),
      FirebaseDegraded(:final message) =>
        FirebaseSetupWarning(message: message, child: app),
    };

/// Pantalla sobria que sustituye a la app cuando Firebase no arranca.
class FirebaseStartupErrorApp extends StatelessWidget {
  const FirebaseStartupErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: LuxColors.bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(LuxSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded,
                      size: 40, color: LuxColors.inkTertiary),
                  SizedBox(height: LuxSpacing.md),
                  Text(
                    'No pudimos iniciar la app',
                    textAlign: TextAlign.center,
                    style: LuxTypography.titleLarge,
                  ),
                  SizedBox(height: LuxSpacing.sm),
                  Text(
                    'Cierra la app y vuelve a abrirla en unos minutos.',
                    textAlign: TextAlign.center,
                    style: LuxTypography.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Franja de aviso (solo debug) sobre la app cuando falta configuración.
class FirebaseSetupWarning extends StatelessWidget {
  const FirebaseSetupWarning({
    super.key,
    required this.message,
    required this.child,
  });

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: LuxColors.warning,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: LuxSpacing.md, vertical: LuxSpacing.sm),
                  child: Text(
                    message,
                    style: const TextStyle(
                        color: LuxColors.onAccent, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
