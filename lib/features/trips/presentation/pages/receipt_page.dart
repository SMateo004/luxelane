import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/lux_states.dart';
import '../../../home/presentation/pages/home_design.dart';

/// In-app receipt for a completed (or cancelled) trip.
class ReceiptPage extends StatefulWidget {
  const ReceiptPage({super.key, required this.bookingId, this.booking});

  final String bookingId;
  final Booking? booking;

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  Booking? _booking;
  String? _error;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    if (_booking == null) _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final result = await sl<BookingRepository>().getBookingById(widget.bookingId);
    if (!mounted) return;
    result.fold(
      (f) => setState(() => _error = f.message),
      (b) => setState(() => _booking = b),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    return Scaffold(
      backgroundColor: LD.bg2,
      appBar: AppBar(
        backgroundColor: LD.bg2,
        foregroundColor: LD.ink,
        title: const Text('Recibo'),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.canPop() ? context.pop() : context.go('/trips'),
        ),
      ),
      body: booking == null
          ? (_error != null
              ? LuxErrorState(light: true, message: _error!, onRetry: _load)
              : const Center(child: CircularProgressIndicator(color: LuxPalette.champagne)))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _ReceiptCard(booking: booking),
                ),
              ),
            ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.booking});
  final Booking booking;

  String get _code => booking.id.substring(0, booking.id.length.clamp(0, 8)).toUpperCase();

  String get _plainText {
    final f = DateFormat("d 'de' MMMM yyyy, HH:mm", 'es');
    final total = booking.finalPrice ?? booking.estimatedPrice;
    return [
      'Luxelane — Recibo $_code',
      f.format(booking.scheduledAt),
      '${booking.vehicleClass.label} · ${booking.serviceType.label}',
      'Desde: ${booking.origin.displayName}',
      if (booking.serviceType == ServiceType.oneWay) 'Hasta: ${booking.destination.displayName}',
      'Total: ${LuxMoney.format(total, cents: true)}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final cancelled = booking.status == BookingStatus.cancelled;
    final total = booking.finalPrice ?? booking.estimatedPrice;
    final date = DateFormat("EEEE d 'de' MMMM yyyy · HH:mm", 'es').format(booking.scheduledAt);
    final paidByCard = booking.stripePaymentIntentId != null;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: LD.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('LUXELANE', style: uiLabel(size: 12, spacing: 3, color: LD.ink)),
              const Spacer(),
              Text('Nº $_code', style: uiLabel(spacing: 1.2)),
            ],
          ),
          const SizedBox(height: 28),
          Text(cancelled ? 'RESERVA CANCELADA' : 'VIAJE COMPLETADO',
              style: eyebrow(color: cancelled ? LuxPalette.error : LD.accent)),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(
              cancelled ? 'Sin cargo' : LuxMoney.format(total, cents: true),
              style: displayText(size: 44, weight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 4),
          Text(date, style: bodyText(size: 13, color: LD.ink3)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1, color: LD.border),
          ),
          _Line('Servicio', booking.serviceType.label),
          _Line('Vehículo', booking.vehicleClass.label),
          _Line('Recogida', booking.origin.displayName),
          if (booking.serviceType == ServiceType.oneWay)
            _Line('Destino', booking.destination.displayName)
          else
            _Line('Duración', '${booking.hours ?? 2} horas'),
          if (booking.flightNumber != null) _Line('Vuelo', booking.flightNumber!),
          _Line('Pasajeros', '${booking.passengerCount}'),
          if (!cancelled) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: LD.border),
            ),
            _Line('Precio fijo', LuxMoney.format(booking.estimatedPrice, cents: true)),
            if (booking.finalPrice != null && booking.finalPrice != booking.estimatedPrice)
              _Line('Ajuste', LuxMoney.format(booking.finalPrice! - booking.estimatedPrice, cents: true)),
            _Line('Total', LuxMoney.format(total, cents: true), strong: true),
            _Line('Forma de pago', paidByCard ? 'Tarjeta' : 'Pago al chófer'),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _plainText));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recibo copiado al portapapeles')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copiar recibo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: LD.accent,
                side: const BorderSide(color: LD.accent),
                shape: const RoundedRectangleBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Montos en bolivianos (BOB).',
              textAlign: TextAlign.center, style: uiLabel(spacing: 0.3)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label, style: bodyText(size: 13, color: LD.ink3).copyWith(height: 1.4)),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: bodyText(size: strong ? 16 : 13, color: LD.ink).copyWith(
                  height: 1.4,
                  fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
}
