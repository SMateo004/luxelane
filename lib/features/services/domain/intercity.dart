import '../../../core/enums/enums.dart';
import '../../../core/models/models.dart';
import '../../../core/models/place_model.dart';
import '../../../core/utils/eta.dart';

/// Popular city-to-city destinations from Santa Cruz de la Sierra.
enum IntercityDestination {
  samaipata(-18.1797, -63.8737, 'Samaipata'),
  buenaVista(-17.4589, -63.6564, 'Buena Vista'),
  montero(-17.3383, -63.2508, 'Montero'),
  sanJoseChiquitos(-17.8466, -60.7420, 'San José de Chiquitos'),
  concepcion(-16.1343, -62.0254, 'Concepción'),
  cochabamba(-17.3895, -66.1568, 'Cochabamba');

  const IntercityDestination(this.lat, this.lng, this.name);
  final double lat;
  final double lng;

  /// Proper name, the same in every language.
  final String name;

  Place get place => Place(name: name, address: '$name, Bolivia', lat: lat, lng: lng);
}

abstract final class Intercity {
  /// Santa Cruz de la Sierra city centre.
  static const santaCruzLat = -17.7833;
  static const santaCruzLng = -63.1821;

  /// Highways out of Santa Cruz wind more than city streets: road distance is
  /// roughly 1.45× the straight line on these routes. Only used for the
  /// "from" estimate on the cards; bookings use the real route distance.
  static const roadFactor = 1.45;

  /// Estimated road distance from Santa Cruz, rounded to 5 km.
  static int estimatedKm(IntercityDestination d) {
    final km = Eta.haversineKm(santaCruzLat, santaCruzLng, d.lat, d.lng) * roadFactor;
    return (km / 5).round() * 5;
  }

  /// Estimated one-way fare from the city centre in the given class.
  static double estimatedFare(IntercityDestination d, {VehicleClass vehicleClass = VehicleClass.business}) =>
      DefaultPricing.estimate(vehicleClass, ServiceType.oneWay, km: estimatedKm(d).toDouble()).ceilToDouble();
}
