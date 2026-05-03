import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested({required this.userId});
  final String userId;
  @override
  List<Object?> get props => [userId];
}

class ProfileUpdateRequested extends ProfileEvent {
  const ProfileUpdateRequested({required this.user});
  final User user;
  @override
  List<Object?> get props => [user.id];
}

class DriverProfileUpdateRequested extends ProfileEvent {
  const DriverProfileUpdateRequested({required this.driverProfile});
  final DriverProfile driverProfile;
  @override
  List<Object?> get props => [driverProfile.userId];
}

class DriverLocationUpdated extends ProfileEvent {
  const DriverLocationUpdated({
    required this.userId,
    required this.lat,
    required this.lng,
  });
  final String userId;
  final double lat;
  final double lng;
  @override
  List<Object?> get props => [userId, lat, lng];
}

class DriverAvailabilityToggled extends ProfileEvent {
  const DriverAvailabilityToggled({
    required this.userId,
    required this.isAvailable,
  });
  final String userId;
  final bool isAvailable;
  @override
  List<Object?> get props => [userId, isAvailable];
}

class FcmTokenUpdated extends ProfileEvent {
  const FcmTokenUpdated({required this.userId, required this.token});
  final String userId;
  final String token;
  @override
  List<Object?> get props => [userId];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded({required this.user, this.driverProfile});
  final User user;
  final DriverProfile? driverProfile;
  @override
  List<Object?> get props => [user.id, driverProfile?.userId];
}

class ProfileUpdated extends ProfileState {
  const ProfileUpdated(this.user);
  final User user;
  @override
  List<Object?> get props => [user.id];
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required UserRepository userRepository})
      : _repo = userRepository,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileUpdateRequested>(_onUpdate);
    on<DriverProfileUpdateRequested>(_onDriverUpdate);
    on<DriverLocationUpdated>(_onDriverLocation);
    on<DriverAvailabilityToggled>(_onAvailability);
    on<FcmTokenUpdated>(_onFcmToken);
  }

  final UserRepository _repo;

  Future<void> _onLoad(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    final userResult = await _repo.getUserById(event.userId);
    await userResult.fold(
      (f) async => emit(ProfileError(f.message)),
      (user) async {
        if (user.role == UserRole.driver) {
          final dpResult = await _repo.getDriverProfile(event.userId);
          dpResult.fold(
            (f) => emit(ProfileLoaded(user: user)),
            (dp) => emit(ProfileLoaded(user: user, driverProfile: dp)),
          );
        } else {
          emit(ProfileLoaded(user: user));
        }
      },
    );
  }

  Future<void> _onUpdate(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final result = await _repo.updateUser(event.user);
    result.fold(
      (f) => emit(ProfileError(f.message)),
      (_) => emit(ProfileUpdated(event.user)),
    );
  }

  Future<void> _onDriverUpdate(
    DriverProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    await _repo.updateDriverProfile(event.driverProfile);
  }

  Future<void> _onDriverLocation(
    DriverLocationUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    await _repo.updateDriverLocation(
      userId: event.userId,
      latitude: event.lat,
      longitude: event.lng,
    );
  }

  Future<void> _onAvailability(
    DriverAvailabilityToggled event,
    Emitter<ProfileState> emit,
  ) async {
    await _repo.setDriverAvailability(
      userId: event.userId,
      isAvailable: event.isAvailable,
    );
  }

  Future<void> _onFcmToken(
    FcmTokenUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    await _repo.updateFcmToken(userId: event.userId, token: event.token);
  }
}
