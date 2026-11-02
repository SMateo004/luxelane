import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../data/image_prep.dart';
import '../../data/photo_picker.dart';
import '../bloc/registration_cubit.dart';
import '../pages/document_capture_page.dart';

/// Lista de documentos pedidos (config/ops.driverRequirements) con su
/// estado, el motivo de rechazo y «Volver a subir».
class DocumentsStep extends StatelessWidget {
  const DocumentsStep({super.key, required this.state, required this.picker});
  final RegistrationState state;
  final PhotoPicker picker;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cubit = context.read<RegistrationCubit>();
    final a = state.app;
    return ListView(
      padding: const EdgeInsets.all(LuxSpacing.lg),
      children: [
        if (!uploadsSupported) ...[
          _Banner(text: t.regWebUploadBlocked, icon: Icons.phone_iphone),
          const SizedBox(height: LuxSpacing.md),
        ],
        if (!a.requirementsConfigured)
          _Banner(text: t.regDocsNotConfigured, icon: Icons.info_outline)
        else ...[
          Text(t.regDocsIntro, style: LuxTypography.bodyMedium),
          const SizedBox(height: LuxSpacing.md),
          for (final r in a.requirements)
            Padding(
              padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
              child: _DocumentRow(
                requirement: r,
                document: a.doc(r.type),
                uploading: state.uploading.contains(r.type),
                error: state.uploadErrors[r.type],
                editable:
                    a.status.editable || a.status == DriverAppStatus.approved,
                onUpload: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: DocumentCapturePage(
                      requirement: r,
                      picker: picker,
                    ),
                  ),
                )),
              ),
            ),
        ],
        const SizedBox(height: LuxSpacing.lg),
        LuxButton(label: t.regContinue, onPressed: cubit.next),
        const SizedBox(height: LuxSpacing.sm),
        LuxButton.ghost(label: t.regBack, onPressed: cubit.back),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(LuxSpacing.md),
        decoration: BoxDecoration(
          color: LuxColors.sapphireTint,
          borderRadius: BorderRadius.circular(LuxRadius.md),
        ),
        child: MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(icon, color: LuxColors.sapphire)),
              const SizedBox(width: LuxSpacing.sm),
              Expanded(child: Text(text, style: LuxTypography.bodyMedium)),
            ],
          ),
        ),
      );
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.requirement,
    required this.document,
    required this.uploading,
    required this.error,
    required this.editable,
    required this.onUpload,
  });

  final DriverRequirement requirement;
  final DriverDocument? document;
  final bool uploading;
  final String? error;
  final bool editable;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final d = document;
    final status = d?.status ?? DriverDocStatus.pendingUpload;
    final color = switch (status) {
      DriverDocStatus.approved => LuxColors.success,
      DriverDocStatus.rejected || DriverDocStatus.expired => LuxColors.error,
      _ => LuxColors.inkTertiary,
    };
    final again = status != DriverDocStatus.pendingUpload;
    return LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(requirement.type.label, style: LuxTypography.titleMedium),
                const SizedBox(height: LuxSpacing.xs),
                Wrap(
                  spacing: LuxSpacing.sm,
                  runSpacing: LuxSpacing.xs,
                  children: [
                    Text(
                      requirement.required
                          ? t.regDocRequired
                          : t.regDocOptional,
                      style: LuxTypography.caption,
                    ),
                    Text(status.label,
                        style: LuxTypography.caption.copyWith(color: color)),
                  ],
                ),
                if (d?.expiresAt != null)
                  Text(t.regDocExpires(LuxFormat.date(d!.expiresAt!)),
                      style: LuxTypography.caption),
                if (status == DriverDocStatus.rejected &&
                    d?.rejectReason != null) ...[
                  const SizedBox(height: LuxSpacing.xs),
                  Text(t.regDocRejectedReason(d!.rejectReason!.label),
                      style: LuxTypography.bodyMedium),
                  if (d.rejectNote != null)
                    Text(d.rejectNote!, style: LuxTypography.bodyMedium),
                ],
                if (error != null) ...[
                  const SizedBox(height: LuxSpacing.xs),
                  Text(error!,
                      style: LuxTypography.bodyMedium
                          .copyWith(color: LuxColors.error)),
                ],
              ],
            ),
          ),
          if (editable && uploadsSupported) ...[
            const SizedBox(height: LuxSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: uploading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: LuxSpacing.sm),
                          Text(t.regDocUploading),
                        ],
                      )
                    : TextButton.icon(
                        key: ValueKey('reg-doc-${requirement.type.wire}'),
                        onPressed: onUpload,
                        icon: Icon(again
                            ? Icons.refresh_rounded
                            : Icons.photo_camera_outlined),
                        label: Text(again ? t.regDocReupload : t.regDocUpload),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
