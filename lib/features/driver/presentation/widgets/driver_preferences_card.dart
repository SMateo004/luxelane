import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';

/// Abre una URL fuera de la app (sustituible en los tests).
typedef ExternalLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchExternal(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Preferencias del pasajero para el viaje que atiende el chófer: la copia
/// de la reserva (bookings/{id}/driverView/preferences). Las reglas solo la
/// dejan leer al chófer asignado y activo entre confirmed e in_progress;
/// fuera de esa ventana el flujo da null y la tarjeta no se muestra.
class DriverPreferencesCard extends StatelessWidget {
  const DriverPreferencesCard({
    super.key,
    required this.bookingId,
    this.repository,
    this.launch = _launchExternal,
  });

  final String bookingId;

  /// Por defecto, el del contenedor de dependencias.
  final PreferencesRepository? repository;
  final ExternalLauncher launch;

  @override
  Widget build(BuildContext context) {
    final repo = repository ??
        (sl.isRegistered<PreferencesRepository>()
            ? sl<PreferencesRepository>()
            : null);
    if (repo == null || bookingId.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<TripPreferences?>(
      stream: repo.watchBookingPreferences(bookingId),
      builder: (context, snap) {
        final prefs = snap.data;
        if (prefs == null || prefs.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: LuxSpacing.md),
          child: DriverPreferencesView(preferences: prefs, launch: launch),
        );
      },
    );
  }
}

/// La tarjeta en sí: iconos y etiquetas legibles, la nota completa y el
/// botón para abrir la lista fuera de la app, con aviso previo.
class DriverPreferencesView extends StatelessWidget {
  const DriverPreferencesView({
    super.key,
    required this.preferences,
    this.launch = _launchExternal,
  });

  final TripPreferences preferences;
  final ExternalLauncher launch;

  Future<void> _openPlaylist(BuildContext context, String url) async {
    final t = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.prefsOpenPlaylistTitle),
        content: Text(t.prefsOpenPlaylistBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(t.prefsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(t.prefsOpenPlaylistConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final uri = Uri.tryParse(url);
    // Solo https; nunca se incrusta ni se previsualiza.
    final opened = uri != null && uri.scheme == 'https' && await launch(uri);
    if (!opened && context.mounted) {
      showLuxSnackbar(context, t.prefsOpenPlaylistError, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final p = preferences;
    final rows = <(IconData, String, String)>[
      if (p.languages.isNotEmpty)
        (
          Icons.translate_rounded,
          t.prefsLanguagesTitle,
          p.languages.map((l) => l.label).join(', '),
        ),
      if (p.temperature != CabinTemperaturePref.noPreference)
        (
          Icons.thermostat_outlined,
          t.prefsTemperatureTitle,
          p.temperature.label
        ),
      if (p.conversation != ConversationPref.noPreference)
        (
          Icons.forum_outlined,
          t.prefsConversationTitle,
          p.conversation.label,
        ),
      if (p.music != MusicStyle.noPreference)
        (Icons.music_note_outlined, t.prefsMusicTitle, p.music.label),
      if (p.needs.isNotEmpty)
        (
          Icons.luggage_outlined,
          t.prefsNeedsTitle,
          p.needs.map((n) => n.label).join(', '),
        ),
      if (p.note != null)
        (Icons.sticky_note_2_outlined, t.prefsNoteTitle, p.note!),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LuxSpacing.md),
      decoration: BoxDecoration(
        color: LuxColors.sapphireTint,
        borderRadius: BorderRadius.circular(LuxRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(t.prefsCardTitle, style: LuxTypography.eyebrow),
          ),
          for (final (icon, label, value) in rows) ...[
            const SizedBox(height: LuxSpacing.sm),
            MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(icon, size: 18, color: LuxColors.sapphire),
                  ),
                  const SizedBox(width: LuxSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: LuxTypography.caption),
                        Text(value, style: LuxTypography.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (p.playlistUrl case final url?) ...[
            const SizedBox(height: LuxSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: TextButton.icon(
                onPressed: () => _openPlaylist(context, url),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(t.prefsOpenPlaylist),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
