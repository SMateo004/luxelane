import 'package:dartz/dartz.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/usecases/usecase.dart';

class LoginUseCase implements UseCase<User, LoginParams> {
  LoginUseCase(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, User>> call(LoginParams params) =>
      _repo.login(email: params.email, password: params.password);
}

class LoginParams {
  const LoginParams({required this.email, required this.password});
  final String email;
  final String password;
}

// ---------------------------------------------------------------------------

class RegisterUseCase implements UseCase<User, RegisterParams> {
  RegisterUseCase(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, User>> call(RegisterParams params) => _repo.register(
        email: params.email,
        password: params.password,
        phone: params.phone,
        displayName: params.displayName,
        role: params.role,
      );
}

class RegisterParams {
  const RegisterParams({
    required this.email,
    required this.password,
    required this.phone,
    required this.displayName,
    required this.role,
  });
  final String email;
  final String password;
  final String phone;
  final String displayName;
  final UserRole role;
}

// ---------------------------------------------------------------------------

class LogoutUseCase implements UseCase<void, NoParams> {
  LogoutUseCase(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, void>> call(NoParams params) => _repo.logout();
}

// ---------------------------------------------------------------------------

class GetCurrentUserUseCase implements UseCase<User, NoParams> {
  GetCurrentUserUseCase(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, User>> call(NoParams params) => _repo.getCurrentUser();
}

// ---------------------------------------------------------------------------

class WatchAuthStateUseCase {
  WatchAuthStateUseCase(this._repo);
  final AuthRepository _repo;

  Stream<User?> call() => _repo.authStateChanges;
}
