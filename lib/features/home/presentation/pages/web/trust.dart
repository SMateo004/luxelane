part of '../home_web_page.dart';

// ============================================================
// Trust Section — the Luxelane promise + how it works.
// Only commitments the product actually enforces are listed here
// (server-fixed prices, free cancellation before the ride, verified
// chauffeurs, live tracking). Never add unverified reviews.
// ============================================================

class _TrustSection extends StatelessWidget {
  const _TrustSection({required this.onBook});
  final VoidCallback onBook;

  static List<({IconData icon, String title, String body})> _promises(AppLocalizations l) => [
    (
      icon: Icons.lock_outline,
      title: l.homePromiseFixedPriceTitle,
      body: l.homePromiseFixedPriceBody(
          WaitingPolicy.airportFreeMinutes, WaitingPolicy.cityFreeMinutes),
    ),
    (
      icon: Icons.event_available_outlined,
      title: l.homePromiseCancelTitle,
      body: l.homePromiseCancelBody,
    ),
    (
      icon: Icons.verified_user_outlined,
      title: l.homePromiseVerifiedTitle,
      body: l.homePromiseVerifiedBody,
    ),
    (
      icon: Icons.near_me_outlined,
      title: l.homePromiseTrackingTitle,
      body: l.homePromiseTrackingBody,
    ),
  ];

  static List<({String title, String body})> _steps(AppLocalizations l) => [
    (title: l.homeStepBookTitle, body: l.homeStepBookBody),
    (title: l.homeStepPriceTitle, body: l.homeStepPriceBody),
    (title: l.homeStepChauffeurTitle, body: l.homeStepChauffeurBody),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 900;
    final gutter = narrow ? 20.0 : 48.0;
    final l = context.l10n;
    final promises = _promises(l);
    final steps = _steps(l);

    return Container(
      color: LD.bg,
      padding:
          EdgeInsets.symmetric(vertical: narrow ? 72 : 112, horizontal: gutter),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RevealOnScroll(
                  child: Text(l.homeTrustEyebrow.toUpperCase(), style: eyebrow())),
              const SizedBox(height: 16),
              RevealOnScroll(
                delay: const Duration(milliseconds: 80),
                child: Semantics(
                  header: true,
                  child: Text(
                    l.homeTrustTitle,
                    style: displayText(
                        size: narrow ? 40 : 60, weight: FontWeight.w400),
                  ),
                ),
              ),
              SizedBox(height: narrow ? 40 : 64),
              _Grid(
                columns: width < 600 ? 1 : (width < 1100 ? 2 : 4),
                children: [
                  for (var i = 0; i < promises.length; i++)
                    RevealOnScroll(
                      delay: Duration(milliseconds: 60 * i),
                      child: _PromiseCard(
                        icon: promises[i].icon,
                        title: promises[i].title,
                        body: promises[i].body,
                      ),
                    ),
                ],
              ),
              SizedBox(height: narrow ? 72 : 112),
              RevealOnScroll(child: Text(l.homeHowItWorksEyebrow.toUpperCase(), style: eyebrow())),
              const SizedBox(height: 32),
              _Grid(
                columns: width < 800 ? 1 : 3,
                children: [
                  for (var i = 0; i < steps.length; i++)
                    RevealOnScroll(
                      delay: Duration(milliseconds: 80 * i),
                      child: _StepTile(
                          n: '${i + 1}'.padLeft(2, '0'),
                          title: steps[i].title,
                          body: steps[i].body),
                    ),
                ],
              ),
              const SizedBox(height: 48),
              RevealOnScroll(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _TrustCta(onTap: onBook),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple responsive grid: equal-width columns, rows sized to content.
class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children});
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const gap = 24.0;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final row = children.sublist(i, (i + columns).clamp(0, children.length));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) const SizedBox(width: gap),
              Expanded(
                  child: j < row.length ? row[j] : const SizedBox.shrink()),
            ],
          ],
        ),
      ));
      if (i + columns < children.length) rows.add(const SizedBox(height: gap));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _PromiseCard extends StatelessWidget {
  const _PromiseCard(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: LD.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: LD.accentTint, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: LD.accent),
            ),
            const SizedBox(height: 24),
            Text(title, style: displayText(size: 24, weight: FontWeight.w500)),
            const SizedBox(height: 10),
            Text(body, style: bodyText(size: 14)),
          ],
        ),
      );
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.n, required this.title, required this.body});
  final String n;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: LD.accent)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n,
                style: displayText(
                    size: 34, color: LD.accent, weight: FontWeight.w400)),
            const SizedBox(height: 12),
            Text(title,
                style: bodyText(size: 16, color: LD.ink)
                    .copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(body, style: bodyText(size: 14)),
          ],
        ),
      );
}

class _TrustCta extends StatefulWidget {
  const _TrustCta({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_TrustCta> createState() => _TrustCtaState();
}

class _TrustCtaState extends State<_TrustCta> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: context.l10n.homeBookRide,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: LuxMotion.fast,
              curve: LuxMotion.curve,
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              color: _hover ? LuxPalette.champagneLight : LD.cta,
              // widthFactor keeps the button as wide as its label.
              child: Center(
                widthFactor: 1,
                child: Text(
                  context.l10n.homeBookRide.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: kSans,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                    color: LD.onCta,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
