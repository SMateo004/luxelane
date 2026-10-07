// Fails when user-facing text is hardcoded instead of coming from
// AppLocalizations (context.l10n). Add new strings to lib/l10n/parts/*.json.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Arguments that commonly carry visible text.
final _uiPattern = RegExp(
  r'''(?:\b(?:Text|SelectableText)\(\s*|\bTextSpan\(\s*text:\s*|\b(?:label|labelText|hintText|helperText|errorText|title|subtitle|tooltip|message|semanticsLabel|actionLabel|notificationTitle|notificationText|body|headline|tag|sub|quote)\s*:\s*|showLuxSnackbar\([^,]+,\s*|SnackBar\(\s*content:\s*Text\(\s*)(?:const\s+)?(['"])((?:(?!\1)[^\n])*)\1''',
);

/// Visible text that is the same in every language.
const _allowed = {
  'Luxelane', 'LUXELANE', 'L', 'WhatsApp', 'Bs', '—', '·', '•', '→', '+', '-', '/', ':', '"',
};

/// Files that legitimately hold literal text.
bool _skipFile(String path) =>
    path.contains('/l10n/') ||
    path.endsWith('legal_content.dart') || // per-language documents
    path.endsWith('.g.dart');

bool _isTranslatable(String literal) {
  final text = literal.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '').trim();
  if (text.isEmpty || _allowed.contains(text)) return false;
  // Needs at least two letters in a row to be "words".
  return RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ¿¡]{2,}').hasMatch(text) &&
      !RegExp(r'^(assets/|https?:|[a-z]+_[a-z_]+$|/)').hasMatch(text);
}

List<String> findHardcodedStrings() {
  final hits = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart') || _skipFile(entity.path)) continue;
    // Drop line comments, keep offsets stable for line numbers.
    final source = entity
        .readAsStringSync()
        .replaceAllMapped(RegExp(r'^\s*//.*$', multiLine: true), (m) => ' ' * m[0]!.length);
    for (final m in _uiPattern.allMatches(source)) {
      if (!_isTranslatable(m.group(2)!)) continue;
      final line = '\n'.allMatches(source.substring(0, m.start)).length + 1;
      hits.add('${entity.path}:$line: ${m.group(2)}');
    }
  }
  return hits;
}

void main() {
  test('no hardcoded user-facing strings', () {
    final hits = findHardcodedStrings();
    expect(hits, isEmpty, reason: 'Move these to lib/l10n/parts/*.json:\n${hits.join('\n')}');
  });
}
