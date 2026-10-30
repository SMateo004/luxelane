import 'dart:io';

/// Textos fijos en lib/ (idiomas, A5): literales de cadena que parecen
/// lenguaje natural. Criterio, igual para la línea base y para el
/// trinquete:
/// - se quitan comentarios; dentro de la cadena, las interpolaciones;
/// - cuenta si tiene acentos, ñ, ¿ o ¡; o un espacio y una palabra de 2+
///   letras; o es una palabra con mayúscula inicial («Reservar») o en
///   mayúsculas de 3+ letras («SOS»);
/// - no cuentan imports, rutas, URLs, ni las líneas de debugPrint, logs,
///   assert, excepciones, RegExp ni Key.

final _letters = RegExp(r'[A-Za-zÁÉÍÓÚáéíóúñÑ]');
final _accents = RegExp(r'[ÁÉÍÓÚáéíóúñÑ¿¡ãõçâêôàÃÕÇÂÊÔ]');
final _word2 = RegExp(r'[A-Za-z]{2,}');
final _capitalWord = RegExp(r'^[A-ZÁÉÍÓÚ][a-záéíóúñ]+[.!?:…]?$');
final _upperWord = RegExp(r'^[A-ZÁÉÍÓÚÑ]{3,}[.!?:…]?$');
final _notText = RegExp(r'^(package:|dart:|assets/|https?://|/|#|[a-z_]+/)');
final _skipLine = RegExp(
  r'\b(import|export|part)\b|debugPrint|log\(|logger\.|assert\(|Exception\(|Error\(|RegExp\(|Key\(',
);

bool looksLikeText(String body) {
  var s = body
      .replaceAll(RegExp(r'\$\{[^}]*\}'), '')
      .replaceAll(RegExp(r'\$[A-Za-z_]\w*'), '')
      .replaceAll(RegExp(r'\\[nt]'), ' ');
  if (!_letters.hasMatch(s)) return false;
  if (_notText.hasMatch(s)) return false;
  if (_accents.hasMatch(s)) return true;
  s = s.trim();
  if (s.contains(' ') && _word2.hasMatch(s)) return true;
  return _capitalWord.hasMatch(s) || _upperWord.hasMatch(s);
}

/// Cadenas de un archivo Dart con su línea, sin comentarios.
Iterable<({String body, String line})> literals(String src) sync* {
  var i = 0;
  final n = src.length;
  int lineStart(int at) => src.lastIndexOf('\n', at) + 1;
  String lineAt(int at) {
    final s = lineStart(at);
    final e = src.indexOf('\n', at);
    return src.substring(s, e < 0 ? n : e);
  }

  while (i < n) {
    if (src.startsWith('//', i)) {
      final e = src.indexOf('\n', i);
      i = e < 0 ? n : e;
      continue;
    }
    if (src.startsWith('/*', i)) {
      final e = src.indexOf('*/', i);
      i = e < 0 ? n : e + 2;
      continue;
    }
    final c = src[i];
    if (c == "'" || c == '"') {
      final raw = i > 0 && src[i - 1] == 'r';
      final triple = src.startsWith(c * 3, i);
      final q = triple ? c * 3 : c;
      var j = i + q.length;
      while (j < n && !src.startsWith(q, j)) {
        if (!raw && src[j] == r'\') j++;
        if (!triple && src[j] == '\n') break;
        j++;
      }
      final body = src.substring(i + q.length, j.clamp(0, n));
      yield (body: body, line: lineAt(i));
      i = j + q.length;
      continue;
    }
    i++;
  }
}

int countFile(String src) => literals(src)
    .where((l) => looksLikeText(l.body) && !_skipLine.hasMatch(l.line))
    .length;

/// Lo que mide el trinquete (meta: cero al final de la migración).
bool inRatchet(String path) =>
    (path.startsWith('lib/features/') &&
        !path.startsWith('lib/features/admin/') &&
        !path.startsWith('lib/features/legal/')) ||
    path.startsWith('lib/core/widgets/');

/// Fuera de la meta, pero tampoco pueden subir: textos de la app en
/// modelos, enums, errores y utilidades (p. ej. function_errors.dart).
bool inWatch(String path) =>
    !inRatchet(path) &&
    !path.startsWith('lib/features/admin/') &&
    !path.startsWith('lib/features/legal/') &&
    !path.startsWith('lib/l10n/') &&
    path != 'lib/firebase_options.dart';

String folderOf(String path) {
  final parts = path.split('/');
  return parts
      .take(parts[1] == 'features' || parts[1] == 'core' ? 3 : 2)
      .join('/');
}

/// Cuenta por carpeta: {'trinquete': {...}, 'vigilados': {...}}.
Map<String, Map<String, int>> countLib() {
  final out = {'trinquete': <String, int>{}, 'vigilados': <String, int>{}};
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));
  for (final f in files) {
    final path = f.path.replaceAll(r'\', '/');
    final group = inRatchet(path)
        ? 'trinquete'
        : inWatch(path)
            ? 'vigilados'
            : null;
    if (group == null) continue;
    final n = countFile(f.readAsStringSync());
    if (n == 0) continue;
    final k = folderOf(path);
    out[group]![k] = (out[group]![k] ?? 0) + n;
  }
  for (final g in out.keys) {
    out[g] = Map.fromEntries(
      out[g]!.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
  return out;
}
