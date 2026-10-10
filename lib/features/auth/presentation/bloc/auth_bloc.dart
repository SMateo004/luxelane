import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../domain/auth_failure.dart';

// ---------------------------------------------------------------------------
// Public events
// ---------------------------------------------------------------------------

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  const RegisterRequested({
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
  @override
  List<Object?> get props => [email, phone, displayName, role];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class VerificationEmailSent extends AuthEvent {
  const VerificationEmailSent();
}

class PhoneVerificationRequested extends AuthEvent {
  const PhoneVerificationRequested({required this.phone});
  final String phone;
  @override
  List<Object?> get props => [phone];
}

class PasswordResetRequested extends AuthEvent {
  const PasswordResetRequested({required this.email});
  final String email;
  @override
  List<Object?> get props => [email];
}

// Internal — fired by the background Firebase watcher when the session
// expires or the user signs out on another device.
class _AuthSignedOut extends AuthEvent {
  const _AuthSignedOut();
}

/// users/{uid}.isActive changed while signed in (an admin suspended or
/// reactivated the account).
class _AccountStatusChanged extends AuthEvent {
  const _AccountStatusChanged(this.isActive);
  final bool isActive;
  @override
  List<Object?> get props => [isActive];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
  @override
  List<Object?> get props => [user.id, user.isActive];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message, {this.code});

  /// Developer-facing detail (provider text). Not for display: show
  /// `authErrorMessage(context.l10n, code)` instead.
  final String message;

  /// Backend error code (e.g. `wrong-password`), when known.
  final String? code;

  factory AuthError.fromFailure(Failure f) =>
      AuthError(f.message, code: f is AuthCodeFailure ? f.code : null);

  @override
  List<Object?> get props => [message, code];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository, Stream<bool> Function(String uid)? watchIsActive})
      : _repo = authRepository,
        _watchIsActive = watchIsActive,
        super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    on<_AuthSignedOut>(_onSignedOut);
    on<VerificationEmailSent>(_onVerificationEmail);
    on<PhoneVerificationRequested>(_onPhoneVerification);
    on<PasswordResetRequested>(_onPasswordReset);
    on<_AccountStatusChanged>(_onAccountStatusChanged);
  }

  final AuthRepository _repo;

  /// Live users/{uid}.isActive, so a suspension applies without restarting.
  final Stream<bool> Function(String uid)? _watchIsActive;
  StreamSubscription<bool>? _statusSub;

  void _watchStatus() {
    _statusSub?.cancel();
    _statusSub = null;
    final s = state;
    final watch = _watchIsActive;
    if (watch == null || s is! AuthAuthenticated || s.user.role == UserRole.admin) return;
    _statusSub = watch(s.user.id).listen(
      (active) {
        if (!isClosed) add(_AccountStatusChanged(active));
      },
      onError: (_) {},
    );
  }

  void _onAccountStatusChanged(_AccountStatusChanged event, Emitter<AuthState> emit) {
    final s = state;
    if (s is AuthAuthenticated && s.user.isActive != event.isActive) {
      emit(AuthAuthenticated(s.user.copyWith(isActive: event.isActive)));
    }
  }

  // Watches the raw Firebase sign-in flag after the initial state is resolved.
  // Only reacts to sign-out (false) so it never races with _onLogin/_onRegister.
  StreamSubscription<bool>? _signOutSub;

  // ── _onStarted ─────────────────────────────────────────────────────────────
  // Reads exactly ONE emission from authStateChanges (Firebase + Firestore) to
  // resolve the initial session, then hands off to _signOutSub for the rest.
  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    // .take(1) closes the stream after the first event so emit.forEach returns
    // immediately instead of blocking forever.
    await emit.forEach<User?>(
      _repo.authStateChanges.take(1),
      onData: (user) =>
          user != null ? AuthAuthenticated(user) : const AuthUnauthenticated(),
      onError: (_, __) => const AuthUnauthenticated(),
    );
    _watchStatus();

    // After initial state is known, watch *only* for sign-out via the raw
    // Firebase stream (no Firestore) — login/register own their transitions.
    await _signOutSub?.cancel();
    _signOutSub = _repo.isSignedIn.listen((signedIn) {
      if (!signedIn && !isClosed) add(const _AuthSignedOut());
    });
  }

  // ── _onLogin ───────────────────────────────────────────────────────────────
  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result =
        await _repo.login(email: event.email, password: event.password);
    result.fold(
      (f) => emit(AuthError.fromFailure(f)),
      (user) => emit(AuthAuthenticated(user)),
    );
    _watchStatus();
  }

  // ── _onRegister ────────────────────────────────────────────────────────────
  Future<void> _onRegister(
      RegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _repo.register(
      email: event.email,
      password: event.password,
      phone: event.phone,
      displayName: event.displayName,
      role: event.role,
    );
    result.fold(
      (f) => emit(AuthError.fromFailure(f)),
      (user) => emit(AuthAuthenticated(user)),
    );
    _watchStatus();
  }

  // ── _onLogout ──────────────────────────────────────────────────────────────
  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    // Cancel the watcher so it doesn't double-fire _AuthSignedOut.
    await _signOutSub?.cancel();
    await _statusSub?.cancel();
    final result = await _repo.logout();
    result.fold(
      (f) => emit(AuthError.fromFailure(f)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  // ── _onSignedOut (internal) ────────────────────────────────────────────────
  void _onSignedOut(_AuthSignedOut event, Emitter<AuthState> emit) {
    _statusSub?.cancel();
    emit(const AuthUnauthenticated());
  }

  // ── Misc ───────────────────────────────────────────────────────────────────
  Future<void> _onVerificationEmail(
    VerificationEmailSent event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.sendVerificationEmail();
  }

  Future<void> _onPhoneVerification(
    PhoneVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.sendPhoneVerification(event.phone);
  }

  Future<void> _onPasswordReset(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.resetPassword(event.email);
  }

  @override
  Future<void> close() {
    _signOutSub?.cancel();
    _statusSub?.cancel();
    return super.close();
  }
}
