import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../core/enums/enums.dart';
import '../../../core/models/booking_form_data.dart';
import '../../../core/models/place_model.dart';
import '../../../core/services/maps_service.dart';
import '../../../core/utils/waiting_policy.dart';
import '../../../l10n/l10n.dart';
import '../../home/presentation/pages/home_design.dart';
import '../../services/presentation/pages/intercity_page.dart' show RouteLookup;
import '../../services/presentation/widgets/service_widgets.dart';
import '../data/hotel_repository.dart';
import '../domain/partner_hotel.dart';

/// Hotel transfers: partner hotels ↔ Viru Viru. A hotel's link (QR at
/// reception) opens the page with that hotel's form already open.
class HotelTransfersPage extends StatefulWidget {
  const HotelTransfersPage({super.key, this.initialHotelId, this.repository, this.routeLookup});
  final String? initialHotelId;
  final HotelRepository? repository;
  final RouteLookup? routeLookup;

  @override
  State<HotelTransfersPage> createState() => _HotelTransfersPageState();
}

class _HotelTransfersPageState extends State<HotelTransfersPage> {
  late final Stream<List<PartnerHotel>> _hotels = (widget.repository ?? sl<HotelRepository>()).watchActive();
  bool _openedInitial = false;

  void _maybeOpenInitial(List<PartnerHotel> hotels) {
    if (_openedInitial || widget.initialHotelId == null) return;
    final match = hotels.where((h) => h.id == widget.initialHotelId);
    if (match.isEmpty) return;
    _openedInitial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openForm(match.first, HotelTransferDirection.toAirport);
    });
  }

  void _openForm(PartnerHotel hotel, HotelTransferDirection direction) {
    final lookup = widget.routeLookup ?? (o, d) => sl<MapsService>().getRoute(origin: o, destination: d);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final form = HotelTransferForm(hotel: hotel, initialDirection: direction, routeLookup: lookup);
    if (wide) {
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: form),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: form,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 1100 ? 3 : (width >= 700 ? 2 : 1);
    final gutter = width < 600 ? 20.0 : 48.0;

    return Scaffold(
      backgroundColor: LD.bg,
      appBar: AppBar(
        backgroundColor: LD.bg,
        foregroundColor: LD.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          tooltip: l.commonBack,
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text('LUXELANE', style: uiLabel(size: 12, spacing: 3, color: LD.ink)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<PartnerHotel>>(
        stream: _hotels,
        builder: (context, snap) {
          final hotels = snap.data ?? const <PartnerHotel>[];
          _maybeOpenInitial(hotels);
          final loading = !snap.hasData && !snap.hasError;
          return ListView(
            padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 64),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.hotelEyebrow.toUpperCase(), style: eyebrow()),
                      const SizedBox(height: 12),
                      Semantics(
                        header: true,
                        child: Text(l.hotelTitle,
                            style: displayText(size: width < 600 ? 36 : 54, weight: FontWeight.w400)),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Text(l.hotelIntro, style: bodyText(size: 16)),
                      ),
                      const SizedBox(height: 36),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator(color: LD.accent)),
                        )
                      else if (hotels.isEmpty)
                        _NoHotels(onBook: () => context.go('/'))
                      else
                        EvenGrid(
                          columns: cols,
                          minHeight: 196,
                          children: [
                            for (final h in hotels)
                              _HotelCard(hotel: h, onPick: (d) => _openForm(h, d)),
                          ],
                        ),
                      const SizedBox(height: 48),
                      Text(l.intercityIncludedTitle.toUpperCase(), style: eyebrow()),
                      const SizedBox(height: 16),
                      EvenGrid(columns: cols, minHeight: 128, children: [
                        IncludedCard(
                            icon: Icons.lock_outline, title: l.intercityIncFixedTitle, body: l.intercityIncFixedBody),
                        IncludedCard(
                          icon: Icons.flight_land_outlined,
                          title: l.hotelIncFlightTitle,
                          body: l.hotelIncFlightBody(WaitingPolicy.airportFreeMinutes),
                        ),
                        IncludedCard(
                            icon: Icons.meeting_room_outlined, title: l.hotelIncLobbyTitle, body: l.hotelIncLobbyBody),
                      ]),
                      const SizedBox(height: 40),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        TextButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.edit_location_alt_outlined, size: 18, color: LD.accent),
                          label: Text(l.hotelOtherHotel, style: const TextStyle(color: LD.accent)),
                        ),
                        TextButton.icon(
                          onPressed: () => context.go('/contacto'),
                          icon: const Icon(Icons.handshake_outlined, size: 18, color: LD.accent),
                          label: Text(l.hotelPartnerCta, style: const TextStyle(color: LD.accent)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoHotels extends StatelessWidget {
  const _NoHotels({required this.onBook});
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: LD.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.hotel_outlined, color: LD.accent),
        const SizedBox(height: 12),
        Text(l.hotelNoneTitle, style: bodyText(size: 16, color: LD.ink).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(l.hotelNoneBody, style: bodyText(size: 14)),
      ]),
    );
  }
}

