import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/driver_registration_repository.dart';

/// Antes de startDriverApplication (A10): la cuenta pasa a ser de chófer,
/// no vuelve a ser de pasajero, y quien ya tiene reservas usa otro correo.
class DriverApplicationIntroPage extends StatefulWidget {
  const DriverApplicationIntroPage({
    super.key,
    required this.repository,
    required this.onStarted,
  });

  final DriverRegistrationRepository repository;

  /// Tras abrir la solicitud (con el token ya renovado).
  final VoidCallback onStarted;

  @override
  State<DriverApplicationIntroPage> createState() =>
      _DriverApplicationIntroPageState();
}

class _DriverApplicationIntroPageState
    extends State<DriverApplicationIntroPage> {
  bool _busy = false;

  Future<void> _start() async {
    final t = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.regIntroConfirmTitle),
        content: Text(t.regIntroConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(t.regCancel),
          ),
          TextButton(
            key: const ValueKey('reg-intro-confirm'),
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(t.regIntroConfirmYes),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final r = await widget.repository.startApplication();
    if (!mounted) return;
    setState(() => _busy = false);
    r.fold(
      (f) => showLuxSnackbar(context, f.message, isError: true),
      (_) => widget.onStarted(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    Widget point(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: LuxSpacing.md),
          child: MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(icon, color: LuxColors.sapphire, size: 22),
                ),
                const SizedBox(width: LuxSpacing.md),
                Expanded(child: Text(text, style: LuxTypography.bodyLarge)),
              ],
            ),
          ),
        );
    return Scaffold(
      backgroundColor: LuxColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(LuxSpacing.lg),
              children: [
                Semantics(
                  header: true,
                  child:
                      Text(t.regIntroTitle, style: LuxTypography.headlineLarge),
                ),
                const SizedBox(height: LuxSpacing.md),
                Text(t.regIntroBody, style: LuxTypography.bodyLarge),
                const SizedBox(height: LuxSpacing.lg),
                point(Icons.swap_horiz_rounded, t.regIntroPointOneWay),
                point(Icons.alternate_email_rounded, t.regIntroPointBookings),
                point(Icons.fact_check_outlined, t.regIntroPointReview),
                const SizedBox(height: LuxSpacing.lg),
                LuxButton(
                  key: const ValueKey('reg-intro-start'),
                  label: t.regIntroStart,
                  loading: _busy,
                  onPressed: _busy ? null : _start,
                ),
                const SizedBox(height: LuxSpacing.sm),
                LuxButton.ghost(
                  label: t.regSignOut,
                  onPressed: _busy
                      ? null
                      : () =>
                          context.read<AuthBloc>().add(const LogoutRequested()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
