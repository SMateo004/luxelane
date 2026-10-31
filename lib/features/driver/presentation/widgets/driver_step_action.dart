import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/config/remote_flags.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/app_update_dialog.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../bloc/driver_bloc.dart';
import 'pickup_code_entry.dart';

/// Lo que el chófer ve como siguiente paso. Cada paso lo valida el servidor
/// (advanceBooking); «Iniciar viaje» solo existe con la reserva verificada.
class DriverStepAction extends StatelessWidget {
  const DriverStepAction({
    super.key,
    required this.booking,
    this.onCompleted,
    this.openCodeEntry = showPickupCodeEntry,
    this.clock = DateTime.now,
  });

  final Booking booking;

  /// Tras deslizar «Completar viaje» (p. ej. volver al inicio).
  final VoidCallback? onCompleted;
  final Future<void> Function(BuildContext, Booking) openCodeEntry;

  /// Hora actual (inyectable en los tests del «no aparece»).
  final DateTime Function() clock;

  static String? slideLabel(BookingStatus s) => switch (s) {
        BookingStatus.confirmed => L10n.current.driverSlideDepart,
        BookingStatus.driverArriving => L10n.current.driverSlideArrived,
        BookingStatus.verified => L10n.current.driverSlideStart,
        BookingStatus.inProgress => L10n.current.driverSlideComplete,
        _ => null,
      };

  /// Texto del estado para el chófer.
  static String message(Booking b) {
    final t = L10n.current;
    return switch (b.status) {
      BookingStatus.confirmed => t.driverStepConfirmed,
      BookingStatus.driverArriving => t.driverStepArriving,
      BookingStatus.driverArrived =>
        b.pickupLocked ? t.driverStepLocked : t.driverStepAskCode,
      BookingStatus.verified => t.driverStepVerified,
      BookingStatus.inProgress => t.driverStepInProgress,
      BookingStatus.noShow => t.driverStepNoShow,
      _ => t.driverStepActive,
    };
  }

  void _advance(BuildContext context) {
    final bloc = context.read<DriverBloc>();
    switch (booking.status) {
      case BookingStatus.confirmed:
        bloc.add(DriverBookingAccepted(bookingId: booking.id));
      case BookingStatus.driverArriving:
        bloc.add(DriverArrivedAtPickup(bookingId: booking.id));
      case BookingStatus.verified:
        bloc.add(DriverTripStarted(bookingId: booking.id));
      case BookingStatus.inProgress:
        bloc.add(DriverTripCompleted(bookingId: booking.id));
        onCompleted?.call();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (booking.status == BookingStatus.driverArrived) {
      if (booking.pickupLocked) {
        return ValueListenableBuilder<String?>(
          valueListenable: RemoteFlags.instance.dispatchPhone,
          builder: (_, phone, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.driverLockedFiveCodes,
                style: LuxTypography.bodyMedium,
              ),
              const SizedBox(height: LuxSpacing.sm),
              CallDispatchButton(phone: phone),
            ],
          ),
        );
      }
      final codeButton = LuxButton(
        label: context.l10n.driverEnterCode,
        icon: Icons.pin_outlined,
        onPressed: () => openCodeEntry(context, booking),
      );
      // Sin política de cancelación no hay «no aparece» (B4).
      final availableAt = booking.noShowAvailableAt;
      if (availableAt == null) return codeButton;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          codeButton,
          const SizedBox(height: LuxSpacing.sm),
          NoShowAction(
              booking: booking, availableAt: availableAt, clock: clock),
        ],
      );
    }
    final label = slideLabel(booking.status);
    if (label == null) return const SizedBox.shrink();
    // Deslizar evita completar un paso con un toque accidental.
    // Cada aviso del bloc (también «sin conexión: no se guardó el paso»)
    // reinicia el control; si el paso se aplicó, cambia la etiqueta.
    final noticeSeq = context.select<DriverBloc, int>(
      (b) => b.state is DriverLoaded ? (b.state as DriverLoaded).noticeSeq : 0,
    );
    final slide = LuxSlideToConfirm(
      key: ValueKey('slide-${booking.status.label}'),
      label: label,
      resetToken: noticeSeq,
      onConfirmed: () => _advance(context),
    );
    if (booking.status != BookingStatus.confirmed &&
        booking.status != BookingStatus.driverArriving) {
      return slide;
    }
    // Antes de llegar, el chófer puede devolver el viaje (B5).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        slide,
        const SizedBox(height: LuxSpacing.xs),
        TextButton.icon(
          key: const Key('release-booking'),
          onPressed: () => _release(context),
          icon: const Icon(Icons.undo_outlined, size: 18),
          label: Text(context.l10n.driverCannotDoTrip),
        ),
      ],
    );
  }

  Future<void> _release(BuildContext context) async {
    final bloc = context.read<DriverBloc>();
    final reason = await showReleaseBookingDialog(context);
    if (reason == null) return;
    bloc.add(DriverBookingReleased(bookingId: booking.id, reason: reason));
  }
}

