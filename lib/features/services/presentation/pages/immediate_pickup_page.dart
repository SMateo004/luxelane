import 'package:flutter/material.dart';

import '../../../../core/design/lux_promise.dart';
import '../../../../core/widgets/lux_service_booking_card.dart';
import '../../../../l10n/l10n.dart';
import '../widgets/service_page_template.dart';

/// /servicios/recogida-inmediata
class ImmediatePickupPage extends StatelessWidget {
  const ImmediatePickupPage({super.key});

  static ServicePageContent content(AppLocalizations t) => ServicePageContent(
        mode: LuxBookingMode.immediate,
        eyebrow: t.servicesImmediateEyebrow,
        title: t.servicesImmediateTitle,
        lead: t.servicesImmediateLead,
        heroImage: 'assets/images/services/recogida/hero.jpg',
        heroFallback: 'assets/images/home/hero_bg.jpg',
        assurances: [
          LuxAssurance(
            Icons.my_location_rounded,
            t.servicesImmediateTrackingTitle,
            t.servicesImmediateTrackingDetail,
          ),
          LuxAssurance.fixedPrice,
          LuxAssurance.chauffeurs,
        ],
        steps: [
          ServiceStep(
            t.servicesImmediateStep1Title,
            t.servicesImmediateStep1Body,
          ),
          ServiceStep(
            t.servicesImmediateStep2Title,
            t.servicesImmediateStep2Body,
          ),
          ServiceStep(
            t.servicesImmediateStep3Title,
            t.servicesImmediateStep3Body,
          ),
        ],
        storyEyebrow: t.servicesImmediateStoryEyebrow,
        storyTitle: t.servicesImmediateStoryTitle,
        storyBody: t.servicesImmediateStoryBody,
        storyPoints: [
          t.servicesImmediateStoryPoint1,
          t.servicesImmediateStoryPoint2,
          t.servicesImmediateStoryPoint3,
        ],
        storyImage: 'assets/images/services/recogida/story.jpg',
        storyFallback: 'assets/images/home/promise_photo.jpg',
        faqs: [
          ServiceFaq(
            t.servicesImmediateFaq1Question,
            t.servicesImmediateFaq1Answer,
          ),
          ServiceFaq(
            t.servicesImmediateFaq2Question,
            t.servicesImmediateFaq2Answer,
          ),
          ServiceFaq(
            t.servicesImmediateFaq3Question,
            t.servicesImmediateFaq3Answer,
          ),
          ServiceFaq(
            t.servicesImmediateFaq4Question,
            t.servicesImmediateFaq4Answer,
          ),
        ],
        closingTitle: t.servicesImmediateClosingTitle,
        closingBody: t.servicesImmediateClosingBody,
      );

  @override
  Widget build(BuildContext context) =>
      ServicePageTemplate(content: content(context.l10n));
}
