import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/service_area.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';

/// ATT (Autoridad de Transportes) flight status site.
final _miVueloUrl = Uri.parse('https://mivuelo.att.gob.bo/');

// Generic exits for a pickup airport we don't have on file.
const _anyAirport = ServiceAirport('', '', 0, 0);

/// Airport pickup details for the driver: where the passenger comes out and
/// the flight number, which opens the ATT flight tracker. Renders nothing for
/// bookings without a flight.
class FlightInfoCard extends StatelessWidget {
  const FlightInfoCard({super.key, required this.booking});
  final Booking booking;

  ServiceAirport? get _airport =>
      ServiceArea.airportByIata(booking.pickupAirport) ??
      ServiceArea.airportFor(booking.origin);

  @override
  Widget build(BuildContext context) {
    final flight = booking.flightNumber;
    if (flight == null || flight.isEmpty) return const SizedBox.shrink();
    final airport = _airport;
    final type = FlightType.fromName(booking.flightType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LuxSpacing.md),
      decoration: BoxDecoration(
        color: LuxColors.sapphireTint,
        borderRadius: BorderRadius.circular(LuxRadius.sm),
        border: Border.all(color: LuxColors.sapphire.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flight_land_rounded,
                size: 16,
                color: LuxColors.sapphire,
              ),
              const SizedBox(width: LuxSpacing.sm),
              Expanded(
                child: Text(
                  airport?.name ?? context.l10n.driverFlightAirportPickup,
                  style: LuxTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (type != null) _Tag(type.label),
            ],
          ),
          const SizedBox(height: LuxSpacing.sm),
          Text(context.l10n.driverFlightExitLabel,
              style: LuxTypography.caption),
          const SizedBox(height: 2),
          Text(
            type == null
                ? context.l10n.driverFlightAskType
                : (airport ?? _anyAirport).exitFor(type),
            style: LuxTypography.bodyLarge,
          ),
          const SizedBox(height: LuxSpacing.md),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(LuxRadius.sm),
              onTap: () => openFlightTracker(context, flight, airport),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(
                      context.l10n.driverFlightNumber(flight),
                      style: LuxTypography.bodyLarge.copyWith(
                        color: LuxColors.sapphire,
                        decoration: TextDecoration.underline,
                        decorationColor: LuxColors.sapphire,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 14,
                      color: LuxColors.sapphire,
                    ),
                    const SizedBox(width: LuxSpacing.sm),
                    Expanded(
                      child: Text(
                        context.l10n.driverFlightCheckStatus,
                        style: LuxTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
          color: LuxColors.sapphire.withOpacity(0.18),
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
