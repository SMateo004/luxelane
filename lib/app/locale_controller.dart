import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lux_locale.dart';

/// Elección de idioma de la app. Cambia al instante (las apps escuchan este
/// valor) y se recuerda en el dispositivo; la cuenta la guarda LocaleSync
/// en users/{uid}.locale con updatePreferences.
class LocaleController extends ValueNotifier<LocaleChoice> {
  LocaleController({LocaleChoice initial = LocaleChoice.system})
      : super(initial);

  static const _key = 'lux.locale';

  /// Idioma efectivo con los idiomas actuales del teléfono.
  Locale effective([List<Locale>? device]) => LuxLocale.resolve(
        value,
        device ?? WidgetsBinding.instance.platformDispatcher.locales,
      );

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      value = LuxLocale.choiceOf(p.getString(_key));
    } catch (_) {
      // Sin almacenamiento local: se queda en «Sistema».
    }
  }

  Future<void> choose(LocaleChoice choice) async {
    value = choice;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, choice.name);
    } catch (_) {}
  }
}
