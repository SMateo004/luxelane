import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';

void main() {
  final now = DateTime(2025, 6, 1, 12);
  final ts = Timestamp.fromDate(now);

  final json = {
    'id': 'booking-1',
    'riderId': 'rider-1',
    'driverId': null,
    'origin': {
      'address': '123 Main St',
      'coordinates': const GeoPoint(40.7128, -74.0060),
    },
    'destination': {
      'address': 'JFK Airport',
      'coordinates': const GeoPoint(40.6413, -73.7781),
    },
    'scheduledAt': ts,
    'class': 'business',
    'serviceType': 'oneWay',
    'status': 'pending',
    'estimatedPrice': 75.0,
    'finalPrice': null,
    'paymentId': null,
    'createdAt': ts,
    'updatedAt': ts,
    'notes': null,
  };

  group('Booking', () {
    test('fromJson parses correctly', () {
      final booking = Booking.fromJson(json);

      expect(booking.id, 'booking-1');
      expect(booking.riderId, 'rider-1');
      expect(booking.driverId, isNull);
      expect(booking.vehicleClass, VehicleClass.business);
      expect(booking.status, BookingStatus.pending);
      expect(booking.estimatedPrice, 75.0);
      expect(booking.origin.address, '123 Main St');
      expect(booking.destination.address, 'JFK Airport');
    });

    test('toJson roundtrip preserves values', () {
      final booking = Booking.fromJson(json);
      final encoded = booking.toJson();
      final decoded = Booking.fromJson(encoded);

      expect(decoded.id, booking.id);
      expect(decoded.riderId, booking.riderId);
      expect(decoded.vehicleClass, booking.vehicleClass);
      expect(decoded.status, booking.status);
      expect(decoded.estimatedPrice, booking.estimatedPrice);
      expect(decoded.origin.address, booking.origin.address);
      expect(decoded.scheduledAt, booking.scheduledAt);
    });

    test('copyWith updates only specified fields', () {
      final booking = Booking.fromJson(json);
      final updated = booking.copyWith(
        status: BookingStatus.confirmed,
        driverId: 'driver-99',
      );

      expect(updated.status, BookingStatus.confirmed);
      expect(updated.driverId, 'driver-99');
      expect(updated.riderId, booking.riderId);
      expect(updated.estimatedPrice, booking.estimatedPrice);
    });

    test('BookingStatus.fromString maps all values', () {
      expect(BookingStatusX.fromString('pending'), BookingStatus.pending);
      expect(BookingStatusX.fromString('confirmed'), BookingStatus.confirmed);
      expect(BookingStatusX.fromString('in_progress'), BookingStatus.inProgress);
      expect(BookingStatusX.fromString('completed'), BookingStatus.completed);
      expect(BookingStatusX.fromString('cancelled'), BookingStatus.cancelled);
    });
  });

  group('Place', () {
    test('fromJson/toJson roundtrip', () {
      const geo = GeoPoint(40.7128, -74.0060);
      final placeJson = {'address': '123 Main St', 'coordinates': geo};
      final place = Place.fromJson(placeJson);

      expect(place.address, '123 Main St');
      expect(place.lat, 40.7128);
      expect(place.lng, -74.0060);

      final encoded = place.toJson();
      final decoded = Place.fromJson(encoded);
      expect(decoded.address, place.address);
      expect(decoded.lat, place.lat);
    });
  });
}
