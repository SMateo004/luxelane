import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';

Booking _pending(String id, {Map<String, dynamic>? dispatch}) => Booking.fromJson({
      'id': id,
      'riderId': 'r1',
      'origin': {'address': 'A', 'coordinates': const GeoPoint(-17.78, -63.18)},
      'destination': {'address': 'B', 'coordinates': const GeoPoint(-17.64, -63.13)},
      'scheduledAt': Timestamp.fromDate(DateTime(2026, 10, 7, 14)),
      'class': 'business',
      'serviceType': 'oneWay',
      'status': 'pending',
      'estimatedPrice': 110,
      if (dispatch != null) 'dispatch': dispatch,
    });

final _me = User(
  id: 'me',
  email: 'me@x.com',
  phone: '',
  displayName: 'Yo',
  role: UserRole.driver,
  createdAt: DateTime(2026),
  isVerified: true,
  isActive: true,
  fcmTokens: const [],
);

final _profile = DriverProfile(
  userId: 'me',
  licenseNumber: 'L1',
  licenseExpiry: DateTime(2030),
  vehicleId: 'v1',
  documentsVerified: true,
  rating: 0,
  totalRides: 0,
  isAvailable: true,
);

void main() {
  test('broadcast bookings are visible to every chauffeur', () {
    expect(_pending('b1').isOfferedTo('me'), isTrue);
    expect(_pending('b2', dispatch: {'mode': 'broadcast'}).isOfferedTo('me'), isTrue);
  });

  test('targeted bookings are visible only to the offered chauffeur', () {
    final b = _pending('b3', dispatch: {
      'mode': 'targeted',
      'offeredTo': 'other',
      'offerExpiresAt': Timestamp.fromDate(DateTime(2026, 10, 7, 13)),
    });
    expect(b.isOfferedTo('me'), isFalse);
    expect(b.isOfferedTo('other'), isTrue);
    expect(b.dispatch!.offerExpiresAt, DateTime(2026, 10, 7, 13));
  });

  test("currentRequest skips offers meant for someone else", () {
    final state = DriverLoaded(
      user: _me,
      profile: _profile,
      isAvailable: true,
      bookings: const [],
      pendingRequests: [
        _pending('theirs', dispatch: {'mode': 'targeted', 'offeredTo': 'other'}),
        _pending('mine', dispatch: {'mode': 'targeted', 'offeredTo': 'me'}),
      ],
    );
    expect(state.currentRequest?.id, 'mine');
  });
}
