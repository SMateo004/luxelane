import 'package:flutter/material.dart';

import '../../../../core/widgets/lux_info_page.dart';
import '../../../home/presentation/pages/home_design.dart';

enum LegalDoc { terms, privacy }

/// Términos y condiciones y política de privacidad.
///
/// BORRADOR: texto base para Bolivia que debe revisar un abogado antes de
/// publicar la app en las tiendas.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.doc});
  final LegalDoc doc;

  static const _updated = 'Última actualización: octubre de 2026';

  @override
  Widget build(BuildContext context) {
    final terms = doc == LegalDoc.terms;
    final sections = terms ? _terms : _privacy;
    return LuxInfoPage(
      eyebrow: 'Legal',
      title: terms ? 'Términos y condiciones' : 'Política de privacidad',
      lead: _updated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (heading, body) in sections) ...[
            Text(heading,
                style: displayText(
                    size: 26, color: LD.ink, weight: FontWeight.w500)),
            const SizedBox(height: 10),
            for (final p in body) ...[
              Text(p, style: bodyText(size: 14.5)),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }

  static const _terms = <(String, List<String>)>[
    (
      '1. Quiénes somos',
      [
        'Luxelane presta un servicio de reserva de traslados con chófer '
            'privado en ciudades de Bolivia. Al crear una cuenta o reservar un '
            'viaje aceptas estos términos.',
      ]
    ),
    (
      '2. Reservas y precio',
      [
        'El precio que ves al confirmar es el precio final del trayecto '
            'reservado e incluye impuestos y peajes. Los cambios de recorrido, '
            'paradas adicionales o tiempo de espera fuera de lo incluido pueden '
            'ajustar el importe final, que siempre se te informa.',
        'Las reservas por horas tienen un mínimo de 2 horas.',
      ]
    ),
    (
      '3. Cancelaciones',
      [
        'Puedes cancelar sin costo hasta 1 hora antes de la recogida. '
            'Una vez que el chófer está en camino o el viaje ha comenzado, la '
            'reserva ya no se puede cancelar desde la app.',
      ]
    ),
    (
      '4. Pagos',
      [
        'Si pagas con tarjeta, se autoriza el importe al reservar y se cobra '
            'al completar el viaje; si cancelas a tiempo, la retención se '
            'libera. Para viajes con más de 6 días de antelación, la tarjeta se '
            'cobra al completar el viaje. Los pagos con tarjeta los procesa '
            'Stripe; Luxelane no guarda los datos completos de tu tarjeta.',
      ]
    ),
    (
      '5. Uso del servicio',
      [
        'Debes respetar la capacidad de pasajeros y equipaje de la clase '
            'reservada. El chófer puede rechazar el servicio si se excede, o '
            'ante conductas que pongan en riesgo su seguridad o la del vehículo.',
        'Luxelane puede suspender cuentas que hagan un uso indebido del '
            'servicio.',
      ]
    ),
    (
      '6. Chóferes',
      [
        'Los chóferes son verificados por Luxelane antes de recibir viajes. '
            'Sus ganancias se calculan con la tarifa del viaje menos la comisión '
            'de la plataforma vigente al completarlo.',
      ]
    ),
    (
      '7. Responsabilidad',
      [
        'Luxelane hace todo lo razonable para que el servicio sea puntual y '
            'seguro, pero no responde por retrasos causados por terceros, '
            'tráfico, clima o fuerza mayor.',
      ]
    ),
    (
      '8. Cambios y contacto',
      [
        'Podemos actualizar estos términos; los cambios importantes se '
            'avisarán en la app. Para cualquier consulta, escríbenos desde la '
            'sección de soporte.',
      ]
    ),
  ];

  static const _privacy = <(String, List<String>)>[
    (
      '1. Qué datos recogemos',
      [
        'Datos de cuenta: nombre, correo electrónico y teléfono.',
        'Datos de viaje: lugares de recogida y destino, horarios, número de '
            'vuelo si lo indicas y notas para el chófer.',
        'Ubicación: para proponerte la recogida y, durante un viaje, para '
            'mostrar el recorrido. Si eres chófer, compartimos tu ubicación '
            'mientras estás conectado o atendiendo un viaje.',
        'Pagos: los datos de tarjeta los gestiona Stripe; nosotros solo vemos '
            'la marca y los últimos 4 dígitos.',
      ]
    ),
    (
      '2. Para qué los usamos',
      [
        'Para prestar el servicio (asignar chófer, calcular precios, cobrar), '
            'enviarte avisos sobre tu reserva, dar soporte, prevenir fraudes y '
            'mejorar la app.',
      ]
    ),
    (
      '3. Con quién los compartimos',
      [
        'Con el chófer asignado (tu nombre y los datos del viaje) y, si eres '
            'chófer, con el pasajero (tu nombre, teléfono y vehículo). Con '
            'proveedores que nos ayudan a operar: Google Firebase y Google Maps, '
            'y Stripe para los pagos. No vendemos tus datos.',
      ]
    ),
    (
      '4. Cuánto tiempo los guardamos',
      [
        'Mientras tu cuenta esté activa y el tiempo que exijan las '
            'obligaciones contables y legales aplicables.',
      ]
    ),
    (
      '5. Tus derechos',
      [
        'Puedes pedir acceso, corrección o eliminación de tus datos, y '
            'retirar el permiso de ubicación desde los ajustes de tu teléfono.',
        'Puedes eliminar tu cuenta en cualquier momento desde Perfil → '
            'Eliminar cuenta. Se borran tu perfil, tus tarjetas guardadas y '
            'tus avisos; conservamos el registro de viajes y pagos durante el '
            'plazo que exige la normativa contable y fiscal.',
      ]
    ),
    (
      '6. Seguridad',
      [
        'Usamos conexiones cifradas y reglas de acceso para que cada persona '
            'solo vea los datos que le corresponden.',
      ]
    ),
    (
      '7. Contacto',
      [
        'Para ejercer tus derechos o hacer consultas sobre privacidad, '
            'escríbenos desde la sección de soporte de la app.',
      ]
    ),
  ];
}
