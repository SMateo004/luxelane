import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/lux_states.dart';
import '../../../../l10n/l10n.dart';
import '../../../home/presentation/pages/home_design.dart';
import '../../../loyalty/presentation/loyalty_widgets.dart';

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
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    if (_booking == null) _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    final result = await sl<BookingRepository>().getBookingById(widget.bookingId);
    if (!mounted) return;
    result.fold(
      (f) {
        debugPrint('Receipt load failed: ${f.message}');
        setState(() => _failed = true);
      },
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
        title: Text(context.l10n.tripReceiptTitle),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.canPop() ? context.pop() : context.go('/trips'),
        ),
      ),
      body: booking == null
          ? (_failed
              ? LuxErrorState(light: true, message: context.l10n.commonConnectionError, onRetry: _load)
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

  /// Copyable receipt, in the current app language.
  String _plainText(AppLocalizations l) {
    final f = DateFormat.yMMMMd().add_jm();
    final total = booking.finalPrice ?? booking.estimatedPrice;
    return [
      l.tripReceiptPlainHeader(_code),
      f.format(booking.scheduledAt),
      '${booking.vehicleClass.localizedLabel(l)} · ${booking.serviceType.localizedLabel(l)}',
      l.tripReceiptPlainFrom(booking.origin.displayName),
      if (booking.serviceType == ServiceType.oneWay) l.tripReceiptPlainTo(booking.destination.displayName),
      l.tripReceiptPlainTotal(LuxMoney.format(total, cents: true)),
      if (booking.isCorporate) l.corpBilledTo(booking.companyName ?? ''),
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final cancelled = booking.status == BookingStatus.cancelled;
    final total = booking.finalPrice ?? booking.estimatedPrice;
    final l = context.l10n;
    final date = '${DateFormat.yMMMMEEEEd().format(booking.scheduledAt)} · '
        '${DateFormat.jm().format(booking.scheduledAt)}';
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
              const SizedBox(width: 8),
              Text(l.tripReceiptNumber(_code), style: uiLabel(spacing: 1.2)),
            ],
          ),
          const SizedBox(height: 28),
          Text(cancelled ? l.tripReceiptCancelled : l.tripReceiptCompleted,
              style: eyebrow(color: cancelled ? LuxPalette.error : LD.accent)),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(
              cancelled ? l.tripReceiptNoCharge : LuxMoney.format(total, cents: true),
              style: displayText(size: 44, weight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 4),
          Text(date, style: bodyText(size: 13, color: LD.ink3)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1, color: LD.border),
          ),
          _Line(l.tripReceiptService, booking.serviceType.localizedLabel(l)),
          _Line(l.tripReceiptVehicle, booking.vehicleClass.localizedLabel(l)),
          _Line(l.tripPickup, booking.origin.displayName),
          if (booking.serviceType == ServiceType.oneWay)
            _Line(l.tripDestination, booking.destination.displayName)
          else
            _Line(
                l.tripReceiptDuration,
                booking.days > 1
                    ? l.bookingDaysSummary(booking.days, booking.hours ?? 2)
                    : l.unitHours(booking.hours ?? 2)),
          if (booking.flightNumber != null) _Line(l.tripReceiptFlight, booking.flightNumber!),
          _Line(l.tripReceiptPassengers, '${booking.passengerCount}'),
          if (!cancelled) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: LD.border),
            ),
            if (booking.discount > 0 && booking.baseAmount != null) ...[
              _Line(l.tripReceiptFixedPrice, LuxMoney.format(booking.baseAmount!, cents: true)),
              _Line(
                  booking.loyaltyTier != null
                      ? l.loyaltyDiscountLine(loyaltyTierName(l, booking.loyaltyTier) ?? '')
                      : l.promoDiscountLine(booking.promoCode ?? ''),
                  '−${LuxMoney.format(booking.discount, cents: true)}'),
            ] else
              _Line(l.tripReceiptFixedPrice, LuxMoney.format(booking.estimatedPrice, cents: true)),
            if (booking.finalPrice != null && booking.finalPrice != booking.estimatedPrice)
              _Line(l.tripReceiptAdjustment, LuxMoney.format(booking.finalPrice! - booking.estimatedPrice, cents: true)),
            _Line(l.tripReceiptTotal, LuxMoney.format(total, cents: true), strong: true),
            _Line(
                l.tripReceiptPaymentMethod,
                booking.isCorporate
                    ? l.corpBilledTo(booking.companyName ?? '')
                    : paidByCard ? l.tripReceiptCard : l.tripReceiptPayChauffeur),
            if (booking.costCenter != null) _Line(l.corpCostCenter, booking.costCenter!),
            if (booking.billingReference != null) _Line(l.corpReference, booking.billingReference!),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _plainText(l)));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.tripReceiptCopied)),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(l.tripReceiptCopy),
              style: OutlinedButton.styleFrom(
                foregroundColor: LD.accent,
                side: const BorderSide(color: LD.accent),
                shape: const RoundedRectangleBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.push('/ayuda?booking=${booking.id}'),
            icon: const Icon(Icons.support_agent_outlined, size: 18, color: LD.accent),
            label: Text(l.supportTripHelpCta, style: const TextStyle(color: LD.accent)),
          ),
          const SizedBox(height: 4),
          Text(l.tripReceiptCurrencyNote,
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
              width: 128,
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
