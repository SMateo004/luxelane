/// Validaciones de formularios compartidas. Coinciden con los límites de
/// firestore.rules (nombre de 1 a 80 caracteres, teléfono de hasta 20), así
/// que lo que pasa aquí no lo rechaza después el servidor.
abstract class LuxValidators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? email(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Escribe tu correo';
    if (!_email.hasMatch(t)) return 'Ingresa un correo válido';
    return null;
  }

  static String? name(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Indica tu nombre para que tu chófer pueda recibirte';
    if (t.length < 2) return 'Nombre demasiado corto';
    if (t.length > 80) return 'Máximo 80 caracteres';
    return null;
  }

  /// Teléfono con 7 a 15 dígitos; admite +, espacios, guiones y paréntesis.
  static String? phone(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Tu chófer lo necesita para contactarte';
    if (t.length > 20 || !RegExp(r'^\+?[\d\s\-()]+$').hasMatch(t)) {
      return 'Teléfono no válido';
    }
    final digits = t.replaceAll(RegExp(r'\D'), '').length;
    if (digits < 7 || digits > 15) return 'Teléfono no válido';
    return null;
  }

  static String? newPassword(String? v) {
    final t = v ?? '';
    if (t.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(t) || !RegExp(r'\d').hasMatch(t)) {
      return 'Combina letras y números';
    }
    return null;
  }
}
