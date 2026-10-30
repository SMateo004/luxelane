import 'dart:convert';
import 'dart:io';

/// Claves y marcadores de los .arb (idiomas, A7). Las claves que empiezan
/// por @ son metadatos.
Map<String, Map<String, dynamic>> readArbs([String dir = 'lib/l10n']) => {
      for (final code in ['es', 'en', 'pt'])
        code: jsonDecode(File('$dir/app_$code.arb').readAsStringSync())
            as Map<String, dynamic>,
    };

final _placeholder = RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)');

/// Nombres de marcador de un mensaje ICU: {name}, {count, plural, …}.
Set<String> placeholdersOf(String message) =>
    _placeholder.allMatches(message).map((m) => m.group(1)!).toSet();

/// Problemas respecto a la plantilla (es): claves que faltan o sobran y
/// marcadores distintos. Vacío = todo en orden.
List<String> arbProblems(Map<String, Map<String, dynamic>> arbs) {
  final template = arbs['es']!;
  final keys = template.keys.where((k) => !k.startsWith('@')).toSet();
  final out = <String>[];
  for (final entry in arbs.entries) {
    if (entry.key == 'es') continue;
    final other = entry.value;
    final otherKeys = other.keys.where((k) => !k.startsWith('@')).toSet();
    for (final k in keys.difference(otherKeys)) {
      out.add('${entry.key}: falta $k');
    }
    for (final k in otherKeys.difference(keys)) {
      out.add('${entry.key}: sobra $k');
    }
    for (final k in keys.intersection(otherKeys)) {
      final a = placeholdersOf(template[k] as String);
      final b = placeholdersOf(other[k] as String);
      if (a.length != b.length || !a.containsAll(b)) {
        out.add('${entry.key}: $k tiene marcadores $b y la plantilla $a');
      }
      if ((other[k] as String).trim().isEmpty) {
        out.add('${entry.key}: $k vacío');
      }
    }
  }
  for (final k in keys) {
    final meta = template['@$k'];
    final declared = meta is Map && meta['placeholders'] is Map
        ? (meta['placeholders'] as Map).keys.toSet()
        : <String>{};
    final used = placeholdersOf(template[k] as String);
    if (declared.length != used.length || !declared.containsAll(used)) {
      out.add('es: $k usa $used y declara $declared');
    }
  }
  return out..sort();
}
