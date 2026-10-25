import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/mfa.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

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

class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// El segundo paso (TOTP) terminó bien.
class MfaSignInCompleted extends AuthEvent {
  const MfaSignInCompleted(this.user);
  final User user;
  @override
  List<Object?> get props => [user.id];
}

class VerificationEmailSent extends AuthEvent {
  const VerificationEmailSent();
}

class PasswordResetRequested extends AuthEvent {
  const PasswordResetRequested({required this.email});
  final String email;
  @override
  List<Object?> get props => [email];
}

// Internal — fired by the background Firebase watcher when the session
// expires or the user signs out on another device.
class _AuthProfileChanged extends AuthEvent {
  const _AuthProfileChanged(this.user);
  final User? user;
  @override
  List<Object?> get props => [user?.id, user?.isActive];
}

class _AuthSignedOut extends AuthEvent {
  const _AuthSignedOut();
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
  // Los campos que pueden cambiar en vivo (admin o servidor) forman parte
  // del estado, así un cambio real se emite y uno irrelevante no.
  @override
  List<Object?> get props => [
        user.id,
        user.role,
        user.isActive,
        user.stripeCustomerId,
        user.displayName,
        user.phone,
        user.photoUrl,
      ];
}

/// El inicio de sesión pide el código de la app autenticadora.
class AuthMfaRequired extends AuthState {
  const AuthMfaRequired(this.challenge);
  final MfaChallenge challenge;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _repo = authRepository,
        super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<MfaSignInCompleted>(_onMfaCompleted);
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<LogoutRequested>(_onLogout);
    on<_AuthSignedOut>(_onSignedOut);
    on<VerificationEmailSent>(_onVerificationEmail);
    on<PasswordResetRequested>(_onPasswordReset);
    on<_AuthProfileChanged>(_onProfileChanged);
  }

  StreamSubscription<User?>? _profileSub;

  /// Tras entrar: vigila el cierre de sesión y el perfil en vivo.
  void _watchSession(String uid) {
    _signOutSub?.cancel();
    _signOutSub = _repo.isSignedIn.listen((signedIn) {
      if (!signedIn && !isClosed) add(const _AuthSignedOut());
    });
    _profileSub?.cancel();
    _profileSub = _repo.watchUser(uid).listen((u) {
      if (!isClosed) add(_AuthProfileChanged(u));
    }, onError: (_) {});
  }

  Future<void> _onProfileChanged(
    _AuthProfileChanged event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    final u = event.user;
    if (u == null) return; // aún creándose (registro)
    if (!u.isActive) {
      // Bloqueado desde el panel admin con la app abierta.
      await _profileSub?.cancel();
      await _signOutSub?.cancel();
      await _repo.logout();
      emit(AuthError(blockedAccountMessage(u.role)));
      return;
    }
    emit(AuthAuthenticated(u));
  }

  final AuthRepository _repo;

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
      // Cuenta bloqueada al abrir la app: el login muestra el motivo.
      onError: (e, __) => e is AuthFailure && isBlockedAccountMessage(e.message)
          ? AuthError(e.message)
          : const AuthUnauthenticated(),
    );

    final s = state;
    if (s is AuthAuthenticated) {
      _watchSession(s.user.id);
    } else {
      // Sin sesión: solo hace falta enterarse de un cierre externo.
      await _signOutSub?.cancel();
      _signOutSub = _repo.isSignedIn.listen((signedIn) {
        if (!signedIn && !isClosed) add(const _AuthSignedOut());
      });
    }
  }

  // ── _onLogin ───────────────────────────────────────────────────────────────
  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _repo.login(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (f) => emit(
        f is MfaRequiredFailure
            ? AuthMfaRequired(f.challenge)
            : AuthError(f.message),
      ),
      (user) {
        emit(AuthAuthenticated(user));
        _watchSession(user.id);
      },
    );
  }

  void _onMfaCompleted(MfaSignInCompleted event, Emitter<AuthState> emit) {
    emit(AuthAuthenticated(event.user));
    _watchSession(event.user.id);
  }

  // ── _onRegister ────────────────────────────────────────────────────────────
  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repo.register(
      email: event.email,
      password: event.password,
      phone: event.phone,
      displayName: event.displayName,
      role: event.role,
    );
    result.fold((f) => emit(AuthError(f.message)), (user) {
      emit(AuthAuthenticated(user));
      _watchSession(user.id);
    });
  }

  // ── _onGoogleSignIn ────────────────────────────────────────────────────────
  Future<void> _onGoogleSignIn(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repo.signInWithGoogle();
    result.fold(
      // Closing the Google sheet is a choice, not an error: no message.
      (f) => emit(
        f is AuthCancelledFailure
            ? const AuthUnauthenticated()
            : f is MfaRequiredFailure
                ? AuthMfaRequired(f.challenge)
                : AuthError(f.message),
      ),
      (user) {
        emit(AuthAuthenticated(user));
        _watchSession(user.id);
      },
    );
  }

  // ── _onLogout ──────────────────────────────────────────────────────────────
  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    // Cancel the watchers so they don't double-fire _AuthSignedOut.
    await _signOutSub?.cancel();
    await _profileSub?.cancel();
    final result = await _repo.logout();
    result.fold(
      (f) => emit(AuthError(f.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  // ── _onSignedOut (internal) ────────────────────────────────────────────────
  void _onSignedOut(_AuthSignedOut event, Emitter<AuthState> emit) {
    _profileSub?.cancel();
    emit(const AuthUnauthenticated());
  }

  // ── Misc ───────────────────────────────────────────────────────────────────
  Future<void> _onVerificationEmail(
    VerificationEmailSent event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.sendVerificationEmail();
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
    _profileSub?.cancel();
    return super.close();
  }
}
