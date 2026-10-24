import '../enums/enums.dart';
import '../models/models.dart';

/// Lo que la app sabe del pasajero a partir de sus viajes, para que cada
/// pantalla se sienta hecha a su medida: sus lugares, su clase de vehículo
/// y su próximo trayecto. Todo se calcula en el dispositivo.
class RiderInsights {
  const RiderInsights({
    this.recentPlaces = const [],
    this.favoriteClass,
    this.nextTrip,
    this.lastTrip,
    this.completedTrips = 0,
  });

  static const empty = RiderInsights();

  /// Lugares a los que suele ir (o de los que suele salir), sin repetir,
  /// los más recientes primero.
  final List<Place> recentPlaces;

  /// Clase que más reserva (desde 2 viajes; antes no es una costumbre).
  final VehicleClass? favoriteClass;

  /// Próximo viaje reservado que aún no terminó.
  final Booking? nextTrip;

  /// Último viaje completado, para repetirlo con un toque.
  final Booking? lastTrip;
  final int completedTrips;

  factory RiderInsights.from(List<Booking> bookings, {DateTime? now}) {
    final t = now ?? DateTime.now();
    if (bookings.isEmpty) return empty;

    final byRecent = [...bookings]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Lugares: destinos primero (a dónde va), luego recogidas.
    final places = <Place>[];
    final seen = <String>{};
    void add(Place p) {
      if (p.lat == 0 && p.lng == 0) return;
      final name = p.displayName.trim();
      if (name.isEmpty) return;
      // Dos direcciones a menos de ~100 m son el mismo lugar.
      final key = '${(p.lat * 1000).round()}:${(p.lng * 1000).round()}';
      if (!seen.add(key)) return;
      places.add(p);
    }

    for (final b in byRecent) {
      if (b.status == BookingStatus.cancelled) continue;
      if (b.serviceType != ServiceType.byTheHour) add(b.destination);
    }
    for (final b in byRecent) {
      if (b.status == BookingStatus.cancelled) continue;
      add(b.origin);
    }

    final completed =
        byRecent.where((b) => b.status == BookingStatus.completed).toList();

    final counts = <VehicleClass, int>{};
    for (final b in byRecent) {
      if (b.status == BookingStatus.cancelled) continue;
      counts[b.vehicleClass] = (counts[b.vehicleClass] ?? 0) + 1;
    }
    VehicleClass? favorite;
    if (counts.isNotEmpty) {
      final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
      if (top.value >= 2) favorite = top.key;
    }

    const open = {
      BookingStatus.pending,
      BookingStatus.confirmed,
      BookingStatus.driverArriving,
      BookingStatus.driverArrived,
      BookingStatus.verified,
      BookingStatus.inProgress,
    };
    final upcoming = bookings
        .where(
          (b) =>
              open.contains(b.status) &&
              b.scheduledAt.isAfter(t.subtract(const Duration(hours: 3))),
        )
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return RiderInsights(
      recentPlaces: places.take(4).toList(),
      favoriteClass: favorite,
      nextTrip: upcoming.isEmpty ? null : upcoming.first,
      lastTrip: completed.isEmpty ? null : completed.first,
      completedTrips: completed.length,
    );
  }
}

/// Una frase que acompaña el saludo según el momento: lo que probablemente
/// necesita ahora mismo, dicho con calma.
String contextualPrompt(DateTime now, {Booking? nextTrip}) {
  if (nextTrip != null) {
    final mins = nextTrip.scheduledAt.difference(now).inMinutes;
    if (nextTrip.status == BookingStatus.inProgress) {
      return 'Disfruta el trayecto.';
    }
    if (nextTrip.status == BookingStatus.driverArrived) {
      return 'Tu chófer ya te espera.';
    }
    if (nextTrip.status == BookingStatus.driverArriving) {
      return 'Tu chófer va en camino.';
    }
    if (mins >= 0 && mins <= 120) return 'Tu próximo trayecto está cerca.';
  }
  final h = now.hour;
  if (h >= 5 && h < 11) return '¿A dónde empieza tu día?';
  if (h >= 11 && h < 15) return '¿A dónde te llevamos?';
  if (h >= 15 && h < 20) return '¿Cerramos el día en calma?';
  if (h >= 20 || h < 1) return '¿Volvemos con calma?';
  return 'Estamos aquí a cualquier hora.';
}
