part of '../home_web_page.dart';

// ============================================================
// Marquee Bar
// ============================================================

class _MarqueeBar extends StatefulWidget {
  const _MarqueeBar();

  @override
  State<_MarqueeBar> createState() => _MarqueeBarState();
}

class _MarqueeBarState extends State<_MarqueeBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static List<String> _items(AppLocalizations l) => [
    l.homeMarqueeFixedPrices, l.homePromiseVerifiedTitle, l.homePromiseCancelTitle,
    l.homeMarqueeBookInMinutes, l.homeMarqueePremiumFleet, l.homePromiseTrackingTitle,
    l.homeMarqueeAirportTransfers, l.homeMarqueeCorporateTravel, l.homeMarqueeFreeWait,
    l.homeMarqueeHourly,
  ];

  static final _style = TextStyle(
    fontFamily: kSans, fontSize: 9, fontWeight: FontWeight.w300,
    letterSpacing: 3.0,
    color: Colors.white.withAlpha(70),
    decoration: TextDecoration.none,
  );
  static const _gap = 24.0 + 3.0 + 24.0; // spacer + dot + spacer

  /// Width of one full set of items, so the loop is seamless whatever the
  /// language (translations change the text lengths).
  double _setWidth(BuildContext context, List<String> items) {
    final scaler = MediaQuery.textScalerOf(context);
    var total = 0.0;
    for (final item in items) {
      final tp = TextPainter(
        text: TextSpan(text: item, style: _style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      total += tp.width + _gap;
      tp.dispose();
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 36))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final items = _items(context.l10n).map((t) => t.toUpperCase()).toList();
    final oneSetPx = _setWidth(context, items);
    return Container(
        height: 40, color: LD.dark,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => OverflowBox(
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(-_ctrl.value * oneSetPx, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int r = 0; r < 3; r++)
                    for (int i = 0; i < items.length; i++) ...[
                      Text(items[i], maxLines: 1, softWrap: false, style: _style),
                      const SizedBox(width: 24),
                      Container(
                        width: 3, height: 3,
                        decoration: const BoxDecoration(color: LD.accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }
}
