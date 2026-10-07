import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../enums/enums.dart';
import '../models/models.dart';
import '../utils/waiting_policy.dart';
import 'components.dart';

// ============================================================
// Trip widgets shared by the rider and chauffeur apps.
// ============================================================

/// Live countdown of the free waiting time once the chauffeur has arrived.
class FreeWaitBanner extends StatefulWidget {
  const FreeWaitBanner({super.key, required this.booking, this.forDriver = false});
  final Booking booking;
  final bool forDriver;

  @override
  State<FreeWaitBanner> createState() => _FreeWaitBannerState();
}

class _FreeWaitBannerState extends State<FreeWaitBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final until = WaitingPolicy.freeUntil(b);
    final left = WaitingPolicy.remaining(b);
    final l = context.l10n;
    final time = DateFormat.jm().format(until);
    final over = left == null;
    final color = over ? LuxColors.warning : LuxColors.success;

    final title = over ? l.tripFreeWaitOver(time) : l.tripFreeWaitLeft(left.inMinutes + 1);
    final subtitle = over
        ? (widget.forDriver ? l.tripFreeWaitOverDriver : l.tripFreeWaitOverRider)
        : l.tripFreeWaitUntil(time, WaitingPolicy.localizedSummary(l, b));

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(LuxSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(LuxRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(over ? Icons.hourglass_bottom_rounded : Icons.hourglass_top_rounded, color: color),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: LuxTypography.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: LuxTypography.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rider-side card for airport pickups: where and how the chauffeur waits.
class MeetAndGreetCard extends StatelessWidget {
  const MeetAndGreetCard({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final name = booking.passengerName;
    final l = context.l10n;
    return LuxCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.badge_outlined, color: LuxColors.accent),
          const SizedBox(width: LuxSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.tripMeetGreetTitle, style: LuxTypography.titleMedium),
                const SizedBox(height: 4),
                Text(
                  name != null && name.isNotEmpty
                      ? l.tripMeetGreetBodyNamed(name)
                      : l.tripMeetGreetBody,
                  style: LuxTypography.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l.tripMeetGreetWait(WaitingPolicy.airportFreeMinutes),
                  style: LuxTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chauffeur-side card: who to pick up and how to reach them.
class PassengerCard extends StatelessWidget {
  const PassengerCard({super.key, required this.booking});
  final Booking booking;

  static String _digits(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> _launch(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      showLuxSnackbar(context, context.l10n.commonCouldNotOpenApp, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (booking.passengerName ?? '').trim();
    final phone = (booking.passengerPhone ?? '').trim();
    final airport = WaitingPolicy.isAirport(booking);
    final l = context.l10n;
    final details = [
      l.unitPassengers(booking.passengerCount),
      if (booking.luggageCount > 0) l.unitBags(booking.luggageCount),
      if (airport) l.tripFlightNumber(booking.flightNumber!.trim()),
    ].join(' · ');

    return LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: LuxColors.accent),
              const SizedBox(width: LuxSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isEmpty ? l.tripPassenger : name, style: LuxTypography.titleLarge),
                    const SizedBox(height: 2),
                    Text(details, style: LuxTypography.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: LuxSpacing.sm),
            Text(booking.notes!, style: LuxTypography.caption),
          ],
          const SizedBox(height: LuxSpacing.md),
          Wrap(
            spacing: LuxSpacing.sm,
            runSpacing: LuxSpacing.sm,
            children: [
              if (phone.isNotEmpty) ...[
                _ActionChip(
                  icon: Icons.call_outlined,
                  label: l.commonCall,
                  onTap: () => _launch(context, Uri(scheme: 'tel', path: _digits(phone))),
                ),
                _ActionChip(
                  icon: Icons.chat_outlined,
                  label: l.commonWhatsApp,
                  onTap: () => _launch(context, Uri.parse('https://wa.me/${_digits(phone).replaceAll('+', '')}')),
                ),
              ],
              if (name.isNotEmpty)
                _ActionChip(
                  icon: Icons.badge_outlined,
                  label: l.tripShowSign,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => NameSignPage(name: name),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            foregroundColor: LuxColors.accent,
            side: const BorderSide(color: LuxColors.accent),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
      );
}

/// Full-screen name sign the chauffeur holds up at arrivals.
class NameSignPage extends StatefulWidget {
  const NameSignPage({super.key, required this.name});
  final String name;

  @override
  State<NameSignPage> createState() => _NameSignPageState();
}

class _NameSignPageState extends State<NameSignPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: Semantics(
          label: context.l10n.tripNameSignSemantics(widget.name),
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text(
                      'LUXELANE',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 6,
                        color: LuxPalette.champagneDeep,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Cormorant Garamond',
                              fontSize: 140,
                              fontWeight: FontWeight.w600,
                              color: LuxPalette.ink,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.tripNameSignTapToClose,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: LuxPalette.slate),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// True while the free-wait countdown is relevant.
bool showsFreeWait(Booking b) => b.status == BookingStatus.driverArrived;
