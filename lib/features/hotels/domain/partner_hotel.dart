import '../../../core/models/place_model.dart';

/// A hotel Luxelane has an agreement with. Listed on the public hotel
/// transfers page while active; each one has a link (for a QR at reception)
/// that opens the page with the hotel already chosen.
class PartnerHotel {
  const PartnerHotel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.meetingPoint = '',
    this.active = true,
  });

  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;

  /// Where the chauffeur meets guests (e.g. "Lobby principal"); goes into
  /// the booking notes for the chauffeur.
  final String meetingPoint;
  final bool active;

  Place get place => Place(name: name, address: address, lat: lat, lng: lng);

  factory PartnerHotel.fromJson(String id, Map<String, dynamic> j) => PartnerHotel(
        id: id,
        name: (j['name'] as String? ?? '').trim(),
        address: (j['address'] as String? ?? '').trim(),
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
        meetingPoint: (j['meetingPoint'] as String? ?? '').trim(),
        active: j['active'] != false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'meetingPoint': meetingPoint,
        'active': active,
      };

  PartnerHotel copyWith({bool? active}) => PartnerHotel(
        id: id,
        name: name,
        address: address,
        lat: lat,
        lng: lng,
        meetingPoint: meetingPoint,
        active: active ?? this.active,
      );
}

enum HotelTransferDirection { toAirport, fromAirport }

abstract final class HotelTransfers {
  /// Viru Viru International Airport (VVI), Santa Cruz.
  static const airport = Place(
    name: 'Aeropuerto Internacional Viru Viru',
    address: 'Aeropuerto Internacional Viru Viru, Santa Cruz de la Sierra',
    lat: -17.6448,
    lng: -63.1354,
  );

  static const maxName = 80;
  static const maxMeetingPoint = 120;

  /// Public link that opens the hotel transfers page with [hotelId] chosen.
  static String link(String baseUrl, String hotelId) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$base/servicios/hoteles?h=${Uri.encodeQueryComponent(hotelId)}';
  }

  /// Validation shared by the admin form and mirrored by the rules.
  static String? validate({required String name, required Place? place, String meetingPoint = ''}) {
    if (name.trim().isEmpty || name.trim().length > maxName) return 'hotel/name';
    if (place == null || (place.lat == 0 && place.lng == 0)) return 'hotel/place';
    if (meetingPoint.trim().length > maxMeetingPoint) return 'hotel/meeting-point';
    return null;
  }

  /// Pickup and drop-off for a transfer in [direction].
  static (Place origin, Place destination) route(PartnerHotel hotel, HotelTransferDirection direction) =>
      direction == HotelTransferDirection.toAirport ? (hotel.place, airport) : (airport, hotel.place);
}