class _HotelCard extends StatelessWidget {
  const _HotelCard({required this.hotel, required this.onPick});
  final PartnerHotel hotel;
  final ValueChanged<HotelTransferDirection> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    ButtonStyle style() => OutlinedButton.styleFrom(
          foregroundColor: LD.ink,
          side: const BorderSide(color: LD.border),
          shape: const RoundedRectangleBorder(),
          minimumSize: const Size(0, 44),
        );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: LD.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(hotel.name, style: displayText(size: 26, weight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(hotel.address, style: bodyText(size: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
        if (hotel.meetingPoint.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(l.hotelMeetingPoint(hotel.meetingPoint), style: uiLabel(size: 11, spacing: 0.4, color: LD.ink)),
        ],
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            style: style(),
            onPressed: () => onPick(HotelTransferDirection.toAirport),
            icon: const Icon(Icons.flight_takeoff_outlined, size: 16, color: LD.accent),
            label: Text(l.hotelToAirport),
          ),
          OutlinedButton.icon(
            style: style(),
            onPressed: () => onPick(HotelTransferDirection.fromAirport),
            icon: const Icon(Icons.flight_land_outlined, size: 16, color: LD.accent),
            label: Text(l.hotelFromAirport),
          ),
        ]),
      ]),
    );
  }
}

/// Direction and time for a hotel transfer, then on to the booking.
class HotelTransferForm extends StatefulWidget {
  const HotelTransferForm({
    super.key,
    required this.hotel,
    required this.routeLookup,
    this.initialDirection = HotelTransferDirection.toAirport,
    this.now,
  });
  final PartnerHotel hotel;
  final RouteLookup routeLookup;
  final HotelTransferDirection initialDirection;
  final DateTime? now;

  @override
  State<HotelTransferForm> createState() => _HotelTransferFormState();
}

class _HotelTransferFormState extends State<HotelTransferForm> {
  late HotelTransferDirection _direction = widget.initialDirection;
  late DateTime _at = _defaultTime();
  bool _loading = false;
  String? _error;

  DateTime get _now => widget.now ?? DateTime.now();

  /// Two hours from now, on the next quarter hour.
  DateTime _defaultTime() {
    final t = _now.add(const Duration(hours: 2));
    final q = (t.minute / 15).ceil() * 15;
    return DateTime(t.year, t.month, t.day, t.hour).add(Duration(minutes: q));
  }

  Future<void> _pickDateTime() async {
    final now = _now;
    final day = await showDatePicker(
      context: context,
      initialDate: _at.isAfter(now) ? _at : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_at));
    if (time == null || !mounted) return;
    setState(() => _at = DateTime(day.year, day.month, day.day, time.hour, time.minute));
  }

  Future<void> _continue() async {
    final l = context.l10n;
    if (!_at.isAfter(_now)) {
      setState(() => _error = l.intercityTimeInPast);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final (Place origin, Place destination) = HotelTransfers.route(widget.hotel, _direction);
    final route = await widget.routeLookup(origin, destination);
    if (!mounted) return;
    setState(() => _loading = false);
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(
      '/booking',
      extra: BookingFormData(
        origin: origin,
        destination: destination,
        serviceType: ServiceType.oneWay,
        scheduledAt: _at,
        routeDistanceKm: route?.distanceKm ?? 0,
        routeDurationMin: route?.durationMin ?? 0,
        polylinePoints: route?.polylinePoints ?? const [],
        pickupNote: _direction == HotelTransferDirection.toAirport ? widget.hotel.meetingPoint : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final when = l.homeDateTimeShort(DateFormat.yMMMEd().format(_at), DateFormat.jm().format(_at));
    final toAirport = _direction == HotelTransferDirection.toAirport;
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        fontFamily: kSans,
        colorScheme: const ColorScheme.light(primary: LD.accent, onPrimary: Colors.white, surface: Colors.white),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.hotelEyebrow.toUpperCase(), style: eyebrow()),
            const SizedBox(height: 8),
            Text(widget.hotel.name, style: displayText(size: 28, weight: FontWeight.w500)),
            const SizedBox(height: 20),
            SegmentedButton<HotelTransferDirection>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                shape: const RoundedRectangleBorder(),
                selectedBackgroundColor: LD.accentTint,
                selectedForegroundColor: LD.ink,
                foregroundColor: LD.ink,
                side: const BorderSide(color: LD.border),
              ),
              segments: [
                ButtonSegment(
                    value: HotelTransferDirection.toAirport,
                    icon: const Icon(Icons.flight_takeoff_outlined, size: 16),
                    label: Text(l.hotelToAirport)),
                ButtonSegment(
                    value: HotelTransferDirection.fromAirport,
                    icon: const Icon(Icons.flight_land_outlined, size: 16),
                    label: Text(l.hotelFromAirport)),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() => _direction = s.first),
            ),
            const SizedBox(height: 12),
            Text(
              toAirport ? l.hotelToAirportHint : l.hotelFromAirportHint(WaitingPolicy.airportFreeMinutes),
              style: bodyText(size: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                alignment: Alignment.centerLeft,
                foregroundColor: LD.ink,
                side: const BorderSide(color: LD.border),
                shape: const RoundedRectangleBorder(),
              ),
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(toAirport ? l.hotelPickupAt(when) : l.hotelLandingAt(when)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(fontFamily: kSans, fontSize: 13, color: LuxPalette.error)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LD.cta,
                  foregroundColor: LD.onCta,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: LD.onCta))
                    : Text(l.intercityContinue.toUpperCase(),
                        style: const TextStyle(fontFamily: kSans, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
