import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../profile/presentation/widgets/trip_preferences_editor.dart';

/// Paso opcional de la reserva: las preferencias de este viaje, con las del
/// perfil precargadas. Sin tocarlo no se envía nada (el servidor copia las
/// del perfil); si el pasajero las cambia, [onChanged] da las de este viaje
/// y, si vuelve a las del perfil, null.
class TripPreferencesStep extends StatelessWidget {
  const TripPreferencesStep({
    super.key,
    required this.profile,
    required this.trip,
    required this.onChanged,
    this.repository,
  });

  /// Las del perfil del pasajero.
  final TripPreferences profile;

  /// Las cambiadas para este viaje; null si se usan las del perfil.
  final TripPreferences? trip;
  final ValueChanged<TripPreferences?> onChanged;

  /// Para las opciones (getPreferenceOptions). Por defecto, el del
  /// contenedor de dependencias.
  final PreferencesRepository? repository;

  Future<void> _edit(BuildContext context) async {
    final repo = repository ??
        (sl.isRegistered<PreferencesRepository>()
            ? sl<PreferencesRepository>()
            : null);
    final result =
        await showModalBottomSheet<(TripPreferences, PreferenceOptions)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: LuxColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LuxRadius.xl)),
      ),
      builder: (_) => _TripPreferencesSheet(
        initial: trip ?? profile,
        options: repo?.options() ?? Future.value(PreferenceOptions.none),
      ),
    );
    if (result == null) return; // Omitir: nada cambia.
    final (prefs, options) = result;
    // Iguales a las del perfil: no hace falta mandarlas.
    onChanged(prefs == cleanForSend(profile, options) ? null : prefs);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final current = trip ?? profile;
    final summary = current.summary;
    final source = trip != null
        ? t.prefsTripChanged
        : (profile.isEmpty ? null : t.prefsTripFromProfile);
    return Semantics(
      container: true,
      label: t.prefsTripTitle,
      child: AnimatedSize(
        duration: LuxMotion.of(context, LuxMotion.base),
        curve: LuxMotion.emphasized,
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            LuxSpacing.md,
            LuxSpacing.md,
            LuxSpacing.sm,
            LuxSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: LuxColors.surface,
            borderRadius: BorderRadius.circular(LuxRadius.lg),
            border: Border.all(color: LuxColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ExcludeSemantics(
                    child: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: LuxColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(width: LuxSpacing.sm),
                  Expanded(
                    child: Text(
                      t.prefsTripTitle,
                      style: LuxTypography.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LuxSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(right: LuxSpacing.sm),
                child: Text(
                  summary.isEmpty ? t.prefsTripEmpty : summary.join(' · '),
                  style: LuxTypography.bodyMedium,
                ),
              ),
              if (source != null) ...[
                const SizedBox(height: LuxSpacing.xs),
                Text(source, style: LuxTypography.caption),
              ],
              Wrap(
                children: [
                  TextButton(
                    onPressed: () => _edit(context),
                    child: Text(t.prefsTripEdit),
                  ),
                  if (trip != null)
                    TextButton(
                      onPressed: () => onChanged(null),
                      child: Text(t.prefsTripReset),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripPreferencesSheet extends StatefulWidget {
  const _TripPreferencesSheet({required this.initial, required this.options});
  final TripPreferences initial;
  final Future<PreferenceOptions> options;

  @override
  State<_TripPreferencesSheet> createState() => _TripPreferencesSheetState();
}

class _TripPreferencesSheetState extends State<_TripPreferencesSheet> {
  late TripPreferences _draft = widget.initial;
  PreferenceOptions _options = PreferenceOptions.none;

  @override
  void initState() {
    super.initState();
    widget.options.then((o) {
      if (mounted) setState(() => _options = o);
    }, onError: (_) {});
  }

  bool get _valid =>
      playlistLooksValid(_options.playlistEnabled ? _draft.playlistUrl : null);

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LuxSpacing.lg,
              LuxSpacing.lg,
              LuxSpacing.sm,
              LuxSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      Text(t.prefsTripTitle, style: LuxTypography.titleLarge),
                ),
                IconButton(
                  tooltip: t.prefsTripSkip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: LuxColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: LuxSpacing.lg),
              child: TripPreferencesEditor(
                value: _draft,
                options: _options,
                onChanged: (p) => setState(() => _draft = p),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LuxSpacing.lg,
              LuxSpacing.sm,
              LuxSpacing.lg,
              LuxSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LuxButton(
                  label: t.prefsTripApply,
                  onPressed: _valid
                      ? () => Navigator.of(context)
                          .pop((cleanForSend(_draft, _options), _options))
                      : null,
                ),
                LuxButton.ghost(
                  label: t.prefsTripSkip,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
