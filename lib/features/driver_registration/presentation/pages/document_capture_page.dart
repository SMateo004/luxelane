import 'dart:typed_data';

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

/// Qué fotografiar y con qué forma (la cámara del sistema se abre a
/// pantalla completa: la guía se ve antes y en la revisión).
({String help, double aspect}) captureGuide(DriverDocType t) {
  final l = L10n.current;
  if (t == DriverDocType.livePhoto) return (help: l.regHelpLive, aspect: 0.8);
  if (t == DriverDocType.profilePhoto) {
    return (help: l.regHelpProfile, aspect: 0.8);
  }
  if (t == DriverDocType.vehiclePhotoPlate) {
    return (help: l.regHelpPlate, aspect: 2.5);
  }
  if (t == DriverDocType.vehiclePhotoInteriorFront ||
      t == DriverDocType.vehiclePhotoInteriorBack) {
    return (help: l.regHelpInterior, aspect: 1.5);
  }
  if (t.vehiclePhoto) return (help: l.regHelpVehicle, aspect: 1.5);
  if (t.pdf) return (help: l.regHelpPaper, aspect: 0.707);
  // Tarjetas: documento de identidad y licencia (formato ID-1).
  return (help: l.regHelpIdDocument, aspect: 1.586);
}

class DocumentCapturePage extends StatefulWidget {
  const DocumentCapturePage({
    super.key,
    required this.requirement,
    required this.picker,
  });

  final DriverRequirement requirement;
  final PhotoPicker picker;

  @override
  State<DocumentCapturePage> createState() => _DocumentCapturePageState();
}

class _DocumentCapturePageState extends State<DocumentCapturePage> {
  Uint8List? _photo;
  DateTime? _expiry;
  bool _expiryMissing = false;

  DriverDocType get _type => widget.requirement.type;

  Future<void> _pick(PhotoSource source) async {
    final t = context.l10n;
    final r = await widget.picker.pick(source, frontCamera: _type.frontCamera);
    if (!mounted) return;
    switch (r) {
      case Picked(:final bytes):
        setState(() => _photo = bytes);
      case PickCancelled():
        showLuxSnackbar(context, t.regPhotoCancelled);
      case PickUnavailable():
        showLuxSnackbar(context, t.regCameraUnavailable, isError: true);
    }
  }

  Future<void> _use() async {
    final needsExpiry = widget.requirement.expires;
    if (needsExpiry && _expiry == null) {
      setState(() => _expiryMissing = true);
      return;
    }
    final ok = await context
        .read<RegistrationCubit>()
        .uploadPhoto(_type, _photo!, expiresAt: _expiry);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final guide = captureGuide(_type);
    return BlocBuilder<RegistrationCubit, RegistrationState>(
      builder: (context, s) {
        final busy = s.uploading.contains(_type);
        final error = s.uploadErrors[_type];
        return Scaffold(
          backgroundColor: LuxColors.bg,
          appBar: AppBar(title: Text(_type.label)),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(LuxSpacing.lg),
                  children: [
                    if (!uploadsSupported)
                      Text(t.regWebUploadBlocked,
                          style: LuxTypography.bodyLarge)
                    else if (_photo == null) ...[
                      Text(guide.help, style: LuxTypography.bodyLarge),
                      const SizedBox(height: LuxSpacing.md),
                      _FrameGuide(aspect: guide.aspect),
                      const SizedBox(height: LuxSpacing.sm),
                      Text(t.regFrameHint, style: LuxTypography.caption),
                      const SizedBox(height: LuxSpacing.lg),
                      LuxButton(
                        key: const ValueKey('reg-take-photo'),
                        label: t.regTakePhoto,
                        icon: Icons.photo_camera_outlined,
                        onPressed: () => _pick(PhotoSource.camera),
                      ),
                      const SizedBox(height: LuxSpacing.sm),
                      if (_type.cameraOnly)
                        Text(t.regLiveCameraOnly, style: LuxTypography.caption)
                      else
                        LuxOutlinedButton(
                          key: const ValueKey('reg-from-gallery'),
                          label: t.regFromGallery,
                          icon: Icons.photo_library_outlined,
                          onPressed: () => _pick(PhotoSource.gallery),
                        ),
                    ] else ...[
                      Semantics(
                        header: true,
                        child: Text(t.regReviewTitle,
                            style: LuxTypography.titleLarge),
                      ),
                      const SizedBox(height: LuxSpacing.xs),
                      Text(t.regReviewHint, style: LuxTypography.bodyMedium),
                      const SizedBox(height: LuxSpacing.md),
                      Semantics(
                        image: true,
                        label: t.regPhotoPreviewLabel,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(LuxRadius.md),
                          child: Image.memory(
                            _photo!,
                            fit: BoxFit.contain,
                            height: 320,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) => SizedBox(
                              height: 120,
                              child: Center(child: Text(t.regPhotoUnreadable)),
                            ),
                          ),
                        ),
                      ),
                      if (widget.requirement.expires) ...[
                        const SizedBox(height: LuxSpacing.md),
                        _ExpiryField(
                          value: _expiry,
                          missing: _expiryMissing,
                          onPicked: (d) => setState(() {
                            _expiry = d;
                            _expiryMissing = false;
                          }),
                        ),
                      ],
                      if (error != null) ...[
                        const SizedBox(height: LuxSpacing.sm),
                        Text(error,
                            style: LuxTypography.bodyMedium
                                .copyWith(color: LuxColors.error)),
                      ],
                      const SizedBox(height: LuxSpacing.lg),
                      LuxButton(
                        key: const ValueKey('reg-use-photo'),
                        label: t.regUsePhoto,
                        loading: busy,
                        onPressed: busy ? null : _use,
                      ),
                      const SizedBox(height: LuxSpacing.sm),
                      LuxOutlinedButton(
                        label: t.regRetake,
                        onPressed:
                            busy ? null : () => setState(() => _photo = null),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FrameGuide extends StatelessWidget {
  const _FrameGuide({required this.aspect});
  final double aspect;

  @override
  Widget build(BuildContext context) => Semantics(
        label: context.l10n.regFrameLabel,
        excludeSemantics: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: AspectRatio(
              aspectRatio: aspect,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: LuxColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(LuxRadius.md),
                  border: Border.all(color: LuxColors.sapphire, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.center_focus_strong_outlined,
                      size: 40, color: LuxColors.sapphire),
                ),
              ),
            ),
          ),
        ),
      );
}

class _ExpiryField extends StatelessWidget {
  const _ExpiryField({
    required this.value,
    required this.missing,
    required this.onPicked,
  });

  final DateTime? value;
  final bool missing;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final now = DateTime.now();
    final shown = value == null ? t.regPickDate : LuxFormat.date(value!);
    return Semantics(
      button: true,
      label: '${t.regExpiryNeeded}: $shown',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('reg-expiry'),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value ?? now.add(const Duration(days: 365)),
            firstDate: now.add(const Duration(days: 1)),
            lastDate: DateTime(now.year + 30),
          );
          if (d != null) onPicked(d);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: t.regExpiryNeeded,
              errorText: missing ? t.regExpiryRequired : null,
              suffixIcon: const Icon(Icons.event_outlined),
            ),
            child: Text(shown, style: LuxTypography.bodyLarge),
          ),
        ),
      ),
    );
  }
}
