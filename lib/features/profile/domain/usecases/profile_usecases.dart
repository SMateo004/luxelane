import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/usecases/usecase.dart';

class GetUserUseCase implements UseCase<User, String> {
  GetUserUseCase(this._repo);
  final UserRepository _repo;

  @override
  Future<Either<Failure, User>> call(String userId) =>
      _repo.getUserById(userId);
}

// ---------------------------------------------------------------------------

class UpdateUserUseCase implements UseCase<void, User> {
  UpdateUserUseCase(this._repo);
  final UserRepository _repo;

  @override
  Future<Either<Failure, void>> call(User user) => _repo.updateUser(user);
}

// ---------------------------------------------------------------------------

class UpdateDriverLocationUseCase
    implements UseCase<void, UpdateLocationParams> {
  UpdateDriverLocationUseCase(this._repo);
  final UserRepository _repo;

  @override
  Future<Either<Failure, void>> call(UpdateLocationParams params) =>
      _repo.updateDriverLocation(
        userId: params.userId,
        latitude: params.lat,
        longitude: params.lng,
      );
}

class UpdateLocationParams {
  const UpdateLocationParams({
    required this.userId,
    required this.lat,
    required this.lng,
  });
  final String userId;
  final double lat;
  final double lng;
}

// ---------------------------------------------------------------------------

class SetDriverAvailabilityUseCase
    implements UseCase<void, SetAvailabilityParams> {
  SetDriverAvailabilityUseCase(this._repo);
  final UserRepository _repo;

  @override
  Future<Either<Failure, void>> call(SetAvailabilityParams params) =>
      _repo.setDriverAvailability(
        userId: params.userId,
        isAvailable: params.isAvailable,
      );
}

class SetAvailabilityParams {
  const SetAvailabilityParams({
    required this.userId,
    required this.isAvailable,
  });
  final String userId;
  final bool isAvailable;
}
