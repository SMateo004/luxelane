import '../../../app/theme/lux_motion.dart';
import '../../../core/enums/enums.dart';

/// Momentos del viaje que el pasajero debe notar (E31): antes la llegada no
/// vibraba, el código verificado solo hacía desaparecer la tarjeta y el fin
/// del viaje no tenía ningún momento de éxito.
enum RideMoment { arrived, verified, completed }

/// El momento que toca al pasar de [previous] a [next]. Al abrir la
/// pantalla (sin estado anterior) no se celebra nada.
RideMoment? rideMomentFor(BookingStatus? previous, BookingStatus next) {
  if (previous == null || previous == next) return null;
  return switch (next) {
    BookingStatus.driverArrived => RideMoment.arrived,
    BookingStatus.verified => RideMoment.verified,
    BookingStatus.completed => RideMoment.completed,
    _ => null,
  };
}

/// Háptica del momento (en web no hace nada).
void playRideMoment(RideMoment m) => switch (m) {
      RideMoment.arrived => LuxHaptics.confirm(),
      RideMoment.verified || RideMoment.completed => LuxHaptics.success(),
    };
