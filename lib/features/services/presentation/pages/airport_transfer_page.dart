import 'package:flutter/material.dart';

import '../../../../core/design/lux_promise.dart';
import '../../../../core/widgets/lux_service_booking_card.dart';
import '../widgets/service_page_template.dart';

/// /servicios/traslado-aeropuerto
class AirportTransferPage extends StatelessWidget {
  const AirportTransferPage({super.key});

  static const content = ServicePageContent(
    mode: LuxBookingMode.airport,
    eyebrow: 'Traslado al aeropuerto',
    title: 'Aterriza.\nNosotros nos\nocupamos del resto.',
    lead: 'Tu chófer te espera en llegadas con tu nombre '
        'y se encarga del equipaje. Tú solo sales por la puerta.',
    heroImage: 'assets/images/services/aeropuerto/hero.jpg',
    heroFallback: 'assets/images/home/immersive_bg.jpg',
    assurances: [
      LuxAssurance.fixedPrice,
      LuxAssurance.chauffeurs,
    ],
    steps: [
      ServiceStep(
        'Reserva en 2 minutos',
        'Indica aeropuerto, destino y hora. Añade tu número de vuelo y verás el precio final al instante.',
      ),
      ServiceStep(
        'Recibe a tu chófer',
        'Antes de la recogida tendrás su nombre, vehículo y contacto en la app.',
      ),
      ServiceStep(
        'Sal y relájate',
        'Te espera en llegadas, se ocupa del equipaje y te lleva directo a tu destino.',
      ),
    ],
    storyEyebrow: 'La llegada',
    storyTitle: 'El primer momento\nde tu viaje, resuelto.',
    storyBody: 'Después de un vuelo largo, lo último que quieres son colas, '
        'negociaciones o incertidumbre. Un chófer de Luxelane convierte la '
        'llegada en una transición tranquila hacia tu hotel, tu reunión o tu casa.',
    storyPoints: [
      'Ayuda con el equipaje, de la cinta al maletero',
      'Conexiones entre aeropuertos y hoteles sin complicaciones',
    ],
    storyImage: 'assets/images/services/aeropuerto/arrival.jpg',
    storyFallback: 'assets/images/home/promise_photo.jpg',
    faqs: [
      ServiceFaq(
        '¿Dónde me espera el chófer?',
        'En la zona de llegadas. Recibirás sus datos de contacto en la app antes de la recogida.',
      ),
      ServiceFaq(
        '¿Puedo cancelar mi reserva?',
        'Sí, desde la app antes de que empiece el viaje. Si según la política de cancelación corresponde un recargo, lo verás antes de confirmar.',
      ),
      ServiceFaq(
        '¿Cuánto equipaje puedo llevar?',
        'Depende de la clase de vehículo. Si viajas con mucho equipaje o en grupo, la Business Van ofrece espacio para hasta 7 pasajeros.',
      ),
    ],
    closingTitle: 'Tu próximo vuelo\nya tiene chófer.',
    closingBody:
        'Reserva ahora. Precio fijo al reservar y chóferes con documentos verificados.',
  );

  @override
  Widget build(BuildContext context) =>
      const ServicePageTemplate(content: content);
}
