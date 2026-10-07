import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../home/presentation/pages/home_design.dart';

/// Shown right after a booking is created: animated confirmation, the
/// fixed price, trip summary and a countdown to pickup.
class BookingConfirmedPage extends StatefulWidget {
  const BookingConfirmedPage({super.key, required this.bookingId, this.booking});

  final String bookingId;

  /// Passed via `GoRouter` extra right after creation; fetched otherwise.
  final Booking? booking;

  @override
  State<BookingConfirmedPage> createState() => _BookingConfirmedPageState();
}

class _BookingConfirmedPageState extends State<BookingConfirmedPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  Booking? _booking;
  String? _error;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    if (_booking == null) _load();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _anim.value = 1;
    } else if (!_anim.isAnimating && _anim.value == 0) {
      _anim.forward();
    }
  }

  Future<void> _load() async {
    final result = await sl<BookingRepository>().getBookingById(widget.bookingId);
    if (!mounted) return;
    result.fold(
      (f) => setState(() => _error = f.message),
      (b) => setState(() => _booking = b),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    return Scaffold(
      backgroundColor: LD.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: booking == null
                  ? _Status(error: _error, onRetry: _load)
                  : _Content(booking: booking, anim: _anim),
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.booking, required this.anim});
  final Booking booking;
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: anim, curve: const Interval(0.35, 1, curve: LuxMotion.curve));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _AnimatedCheck(progress: anim)),
        const SizedBox(height: 28),
        FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(fade),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('RESERVA CONFIRMADA', textAlign: TextAlign.center, style: eyebrow()),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(
                    'Tu chófer te esperará.',
                    textAlign: TextAlign.center,
                    style: displayText(size: 40, weight: FontWeight.w400),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _countdown(booking.effectivePickup),
                  textAlign: TextAlign.center,
                  style: bodyText(),
                ),
                const SizedBox(height: 28),
                _SummaryCard(booking: booking),
                const SizedBox(height: 16),
                const _Assurances(),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.go('/ride/${booking.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LD.cta,
                      foregroundColor: LD.onCta,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      textStyle: const TextStyle(
                        fontFamily: kSans,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    child: const Text('VER MI RESERVA'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: LD.ink2,
                  ),
                  child: const Text('Volver al inicio',
                      style: TextStyle(fontFamily: kSans, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _countdown(DateTime at) {
    final diff = at.difference(DateTime.now());
    if (diff.isNegative || diff.inMinutes < 1) return 'Tu chófer está en camino.';
    if (diff.inMinutes < 60) return 'Recogida en ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      final m = diff.inMinutes % 60;
      return 'Recogida en ${diff.inHours} h${m > 0 ? ' $m min' : ''}';
    }
    final days = diff.inDays;
    return 'Recogida en $days ${days == 1 ? 'día' : 'días'}';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat("EEE d 'de' MMMM · HH:mm", 'es').format(booking.effectivePickup);
    final hourly = booking.serviceType == ServiceType.byTheHour;
    final paidByCard = booking.stripePaymentIntentId != null;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: LD.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.vehicleClass.label.toUpperCase(), style: uiLabel(color: LD.accent)),
                    const SizedBox(height: 4),
                    Text(booking.vehicleClass.description, style: bodyText(size: 13, color: LD.ink3)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(LuxMoney.format(booking.estimatedPrice),
                          style: displayText(size: 30, weight: FontWeight.w500)),
                    ),
                    Text('Precio fijo · ${paidByCard ? 'tarjeta autorizada' : 'pago al chófer'}',
                        textAlign: TextAlign.end,
                        style: uiLabel(spacing: 0.4)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: LD.border),
          ),
          _Row(icon: Icons.event_outlined, label: date),
          _Row(icon: Icons.trip_origin, label: booking.origin.displayName),
          if (hourly)
            _Row(icon: Icons.schedule, label: 'Chófer a disposición · ${booking.hours ?? 2} h')
          else
            _Row(icon: Icons.place_outlined, label: booking.destination.displayName),
          if (booking.flightNumber != null)
            _Row(icon: Icons.flight_land_outlined, label: 'Vuelo ${booking.flightNumber}'),
          _Row(
            icon: Icons.person_outline,
            label: '${booking.passengerCount} '
                '${booking.passengerCount == 1 ? 'pasajero' : 'pasajeros'}'
                '${booking.luggageCount > 0 ? ' · ${booking.luggageCount} maletas' : ''}',
          ),
          const SizedBox(height: 8),
          Text('Código de reserva: ${booking.id.substring(0, booking.id.length.clamp(0, 8)).toUpperCase()}',
              style: uiLabel(spacing: 1.2)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: LD.accent),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: bodyText(size: 14, color: LD.ink).copyWith(height: 1.4))),
          ],
        ),
      );
}

class _Assurances extends StatelessWidget {
  const _Assurances();

  static const _items = [
    (Icons.lock_outline, 'Precio fijo, sin sorpresas'),
    (Icons.event_available_outlined, 'Cancelación gratuita hasta 1 h antes'),
    (Icons.verified_user_outlined, 'Chóferes verificados'),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          for (final (icon, text) in _items)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 14, color: LD.accent),
              const SizedBox(width: 6),
              Flexible(child: Text(text, style: uiLabel(size: 11, spacing: 0.3, color: LD.ink2))),
            ]),
        ],
      );
}

class _AnimatedCheck extends StatelessWidget {
  const _AnimatedCheck({required this.progress});
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Reserva confirmada',
        child: AnimatedBuilder(
          animation: progress,
          builder: (_, __) => CustomPaint(
            size: const Size(88, 88),
            painter: _CheckPainter(LuxMotion.curve.transform(progress.value)),
          ),
        ),
      );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final ring = (t / 0.55).clamp(0.0, 1.0);
    final tick = ((t - 0.45) / 0.55).clamp(0.0, 1.0);

    canvas.drawCircle(c, r * (0.85 + 0.15 * ring), Paint()..color = LuxPalette.champagne.withValues(alpha: 0.14 * ring));
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 4),
      -1.5708,
      6.2832 * ring,
      false,
      Paint()
        ..color = LuxPalette.champagne
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    if (tick > 0) {
      final a = Offset(size.width * 0.30, size.height * 0.52);
      final b = Offset(size.width * 0.44, size.height * 0.65);
      final d = Offset(size.width * 0.70, size.height * 0.38);
      final path = Path()..moveTo(a.dx, a.dy);
      final first = (tick / 0.4).clamp(0.0, 1.0);
      path.lineTo(a.dx + (b.dx - a.dx) * first, a.dy + (b.dy - a.dy) * first);
      if (tick > 0.4) {
        final second = ((tick - 0.4) / 0.6).clamp(0.0, 1.0);
        path.lineTo(b.dx + (d.dx - b.dx) * second, b.dy + (d.dy - b.dy) * second);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = LuxPalette.champagneDeep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t;
}

class _Status extends StatelessWidget {
  const _Status({this.error, required this.onRetry});
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error == null) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: LuxPalette.champagne),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('No pudimos cargar tu reserva', style: displayText(size: 28, weight: FontWeight.w400)),
        const SizedBox(height: 8),
        Text(error!, textAlign: TextAlign.center, style: bodyText(size: 13, color: LD.ink3)),
        const SizedBox(height: 16),
        TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    );
  }
}
