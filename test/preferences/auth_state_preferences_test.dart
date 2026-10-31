import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';

/// Preferencias, B1: un cambio solo de preferencias (o de idioma) en la
/// cuenta se emite, para que la reserva no precargue las antiguas.
void main() {
  final user = User(
    id: 'ana',
    email: 'a@b.c',
    phone: '',
    displayName: 'Ana',
    role: UserRole.rider,
    createdAt: DateTime(2026),
    isVerified: true,
    isActive: true,
    fcmTokens: const [],
  );

  test('AuthAuthenticated distingue preferencias distintas', () {
    final other = user.copyWith(
      tripPreferences:
          const TripPreferences(conversation: ConversationPref.quiet),
    );
    expect(AuthAuthenticated(user), isNot(AuthAuthenticated(other)));
    expect(AuthAuthenticated(user), AuthAuthenticated(user.copyWith()));
  });

  test('las preferencias del viaje viajan en la reserva, no en un Expando', () {
    final b = Booking(
      id: 'b',
      riderId: 'ana',
      origin: const Place(name: 'A', address: 'A', lat: 0, lng: 0),
      destination: const Place(name: 'B', address: 'B', lat: 0, lng: 0),
      scheduledAt: DateTime(2026),
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: BookingStatus.pending,
      estimatedPrice: 1,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      requestedPreferences: const TripPreferences(music: MusicStyle.none),
    );
    expect(b.copyWith().requestedPreferences?.music, MusicStyle.none);
  });
}
