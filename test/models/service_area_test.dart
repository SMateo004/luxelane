import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/models/place_model.dart';
import 'package:luxelane/core/utils/service_area.dart';

const _scz = Place(
  name: 'Plaza 24 de Septiembre',
  address: '',
  lat: -17.7836,
  lng: -63.1822,
);
const _equipetrol = Place(
  name: 'Equipetrol',
  address: '',
  lat: -17.7650,
  lng: -63.1960,
);
const _viruViru = Place(
  name: 'Aeropuerto Internacional Viru Viru',
  address: '',
  lat: -17.6447,
  lng: -63.1353,
);
const _laPaz = Place(
  name: 'San Jorge',
  address: '',
  lat: -16.5100,
  lng: -68.1250,
);
const _elAltoAirport = Place(
  name: '',
  address: 'El Alto',
  lat: -16.5125,
  lng: -68.1915,
);
const _cochabamba = Place(
  name: 'Plaza 14 de Septiembre',
  address: '',
  lat: -17.3936,
  lng: -66.1570,
);

void main() {
  group('ServiceArea.cityOf', () {
    test('resolves metro areas, airports included', () {
      expect(ServiceArea.cityOf(_scz)?.name, 'Santa Cruz de la Sierra');
      expect(ServiceArea.cityOf(_viruViru)?.name, 'Santa Cruz de la Sierra');
      expect(ServiceArea.cityOf(_elAltoAirport)?.name, 'La Paz');
      expect(ServiceArea.cityOf(_cochabamba)?.name, 'Cochabamba');
    });

    test('unknown coordinates have no city', () {
      expect(
        ServiceArea.cityOf(const Place(address: 'x', lat: 0, lng: 0)),
        isNull,
      );
    });
  });

  group('ServiceArea.destinationError', () {
    test('allows trips inside the same city', () {
      expect(ServiceArea.destinationError(_scz, _equipetrol), isNull);
      expect(ServiceArea.destinationError(_viruViru, _equipetrol), isNull);
      expect(ServiceArea.destinationError(_elAltoAirport, _laPaz), isNull);
    });

    test('rejects a destination in another city', () {
      expect(
        ServiceArea.destinationError(_scz, _cochabamba),
        contains('Santa Cruz de la Sierra'),
      );
      expect(ServiceArea.destinationError(_laPaz, _scz), contains('La Paz'));
    });

    test('outside known cities, limits the distance from the pickup', () {
      const samaipata = Place(
        address: 'Samaipata',
        lat: -18.1790,
        lng: -63.8750,
      );
      const near = Place(address: 'Cerca', lat: -18.1900, lng: -63.8500);
      expect(ServiceArea.destinationError(samaipata, near), isNull);
      expect(ServiceArea.destinationError(samaipata, _scz), isNotNull);
    });

    test('lets through places without coordinates', () {
      const unknown = Place(address: 'x', lat: 0, lng: 0);
      expect(ServiceArea.destinationError(_scz, unknown), isNull);
    });
  });

  test('destinationAreaFor uses the pickup city', () {
    final area = ServiceArea.destinationAreaFor(_viruViru)!;
    expect(area.lat, closeTo(-17.7833, 1e-4));
    expect(area.radiusMeters, 30000);
    expect(ServiceArea.destinationAreaFor(null), isNull);
  });

  group('ServiceArea.isAirport', () {
    test('by position, even without a name', () {
      expect(ServiceArea.isAirport(_elAltoAirport), isTrue);
    });

    test('by name', () {
      expect(
        ServiceArea.isAirport(
          const Place(
            name: 'Aeropuerto Jorge Wilstermann',
            address: '',
            lat: 0,
            lng: 0,
          ),
        ),
        isTrue,
      );
    });

    test('not for streets named after an airport or regular places', () {
      expect(
        ServiceArea.isAirport(
          const Place(
            name: 'Av. Aeropuerto',
            address: '',
            lat: -17.70,
            lng: -63.16,
          ),
        ),
        isFalse,
      );
      expect(ServiceArea.isAirport(_scz), isFalse);
    });
  });

  group('FlightNumber', () {
    test('accepts IATA and ICAO formats', () {
      for (final f in ['OB 760', 'z8-315', 'LA8810', 'BOV760', 'AA 922']) {
        expect(FlightNumber.isValid(f), isTrue, reason: f);
      }
      expect(FlightNumber.normalize('z8-315'), 'Z8315');
    });

    test('rejects junk and asks for a missing number', () {
      for (final f in ['760', 'VIRU', 'OB', '12 345', 'OB 12345']) {
        expect(FlightNumber.isValid(f), isFalse, reason: f);
      }
      expect(FlightNumber.error(''), isNotNull);
      expect(FlightNumber.error('OB760'), isNull);
    });
  });

  group('airports for flight pickups', () {
    test('airportFor matches by name within a few km of the airport', () {
      const named = Place(
        name: 'Aeropuerto Internacional Viru Viru',
        address: '',
        lat: -17.6550,
        lng: -63.1400,
      );
      expect(ServiceArea.airportAt(named), isNull);
      expect(ServiceArea.airportFor(named)?.iata, 'VVI');
      expect(ServiceArea.airportFor(_scz), isNull);
    });

    test('airport city and arrivals exit by flight type', () {
      final lpb = ServiceArea.airportByIata('LPB')!;
      expect(lpb.cityName, 'La Paz');
      expect(lpb.exitFor(FlightType.domestic), contains('nacionales'));
      expect(
        lpb.exitFor(FlightType.international),
        contains('internacionales'),
      );
      expect(FlightType.fromName('international'), FlightType.international);
      expect(FlightType.fromName(null), isNull);
    });
  });
}
