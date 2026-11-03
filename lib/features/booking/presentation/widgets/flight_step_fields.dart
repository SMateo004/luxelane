import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/utils/service_area.dart';
import '../../../../l10n/l10n.dart';
import '../../data/airport_repository.dart';

/// Lo que el pasajero declara del vuelo, además del tipo y el número.
class FlightDraft {
  const FlightDraft({
    this.airline = '',
    this.date,
    this.time,
    this.hasCheckedBag = true,
  });

  final String airline;
  final DateTime? date;
  final TimeOfDay? time;

  /// Por defecto «con equipaje facturado»: el caso más largo.
  final bool hasCheckedBag;

  String? get timeWire => time == null
      ? null
      : '${time!.hour.toString().padLeft(2, '0')}:'
          '${time!.minute.toString().padLeft(2, '0')}';

  FlightDraft copyWith({
    String? airline,
    DateTime? date,
    TimeOfDay? time,
    bool? hasCheckedBag,
  }) =>
      FlightDraft(
        airline: airline ?? this.airline,
        date: date ?? this.date,
        time: time ?? this.time,
        hasCheckedBag: hasCheckedBag ?? this.hasCheckedBag,
      );

  /// El vuelo a enviar; null si falta algo o el número no vale.
  FlightRequest? toRequest({
    required String? airportCode,
    required FlightType? type,
    required String number,
  }) {
    if (airportCode == null || type == null || date == null || time == null) {
      return null;
    }
    if (!FlightNumber.isValid(number)) return null;
    return FlightRequest(
      airportCode: airportCode,
      flightType: type,
      airline: airline.trim().isEmpty ? null : airline.trim(),
      flightNumber: FlightNumber.normalize(number),
      flightDate: date!,
      scheduledArrival: timeWire!,
      hasCheckedBag: hasCheckedBag,
    );
  }
}

/// Aerolínea (opcional), fecha, hora del billete y equipaje facturado.
class FlightDetailsFields extends StatelessWidget {
  const FlightDetailsFields({
    super.key,
    required this.draft,
    required this.onChanged,
    this.showErrors = false,
  });

  final FlightDraft draft;
  final ValueChanged<FlightDraft> onChanged;
  final bool showErrors;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final now = DateTime.now();
    Widget picker({
      required Key key,
      required String label,
      required String value,
      required IconData icon,
      required String? error,
      required VoidCallback onTap,
    }) =>
        Semantics(
          button: true,
          label: '$label: $value',
          excludeSemantics: true,
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(LuxRadius.md),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  errorText: error,
                  suffixIcon: Icon(icon),
                ),
                child: Text(value, style: LuxTypography.bodyLarge),
              ),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const ValueKey('flight-airline'),
          initialValue: draft.airline,
          maxLength: 40,
          decoration: InputDecoration(
            labelText: t.bookingFlightAirline,
            counterText: '',
          ),
          onChanged: (v) => onChanged(draft.copyWith(airline: v)),
        ),
        const SizedBox(height: LuxSpacing.md),
        picker(
          key: const ValueKey('flight-date'),
          label: t.bookingFlightDate,
          value: draft.date == null
              ? t.bookingFlightPickDate
              : LuxFormat.date(draft.date!),
          icon: Icons.event_outlined,
          error: showErrors && draft.date == null
              ? t.bookingFlightDateMissing
              : null,
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: draft.date ?? now,
              firstDate: DateTime(now.year, now.month, now.day)
                  .subtract(const Duration(days: 1)),
              lastDate: now.add(const Duration(days: 365)),
            );
            if (d != null) onChanged(draft.copyWith(date: d));
          },
        ),
        const SizedBox(height: LuxSpacing.md),
        picker(
          key: const ValueKey('flight-time'),
          label: t.bookingFlightTime,
          value: draft.time == null
              ? t.bookingFlightPickTime
              : draft.time!.format(context),
          icon: Icons.schedule_outlined,
          error: showErrors && draft.time == null
              ? t.bookingFlightTimeMissing
              : null,
          onTap: () async {
            final v = await showTimePicker(
              context: context,
              initialTime: draft.time ?? const TimeOfDay(hour: 12, minute: 0),
            );
            if (v != null) onChanged(draft.copyWith(time: v));
          },
        ),
        const SizedBox(height: LuxSpacing.md),
        Semantics(
          header: true,
          child: Text(t.bookingFlightCheckedBagQuestion,
              style: LuxTypography.bodyMedium),
        ),
        const SizedBox(height: LuxSpacing.xs),
        Wrap(
          spacing: LuxSpacing.sm,
          runSpacing: LuxSpacing.sm,
          children: [
            for (final (bag, label) in [
              (true, t.bookingFlightCheckedBagYes),
              (false, t.bookingFlightCheckedBagNo),
            ])
              ChoiceChip(
                key: ValueKey('flight-bag-$bag'),
                label: Text(label),
                selected: draft.hasCheckedBag == bag,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) =>
                    onChanged(draft.copyWith(hasCheckedBag: bag)),
              ),
          ],
        ),
        const SizedBox(height: LuxSpacing.xs),
        Text(t.bookingFlightCheckedBagHelp, style: LuxTypography.caption),
      ],
    );
  }
}

