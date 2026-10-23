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
  });

  final Booking booking;

  /// Tras deslizar «Completar viaje» (p. ej. volver al inicio).
  final VoidCallback? onCompleted;
  final Future<void> Function(BuildContext, Booking) openCodeEntry;

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
                  style: LuxTypography.bodyMedium),
              const SizedBox(height: LuxSpacing.sm),
              CallDispatchButton(phone: phone),
            ],
          ),
        );
      }
      return LuxButton(
        label: 'Ingresar código del pasajero',
        icon: Icons.pin_outlined,
        onPressed: () => openCodeEntry(context, booking),
      );
    }
    final label = slideLabel(booking.status);
    if (label == null) return const SizedBox.shrink();
    // Deslizar evita completar un paso con un toque accidental.
    return LuxSlideToConfirm(
      key: ValueKey('slide-${booking.status.label}'),
      label: label,
      onConfirmed: () => _advance(context),
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
