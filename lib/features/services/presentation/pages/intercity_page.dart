import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/booking_form_data.dart';
import '../../../../core/models/place_model.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/widgets/place_autocomplete_field.dart';
import '../../../../l10n/l10n.dart';
import '../../../home/presentation/pages/home_design.dart';
import '../../domain/intercity.dart';

/// Route lookup used to price the trip; injectable for tests.
typedef RouteLookup = Future<RouteInfo?> Function(Place origin, Place destination);

/// City to city: private trips from Santa Cruz to popular destinations. A
/// card opens a short form (pickup and date) and continues to the regular
/// booking with the real route, where the server fixes the price.
class IntercityPage extends StatelessWidget {
  const IntercityPage({super.key, this.routeLookup});
  final RouteLookup? routeLookup;

  static String tagline(AppLocalizations l, IntercityDestination d) => switch (d) {
        IntercityDestination.samaipata => l.intercitySamaipata,
        IntercityDestination.buenaVista => l.intercityBuenaVista,
        IntercityDestination.montero => l.intercityMontero,
        IntercityDestination.sanJoseChiquitos => l.intercitySanJose,
        IntercityDestination.concepcion => l.intercityConcepcion,
        IntercityDestination.cochabamba => l.intercityCochabamba,
      };

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
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 64),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.intercityEyebrow.toUpperCase(), style: eyebrow()),
                  const SizedBox(height: 12),
                  Semantics(
                    header: true,
                    child: Text(l.intercityTitle,
                        style: displayText(size: width < 600 ? 36 : 54, weight: FontWeight.w400)),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Text(l.intercityIntro, style: bodyText(size: 16)),
                  ),
                  const SizedBox(height: 36),
                  _Grid(
                    columns: cols,
                    minHeight: 168,
                    children: [
                      for (final d in IntercityDestination.values)
                        _DestinationCard(
                          destination: d,
                          onTap: () => _openForm(context, d),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(l.intercityEstimateNote, style: uiLabel(spacing: 0.3)),
                  const SizedBox(height: 48),
                  Text(l.intercityIncludedTitle.toUpperCase(), style: eyebrow()),
                  const SizedBox(height: 16),
                  _Grid(columns: cols, minHeight: 128, children: [
                    _Included(icon: Icons.lock_outline, title: l.intercityIncFixedTitle, body: l.intercityIncFixedBody),
                    _Included(
                        icon: Icons.verified_user_outlined, title: l.intercityIncChauffeurTitle, body: l.intercityIncChauffeurBody),
                    _Included(icon: Icons.near_me_outlined, title: l.intercityIncTrackingTitle, body: l.intercityIncTrackingBody),
                  ]),
                  const SizedBox(height: 40),
                  TextButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.edit_location_alt_outlined, size: 18, color: LD.accent),
                    label: Text(l.intercityOtherDestination, style: const TextStyle(color: LD.accent)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, IntercityDestination d) {
    final lookup = routeLookup ?? (o, dst) => sl<MapsService>().getRoute(origin: o, destination: dst);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final form = IntercityForm(destination: d, routeLookup: lookup);
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
}

class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children, this.minHeight = 0});
  final int columns;
  final List<Widget> children;

  /// Keeps cards in a row visually even without measuring intrinsic heights
  /// (which go stale when web fonts load after the first layout).
  final double minHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        const gap = 16.0;
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(
                width: w,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: columns > 1 ? minHeight : 0),
                  child: child,
                ),
              ),
          ],
        );
      });
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.destination, required this.onTap});
  final IntercityDestination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = destination;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 168),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(border: Border.all(color: LD.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(d.name, style: displayText(size: 28, weight: FontWeight.w500))),
                  const Icon(Icons.arrow_forward_rounded, color: LD.accent, size: 20),
                ]),
                const SizedBox(height: 6),
                Text(IntercityPage.tagline(l, d), style: bodyText(size: 14)),
                const SizedBox(height: 16),
                Text(
                  l.intercityCardMeta(
                    NumberFormat.decimalPattern().format(Intercity.estimatedKm(d)),
                    LuxMoney.format(Intercity.estimatedFare(d)),
                  ),
                  style: uiLabel(size: 11, spacing: 0.4, color: LD.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Included extends StatelessWidget {
  const _Included({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: LD.border)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: LD.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: bodyText(size: 15, color: LD.ink).copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(body, style: bodyText(size: 13)),
            ]),
          ),
        ]),
      );
}

/// Pickup and date for a city-to-city trip, then on to the booking.
class IntercityForm extends StatefulWidget {
  const IntercityForm({super.key, required this.destination, required this.routeLookup});
  final IntercityDestination destination;
  final RouteLookup routeLookup;

  @override
  State<IntercityForm> createState() => _IntercityFormState();
}

class _IntercityFormState extends State<IntercityForm> {
  Place? _pickup;
  late DateTime _at = _defaultTime();
  bool _loading = false;
  String? _error;

  /// Tomorrow 08:00: long trips are usually planned ahead.
  static DateTime _defaultTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 8);
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
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
    final pickup = _pickup;
    if (pickup == null) {
      setState(() => _error = l.intercityPickupRequired);
      return;
    }
    if (!_at.isAfter(DateTime.now())) {
      setState(() => _error = l.intercityTimeInPast);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final destination = widget.destination.place;
    final route = await widget.routeLookup(pickup, destination);
    if (!mounted) return;
    setState(() => _loading = false);
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(
      '/booking',
      extra: BookingFormData(
        origin: pickup,
        destination: destination,
        serviceType: ServiceType.oneWay,
        scheduledAt: _at,
        routeDistanceKm: route?.distanceKm ?? 0,
        routeDurationMin: route?.durationMin ?? 0,
        polylinePoints: route?.polylinePoints ?? const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final when = l.homeDateTimeShort(DateFormat.yMMMEd().format(_at), DateFormat.jm().format(_at));
    // The form sits on white: give its fields (place search, pickers) the
    // light look instead of the app's dark theme.
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
            Text(l.intercityFormEyebrow.toUpperCase(), style: eyebrow()),
            const SizedBox(height: 8),
            Text(l.intercityFormTitle(widget.destination.name), style: displayText(size: 28, weight: FontWeight.w500)),
            const SizedBox(height: 20),
            PlaceAutocompleteField(
              label: l.homeFormPickupLabel,
              hint: l.homeFormPickupHint,
              prefixIcon: Icons.radio_button_checked_outlined,
              onPlaceSelected: (p) => setState(() {
                _pickup = p;
                _error = null;
              }),
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
              label: Text(when),
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
