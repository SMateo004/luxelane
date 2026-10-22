import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';

/// Texto de un paso del registro, para el panel.
String bookingEventTitle(BookingEvent e) {
  if (e.type == 'pickup_locked') {
    return 'Verificación bloqueada tras ${e.failedAttempts ?? 5} códigos '
        'incorrectos';
  }
  return '${e.from.displayLabel} → ${e.to.displayLabel}';
}

/// Detalles del paso: quién, desde dónde y lo que el servidor anotó.
List<String> bookingEventDetails(
    BookingEvent e, String Function(String uid) userName) {
  final who = switch (e.actorRole) {
    'driver' => 'Chófer ${userName(e.actorUid)}',
    'admin' => 'Admin ${userName(e.actorUid)}',
    'system' => 'Sistema',
    _ => e.actorUid,
  };
  return [
    [
      who,
      if (e.appVersion != null) 'app ${e.appVersion}',
      if (e.method == 'pickup_code') 'con el código del pasajero',
      if (e.method == 'admin_override') 'forzada por el admin',
    ].join(' · '),
    if (e.reason != null) 'Motivo: ${e.reason}',
    if (e.farFromPickup)
      'Lejos del punto de recogida'
          '${e.distanceMeters != null ? ' (${e.distanceMeters} m)' : ''}',
    if (e.arrivalCheck == 'no_radius')
      'Sin radio de llegada configurado: no se comparó la distancia',
    if (e.arrivalCheck == 'no_location')
      'El chófer no envió su ubicación al llegar',
    if (e.hasLocation)
      'Ubicación del chófer: ${e.lat!.toStringAsFixed(5)}, '
          '${e.lng!.toStringAsFixed(5)}',
  ];
}

/// Registro de pasos de la reserva (bookings/{id}/events). Solo lectura:
/// lo escribe el servidor y nadie lo edita.
class BookingEventsList extends StatelessWidget {
  const BookingEventsList({
    super.key,
    required this.events,
    required this.userName,
  });

  final Stream<List<BookingEvent>> events;
  final String Function(String uid) userName;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<BookingEvent>>(
        stream: events,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Text('No se pudo cargar el registro.',
                style: LuxTypography.caption);
          }
          final list = snap.data;
          if (list == null) {
            return const Text('Cargando…', style: LuxTypography.caption);
          }
          if (list.isEmpty) {
            return const Text(
                'Sin pasos registrados (reserva anterior al registro o aún '
                'sin chófer en camino).',
                style: LuxTypography.caption);
          }
          final time = DateFormat('dd/MM HH:mm:ss');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in list)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(e.at == null ? '—' : time.format(e.at!),
                            style: LuxTypography.caption),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bookingEventTitle(e),
                              style: LuxTypography.bodyMedium.copyWith(
                                color: e.type == 'pickup_locked' ||
                                        e.farFromPickup ||
                                        e.method == 'admin_override'
                                    ? LuxColors.warning
                                    : null,
                              ),
                            ),
                            for (final d in bookingEventDetails(e, userName))
                              Text(d, style: LuxTypography.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      );
}
