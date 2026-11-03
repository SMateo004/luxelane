import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/photo_picker.dart';
import '../bloc/registration_cubit.dart';
import '../widgets/documents_step.dart';
import '../widgets/registration_steps.dart';

/// Registro por pasos (B1): datos, vehículo, documentos, segundo factor (con
/// mfaEnforced) y resumen. Reanudable: al volver se abre el primer paso
/// pendiente. Enviada, muestra «En revisión» sin plazos.
class DriverRegistrationPage extends StatelessWidget {
  const DriverRegistrationPage({
    super.key,
    required this.picker,
    this.onEnrollMfa,
  });

  final PhotoPicker picker;

  /// Abre el alta del TOTP (la pantalla de siempre de Perfil).
  final Future<void> Function(BuildContext context)? onEnrollMfa;

  static String stepTitle(RegistrationStep s) {
    final t = L10n.current;
    return switch (s) {
      RegistrationStep.personal => t.regStepPersonal,
      RegistrationStep.vehicle => t.regStepVehicle,
      RegistrationStep.documents => t.regStepDocuments,
      RegistrationStep.security => t.regStepSecurity,
      RegistrationStep.summary => t.regStepSummary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return BlocConsumer<RegistrationCubit, RegistrationState>(
      listenWhen: (a, b) => a.messageSeq != b.messageSeq && b.message != null,
      listener: (context, s) => showLuxSnackbar(context, s.message!),
      builder: (context, s) {
        final cubit = context.read<RegistrationCubit>();
        Widget body;
        if (s.loading && s.view == null) {
          body = const Center(child: CircularProgressIndicator());
        } else if (s.view == null) {
          body = _Message(
            icon: Icons.cloud_off_rounded,
            title: s.loadError ?? t.regErrorGeneric,
            action: t.regRetry,
            onAction: cubit.load,
          );
        } else if (s.app.status == DriverAppStatus.rejected) {
          body = _Message(
            icon: Icons.block_rounded,
            title: t.regStatusRejectedTitle,
            body: t.regStatusRejectedBody,
          );
        } else if (s.waitingReview) {
          body = _Message(
            icon: Icons.hourglass_top_rounded,
            title: t.regStatusReviewTitle,
            body: t.regStatusReviewBody,
            action: t.regRefresh,
            onAction: cubit.load,
          );
        } else {
          body = _Steps(state: s, picker: picker, onEnrollMfa: onEnrollMfa);
        }
        return Scaffold(
          backgroundColor: LuxColors.bg,
          appBar: AppBar(
            title: Text(t.regTitle),
            actions: [
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const LogoutRequested()),
                child: Text(t.regSignOut),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: body,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.state, required this.picker, this.onEnrollMfa});
  final RegistrationState state;
  final PhotoPicker picker;
  final Future<void> Function(BuildContext context)? onEnrollMfa;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final s = state;
    final steps = s.steps;
    final index = steps.indexOf(s.page) + 1;
    final reduce = MediaQuery.of(context).disableAnimations;
    final step = switch (s.page) {
      RegistrationStep.personal => PersonalStep(state: s),
      RegistrationStep.vehicle => VehicleStep(state: s),
      RegistrationStep.documents => DocumentsStep(state: s, picker: picker),
      RegistrationStep.security =>
        SecurityStep(state: s, onEnrollMfa: onEnrollMfa),
      RegistrationStep.summary => SummaryStep(state: s),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              LuxSpacing.lg, LuxSpacing.md, LuxSpacing.lg, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: t.regProgressLabel(index, steps.length),
                excludeSemantics: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(LuxRadius.sm),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: index / steps.length),
                    duration: reduce
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: LuxColors.surfaceDeep,
                      color: LuxColors.sapphire,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: LuxSpacing.sm),
              Semantics(
                header: true,
                child: Text(
                  t.regStepOf(
                    index,
                    steps.length,
                    DriverRegistrationPage.stepTitle(s.page),
                  ),
                  style: LuxTypography.titleLarge,
                ),
              ),
              if (s.app.status == DriverAppStatus.needsChanges) ...[
                const SizedBox(height: LuxSpacing.sm),
                _Notice(text: t.regStatusNeedsChanges),
              ],
            ],
          ),
        ),
        Expanded(child: step),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(LuxSpacing.md),
        decoration: BoxDecoration(
          color: LuxColors.sapphireTint,
          borderRadius: BorderRadius.circular(LuxRadius.md),
        ),
        child: Text(text, style: LuxTypography.bodyMedium),
      );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(LuxSpacing.lg),
        children: [
          const SizedBox(height: LuxSpacing.xl),
          ExcludeSemantics(
            child: Icon(icon, size: 48, color: LuxColors.sapphire),
          ),
          const SizedBox(height: LuxSpacing.md),
          Semantics(
            header: true,
            child: Text(title,
                textAlign: TextAlign.center,
                style: LuxTypography.headlineMedium),
          ),
          if (body != null) ...[
            const SizedBox(height: LuxSpacing.sm),
            Text(body!,
                textAlign: TextAlign.center, style: LuxTypography.bodyLarge),
          ],
          if (action != null) ...[
            const SizedBox(height: LuxSpacing.lg),
            LuxOutlinedButton(label: action!, onPressed: onAction),
          ],
        ],
      );
}
