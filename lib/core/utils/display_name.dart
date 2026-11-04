/// Longitud máxima del nombre visible. Igual que isValidDisplayName en
/// firestore.rules (de 1 a 80 caracteres en el alta y al editarlo).
const int kDisplayNameMaxLength = 80;

/// Nombre con el que se crea el perfil al entrar con Google: el de la
/// cuenta o, si no trae, la parte del correo antes de la arroba. Recortado
/// a [kDisplayNameMaxLength] puntos de código para que las reglas lo acepten.
String profileDisplayName(String? accountName, String email) {
  final name = (accountName ?? '').trim();
  final base = name.isNotEmpty ? name : email.toLowerCase().split('@').first;
  final runes = base.runes;
  if (runes.length <= kDisplayNameMaxLength) return base;
  return String.fromCharCodes(runes.take(kDisplayNameMaxLength)).trim();
}
