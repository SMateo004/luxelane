// Merges lib/l10n/parts/*.json into lib/l10n/app_{es,en,pt}.arb.
//
// Each part file maps message keys to translations:
//
//   {
//     "tripPickupIn": {
//       "es": "Recogida en {minutes} min",
//       "en": "Pickup in {minutes} min",
//       "pt": "Embarque em {minutes} min",
//       "description": "Countdown on the confirmation page",
//       "placeholders": { "minutes": { "type": "int" } }
//     }
//   }
//
// Run: dart run tool/build_l10n.dart && flutter gen-l10n
// Pass --check to fail (exit 1) when the ARB files are out of date (CI).
import 'dart:convert';
import 'dart:io';

const locales = ['es', 'en', 'pt'];
const template = 'es';

void main(List<String> args) {
  final check = args.contains('--check');
  final partsDir = Directory('lib/l10n/parts');
  final files = partsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final messages = <String, Map<String, dynamic>>{};
  final errors = <String>[];
  for (final file in files) {
    final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    map.forEach((key, value) {
      if (messages.containsKey(key)) errors.add('Duplicate key "$key" in ${file.path}');
      if (!RegExp(r'^[a-z][A-Za-z0-9]*$').hasMatch(key)) errors.add('Invalid key "$key" in ${file.path}');
      final entry = Map<String, dynamic>.from(value as Map);
      for (final l in locales) {
        final text = entry[l];
        if (text is! String || text.trim().isEmpty) errors.add('Missing "$l" for "$key" in ${file.path}');
      }
      messages[key] = entry;
    });
  }
  if (errors.isNotEmpty) {
    stderr.writeln(errors.join('\n'));
    exit(1);
  }

  final keys = messages.keys.toList()..sort();
  var stale = false;
  for (final l in locales) {
    final arb = <String, dynamic>{'@@locale': l};
    for (final k in keys) {
      final m = messages[k]!;
      arb[k] = m[l];
      if (l == template && (m['description'] != null || m['placeholders'] != null)) {
        arb['@$k'] = {
          if (m['description'] != null) 'description': m['description'],
          if (m['placeholders'] != null) 'placeholders': m['placeholders'],
        };
      }
    }
    final out = File('lib/l10n/app_$l.arb');
    final text = '${const JsonEncoder.withIndent('  ').convert(arb)}\n';
    if (check) {
      if (!out.existsSync() || out.readAsStringSync() != text) {
        stderr.writeln('${out.path} is out of date. Run: dart run tool/build_l10n.dart');
        stale = true;
      }
    } else {
      out.writeAsStringSync(text);
    }
  }
  if (stale) exit(1);
  stdout.writeln('${keys.length} messages × ${locales.length} locales${check ? ' — up to date' : ' written'}.');
}
