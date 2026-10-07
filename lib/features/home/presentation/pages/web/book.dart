part of '../home_web_page.dart';

// ============================================================
// Book Section — scroll-driven 3D page-flip portfolio showcase
// ============================================================

@immutable
class _BookPageData {
  const _BookPageData({
    required this.num,
    required this.label,
    required this.sub,
    this.photoPath,
    this.carPath,
    required this.tag,
    required this.headline,
    required this.body,
    required this.bullets,
  });
  final String num;
  final String label;
  final String sub;
  final String? photoPath;
  final String? carPath;
  final String tag;
  final String headline;
  final String body;
  final List<String> bullets;
}

List<_BookPageData> _bookPages(AppLocalizations l) {
  final cover = _BookPageData(
    num: '', label: 'LUXELANE', sub: l.homeBookCoverSubtitle,
    tag: '', headline: '', body: '', bullets: const [],
  );
  return [
    // Index 0: Cover (portada) — special: left=back cover, right=logo
    cover,
    // Index 1: The standard (content page 01)
    _BookPageData(
      num: '01', label: l.homeBookStandardLabel, sub: l.homeBookStandardSub,
      photoPath: 'assets/images/home/promise_photo.jpg',
      tag: l.homeBookStandardTag, headline: l.homeBookStandardHeadline,
      body: l.homeBookStandardBody,
      bullets: [l.homePromiseVerifiedTitle, l.homeBookBulletFixedPrice, l.homeBookBulletTracking, l.homeBookBulletAdvance],
    ),
    // Index 2: The experience (content page 02)
    _BookPageData(
      num: '02', label: l.homeBookExperienceLabel, sub: l.homeBookExperienceSub,
      photoPath: 'assets/images/home/immersive_bg.jpg',
      tag: l.homeBookExperienceLabel, headline: l.homeBookExperienceHeadline,
      body: l.homeBookExperienceBody,
      bullets: [l.homeBookBulletLeather, l.homeBookBulletWifiCharging, l.homeBookBulletChampagne, l.homeBookBulletClimate],
    ),
    // Index 3: For business (content page 03)
    _BookPageData(
      num: '03', label: l.homeBusinessEyebrow, sub: l.homeBookBusinessSub,
      photoPath: 'assets/images/home/business_photo.jpg',
      tag: l.homeBusinessEyebrow, headline: l.homeBusinessTitle,
      body: l.homeBusinessBody,
      bullets: [l.homeBookBulletCentralBilling, l.homeBusinessPerkAccountManager, l.homeBookBulletPolicy, l.homeBusinessPerkPriority],
    ),
    // Index 4: Back to cover (cierre del libro)
    cover,
  ];
}

class _BookSection extends StatefulWidget {
  const _BookSection();

  @override
  State<_BookSection> createState() => _BookSectionState();
}

