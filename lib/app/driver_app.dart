import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/injection.dart';
import '../core/repositories/repositories.dart';
import '../core/services/notification_service.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/booking/presentation/bloc/booking_bloc.dart';
import '../features/driver/presentation/bloc/driver_bloc.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';
import '../features/payments/presentation/bloc/payment_bloc.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';
import '../l10n/l10n.dart';
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
    _authBloc         = sl<AuthBloc>()..add(const AuthStarted());
    _driverBloc       = sl<DriverBloc>();
    _notificationBloc = sl<NotificationBloc>();
    _router = buildDriverRouter(_authBloc, _driverBloc);

    // When auth completes, init driver + notifications
    _authBloc.stream.listen((state) {
      if (state is AuthAuthenticated) {
        _driverBloc.add(DriverStarted(userId: state.user.id));
        _notificationBloc.add(
          NotificationWatchStarted(userId: state.user.id),
        );
        // Drivers must receive "new booking" pushes.
        sl<NotificationService>().init(userId: state.user.id);
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
        onGenerateTitle: (context) => context.l10n.appNameDriver,
        debugShowCheckedModeBanner: false,
        theme: luxTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: supportedAppLocales,
        // No fixed `locale`: the app follows the device language and
        // updates live when it changes in system settings.
        localeListResolutionCallback: resolveAppLocale,
        builder: (context, child) => IntlLocaleSync(
          onLocaleChanged: (locale) {
            final state = _authBloc.state;
            if (state is AuthAuthenticated) {
              sl<UserRepository>().updatePreferredLocale(userId: state.user.id, locale: locale);
            }
          },
          child: child ?? const SizedBox.shrink(),
        ),
        routerConfig: _router,
      ),
    );
  }
}
