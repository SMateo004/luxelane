import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

class _AuthSessionDetected extends AuthEvent {
  const _AuthSessionDetected();
}

class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);
  final User user;
  @override
  List<Object?> get props => [user];
}

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
  // Cambios que la app debe notar en vivo (no los tokens de notificación).
  @override
  List<Object?> get props => [
        user.id,
        user.role,
        user.isActive,
        user.isVerified,
        user.displayName,
        user.phone,
        user.photoUrl,
        user.stripeCustomerId,
        user.companyId,
        user.companyRole,
      ];
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
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<LogoutRequested>(_onLogout);
    on<_AuthSignedOut>(_onSignedOut);
    on<VerificationEmailSent>(_onVerificationEmail);
    on<PhoneVerificationRequested>(_onPhoneVerification);
    on<PasswordResetRequested>(_onPasswordReset);
    on<_AuthUserChanged>(_onUserChanged);
    on<_AuthSessionDetected>(_onSessionDetected);
  }

  Future<void> _onSessionDetected(
      _AuthSessionDetected event, Emitter<AuthState> emit) async {
    // Solo si la app cree que no hay sesión; el login la gestiona él mismo.
    if (state is! AuthUnauthenticated && state is! AuthInitial) return;
    User? user;
    try {
      user = await _repo.authStateChanges.first;
    } catch (_) {
      user = null;
    }
    if (user != null && state is! AuthAuthenticated) {
      _emitAuthenticated(user, emit);
    }
  }

  final AuthRepository _repo;

  // Watches the raw Firebase sign-in flag after the initial state is resolved.
  // Only reacts to sign-out (false) so it never races with _onLogin/_onRegister.
  StreamSubscription<bool>? _signOutSub;

  // Perfil en vivo del usuario con sesión: un bloqueo del admin lo saca de
  // la app al momento y los cambios (nombre, Stripe) llegan sin reiniciar.
  StreamSubscription<User?>? _userSub;
  String? _watching;

  void _watchUser(String uid) {
    if (_watching == uid) return;
    _userSub?.cancel();
    _watching = uid;
    _userSub = _repo.watchCurrentUser(uid).listen(
      (u) {
        if (u != null && !isClosed) add(_AuthUserChanged(u));
      },
      onError: (Object _) {},
    );
  }

  void _stopWatchingUser() {
    _userSub?.cancel();
    _userSub = null;
    _watching = null;
  }

  void _emitAuthenticated(User user, Emitter<AuthState> emit) {
    emit(AuthAuthenticated(user));
    _watchUser(user.id);
  }

  Future<void> _onUserChanged(
      _AuthUserChanged event, Emitter<AuthState> emit) async {
    if (state is! AuthAuthenticated) return;
    if ((state as AuthAuthenticated).user.id != event.user.id) return;
    if (!event.user.isActive) {
      _stopWatchingUser();
      await _repo.logout();
      emit(const AuthError(
          'Tu cuenta está suspendida. Contacta con soporte de Luxelane.'));
      return;
    }
    emit(AuthAuthenticated(event.user));
  }

  // ── _onStarted ─────────────────────────────────────────────────────────────
  // Reads exactly ONE emission from authStateChanges (Firebase + Firestore) to
  // resolve the initial session, then hands off to _signOutSub for the rest.
  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    // .take(1) closes the stream after the first event so emit.forEach returns
    // immediately instead of blocking forever.
    User? initial;
    try {
      initial = await _repo.authStateChanges.first;
    } catch (_) {
      initial = null;
    }
    if (initial != null) {
      _emitAuthenticated(initial, emit);
    } else {
      emit(const AuthUnauthenticated());
    }

    // Vigila el cierre de sesión (expiración, otro dispositivo…) durante
    // toda la vida del bloc, también tras volver a iniciar sesión.
    await _signOutSub?.cancel();
    _signOutSub = _repo.isSignedIn.listen((signedIn) {
      if (isClosed) return;
      // En web Firebase restaura la sesión guardada un instante después de
      // arrancar: si llega tarde, se recupera en vez de dejarla cerrada.
      add(signedIn ? const _AuthSessionDetected() : const _AuthSignedOut());
    });
  }

  // ── _onLogin ───────────────────────────────────────────────────────────────
  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result =
        await _repo.login(email: event.email, password: event.password);
    result.fold(
      (f) => emit(AuthError(f.message)),
      (user) => _emitAuthenticated(user, emit),
    );
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
      (f) => emit(AuthError(f.message)),
      (user) => _emitAuthenticated(user, emit),
    );
  }

  // ── _onGoogleSignIn ────────────────────────────────────────────────────────
  Future<void> _onGoogleSignIn(
      GoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _repo.signInWithGoogle();
    result.fold(
      // Closing the Google sheet is a choice, not an error: no message.
      (f) => emit(f is AuthCancelledFailure
          ? const AuthUnauthenticated()
          : AuthError(f.message)),
      (user) => _emitAuthenticated(user, emit),
    );
  }

  // ── _onLogout ──────────────────────────────────────────────────────────────
  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    _stopWatchingUser();
    final result = await _repo.logout();
    result.fold(
      (f) => emit(AuthError(f.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  // ── _onSignedOut (internal) ────────────────────────────────────────────────
  void _onSignedOut(_AuthSignedOut event, Emitter<AuthState> emit) {
    _stopWatchingUser();
    // Un aviso (cuenta suspendida) no se pisa con un cierre genérico.
    if (state is AuthAuthenticated) {
      emit(const AuthUnauthenticated());
    }
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
    _userSub?.cancel();
    return super.close();
  }
}