class _BookSectionState extends State<_BookSection> {
  final _sectionKey = GlobalKey();
  double? _absoluteTop; // measured once, then all math is pure scroll arithmetic
  static const _numPages = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    LuxScrollProvider.of(context); // register dependency for scroll-driven rebuilds
    // Measure absolute top only once (before sticky kicks in)
    if (_absoluteTop == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureOnce());
    }
  }

  void _measureOnce() {
    if (!mounted || _absoluteTop != null) return;
    final box = _sectionKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final notifier = LuxScrollProvider.of(context);
    final scrollY  = notifier?.scrollY ?? 0.0;
    // absoluteTop = scroll offset + relative-to-viewport position
    setState(() => _absoluteTop = scrollY + box.localToGlobal(Offset.zero).dy);
  }

  @override
  Widget build(BuildContext context) {
    // Re-register dependency so we rebuild on every scroll tick
    final scrollY  = LuxScrollProvider.of(context)?.scrollY ?? 0.0;
    final screenH  = MediaQuery.sizeOf(context).height;
    final w        = MediaQuery.sizeOf(context).width;
    final isMobile = w < 800;
    final l        = context.l10n;

    // Pure arithmetic from scroll position — no post-frame callback, no jitter
    final double progress;
    final double stickyOffset;
    if (_absoluteTop == null) {
      progress     = 0;
      stickyOffset = 0;
    } else {
      final raw = (scrollY - _absoluteTop!) / screenH;
      progress     = raw.clamp(0.0, _numPages.toDouble());
      stickyOffset = (scrollY - _absoluteTop!).clamp(0.0, (_numPages - 1) * screenH);
    }

    final pageIdx   = progress.floor().clamp(0, _numPages - 1);
    final t         = progress % 1.0;
    // Smooth cubic-out ease — no jitter at page boundaries
    final eased     = 1 - math.pow(1 - t, 3).toDouble();
    final flipAngle = eased * math.pi;

    return SizedBox(
      key: _sectionKey,
      height: screenH * _numPages,
      child: Stack(clipBehavior: Clip.none, children: [
        Transform.translate(
          offset: Offset(0, stickyOffset),
          child: SizedBox(
            height: screenH,
            child: Container(
              color: LD.dark,
              child: Stack(children: [
                // Radial champagne glow
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, 0.3), radius: 0.85,
                        colors: [LD.accent.withAlpha(70), Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // Eyebrow
                Positioned(top: 44, left: 0, right: 0,
                  child: Center(child: Text(l.homeBookEyebrow.toUpperCase(),
                    style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w500,
                      letterSpacing: 4.0, color: LD.accent.withAlpha(200),
                      decoration: TextDecoration.none)))),

                // Book
                Center(
                  child: _BookWidget(
                    pages: _bookPages(l), currentPage: pageIdx,
                    flipAngle: flipAngle, isMobile: isMobile,
                  ),
                ),

                // Page dots — only show content pages (1, 2, 3)
                Positioned(bottom: 30, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final contentPageIdx = i + 1; // content pages are at indices 1, 2, 3
                      final active = pageIdx == contentPageIdx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: active ? 7.5 : 5, height: active ? 7.5 : 5,
                        decoration: BoxDecoration(
                          color: active ? LD.accent : LD.accent.withAlpha(70),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  )),

                // Scroll cue
                Positioned(right: 44, top: 0, bottom: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: progress < 0.2 ? 0.4 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 1, height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [LD.accent, Colors.transparent],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        RotatedBox(quarterTurns: 1,
                          child: Text(l.homeBookScrollCue.toUpperCase(),
                            style: GoogleFonts.montserrat(fontSize: 7.5, fontWeight: FontWeight.w500,
                              letterSpacing: 3.5, color: LD.accent,
                              decoration: TextDecoration.none))),
                      ]),
                    ),
                  )),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _BookWidget extends StatelessWidget {
  const _BookWidget({
    super.key,
    required this.pages,
    required this.currentPage,
    required this.flipAngle,
    required this.isMobile,
  });

  final List<_BookPageData> pages;
  final int currentPage;
  final double flipAngle;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final w     = MediaQuery.sizeOf(context).width;
    final bookW = isMobile ? w - 40 : math.min(w - 160, 1080.0);
    final bookH = isMobile ? bookW * 0.75 : bookW * 0.56;

    final current  = pages[currentPage];
    final next     = pages[(currentPage + 1) % pages.length];
    final leafFront = flipAngle < math.pi / 2;
    final showLeaf  = flipAngle > 0.005;

    return SizedBox(
      width: bookW, height: bookH,
      child: Stack(children: [
        // Left panel
        Positioned(left: 0, top: 0, bottom: 0, width: bookW / 2,
          child: _BookLeftPanel(data: current, height: bookH, isMobile: isMobile)),

        // Right panel
        Positioned(right: 0, top: 0, bottom: 0, width: bookW / 2,
          child: _BookRightPanel(data: leafFront ? current : next, isMobile: isMobile)),

        // Spine (10px, matches .book-spine)
        Positioned(left: bookW / 2 - 5, top: 0, bottom: 0, width: 10,
          child: Stack(children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF040A12), Color(0xFF1B3050), Color(0xFF040A12)],
                ),
              ),
            ),
            Center(
              child: FractionallySizedBox(
                heightFactor: 0.64,
                child: Container(
                  width: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, LD.accent.withAlpha(180), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ])),

        // Flipping leaf
        if (showLeaf)
          Positioned(right: 0, top: 0, bottom: 0, width: bookW / 2,
            child: Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(-flipAngle),
              child: ClipRect(
                child: leafFront
                    ? _BookRightPanel(data: current, isMobile: isMobile)
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(math.pi),
                        child: _BookLeftPanel(data: next, height: bookH, isMobile: isMobile),
                      ),
              ),
            )),

        // Gloss sheen
        if (showLeaf)
          Positioned(right: 0, top: 0, bottom: 0, width: bookW / 2,
            child: IgnorePointer(
              child: Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(-flipAngle),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withAlpha((math.sin(flipAngle.abs()) * 55).round()),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ]),
    );
  }
}