/// Motivo para liberar el viaje (lista cerrada). null si se arrepiente.
Future<String?> showReleaseBookingDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const _ReleaseDialog(),
    );

class _ReleaseDialog extends StatefulWidget {
  const _ReleaseDialog();

  @override
  State<_ReleaseDialog> createState() => _ReleaseDialogState();
}

class _ReleaseDialogState extends State<_ReleaseDialog> {
  String? _reason;

  /// Motivos de [kDriverReleaseReasons] en el idioma activo (la clave es la
  /// que se envía al servidor).
  static String? _reasonLabel(AppLocalizations t, String key) => switch (key) {
        'vehicle_issue' => t.driverReleaseReasonVehicleIssue,
        'personal_emergency' => t.driverReleaseReasonPersonalEmergency,
        'unsafe_conditions' => t.driverReleaseReasonUnsafeConditions,
        'schedule_conflict' => t.driverReleaseReasonScheduleConflict,
        'other' => t.driverReleaseReasonOther,
        _ => null,
      };

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(context.l10n.driverReleaseTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.driverReleaseBody),
              const SizedBox(height: LuxSpacing.sm),
              for (final e in kDriverReleaseReasons.entries)
                RadioListTile<String>(
                  value: e.key,
                  groupValue: _reason,
                  onChanged: (v) => setState(() => _reason = v),
                  title: Text(_reasonLabel(context.l10n, e.key) ?? e.value),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.driverBack),
          ),
          FilledButton(
            onPressed: _reason == null
                ? null
                : () => Navigator.of(context).pop(_reason),
            child: Text(context.l10n.driverReleaseConfirm),
          ),
        ],
      );
}

/// «El pasajero no aparece»: visible solo con política (noShowAvailableAt)
/// y activo pasado el tiempo de espera. Antes dice desde qué hora.
class NoShowAction extends StatefulWidget {
  const NoShowAction({
    super.key,
    required this.booking,
    required this.availableAt,
    this.clock = DateTime.now,
  });

  final Booking booking;
  final DateTime availableAt;
  final DateTime Function() clock;

  @override
  State<NoShowAction> createState() => _NoShowActionState();
}

class _NoShowActionState extends State<NoShowAction> {
  Timer? _timer;

  bool get _ready => !widget.clock().isBefore(widget.availableAt);

  @override
  void initState() {
    super.initState();
    // Sin animación: solo se vuelve a pintar cuando llega la hora.
    if (!_ready) {
      _timer = Timer.periodic(const Duration(seconds: 15), (t) {
        if (_ready) t.cancel();
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _time => LuxFormat.time(widget.availableAt.toLocal());

  Future<void> _confirm() async {
    final bloc = context.read<DriverBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.driverNoShowTitle),
        content: Text(ctx.l10n.driverNoShowBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.driverNoShowKeepWaiting),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.l10n.driverNoShowNotify),
          ),
        ],
      ),
    );
    if (ok == true) bloc.add(DriverRiderNoShow(bookingId: widget.booking.id));
  }

  @override
  Widget build(BuildContext context) {
    final ready = _ready;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const Key('no-show'),
          onPressed: ready ? _confirm : null,
          icon: const Icon(Icons.person_off_outlined),
          label: Text(context.l10n.driverNoShowButton),
        ),
        if (!ready)
          Padding(
            padding: const EdgeInsets.only(top: LuxSpacing.xs),
            child: Semantics(
              liveRegion: true,
              child: Text(
                context.l10n.driverNoShowAvailableAt(_time),
                textAlign: TextAlign.center,
                style: LuxTypography.caption.copyWith(
                  color: LuxColors.inkSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Avisos del DriverBloc en cualquier pantalla del chófer: mensajes y la
/// petición de actualizar la app (minDriverAppVersion).
class DriverFeedbackListener extends StatelessWidget {
  const DriverFeedbackListener({
    super.key,
    required this.child,
    this.showNotices = true,
  });

  final Widget child;

  /// La pantalla de inicio ya muestra los avisos por su cuenta.
  final bool showNotices;

  static int _seq(DriverState s, int Function(DriverLoaded) f) =>
      s is DriverLoaded ? f(s) : 0;

  @override
  Widget build(BuildContext context) => MultiBlocListener(
        listeners: [
          BlocListener<DriverBloc, DriverState>(
            listenWhen: (prev, curr) =>
                curr is DriverLoaded &&
                _seq(curr, (s) => s.updateSeq) !=
                    _seq(prev, (s) => s.updateSeq),
            listener: (context, state) {
              final update = (state as DriverLoaded).updateRequired;
              if (update != null) AppUpdateDialog.show(context, update);
            },
          ),
          if (showNotices)
            BlocListener<DriverBloc, DriverState>(
              listenWhen: (prev, curr) =>
                  curr is DriverLoaded &&
                  _seq(curr, (s) => s.noticeSeq) !=
                      _seq(prev, (s) => s.noticeSeq),
              listener: (context, state) {
                final notice = (state as DriverLoaded).notice;
                if (notice != null) showLuxSnackbar(context, notice);
              },
            ),
        ],
        child: child,
      );
}
