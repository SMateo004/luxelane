import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/config/remote_flags.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/app_update_dialog.dart';
import '../../../../core/widgets/components.dart';
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
        BookingStatus.confirmed => 'Salir hacia la recogida',
        BookingStatus.driverArriving => 'He llegado',
        BookingStatus.verified => 'Iniciar viaje',
        BookingStatus.inProgress => 'Completar viaje',
        _ => null,
      };

  /// Texto del estado para el chófer.
  static String message(Booking b) => switch (b.status) {
        BookingStatus.confirmed => 'Dirígete a la recogida.',
        BookingStatus.driverArriving => 'En camino a la recogida.',
        BookingStatus.driverArrived => b.pickupLocked
            ? 'Verificación bloqueada. Contacta con central.'
            : 'Pide al pasajero su código de recogida.',
        BookingStatus.verified => 'Pasajero verificado. Desliza para iniciar.',
        BookingStatus.inProgress => 'Viaje en curso · rumbo al destino.',
        BookingStatus.noShow =>
          'Avisaste que el pasajero no apareció. Central lo revisa.',
        _ => 'Viaje activo.',
      };

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
              const Text(
                'Cinco códigos incorrectos: central debe verificar este '
                'viaje.',
                style: LuxTypography.bodyMedium,
              ),
              const SizedBox(height: LuxSpacing.sm),
              CallDispatchButton(phone: phone),
            ],
          ),
        );
      }
      final codeButton = LuxButton(
        label: 'Ingresar código del pasajero',
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
          label: const Text('No puedo hacer este viaje'),
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

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Liberar este viaje'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'El viaje vuelve a buscar chófer y central recibe un aviso. '
                'Queda registrado en tu historial.',
              ),
              const SizedBox(height: LuxSpacing.sm),
              for (final e in kDriverReleaseReasons.entries)
                RadioListTile<String>(
                  value: e.key,
                  groupValue: _reason,
                  onChanged: (v) => setState(() => _reason = v),
                  title: Text(e.value),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: _reason == null
                ? null
                : () => Navigator.of(context).pop(_reason),
            child: const Text('Liberar viaje'),
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

  String get _time {
    final t = widget.availableAt.toLocal();
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirm() async {
    final bloc = context.read<DriverBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿El pasajero no aparece?'),
        content: const Text(
          'Central recibirá un aviso con tu ubicación y revisará la reserva. '
          'Quedarás libre para otros viajes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Seguir esperando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Avisar a central'),
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
          label: const Text('El pasajero no aparece'),
        ),
        if (!ready)
          Padding(
            padding: const EdgeInsets.only(top: LuxSpacing.xs),
            child: Semantics(
              liveRegion: true,
              child: Text(
                'Disponible a partir de las $_time.',
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
