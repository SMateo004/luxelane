import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';

/// Texto que comparte el titular con su invitado.
String pickupShareText(String code) => L10n.current.rideCodeShareText(code);

/// Código de recogida mientras el chófer espera (driver_arrived). Se pide al
/// servidor cada vez que aparece y solo vive en esta pantalla: nunca se
/// guarda en el dispositivo.
class PickupCodeCard extends StatefulWidget {
  const PickupCodeCard({
    super.key,
    required this.bookingId,
    this.guestName,
    this.repository,
    this.onShare,
  });

  final String bookingId;

  /// Nombre del invitado si la reserva es para otra persona: entonces se
  /// ofrece compartir el código con él.
  final String? guestName;
  final TripFlowRepository? repository;

  /// Menú de compartir del sistema (sustituible en tests).
  final Future<void> Function(String text)? onShare;

  @override
  State<PickupCodeCard> createState() => _PickupCodeCardState();
}

class _PickupCodeCardState extends State<PickupCodeCard> {
  PickupCode? _code;
  TripFailure? _error;
  bool _loading = true;

  TripFlowRepository get _repo => widget.repository ?? sl<TripFlowRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.getPickupCode(widget.bookingId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        (f) => _error =
            f is TripFailure ? f : TripFailure(TripIssue.other, f.message),
        (c) => _code = c,
      );
    });
  }

  Future<void> _share() async {
    final code = _code;
    if (code == null) return;
    final share = widget.onShare ?? (text) => Share.share(text);
    await share(pickupShareText(code.code));
  }

  @override
  Widget build(BuildContext context) {
    final duration = LuxMotion.of(context, LuxMotion.base);
    return LuxFadeIn(
      child: LuxCard(
        child: AnimatedSwitcher(
          duration: duration,
          switchInCurve: LuxMotion.decelerate,
          switchOutCurve: LuxMotion.accelerate,
          child: _loading
              ? const _Loading(key: ValueKey('loading'))
              : _error != null
                  ? _ErrorBody(
                      key: ValueKey(_error!.issue),
                      failure: _error!,
                      onRetry: _error!.issue == TripIssue.network ||
                              _error!.issue == TripIssue.other
                          ? _load
                          : null,
                    )
                  : _CodeBody(
                      key: const ValueKey('code'),
                      code: _code!.code,
                      guestName: widget.guestName,
                      onShare: widget.guestName == null ? null : _share,
                    ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: context.l10n.rideCodeLoading,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LuxSkeletonBox(width: 160, height: 14),
            SizedBox(height: LuxSpacing.md),
            LuxSkeletonBox(width: 200, height: 44),
          ],
        ),
      );
}

class _CodeBody extends StatelessWidget {
  const _CodeBody({
    super.key,
    required this.code,
    this.guestName,
    this.onShare,
  });

  final String code;
  final String? guestName;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.rideCodeTitle,
            style: LuxTypography.caption.copyWith(
              letterSpacing: 1.4,
              color: LuxColors.inkSecondary,
            ),
          ),
          const SizedBox(height: LuxSpacing.sm),
          Semantics(
            label: context.l10n.rideCodeSemantics(code.split('').join(' ')),
            excludeSemantics: true,
            child: Wrap(
              spacing: LuxSpacing.sm,
              runSpacing: LuxSpacing.sm,
              children: [for (final digit in code.split('')) _Digit(digit)],
            ),
          ),
          const SizedBox(height: LuxSpacing.sm),
          Text(
            guestName == null
                ? context.l10n.rideCodeHint
                : context.l10n.rideCodeGuestHint(guestName!),
            style:
                LuxTypography.caption.copyWith(color: LuxColors.inkSecondary),
          ),
          if (onShare != null) ...[
            const SizedBox(height: LuxSpacing.md),
            LuxOutlinedButton(
              label: context.l10n.rideCodeShare,
              icon: Icons.ios_share_rounded,
              height: 46,
              onPressed: onShare,
            ),
          ],
        ],
      );
}

class _Digit extends StatelessWidget {
  const _Digit(this.digit);
  final String digit;

  @override
  Widget build(BuildContext context) => Container(
        // Tamaño mínimo y no fijo: con la letra al 200 % los dígitos se
        // recortaban (E8).
        constraints: const BoxConstraints(minWidth: 48, minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: LuxColors.sapphireTint,
          borderRadius: BorderRadius.circular(LuxRadius.sm),
        ),
        // Centrado sin ocupar todo el ancho del Wrap.
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            digit,
            style: LuxTypography.headlineLarge.copyWith(
              color: LuxColors.sapphire,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({super.key, required this.failure, this.onRetry});

  final TripFailure failure;
  final VoidCallback? onRetry;

  IconData get _icon => switch (failure.issue) {
        TripIssue.network => Icons.wifi_off_rounded,
        TripIssue.locked => Icons.lock_outline_rounded,
        TripIssue.expired => Icons.schedule_rounded,
        _ => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon, size: 20, color: LuxColors.inkSecondary),
              const SizedBox(width: LuxSpacing.sm),
              Expanded(
                child: Text(failure.message, style: LuxTypography.bodyMedium),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: LuxSpacing.md),
            LuxOutlinedButton(
              label: context.l10n.rideRetry,
              icon: Icons.refresh_rounded,
              height: 46,
              onPressed: onRetry,
            ),
          ],
        ],
      );
}
