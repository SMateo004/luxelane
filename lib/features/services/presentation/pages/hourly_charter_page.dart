import 'package:flutter/material.dart';

import '../../../../core/design/lux_promise.dart';
import '../../../../core/widgets/lux_service_booking_card.dart';
import '../../../../l10n/l10n.dart';
import '../widgets/service_page_template.dart';

/// /servicios/contratacion-por-horas
class HourlyCharterPage extends StatelessWidget {
  const HourlyCharterPage({super.key});

  static ServicePageContent content(AppLocalizations t) => ServicePageContent(
        mode: LuxBookingMode.hourly,
        eyebrow: t.servicesHourlyEyebrow,
        title: t.servicesHourlyTitle,
        lead: t.servicesHourlyLead,
        heroImage: 'assets/images/services/por-horas/hero.jpg',
        heroFallback: 'assets/images/home/business_photo.jpg',
        assurances: [
          LuxAssurance(
            Icons.alt_route_rounded,
            t.servicesHourlyStopsTitle,
            t.servicesHourlyStopsDetail,
          ),
          LuxAssurance.fixedPrice,
          LuxAssurance.chauffeurs,
        ],
        steps: [
          ServiceStep(t.servicesHourlyStep1Title, t.servicesHourlyStep1Body),
          ServiceStep(t.servicesHourlyStep2Title, t.servicesHourlyStep2Body),
          ServiceStep(t.servicesHourlyStep3Title, t.servicesHourlyStep3Body),
        ],
        storyEyebrow: t.servicesHourlyStoryEyebrow,
        storyTitle: t.servicesHourlyStoryTitle,
        storyBody: t.servicesHourlyStoryBody,
        storyPoints: [
          t.servicesHourlyStoryPoint1,
          t.servicesHourlyStoryPoint2,
          t.servicesHourlyStoryPoint3,
          t.servicesHourlyStoryPoint4,
        ],
        storyImage: 'assets/images/services/por-horas/story.jpg',
        storyFallback: 'assets/images/home/immersive_bg.jpg',
        faqs: [
          ServiceFaq(t.servicesHourlyFaq1Question, t.servicesHourlyFaq1Answer),
          ServiceFaq(t.servicesHourlyFaq2Question, t.servicesHourlyFaq2Answer),
          ServiceFaq(t.servicesHourlyFaq3Question, t.servicesHourlyFaq3Answer),
          ServiceFaq(t.servicesHourlyFaq4Question, t.servicesHourlyFaq4Answer),
          ServiceFaq(t.servicesHourlyFaq5Question, t.servicesHourlyFaq5Answer),
        ],
        closingTitle: t.servicesHourlyClosingTitle,
        closingBody: t.servicesHourlyClosingBody,
      );

  @override
  Widget build(BuildContext context) =>
      ServicePageTemplate(content: content(context.l10n));
}
