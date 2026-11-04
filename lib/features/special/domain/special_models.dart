import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Servicios especiales: extras bajo cotización que no compiten con la
/// reserva principal (no tienen precio instantáneo).
enum SpecialKind { aerotaxi, cityTour }

extension SpecialKindX on SpecialKind {
  static SpecialKind? parse(String? v) => switch (v) {
        'aerotaxi' => SpecialKind.aerotaxi,
        'cityTour' || 'paseo' => SpecialKind.cityTour,
        _ => null,
      };

  /// Segmento de la ruta /especiales/<slug>.
  String get slug => this == SpecialKind.aerotaxi ? 'aerotaxi' : 'paseo';

  String get label =>
      this == SpecialKind.aerotaxi ? 'Aerotaxi' : 'Paseo por la ciudad';

  String get tagline => this == SpecialKind.aerotaxi
      ? 'Vuelos privados cortos entre ciudades de Bolivia.'
      : 'Recorre Santa Cruz con tu chófer, a tu ritmo.';

  String get lead => this == SpecialKind.aerotaxi
      ? 'Coordinamos una aeronave privada con operadores certificados y te '
          'llevamos a la pista con tu chófer. Ideal para Uyuni, Rurrenabaque '
          'o una reunión en otra ciudad el mismo día.'
      : 'Un chófer a tu disposición para conocer la ciudad: el casco viejo, '
          'Equipetrol, mercados, miradores o lo que tengas en mente. Tú '
          'marcas las paradas.';

  IconData get icon => this == SpecialKind.aerotaxi
      ? Icons.flight_outlined
      : Icons.location_city_outlined;
}

enum SpecialStatus {
  newRequest,
  quoted,
  confirmed,
  declined,
  cancelled,
  completed
}

extension SpecialStatusX on SpecialStatus {
  static SpecialStatus parse(Object? v) => switch (v) {
        'quoted' => SpecialStatus.quoted,
        'confirmed' => SpecialStatus.confirmed,
        'declined' => SpecialStatus.declined,
        'cancelled' => SpecialStatus.cancelled,
        'completed' => SpecialStatus.completed,
        _ => SpecialStatus.newRequest,
      };

  String get value => switch (this) {
        SpecialStatus.newRequest => 'new',
        SpecialStatus.quoted => 'quoted',
        SpecialStatus.confirmed => 'confirmed',
        SpecialStatus.declined => 'declined',
        SpecialStatus.cancelled => 'cancelled',
        SpecialStatus.completed => 'completed',
      };

  String get label => switch (this) {
        SpecialStatus.newRequest => 'Preparando cotización',
        SpecialStatus.quoted => 'Cotización lista',
        SpecialStatus.confirmed => 'Confirmado',
        SpecialStatus.declined => 'No disponible',
        SpecialStatus.cancelled => 'Cancelado',
        SpecialStatus.completed => 'Realizado',
      };

  bool get isOpen =>
      this == SpecialStatus.newRequest || this == SpecialStatus.quoted;
}

/// Ciudades con pista para aerotaxi.
const kAerotaxiCities = [
  'Santa Cruz',
  'La Paz',
  'Cochabamba',
  'Sucre',
  'Tarija',
  'Uyuni',
  'Rurrenabaque',
  'Trinidad',
  'Cobija',
  'Riberalta',
  'Oruro',
  'Potosí',
  'San Ignacio de Velasco',
  'Puerto Suárez',
];

const kTourDurations = [2, 3, 4, 6];

const kTourLanguages = {'es': 'Español', 'en': 'English', 'pt': 'Português'};

class SpecialRequest {
  const SpecialRequest({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.kind,
    required this.status,
    required this.date,
    required this.passengers,
    this.riderEmail = '',
    this.riderPhone = '',
    this.from,
    this.to,
    this.pickup,
    this.durationHours,
    this.language,
    this.notes = '',
    this.quoteBs,
    this.adminNote,
    this.createdAt,
  });

  final String id;
  final String riderId;
  final String riderName;
  final String riderEmail;
  final String riderPhone;
  final SpecialKind kind;
  final SpecialStatus status;
  final DateTime date;
  final int passengers;
  final String? from;
  final String? to;
  final String? pickup;
  final int? durationHours;
  final String? language;
  final String notes;
  final double? quoteBs;
  final String? adminNote;
  final DateTime? createdAt;

  /// "Santa Cruz → Uyuni" o "4 h desde Hotel Los Tajibos".
  String get summary => kind == SpecialKind.aerotaxi
      ? '${from ?? ''} → ${to ?? ''}'
      : '${durationHours ?? ''} h desde ${pickup ?? ''}';

  factory SpecialRequest.fromDoc(String id, Map<String, dynamic> j) =>
      SpecialRequest(
        id: id,
        riderId: j['riderId'] as String? ?? '',
        riderName: j['riderName'] as String? ?? '',
        riderEmail: j['riderEmail'] as String? ?? '',
        riderPhone: j['riderPhone'] as String? ?? '',
        kind: SpecialKindX.parse(j['kind'] as String?) ?? SpecialKind.cityTour,
        status: SpecialStatusX.parse(j['status']),
        date: (j['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        passengers: (j['passengers'] as num?)?.toInt() ?? 1,
        from: j['from'] as String?,
        to: j['to'] as String?,
        pickup: j['pickup'] as String?,
        durationHours: (j['durationHours'] as num?)?.toInt(),
        language: j['language'] as String?,
        notes: j['notes'] as String? ?? '',
        quoteBs: (j['quoteBs'] as num?)?.toDouble(),
        adminNote: j['adminNote'] as String?,
        createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
      );

  /// Documento que crea el cliente (lo que permiten las reglas).
  static Map<String, dynamic> newRequestJson({
    required String riderId,
    required String riderName,
    required String riderEmail,
    required String riderPhone,
    required SpecialKind kind,
    required DateTime date,
    required int passengers,
    String? from,
    String? to,
    String? pickup,
    int? durationHours,
    String? language,
    String notes = '',
  }) =>
      {
        'riderId': riderId,
        'riderName':
            riderName.length > 80 ? riderName.substring(0, 80) : riderName,
        'riderEmail': riderEmail,
        'riderPhone':
            riderPhone.length > 20 ? riderPhone.substring(0, 20) : riderPhone,
        'kind': kind.name,
        'date': Timestamp.fromDate(date),
        'passengers': passengers,
        if (kind == SpecialKind.aerotaxi) ...{'from': from, 'to': to},
        if (kind == SpecialKind.cityTour) ...{
          'pickup': pickup,
          'durationHours': durationHours,
          'language': language ?? 'es',
        },
        'notes': notes.trim(),
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
