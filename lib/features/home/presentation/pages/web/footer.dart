part of '../home_web_page.dart';

// ============================================================
// Footer
// ============================================================

class _FooterSection extends StatelessWidget {
  const _FooterSection({
    required this.onFleet,
    required this.onServices,
    required this.onBusiness,
  });
  final VoidCallback onFleet;
  final VoidCallback onServices;
  final VoidCallback onBusiness;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final l = context.l10n;
    final links = [
      (l.homeNavServices,   onServices),
      (l.homeNavFleet,      onFleet),
      (l.homeFooterContact, () => context.push('/contacto')),
      (l.homeFooterTerms,   () => context.push('/terminos')),
      (l.homeFooterPrivacy, () => context.push('/privacidad')),
    ];

    return Container(
      color: const Color(0xFF03050A),
      child: Stack(children: [
        // Sapphire top line (40% opacity)
        Positioned(top: 0, left: 0, right: 0,
          child: Container(height: 1, color: LD.accent.withAlpha(102))),
        Padding(
          padding: EdgeInsets.fromLTRB(narrow ? 24 : 48, 60, narrow ? 24 : 48, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(children: [
                // Logo (35% opacity)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withAlpha(90), width: 1.5),
                    ),
                    child: Center(
                      child: Text('L', style: TextStyle(
                        fontFamily: kSerif, fontSize: 15, fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(90),
                        decoration: TextDecoration.none,
                      )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('LUXELANE', style: TextStyle(
                    fontFamily: kSans, fontSize: 12, fontWeight: FontWeight.w600,
                    letterSpacing: 3.0,
                    color: Colors.white.withAlpha(90),
                    decoration: TextDecoration.none,
                  )),
                ]),
                const SizedBox(height: 28),
                // Tappable nav links — wrap on narrow
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 0,
                  runSpacing: 8,
                  children: links.map((link) => GestureDetector(
                    onTap: link.$2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(link.$1.toUpperCase(), style: TextStyle(
                          fontFamily: kSans, fontSize: 9.5, fontWeight: FontWeight.w400,
                          letterSpacing: 2.5,
                          color: Colors.white.withAlpha(71),
                          decoration: TextDecoration.none,
                        )),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 28),
                Text(l.homeFooterCopyright('${DateTime.now().year}'),
                    textAlign: TextAlign.center, style: TextStyle(
                  fontFamily: kSans, fontSize: 9.5, fontWeight: FontWeight.w300,
                  letterSpacing: 1.0,
                  color: Colors.white.withAlpha(38),
                  decoration: TextDecoration.none,
                )),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