/// Dónde y a qué hora estará el chófer: el punto del aeropuerto para ese
/// tipo de vuelo (o «por confirmar») y readyAt de la cotización.
class FlightPickupInfo extends StatelessWidget {
  const FlightPickupInfo({
    super.key,
    required this.airportCode,
    required this.flightType,
    required this.readyAt,
    required this.repository,
  });

  final String airportCode;
  final FlightType flightType;
  final DateTime? readyAt;
  final AirportRepository repository;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return StreamBuilder<Airport?>(
      stream: repository.watch(airportCode),
      builder: (context, snap) {
        final point = snap.data?.pointFor(flightType);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(LuxSpacing.md),
          decoration: BoxDecoration(
            color: LuxColors.sapphireTint,
            borderRadius: BorderRadius.circular(LuxRadius.md),
          ),
          child: MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(
                  child: Icon(Icons.place_outlined, color: LuxColors.sapphire),
                ),
                const SizedBox(width: LuxSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point?.name ?? t.flightPickupPointPending,
                        style: LuxTypography.titleMedium,
                      ),
                      if (point != null && point.instructions.isNotEmpty)
                        Text(point.instructions,
                            style: LuxTypography.bodyMedium),
                      if (readyAt != null) ...[
                        const SizedBox(height: LuxSpacing.xs),
                        Text(
                          t.flightDriverWillBeAt(LuxFormat.time(readyAt!)),
                          style: LuxTypography.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// En el viaje: lo que el pasajero necesita saber del vuelo (sin datos en
/// vivo, retrasado, cancelado o desviado). Nada si va según lo previsto.
class RiderFlightStatusNote extends StatelessWidget {
  const RiderFlightStatusNote({super.key, required this.flight});
  final FlightInfo flight;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final f = flight;
    final String? text;
    if (f.status.disrupted) {
      text = t.rideFlightDisrupted;
    } else if (f.status == FlightStatus.delayed && f.readyAt != null) {
      text = t.rideFlightDelayed(LuxFormat.time(f.readyAt!));
    } else if (f.noLiveData && f.scheduledArrival != null) {
      text = t.flightNoLiveData(LuxFormat.time(f.scheduledArrival!));
    } else {
      text = null;
    }
    if (text == null) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('rider-flight-note'),
      width: double.infinity,
      padding: const EdgeInsets.all(LuxSpacing.md),
      decoration: BoxDecoration(
        color: f.status.disrupted
            ? LuxColors.error.withValues(alpha: 0.08)
            : LuxColors.sapphireTint,
        borderRadius: BorderRadius.circular(LuxRadius.md),
      ),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                f.status.disrupted
                    ? Icons.warning_amber_rounded
                    : Icons.flight_land_rounded,
                color:
                    f.status.disrupted ? LuxColors.error : LuxColors.sapphire,
              ),
            ),
            const SizedBox(width: LuxSpacing.sm),
            Expanded(child: Text(text, style: LuxTypography.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
