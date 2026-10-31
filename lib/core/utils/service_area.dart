import 'dart:math' as math;

import '../../l10n/l10n.dart';
import '../models/place_model.dart';

/// A metropolitan area we operate in. A trip must start and end in the same
/// one: the city plus its conurbation (El Alto with La Paz, Warnes with
/// Santa Cruz, Quillacollo and Sacaba with Cochabamba…), which is also where
/// each city's airport sits.
class ServiceCity {
  const ServiceCity(this.name, this.lat, this.lng, this.radiusKm);

  final String name;
  final double lat;
  final double lng;
  final double radiusKm;
}

/// Whether a flight lands from inside Bolivia or from abroad; passengers
/// come out through a different arrivals hall for each.
enum FlightType {
  domestic,
  international;

  String get label => switch (this) {
        FlightType.domestic => L10n.current.commonFlightDomestic,
        FlightType.international => L10n.current.commonFlightInternational,
      };

  static FlightType? fromName(String? name) {
    for (final t in values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

/// A commercial airport we pick up from.
class ServiceAirport {
  const ServiceAirport(
    this.iata,
    this.name,
    this.lat,
    this.lng, {
    String? domesticExit,
    String? internationalExit,
  })  : _domesticExit = domesticExit,
        _internationalExit = internationalExit;

  final String iata;
  final String name;
  final double lat;
  final double lng;

  /// Where the passenger walks out, shown to the driver. Override per airport
  /// with the actual door once confirmed on site.
  final String? _domesticExit;
  final String? _internationalExit;

  String get domesticExit =>
      _domesticExit ?? L10n.current.commonAirportDomesticExit;
  String get internationalExit =>
      _internationalExit ?? L10n.current.commonAirportInternationalExit;

  String exitFor(FlightType type) =>
      type == FlightType.domestic ? domesticExit : internationalExit;

  /// City the airport serves (El Alto → La Paz, Viru Viru → Santa Cruz).
  String? get cityName =>
      ServiceArea.cityOf(Place(address: name, lat: lat, lng: lng))?.name;
}

/// Circle a destination search is restricted to.
typedef SearchArea = ({double lat, double lng, double radiusMeters});

/// Same-city and airport rules for pickup/destination pairs. Pure Dart, so it
/// works the same on web and mobile and needs no extra Maps API calls.
abstract final class ServiceArea {
  static const cities = <ServiceCity>[
    ServiceCity(
      'Santa Cruz de la Sierra', // i18n-ignore: nombre propio
      -17.7833,
      -63.1821,
      30,
    ),
    ServiceCity('La Paz', -16.5000, -68.1500, 25), // i18n-ignore: nombre propio
    ServiceCity(
        'Cochabamba', -17.3895, -66.1568, 25), // i18n-ignore: nombre propio
    ServiceCity('Sucre', -19.0333, -65.2627, 35), // i18n-ignore: nombre propio
    ServiceCity('Oruro', -17.9647, -67.1060, 20), // i18n-ignore: nombre propio
    ServiceCity('Potosí', -19.5836, -65.7531, 20), // i18n-ignore: nombre propio
    ServiceCity('Tarija', -21.5355, -64.7296, 20), // i18n-ignore: nombre propio
    ServiceCity(
        'Trinidad', -14.8333, -64.9000, 15), // i18n-ignore: nombre propio
    ServiceCity('Cobija', -11.0267, -68.7692, 15), // i18n-ignore: nombre propio
  ];

  static const airports = <ServiceAirport>[
    ServiceAirport(
      'VVI', // i18n-ignore: nombre propio
      'Aeropuerto Internacional Viru Viru', // i18n-ignore: nombre propio
      -17.6447,
      -63.1353,
    ),
    ServiceAirport(
      'SRZ', // i18n-ignore: nombre propio
      'Aeropuerto El Trompillo', // i18n-ignore: nombre propio
      -17.8117,
      -63.1717,
    ),
    ServiceAirport(
      'LPB', // i18n-ignore: nombre propio
      'Aeropuerto Internacional El Alto', // i18n-ignore: nombre propio
      -16.5131,
      -68.1922,
    ),
    ServiceAirport(
      'CBB', // i18n-ignore: nombre propio
      'Aeropuerto Internacional Jorge Wilstermann', // i18n-ignore: nombre propio
      -17.4211,
      -66.1769,
    ),
    ServiceAirport(
      'SRE', // i18n-ignore: nombre propio
      'Aeropuerto Internacional Alcantarí', // i18n-ignore: nombre propio
      -19.2467,
      -65.1494,
    ),
    ServiceAirport(
      'TJA', // i18n-ignore: nombre propio
      'Aeropuerto Capitán Oriel Lea Plaza', // i18n-ignore: nombre propio
      -21.5558,
      -64.7014,
    ),
    ServiceAirport(
      'ORU', // i18n-ignore: nombre propio
      'Aeropuerto Internacional Juan Mendoza', // i18n-ignore: nombre propio
      -17.9625,
      -67.0761,
    ),
    ServiceAirport(
      'POI', // i18n-ignore: nombre propio
      'Aeropuerto Capitán Nicolás Rojas', // i18n-ignore: nombre propio
      -19.5433,
      -65.7236,
    ),
    ServiceAirport(
      'TDD', // i18n-ignore: nombre propio
      'Aeropuerto Teniente Jorge Henrich', // i18n-ignore: nombre propio
      -14.8186,
      -64.9181,
    ),
    ServiceAirport(
      'CIJ', // i18n-ignore: nombre propio
      'Aeropuerto Capitán Aníbal Arab', // i18n-ignore: nombre propio
      -11.0403,
      -68.7825,
    ),
    ServiceAirport(
      'UYU', // i18n-ignore: nombre propio
      'Aeropuerto Joya Andina', // i18n-ignore: nombre propio
      -20.4464,
      -66.8486,
    ),
  ];

  /// Outside every known city, the destination must be this close to the
  /// pickup instead (same radius the place search uses for "a city").
  static const fallbackRadiusKm = 30.0;

  /// A pin this close to an airport's reference point is the airport.
  static const _airportRadiusKm = 1.2;

  /// A place *named* like an airport is matched to the nearest one this close.
  static const _namedAirportRadiusKm = 6.0;

  /// Coordinates are unknown when Place Details failed (see
  /// PlaceAutocompleteField's fallback), so no distance rule can apply.
  static bool hasCoords(Place p) => p.lat != 0 || p.lng != 0;

  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  /// The metro area [p] is in, or null when it is in none of them.
  static ServiceCity? cityOf(Place p) {
    if (!hasCoords(p)) return null;
    ServiceCity? best;
    var bestKm = double.infinity;
    for (final c in cities) {
      final km = distanceKm(p.lat, p.lng, c.lat, c.lng);
      if (km <= c.radiusKm && km < bestKm) {
        best = c;
        bestKm = km;
      }
    }
    return best;
  }

  /// Where destination suggestions should be restricted to for [origin].
  static SearchArea? destinationAreaFor(Place? origin) {
    if (origin == null || !hasCoords(origin)) return null;
    final city = cityOf(origin);
    if (city != null) {
      return (lat: city.lat, lng: city.lng, radiusMeters: city.radiusKm * 1000);
    }
    return (
      lat: origin.lat,
      lng: origin.lng,
      radiusMeters: fallbackRadiusKm * 1000,
    );
  }

  /// Error si la recogida está fuera de las ciudades y aeropuertos donde
  /// operamos, o no tiene coordenadas reales; null si se puede atender.
  static String? originError(Place origin) {
    if (!hasCoords(origin)) {
      return L10n.current.commonOriginNoCoords;
    }
    if (cityOf(origin) != null || airportFor(origin) != null) return null;
    return L10n.current.commonOriginOutsideArea(
      cities.map((c) => c.name.split(' de ').first).join(', '),
    );
  }

  /// Error to show when [destination] is not in [origin]'s city, else null.
  /// Places without coordinates can't be checked and are let through.
  static String? destinationError(Place origin, Place destination) {
    if (!hasCoords(origin) || !hasCoords(destination)) return null;
    final city = cityOf(origin);
    if (city != null) {
      if (cityOf(destination) == city) return null;
      return L10n.current.commonDestinationOtherCity(city.name);
    }
    final km = distanceKm(
      origin.lat,
      origin.lng,
      destination.lat,
      destination.lng,
    );
    if (km <= fallbackRadiusKm) return null;
    return L10n.current.commonDestinationSameCity;
  }

  // ── Airports ────────────────────────────────────────────────────────────

  static final _airportWord = RegExp(
    r'\b(aeropuerto|airport|aerodromo|terminal aerea)\b', // i18n-ignore: patrón de búsqueda
  );
  // Streets and neighbourhoods named after an airport ("Av. Aeropuerto").
  static final _streetPrefix = RegExp(
    r'^(av|avda|avenida|calle|c|pasaje|psje|carretera|camino|barrio|b|urb|urbanizacion|zona|villa)\b',
  );

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[áàä]'), 'a')
      .replaceAll(RegExp('[éèë]'), 'e')
      .replaceAll(RegExp('[íìï]'), 'i')
      .replaceAll(RegExp('[óòö]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u')
      .trim();

  /// The airport [p] is at, matched by its coordinates.
  static ServiceAirport? airportAt(Place p) {
    if (!hasCoords(p)) return null;
    for (final a in airports) {
      if (distanceKm(p.lat, p.lng, a.lat, a.lng) <= _airportRadiusKm) return a;
    }
    return null;
  }

  static bool _namedAirport(Place p) {
    final name = _fold(p.name);
    return name.isNotEmpty &&
        _airportWord.hasMatch(name) &&
        !_streetPrefix.hasMatch(name);
  }

  /// Whether the pickup is an airport: by position, or by the place's own
  /// name when it came from search ("Aeropuerto Internacional Viru Viru").
  static bool isAirport(Place p) => airportAt(p) != null || _namedAirport(p);

  /// The airport [p] is, also when it was matched by name and its pin is a
  /// bit off our reference point. Null when it isn't one we know.
  static ServiceAirport? airportFor(Place p) {
    final exact = airportAt(p);
    if (exact != null || !_namedAirport(p) || !hasCoords(p)) return exact;
    ServiceAirport? best;
    var bestKm = _namedAirportRadiusKm;
    for (final a in airports) {
      final km = distanceKm(p.lat, p.lng, a.lat, a.lng);
      if (km <= bestKm) {
        best = a;
        bestKm = km;
      }
    }
    return best;
  }

  /// Zona de [p] sin la dirección exacta: el aeropuerto o la ciudad.
  static String? areaLabel(Place p) => airportFor(p)?.name ?? cityOf(p)?.name;

  static ServiceAirport? airportByIata(String? iata) {
    for (final a in airports) {
      if (a.iata == iata) return a;
    }
    return null;
  }
}

/// Flight numbers as printed on a boarding pass: an IATA (2 characters) or
/// ICAO (3 letters) airline code followed by 1–4 digits, e.g. "OB 760",
/// "Z8-315", "LA8810", "BOV760".
abstract final class FlightNumber {
  static final _pattern = RegExp(
    r'^([A-Z]{2}|[A-Z][0-9]|[0-9][A-Z]|[A-Z]{3})([0-9]{1,4})[A-Z]?$',
  );

  /// Upper-cased with spaces and dashes removed.
  static String normalize(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

  static bool isValid(String input) => _pattern.hasMatch(normalize(input));

  /// Error to show for [input], or null when it is a valid flight number.
  static String? error(String input) {
    if (input.trim().isEmpty) {
      return L10n.current.commonFlightNumberMissing;
    }
    if (!isValid(input)) {
      return L10n.current.commonFlightNumberInvalid;
    }
    return null;
  }
}
