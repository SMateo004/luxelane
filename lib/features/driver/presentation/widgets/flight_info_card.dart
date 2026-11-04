import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/utils/service_area.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../booking/data/airport_repository.dart';

/// ATT (Autoridad de Transportes) flight status site.
final _miVueloUrl = Uri.parse('https://mivuelo.att.gob.bo/');

/// Copia del vuelo para el chófer asignado (bookings/{id}/driverView/flight,
/// la escribe el servidor y solo se lee de confirmed a in_progress).
abstract class DriverFlightSource {
  Stream<FlightInfo?> watch(String bookingId);
}

class FirestoreDriverFlightSource implements DriverFlightSource {
  FirestoreDriverFlightSource([FirebaseFirestore? db]) : _db = db;
  final FirebaseFirestore? _db;

  @override
  Stream<FlightInfo?> watch(String bookingId) =>
      (_db ?? FirebaseFirestore.instance)
          .collection('bookings')
          .doc(bookingId)
          .collection('driverView')
          .doc('flight')
          .snapshots()
          .map((s) => s.exists ? FlightInfo.fromMap(s.data()) : null)
          // Fuera de la ventana o sin red: lo que diga la reserva.
          .handleError((_) {});
}

/// Tarjeta «Vuelo» del chófer (Parte B de vuelos): aerolínea, número,
/// estado, hora estimada, «Debes estar en el punto a las HH:MM» y el punto
/// de recogida del tipo de vuelo (o «Punto por confirmar con central»). Sin
/// datos en vivo lo dice. Nada para reservas sin vuelo.
class FlightInfoCard extends StatelessWidget {
  const FlightInfoCard({
    super.key,
    required this.booking,
    this.flights,
    this.airports,
  });

  final Booking booking;
  final DriverFlightSource? flights;
  final AirportRepository? airports;

  ServiceAirport? get _legacyAirport =>
      ServiceArea.airportByIata(booking.pickupAirport) ??
      ServiceArea.airportFor(booking.origin);

  @override
  Widget build(BuildContext context) {
    final number = booking.flightNumber;
    if ((number == null || number.isEmpty) && booking.flight == null) {
      return const SizedBox.shrink();
    }
    final source = flights ?? FirestoreDriverFlightSource();
    final repo = airports ?? FirestoreAirportRepository();
    return StreamBuilder<FlightInfo?>(
      stream: source.watch(booking.id),
      builder: (context, snap) {
        final f = snap.data ?? booking.flight;
        final code =
            f?.airportCode ?? booking.pickupAirport ?? _legacyAirport?.iata;
        final type = f?.flightType ?? FlightType.fromName(booking.flightType);
        return StreamBuilder<Airport?>(
          stream: code == null ? Stream.value(null) : repo.watch(code),
          builder: (context, airportSnap) => _FlightCardBody(
            flight: f,
            number: f?.flightNumber ?? number ?? '',
            type: type,
            airport: airportSnap.data,
            airportLabel: airportSnap.data?.name ?? _legacyAirport?.name,
            legacyAirport: _legacyAirport,
          ),
        );
      },
    );
  }
}

class _FlightCardBody extends StatelessWidget {
  const _FlightCardBody({
    required this.flight,
    required this.number,
    required this.type,
    required this.airport,
    required this.airportLabel,
    required this.legacyAirport,
  });

  final FlightInfo? flight;
  final String number;
  final FlightType? type;
  final Airport? airport;
  final String? airportLabel;
  final ServiceAirport? legacyAirport;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final f = flight;
    final point = type == null ? null : airport?.pointFor(type!);
    Widget line(String text, {TextStyle? style}) => Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(text, style: style ?? LuxTypography.bodyMedium),
        );
    return Container(
      key: const ValueKey('driver-flight-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(LuxSpacing.md),
      decoration: BoxDecoration(
        color: LuxColors.sapphireTint,
        borderRadius: BorderRadius.circular(LuxRadius.sm),
        border: Border.all(color: LuxColors.sapphire.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ExcludeSemantics(
                child: Icon(Icons.flight_land_rounded,
                    size: 16, color: LuxColors.sapphire),
              ),
              const SizedBox(width: LuxSpacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    airportLabel ?? t.driverFlightAirportPickup,
                    style: LuxTypography.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (type != null) _Tag(type!.label),
            ],
          ),
          const SizedBox(height: LuxSpacing.sm),
          Text(
            [
              t.driverFlightCardTitle,
              if (f?.airline != null) f!.airline!,
              number,
            ].join(' · '),
            style: LuxTypography.titleMedium,
          ),
          if (f != null) ...[
            line(t.driverFlightStatus(f.status.label)),
            if (f.actualArrival != null)
              line(t.flightActualArrival(LuxFormat.time(f.actualArrival!)))
            else if (f.estimatedArrival != null)
              line(t
                  .flightEstimatedArrival(LuxFormat.time(f.estimatedArrival!))),
            if (f.noLiveData && f.scheduledArrival != null)
              line(t.flightNoLiveData(LuxFormat.time(f.scheduledArrival!))),
            if (f.readyAt != null)
              line(
                t.flightBeAtPointAt(LuxFormat.time(f.readyAt!)),
                style: LuxTypography.bodyLarge
                    .copyWith(fontWeight: FontWeight.w600),
              ),
          ],
          const SizedBox(height: LuxSpacing.sm),
          Text(point?.name ?? t.flightPickupPointPending,
              style: LuxTypography.bodyLarge),
          if (point != null && point.instructions.isNotEmpty)
            line(point.instructions),
          if (number.isNotEmpty) ...[
            const SizedBox(height: LuxSpacing.sm),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(LuxRadius.sm),
                onTap: () => openFlightTracker(context, number, legacyAirport),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.driverFlightCheckStatus,
                          style: LuxTypography.bodyMedium.copyWith(
                            color: LuxColors.sapphire,
                            decoration: TextDecoration.underline,
                            decorationColor: LuxColors.sapphire,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.open_in_new_rounded,
                          size: 14, color: LuxColors.sapphire),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Warns the driver to switch the site to their airport first (mivuelo opens
/// on another airport by default), then opens it with the flight number
/// copied to the clipboard.
Future<void> openFlightTracker(
  BuildContext context,
  String flight,
  ServiceAirport? airport,
) async {
  final city = airport?.cityName;
  final where = airport == null
      ? context.l10n.driverFlightYourCityAirport
      : city != null
          ? '${airport.name} ($city)'
          : airport.name;

  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.swap_horiz_rounded, color: LuxColors.sapphire),
      title: Text(ctx.l10n.driverFlightDialogTitle),
      content: Text(ctx.l10n.driverFlightDialogBody(where, flight)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(ctx.l10n.driverCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(ctx.l10n.driverFlightDialogOpen),
        ),
      ],
    ),
  );
  if (go != true) return;

  await Clipboard.setData(ClipboardData(text: flight));
  var ok = false;
  try {
    ok = await launchUrl(_miVueloUrl, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok && context.mounted) {
    showLuxSnackbar(
      context,
      context.l10n.driverFlightOpenFailed,
      isError: true,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: LuxColors.sapphire.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(LuxRadius.sm),
        ),
        child: Text(
          text.toUpperCase(),
          style: LuxTypography.caption.copyWith(
            color: LuxColors.sapphire,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      );
}