class _BookLeftPanel extends StatelessWidget {
  const _BookLeftPanel({super.key, required this.data, required this.height, required this.isMobile});
  final _BookPageData data;
  final double height;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final pad = isMobile ? 20.0 : 36.0;
    // Back cover: dark with minimal branding
    if (data.headline.isEmpty) {
      return ClipRect(
        child: Container(
          color: const Color(0xFF04090F),
          child: Stack(children: [
            Positioned(bottom: 40, left: 0, right: 0,
              child: Center(child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: LD.accent.withAlpha(60), width: 1),
                ),
                child: Center(child: Text('L', style: GoogleFonts.cormorantGaramond(
                  fontSize: 22, fontWeight: FontWeight.w400,
                  color: LD.accent.withAlpha(80), decoration: TextDecoration.none,
                ))),
              ))),
          ]),
        ),
      );
    }
    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          gradient: data.photoPath == null
              ? const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF060E1A), Color(0xFF18233A), Color(0xFF060E1A)],
                  stops: [0, 0.55, 1])
              : null,
          image: data.photoPath != null
              ? DecorationImage(image: AssetImage(data.photoPath!), fit: BoxFit.cover, onError: (_, __) {})
              : null,
        ),
        child: Stack(children: [
          // Photo dark overlay
          if (data.photoPath != null)
            Positioned.fill(child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xFF0B1220).withAlpha(122)),
            )),

          // Ghost page number
          Positioned(bottom: -10, right: -6,
            child: Text(data.num,
              style: GoogleFonts.cormorantGaramond(
                fontSize: isMobile ? 100 : 180, fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(6), height: 1,
                decoration: TextDecoration.none))),

          // Car PNG (page 0)
          if (data.carPath != null)
            Positioned(bottom: 48, left: 0, right: 0, height: isMobile ? 100 : 180,
              child: Image.asset(data.carPath!, fit: BoxFit.contain, alignment: Alignment.bottomCenter,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink())),

          // Deco label top-left
          Positioned(top: pad, left: pad, right: pad,
            child: Row(children: [
              Container(width: 24, height: 1, color: LD.accent.withAlpha(180)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(data.label.toUpperCase(),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w500,
                    letterSpacing: 3.0, color: LD.accent.withAlpha(200),
                    decoration: TextDecoration.none)),
              ),
            ])),

          // Caption strip
          Positioned(bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(pad, 28, pad, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [const Color(0xFF040A12).withAlpha(230), Colors.transparent],
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('— ${data.num}',
                  style: GoogleFonts.cormorantGaramond(fontSize: 10, fontWeight: FontWeight.w400,
                    letterSpacing: 3.0, color: LD.accent, decoration: TextDecoration.none)),
                const SizedBox(height: 5),
                Text(data.sub,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic, color: Colors.white.withAlpha(140),
                    decoration: TextDecoration.none)),
              ]),
            )),
        ]),
      ),
    );
  }
}

class _BookRightPanel extends StatelessWidget {
  const _BookRightPanel({super.key, required this.data, required this.isMobile});
  final _BookPageData data;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final hPad = isMobile ? 24.0 : 56.0;
    final vPad = isMobile ? 24.0 : 52.0;
    // Front cover: clean white page with centered logo
    if (data.headline.isEmpty) {
      return Container(
        color: const Color(0xFFFAF8F4),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  border: Border.all(color: LD.ink, width: 1.5),
                ),
                child: Center(child: Text('L', style: GoogleFonts.cormorantGaramond(
                  fontSize: 36, fontWeight: FontWeight.w400,
                  color: LD.ink, decoration: TextDecoration.none,
                ))),
              ),
              const SizedBox(height: 20),
              Text('LUXELANE', style: GoogleFonts.montserrat(
                fontSize: 13, fontWeight: FontWeight.w600,
                letterSpacing: 5.0, color: LD.ink,
                decoration: TextDecoration.none,
              )),
              const SizedBox(height: 10),
              Text(data.sub, textAlign: TextAlign.center, style: GoogleFonts.cormorantGaramond(
                fontSize: 14, fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic, color: LD.ink3,
                decoration: TextDecoration.none,
              )),
            ],
          ),
        ),
      );
    }
    return Container(
      color: const Color(0xFFFAF8F4),
      child: Stack(children: [
        // Ghost number
        Positioned(bottom: -12, right: -8,
          child: Text(data.num,
            style: GoogleFonts.cormorantGaramond(
              fontSize: isMobile ? 100 : 180, fontWeight: FontWeight.w600,
              color: LD.accent.withAlpha(10), height: 1,
              decoration: TextDecoration.none))),

        // Content — scaled down (never clipped) when a translation runs long
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
          child: LayoutBuilder(builder: (context, box) => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: box.maxWidth,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data.tag,
              style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w500,
                letterSpacing: 3.5, color: LD.accent, decoration: TextDecoration.none)),
            const SizedBox(height: 22),
            Text(data.headline,
              style: GoogleFonts.cormorantGaramond(
                fontSize: isMobile ? 26 : 42, fontWeight: FontWeight.w300, height: 1.06,
                color: LD.ink, letterSpacing: -0.01 * (isMobile ? 26 : 42),
                decoration: TextDecoration.none)),
            const SizedBox(height: 20),
            Text(data.body,
              style: GoogleFonts.montserrat(
                fontSize: isMobile ? 12 : 12.5, fontWeight: FontWeight.w300,
                height: 1.9, color: LD.ink2, decoration: TextDecoration.none)),
            const SizedBox(height: 24),
            ...data.bullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(width: 18, height: 1, color: LD.accent, margin: const EdgeInsets.only(right: 14)),
                Expanded(child: Text(b,
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 11 : 11.5, fontWeight: FontWeight.w400,
                    letterSpacing: 0.02 * (isMobile ? 11 : 11.5),
                    color: LD.ink2, decoration: TextDecoration.none))),
              ]),
            )),
              ]),
            ),
          )),
        ),
      ]),
    );
  }
}
