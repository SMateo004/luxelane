import 'package:flutter/material.dart';

import '../../../../core/design/lux_promise.dart';
import '../../../../core/widgets/lux_service_booking_card.dart';
import '../widgets/service_page_template.dart';

/// /servicios/contratacion-por-horas
class HourlyCharterPage extends StatelessWidget {
  const HourlyCharterPage({super.key});

  static const content = ServicePageContent(
    mode: LuxBookingMode.hourly,
    eyebrow: 'Chófer por horas',
    title: 'Tu agenda.\nTu ritmo.\nTu chófer.',
    lead: 'Un chófer y un vehículo exclusivamente para ti, de 2 a 24 horas. '
        'Cambia de planes cuantas veces quieras: él se adapta.',
    heroImage: 'assets/images/services/por-horas/hero.jpg',
    heroFallback: 'assets/images/home/business_photo.jpg',
    assurances: [
      LuxAssurance(Icons.alt_route_rounded, 'Paradas ilimitadas',
          'Reuniones, compras o visitas: tu chófer te espera en cada parada.'),
      LuxAssurance.fixedPrice,
      LuxAssurance.chauffeurs,
      LuxAssurance.privacy,
    ],
    steps: [
      ServiceStep('Elige la duración',
          'Indica el punto de recogida, el día y cuántas horas necesitas. Mínimo 2, máximo 24.'),
      ServiceStep('Diseña tu jornada',
          'Comparte tu itinerario en las notas o decídelo sobre la marcha. No hace falta destino final.'),
      ServiceStep('Disfruta sin mirar el reloj',
          'Tu chófer y tu vehículo están a tu disposición durante todo el tiempo reservado.'),
    ],
    storyEyebrow: 'Para cada ocasión',
    storyTitle: 'Un día entero,\nsin pensar en cómo moverte.',
    storyBody:
        'Desde una agenda de reuniones hasta una tarde descubriendo la ciudad, '
        'el servicio por horas te da la libertad de un vehículo privado sin '
        'ninguna de sus preocupaciones.',
    storyPoints: [
      'Viajes de negocios: de reunión en reunión, sin esperas',
      'Eventos y cenas: llegada impecable, salida sin prisas',
      'Turismo privado: la ciudad a tu ritmo, con un chófer local',
      'Compras y ocio: tu chófer guarda tus bolsas y te espera',
    ],
    storyImage: 'assets/images/services/por-horas/story.jpg',
    storyFallback: 'assets/images/home/immersive_bg.jpg',
    faqs: [
      ServiceFaq('¿Cómo reservo un chófer por horas?',
          'Selecciona el lugar de recogida, la duración, el día y la hora. Después elige la clase de vehículo y confirma. Verás el precio final antes de pagar.'),
      ServiceFaq('¿Puedo cambiar el itinerario durante el servicio?',
          'Sí. El chófer y el vehículo están a tu disposición durante todas las horas reservadas, con tantas paradas como necesites.'),
      ServiceFaq('¿Puedo ampliar el número de horas?',
          'Sí, puedes modificar la reserva antes de la hora de inicio. La duración mínima es de 2 horas y la máxima de 24.'),
      ServiceFaq('¿Puede empezar o terminar en un aeropuerto?',
          'Sí. El servicio puede empezar o terminar en un aeropuerto, siempre que el inicio y el final estén en la misma ciudad.'),
      ServiceFaq('¿Cuándo recibiré los datos del chófer?',
          'Antes de la recogida tendrás en la app el nombre del chófer, el vehículo y su contacto.'),
    ],
    closingTitle: 'Reserva el tiempo.\nNosotros ponemos el camino.',
    closingBody:
        'Desde 2 horas, con precio fijo y un chófer profesional a tu entera disposición.',
  );

  @override
  Widget build(BuildContext context) =>
      const ServicePageTemplate(content: content);
}
