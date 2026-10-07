import 'package:flutter/material.dart';

import '../../../../core/design/lux_promise.dart';
import '../../../../core/widgets/lux_service_booking_card.dart';
import '../widgets/service_page_template.dart';

/// /servicios/recogida-inmediata
class ImmediatePickupPage extends StatelessWidget {
  const ImmediatePickupPage({super.key});

  static const content = ServicePageContent(
    mode: LuxBookingMode.immediate,
    eyebrow: 'Recogida inmediata',
    title: 'Cuando lo\nnecesites.\nEn minutos.',
    lead: 'Un chófer profesional en camino en cuanto confirmas. '
        'La misma excelencia de una reserva anticipada, sin planificar.',
    heroImage: 'assets/images/services/recogida/hero.jpg',
    heroFallback: 'assets/images/home/hero_bg.png',
    assurances: [
      LuxAssurance(Icons.bolt_rounded, 'Chófer en camino al instante',
          'Asignamos al chófer disponible más cercano en cuanto confirmas.'),
      LuxAssurance(Icons.my_location_rounded, 'Seguimiento en tiempo real',
          'Ve en el mapa dónde está tu chófer y cuándo llega.'),
      LuxAssurance.fixedPrice,
      LuxAssurance.chauffeurs,
    ],
    steps: [
      ServiceStep('Indica origen y destino',
          'Escribe la dirección o elígela en el mapa. Verás el precio final antes de confirmar.'),
      ServiceStep('Confirma con un toque',
          'Asignamos un chófer de inmediato y te mostramos su nombre, vehículo y hora de llegada.'),
      ServiceStep('Síguelo en el mapa',
          'Recibe un aviso cuando tu chófer esté en camino y otro cuando haya llegado.'),
    ],
    storyEyebrow: 'Sin planificar',
    storyTitle: 'Lo imprevisto,\ncon la misma elegancia.',
    storyBody: 'Una reunión que se alarga, un cambio de planes, una cena que '
        'merece un final a la altura. La recogida inmediata pone un vehículo '
        'premium y un chófer profesional a tu alcance, en minutos.',
    storyPoints: [
      'Vehículos premium, impecables en cada servicio',
      'Chóferes verificados y formados en atención discreta',
      'Precio fijo calculado antes de confirmar, sin tarifas dinámicas',
      'Atención al cliente 24/7 durante todo el trayecto',
    ],
    storyImage: 'assets/images/services/recogida/story.jpg',
    storyFallback: 'assets/images/home/promise_photo.jpg',
    faqs: [
      ServiceFaq('¿Cuánto tarda en llegar el chófer?',
          'Depende de tu ubicación y de la disponibilidad. Verás la hora estimada de llegada antes de confirmar y podrás seguir al chófer en el mapa.'),
      ServiceFaq('¿El precio cambia según la demanda?',
          'No. El precio se fija antes de confirmar y no cambia: sin tarifas dinámicas ni cargos ocultos.'),
      ServiceFaq('¿Puedo programar el viaje para más tarde?',
          'Sí. Elige "Programar" en el formulario y selecciona el día y la hora que prefieras.'),
      ServiceFaq('¿Qué pasa si necesito cancelar?',
          'Puedes cancelar desde la app. Las reservas programadas se cancelan sin coste hasta 1 hora antes de la recogida.'),
    ],
    closingTitle: 'Tu chófer,\na un toque.',
    closingBody:
        'Confirma ahora y sigue a tu chófer en tiempo real hasta la puerta.',
  );

  @override
  Widget build(BuildContext context) =>
      const ServicePageTemplate(content: content);
}
