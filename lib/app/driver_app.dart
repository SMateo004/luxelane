import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/injection.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/booking/presentation/bloc/booking_bloc.dart';
import '../features/driver/presentation/bloc/driver_bloc.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';
import '../features/payments/presentation/bloc/payment_bloc.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';
import 'driver_router/driver_router.dart';
import 'theme/app_theme.dart';

class DriverApp extends StatefulWidget {
  const DriverApp({super.key});

  @override
  State<DriverApp> createState() => _DriverAppState();
}

class _DriverAppState extends State<DriverApp> {
  late final AuthBloc _authBloc;
  late final DriverBloc _driverBloc;
  late final NotificationBloc _notificationBloc;
  late final dynamic _router;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthStarted());
    _driverBloc = sl<DriverBloc>();
    _notificationBloc = sl<NotificationBloc>();
    _router = buildDriverRouter(_authBloc, _driverBloc);

    // When auth completes, init driver + notifications
    // El perfil en vivo re-emite AuthAuthenticated en cada cambio: solo se
    // arranca de nuevo cuando cambia el usuario o el chófer estaba parado.
    String? startedFor;
    _authBloc.stream.listen((state) {
      if (state is AuthAuthenticated) {
        final uid = state.user.id;
        if (startedFor != uid || _driverBloc.state is DriverInitial) {
          _driverBloc.add(DriverStarted(userId: uid));
        }
        if (startedFor != uid) {
          _notificationBloc.add(NotificationWatchStarted(userId: uid));
        }
        startedFor = uid;
      } else if (state is! AuthLoading) {
        startedFor = null;
      }
      if (state is! AuthAuthenticated &&
          state is! AuthLoading &&
          _driverBloc.state is! DriverInitial) {
        // Sesión cerrada o expirada: nada de escuchas ni ubicación.
        _driverBloc.add(const DriverSignedOut());
      }
    });
  }

  @override
  void dispose() {
    _authBloc.close();
    _driverBloc.close();
    _notificationBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<DriverBloc>.value(value: _driverBloc),
        BlocProvider<NotificationBloc>.value(value: _notificationBloc),
        BlocProvider<BookingBloc>(create: (_) => sl<BookingBloc>()),
        BlocProvider<PaymentBloc>(create: (_) => sl<PaymentBloc>()),
        BlocProvider<ProfileBloc>(create: (_) => sl<ProfileBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Luxelane Driver',
        debugShowCheckedModeBanner: false,
        theme: luxTheme,
        routerConfig: _router,
      ),
    );
  }
}
