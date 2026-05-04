import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/injection.dart';
import '../core/enums/enums.dart';
import '../core/services/crash_service.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/booking/presentation/bloc/booking_bloc.dart';
import '../features/booking/presentation/bloc/vehicle_bloc.dart';
import '../features/driver/presentation/bloc/driver_bloc.dart';
import '../features/payments/presentation/bloc/payment_bloc.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';
import '../features/ride/presentation/bloc/ride_bloc.dart';
import 'router/router.dart';
import 'theme/app_theme.dart';

class LuxelaneApp extends StatefulWidget {
  const LuxelaneApp({super.key});

  @override
  State<LuxelaneApp> createState() => _LuxelaneAppState();
}

class _LuxelaneAppState extends State<LuxelaneApp> {
  // ── BLoCs — created once, never recreated ──────────────────────────────
  late final AuthBloc    _authBloc;
  late final BookingBloc _bookingBloc;
  late final VehicleBloc _vehicleBloc;
  late final RideBloc    _rideBloc;
  late final PaymentBloc _paymentBloc;
  late final ProfileBloc _profileBloc;
  late final DriverBloc           _driverBloc;
  late final NotificationBloc     _notificationBloc;

  // ── Routers — created once ─────────────────────────────────────────────
  late final dynamic _router;

  @override
  void initState() {
    super.initState();

    _authBloc         = sl<AuthBloc>()..add(const AuthStarted());
    _bookingBloc      = sl<BookingBloc>();
    _vehicleBloc      = sl<VehicleBloc>();
    _rideBloc         = sl<RideBloc>();
    _paymentBloc      = sl<PaymentBloc>();
    _profileBloc      = sl<ProfileBloc>();
    _driverBloc       = sl<DriverBloc>();
    _notificationBloc = sl<NotificationBloc>();

    _router = buildRouter(_authBloc);

    // Start DriverBloc + NotificationBloc only when authenticated
    _authBloc.stream.listen((state) {
      if (state is AuthAuthenticated) {
        CrashService.setUser(state.user.id);
        if (state.user.role == UserRole.driver &&
            _driverBloc.state is DriverInitial) {
          _driverBloc.add(DriverStarted(userId: state.user.id));
        }
        _notificationBloc.add(
          NotificationWatchStarted(userId: state.user.id),
        );
      }
    });
  }

  @override
  void dispose() {
    _authBloc.close();
    _bookingBloc.close();
    _vehicleBloc.close();
    _rideBloc.close();
    _paymentBloc.close();
    _profileBloc.close();
    _driverBloc.close();
    _notificationBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // All BLoCs provided via .value — never recreated on rebuild
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<BookingBloc>.value(value: _bookingBloc),
        BlocProvider<VehicleBloc>.value(value: _vehicleBloc),
        BlocProvider<RideBloc>.value(value: _rideBloc),
        BlocProvider<PaymentBloc>.value(value: _paymentBloc),
        BlocProvider<ProfileBloc>.value(value: _profileBloc),
        BlocProvider<DriverBloc>.value(value: _driverBloc),
        BlocProvider<NotificationBloc>.value(value: _notificationBloc),
      ],
      child: MaterialApp.router(
        title: 'Luxelane',
        debugShowCheckedModeBanner: false,
        theme: luxTheme,
        routerConfig: _router,
      ),
    );
  }
}
