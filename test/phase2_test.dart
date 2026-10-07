import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/utils/eta.dart';

Map<String, dynamic> _bookingJson(Map<String, dynamic> extra) => {
      'id': 'b1',
      'riderId': 'r1',
      'origin': {'address': 'A', 'coordinates': const GeoPoint(-17.78, -63.18)},
      'destination': {'address': 'B', 'coordinates': const GeoPoint(-17.64, -63.13)},
      'scheduledAt': Timestamp.fromDate(DateTime(2026, 10, 7, 14, 20)),
      'class': 'business',
      'serviceType': 'oneWay',
      'status': 'confirmed',
      'estimatedPrice': 110,
      ...extra,
    };

void main() {
  group('Eta', () {
    test('estimates city arrival time from straight-line distance', () {
      // ~15.9 km straight × 1.35 road factor at 25 km/h ≈ 52 min
      final eta = Eta.estimate(fromLat: -17.7833, fromLng: -63.1821, toLat: -17.6448, toLng: -63.1354);
      expect(eta.inMinutes, inInclusiveRange(48, 56));
    });

    test('never returns less than a minute', () {
      expect(Eta.estimate(fromLat: 1, fromLng: 1, toLat: 1, toLng: 1).inMinutes, 1);
    });

    test('formats minutes and hours', () {
      expect(Eta.format(const Duration(minutes: 7)), '7 min');
      expect(Eta.format(const Duration(minutes: 65)), '1 h 05 min');
    });
  });

  group('Booking with Phase 2 fields', () {
    test('parses chauffeur, flight and adjusted pickup', () {
      final b = Booking.fromJson(_bookingJson({
        'pickupAt': Timestamp.fromDate(DateTime(2026, 10, 7, 15, 5)),
        'chauffeur': {
          'driverId': 'd1',
          'name': 'Luis A. V.',
          'vehicle': 'Mercedes-Benz E 300',
          'vehicleColor': 'Negro',
          'plate': 'ABC-123',
          'rating': 4.9,
          'ratingCount': 12,
          'phone': '+59170000000',
        },
        'flight': {
          'number': 'OB760',
          'status': 'Delayed',
          'delayMin': 45,
          'estimatedArrival': Timestamp.fromDate(DateTime(2026, 10, 7, 14, 50)),
        },
      }));
      expect(b.effectivePickup, DateTime(2026, 10, 7, 15, 5));
      expect(b.chauffeur!.vehicleLine, 'Mercedes-Benz E 300 · Negro');
      expect(b.chauffeur!.phone, '+59170000000');
      expect(b.flight!.delayed, isTrue);
      expect(b.flight!.label, 'Retrasado 45 min');
    });

    test('falls back to the booked time without flight data', () {
      final b = Booking.fromJson(_bookingJson({}));
      expect(b.effectivePickup, DateTime(2026, 10, 7, 14, 20));
      expect(b.chauffeur, isNull);
      expect(b.flight, isNull);
    });

    test('flight labels', () {
      expect(const FlightInfo(number: 'X', status: '', arrived: true).label, 'Aterrizó');
      expect(const FlightInfo(number: 'X', status: '', cancelled: true).label, 'Cancelado');
      expect(const FlightInfo(number: 'X', status: '', delayMin: 5).label, 'A tiempo');
    });

    test('live location goes stale after two minutes', () {
      final fresh = LiveLocation(lat: 0, lng: 0, updatedAt: DateTime.now());
      final old = LiveLocation(lat: 0, lng: 0, updatedAt: DateTime.now().subtract(const Duration(minutes: 3)));
      expect(fresh.isStale, isFalse);
      expect(old.isStale, isTrue);
    });
  });
}
