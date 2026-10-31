import 'package:flutter/material.dart';

import '../../../../core/design/lux_promise.dart';
import '../../../../core/widgets/lux_service_booking_card.dart';
import '../../../../l10n/l10n.dart';
import '../widgets/service_page_template.dart';

/// /servicios/traslado-aeropuerto
class AirportTransferPage extends StatelessWidget {
  const AirportTransferPage({super.key});

  static ServicePageContent content(AppLocalizations t) => ServicePageContent(
        mode: LuxBookingMode.airport,
        eyebrow: t.servicesAirportEyebrow,
        title: t.servicesAirportTitle,
        lead: t.servicesAirportLead,
        heroImage: 'assets/images/services/aeropuerto/hero.jpg',
        heroFallback: 'assets/images/home/immersive_bg.jpg',
        assurances: const [
          LuxAssurance.fixedPrice,
          LuxAssurance.chauffeurs,
        ],
        steps: [
          ServiceStep(t.servicesAirportStep1Title, t.servicesAirportStep1Body),
          ServiceStep(t.servicesAirportStep2Title, t.servicesAirportStep2Body),
          ServiceStep(t.servicesAirportStep3Title, t.servicesAirportStep3Body),
        ],
        storyEyebrow: t.servicesAirportStoryEyebrow,
        storyTitle: t.servicesAirportStoryTitle,
        storyBody: t.servicesAirportStoryBody,
        storyPoints: [
          t.servicesAirportStoryPoint1,
          t.servicesAirportStoryPoint2,
        ],
        storyImage: 'assets/images/services/aeropuerto/arrival.jpg',
        storyFallback: 'assets/images/home/promise_photo.jpg',
        faqs: [
          ServiceFaq(
            t.servicesAirportFaq1Question,
            t.servicesAirportFaq1Answer,
          ),
          ServiceFaq(
            t.servicesAirportFaq2Question,
            t.servicesAirportFaq2Answer,
          ),
          ServiceFaq(
            t.servicesAirportFaq3Question,
            t.servicesAirportFaq3Answer,
          ),
        ],
        closingTitle: t.servicesAirportClosingTitle,
        closingBody: t.servicesAirportClosingBody,
      );

  @override
  Widget build(BuildContext context) =>
      ServicePageTemplate(content: content(context.l10n));
}
