import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';

/// Si [raw] sirve como enlace de lista en el cliente: vacío o https con
/// dominio. Es una comprobación básica; el servidor decide (hosts
/// admitidos, longitud, sin credenciales).
bool playlistLooksValid(String? raw) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty) return true;
  final uri = Uri.tryParse(s);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

/// Las preferencias listas para enviar: sin la lista si no se ofrece y con
/// la nota y el enlace sin espacios sobrantes.
TripPreferences cleanForSend(TripPreferences p, PreferenceOptions options) {
  final url = p.playlistUrl?.trim() ?? '';
  final note = p.note?.trim() ?? '';
  return p.copyWith(
    playlistUrl: url,
    clearPlaylist: !options.playlistEnabled || url.isEmpty,
    note: note,
    clearNote: note.isEmpty,
  );
}

/// Formulario de preferencias para el chófer: chips y selectores con las
/// listas cerradas del servidor. Lo usan el perfil y la reserva.
class TripPreferencesEditor extends StatefulWidget {
  const TripPreferencesEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.options = PreferenceOptions.none,
  });

  final TripPreferences value;
  final ValueChanged<TripPreferences> onChanged;
  final PreferenceOptions options;

  @override
  State<TripPreferencesEditor> createState() => _TripPreferencesEditorState();
}

class _TripPreferencesEditorState extends State<TripPreferencesEditor> {
  late final TextEditingController _note =
      TextEditingController(text: widget.value.note ?? '');
  late final TextEditingController _playlist =
      TextEditingController(text: widget.value.playlistUrl ?? '');

  @override
  void didUpdateWidget(TripPreferencesEditor old) {
    super.didUpdateWidget(old);
    _v = widget.value;
    // La copia saneada del servidor (p. ej. la nota sin espacios) o un
    // «volver a las del perfil» reemplazan lo escrito.
    final note = widget.value.note ?? '';
    if (note != _note.text) _note.text = note;
    final url = widget.value.playlistUrl ?? '';
    if (url != _playlist.text) _playlist.text = url;
  }

  @override
  void dispose() {
    _note.dispose();
    _playlist.dispose();
    super.dispose();
  }

  /// Lo último elegido, aunque el padre aún no haya reconstruido (dos
  /// toques seguidos no se pisan).
  late TripPreferences _v = widget.value;

  void _set(TripPreferences p) {
    _v = p;
    widget.onChanged(p);
  }

  List<T> _toggle<T extends Enum>(List<T> all, List<T> current, T v) {
    final on = current.contains(v);
    return [
      for (final e in all)
        if (e == v ? !on : current.contains(e)) e,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final duration = LuxMotion.of(context, LuxMotion.base);
    final privateNeeds = PracticalNeed.values.where((n) => n.private);
    final otherNeeds = PracticalNeed.values.where((n) => !n.private);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: t.prefsLanguagesTitle,
          child: _Chips(
            children: [
              for (final l in DriverLanguage.values)
                FilterChip(
                  label: Text(l.label),
                  selected: _v.languages.contains(l),
                  onSelected: (_) => _set(
                    _v.copyWith(
                      languages:
                          _toggle(DriverLanguage.values, _v.languages, l),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _Section(
          title: t.prefsTemperatureTitle,
          child: _SingleChoice<CabinTemperaturePref>(
            values: CabinTemperaturePref.values,
            selected: _v.temperature,
            labelOf: (v) => v.label,
            onChanged: (v) => _set(_v.copyWith(temperature: v)),
          ),
        ),
        _Section(
          title: t.prefsConversationTitle,
          child: _SingleChoice<ConversationPref>(
            values: ConversationPref.values,
            selected: _v.conversation,
            labelOf: (v) => v.label,
            onChanged: (v) => _set(_v.copyWith(conversation: v)),
          ),
        ),
        _Section(
          title: t.prefsMusicTitle,
          child: _SingleChoice<MusicStyle>(
            values: MusicStyle.values,
            selected: _v.music,
            labelOf: (v) => v.label,
            onChanged: (v) => _set(_v.copyWith(music: v)),
          ),
        ),
        AnimatedSize(
          duration: duration,
          curve: LuxMotion.emphasized,
          alignment: Alignment.topCenter,
          child: widget.options.playlistEnabled
              ? _Section(
                  title: t.prefsPlaylistTitle,
                  child: TextField(
                    key: const ValueKey('prefs-playlist'),
                    controller: _playlist,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    style: LuxTypography.bodyLarge,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.queue_music_rounded,
                        color: LuxColors.inkTertiary,
                      ),
                      helperText: t.prefsPlaylistHelp,
                      helperMaxLines: 3,
                      errorText: playlistLooksValid(_playlist.text)
                          ? null
                          : t.prefsPlaylistInvalid,
                      errorMaxLines: 3,
                    ),
                    onChanged: (s) => _set(
                      _v.copyWith(playlistUrl: s, clearPlaylist: s.isEmpty),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        _Section(
          title: t.prefsNeedsTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Chips(
                children: [
                  for (final n in otherNeeds) _needChip(n),
                ],
              ),
              const SizedBox(height: LuxSpacing.sm),
              _Chips(
                children: [
                  for (final n in privateNeeds) _needChip(n),
                ],
              ),
              const SizedBox(height: LuxSpacing.xs),
              _Hint(
                  icon: Icons.lock_outline_rounded,
                  text: t.prefsNeedPrivateHint),
            ],
          ),
        ),
        _Section(
          title: t.prefsNoteTitle,
          child: TextField(
            key: const ValueKey('prefs-note'),
            controller: _note,
            maxLength: widget.options.noteMax,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: LuxTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: t.prefsNoteHint,
              helperText: t.prefsNoteWarning,
              helperMaxLines: 3,
            ),
            onChanged: (s) => _set(_v.copyWith(note: s, clearNote: s.isEmpty)),
          ),
        ),
        const SizedBox(height: LuxSpacing.sm),
        _Hint(icon: Icons.visibility_outlined, text: t.prefsDriverWillSee),
      ],
    );
  }

  Widget _needChip(PracticalNeed n) => FilterChip(
        label: Text(n.label),
        selected: _v.needs.contains(n),
        onSelected: (_) => _set(
          _v.copyWith(needs: _toggle(PracticalNeed.values, _v.needs, n)),
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: LuxSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              label: title,
              excludeSemantics: true,
              child: SectionHeader(title: title),
            ),
            const SizedBox(height: LuxSpacing.sm),
            child,
          ],
        ),
      );
}

class _Chips extends StatelessWidget {
  const _Chips({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: LuxSpacing.sm,
        children: children,
      );
}

/// Una sola opción: chips de elección; tocar la elegida no la quita (para
/// eso está «Sin preferencia»).
class _SingleChoice<T> extends StatelessWidget {
  const _SingleChoice({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => _Chips(
        children: [
          for (final v in values)
            ChoiceChip(
              label: Text(labelOf(v)),
              selected: v == selected,
              onSelected: (_) {
                if (v != selected) onChanged(v);
              },
            ),
        ],
      );
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 16, color: LuxColors.inkTertiary),
          ),
          const SizedBox(width: LuxSpacing.sm),
          Expanded(child: Text(text, style: LuxTypography.caption)),
        ],
      );
}
