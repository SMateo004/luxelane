import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/trip_preferences_editor.dart';

/// Preferencias para el chófer del perfil del pasajero. Se guardan con
/// ProfilePreferencesSaved (updatePreferences); la pantalla muestra la
/// confirmación o el motivo del error que da el bloc.
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key, this.repository});

  /// Para las opciones (getPreferenceOptions). Por defecto, el del
  /// contenedor de dependencias.
  final PreferencesRepository? repository;

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late TripPreferences _draft = _saved;
  PreferenceOptions _options = PreferenceOptions.none;
  bool _saving = false;

  TripPreferences get _saved {
    final s = context.read<ProfileBloc>().state;
    return s is ProfileLoaded ? s.user.tripPreferences : TripPreferences.empty;
  }

  @override
  void initState() {
    super.initState();
    final repo = widget.repository ??
        (sl.isRegistered<PreferencesRepository>()
            ? sl<PreferencesRepository>()
            : null);
    repo?.options().then((o) {
      if (mounted) setState(() => _options = o);
    });
  }

  bool get _canSave =>
      !_saving &&
      context.read<ProfileBloc>().state is ProfileLoaded &&
      playlistLooksValid(
          _options.playlistEnabled ? _draft.playlistUrl : null) &&
      cleanForSend(_draft, _options) != cleanForSend(_saved, _options);

  void _save() {
    setState(() => _saving = true);
    context
        .read<ProfileBloc>()
        .add(ProfilePreferencesSaved(cleanForSend(_draft, _options)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final duration = LuxMotion.of(context, LuxMotion.base);
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (prev, next) =>
          next is ProfileLoaded &&
          next.message != null &&
          (prev is! ProfileLoaded || prev.messageSeq != next.messageSeq),
      listener: (context, state) {
        final s = state as ProfileLoaded;
        if (!_saving) return;
        setState(() {
          _saving = false;
          // Lo que guardó el servidor (saneado); si falló, sigue lo escrito.
          if (!s.isError) _draft = s.user.tripPreferences;
        });
        showLuxSnackbar(context, s.message!, isError: s.isError);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(t.prefsScreenTitle)),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    LuxSpacing.md,
                    LuxSpacing.md,
                    LuxSpacing.md,
                    LuxSpacing.lg,
                  ),
                  children: [
                    AnimatedSize(
                      duration: duration,
                      curve: LuxMotion.emphasized,
                      alignment: Alignment.topCenter,
                      child: _draft.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(
                                bottom: LuxSpacing.lg,
                              ),
                              child: Text(
                                t.prefsEmpty,
                                style: LuxTypography.bodyMedium.copyWith(
                                  color: LuxColors.inkSecondary,
                                ),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    TripPreferencesEditor(
                      value: _draft,
                      options: _options,
                      onChanged: (p) => setState(() => _draft = p),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LuxSpacing.md,
                  LuxSpacing.sm,
                  LuxSpacing.md,
                  LuxSpacing.md,
                ),
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, _) => LuxButton(
                    label: t.prefsSave,
                    loading: _saving,
                    onPressed: _canSave ? _save : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
