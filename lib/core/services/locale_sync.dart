import 'package:flutter/widgets.dart';

import '../../app/locale_controller.dart';
import '../../app/lux_locale.dart';

/// Guarda el idioma en la cuenta (users/{uid}.locale y localeSource) con
/// updatePreferences, para que el servidor escriba los avisos en ese idioma.
/// El cliente nunca lo escribe directo en Firestore.
typedef SaveLocale = Future<Object?> Function(String locale, String source);

class LocaleSync {
  LocaleSync({
    required this.controller,
    required this.save,
    List<Locale> Function()? deviceLocales,
  }) : _device = deviceLocales ??
            (() => WidgetsBinding.instance.platformDispatcher.locales);

  final LocaleController controller;
  final SaveLocale save;
  final List<Locale> Function() _device;

  String get _deviceCode => LuxLocale.fromDevice(_device()).languageCode;

  /// Al entrar un usuario. Sin idioma en la cuenta (primer inicio de
  /// sesión) se guarda el del teléfono, o el elegido aquí. Si la cuenta
  /// tiene uno elegido y este dispositivo sigue en «Sistema», se adopta.
  Future<void> onSignedIn({String? serverLocale, String? serverSource}) async {
    final choice = controller.value;
    try {
      if (choice == LocaleChoice.system) {
        if (serverSource == 'user' && LuxLocale.codes.contains(serverLocale)) {
          await controller.choose(LuxLocale.choiceOf(serverLocale));
          return;
        }
        if (serverLocale != _deviceCode || serverSource != 'system') {
          await save(_deviceCode, 'system');
        }
        return;
      }
      if (serverLocale != choice.name || serverSource != 'user') {
        await save(choice.name, 'user');
      }
    } catch (_) {
      // Sin red o sin sesión válida: se reintenta en el próximo inicio.
    }
  }

  /// Elección en el perfil: la app cambia ya; true si la cuenta la guardó.
  Future<bool> choose(LocaleChoice choice, {required bool signedIn}) async {
    await controller.choose(choice);
    if (!signedIn) return true;
    try {
      if (choice == LocaleChoice.system) {
        await save(_deviceCode, 'system');
      } else {
        await save(choice.name, 'user');
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
