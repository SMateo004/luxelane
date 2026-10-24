import 'package:flutter/material.dart';

import '../../features/home/presentation/pages/home_design.dart';
import 'lux_site_chrome.dart';

/// Página de contenido del sitio (legales, empresas…): barra del sitio,
/// título sobre fondo oscuro, cuerpo claro centrado y pie.
class LuxInfoPage extends StatelessWidget {
  const LuxInfoPage({
    super.key,
    required this.eyebrow,
    required this.title,
    this.lead,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String? lead;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final pad = narrow ? 24.0 : 56.0;
    return Scaffold(
      backgroundColor: LD.bg,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: LD.dark,
                  padding: EdgeInsets.fromLTRB(
                    pad,
                    kSiteNavHeight + (narrow ? 40 : 72),
                    pad,
                    48,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LuxEyebrow(eyebrow, color: const Color(0xFF8CB2E3)),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            style: displayText(
                              size: narrow ? 38 : 56,
                              color: Colors.white,
                            ),
                          ),
                          if (lead != null) ...[
                            const SizedBox(height: 18),
                            Text(
                              lead!,
                              style: bodyText(
                                size: 15,
                                color: Colors.white.withAlpha(190),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, 40, pad, 72),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: child,
                    ),
                  ),
                ),
                const LuxSiteFooter(),
              ],
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LuxSiteNav(solid: true),
          ),
        ],
      ),
    );
  }
}
