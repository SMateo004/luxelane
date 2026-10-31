// Genera lib/l10n/app_es.arb, app_en.arb y app_pt.arb a partir de los
// fragmentos lib/l10n/src/<bloque>.json, uno por bloque de pantallas. Así
// cada bloque edita solo su archivo y la revisión ve los tres idiomas
// juntos. Uso:
//
//   dart run tool/l10n/build_arb.dart && flutter gen-l10n
//
// Formato de un fragmento:
//   {"clave": {"description": "…", "es": "…", "en": "…", "pt": "…",
//              "placeholders": {"name": {"type": "String"}}}}
import 'dart:convert';
import 'dart:io';

const locales = ['es', 'en', 'pt'];

/// Contenido de los tres .arb (por idioma) a partir de [srcDir]. Falla si
/// una clave se repite entre fragmentos o le falta un idioma.
Map<String, String> buildArbs(String srcDir) {
  final files = Directory(srcDir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final out = {
    for (final l in locales) l: <String, Object?>{'@@locale': l}
  };
  final seen = <String, String>{};
  for (final f in files) {
    final name = f.uri.pathSegments.last;
    final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    for (final e in data.entries) {
      final key = e.key;
      if (seen.containsKey(key)) {
        throw StateError('$key está en ${seen[key]} y en $name');
      }
      seen[key] = name;
      final v = e.value as Map<String, dynamic>;
      for (final l in locales) {
        final text = v[l];
        if (text is! String || text.trim().isEmpty) {
          throw StateError('$name: $key no tiene $l');
        }
        out[l]![key] = text;
      }
      out['es']!['@$key'] = {
        'description': v['description'] ?? '',
        if (v['placeholders'] != null) 'placeholders': v['placeholders'],
      };
    }
  }
  const enc = JsonEncoder.withIndent('  ');
  return {for (final l in locales) l: '${enc.convert(out[l])}\n'};
}

void main(List<String> args) {
  final arbs = buildArbs('lib/l10n/src');
  for (final e in arbs.entries) {
    File('lib/l10n/app_${e.key}.arb').writeAsStringSync(e.value);
  }
  stdout.writeln('lib/l10n/app_{es,en,pt}.arb generados');
}
