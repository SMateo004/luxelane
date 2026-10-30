import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/di/injection.dart';
import '../core/services/connection_status.dart';
import '../core/services/notification_service.dart';
import '../core/enums/enums.dart';
import '../core/services/crash_service.dart';
import '../core/services/locale_sync.dart';
import '../core/widgets/lux_connection_banner.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/booking/presentation/bloc/booking_bloc.dart';
import '../features/driver/presentation/bloc/driver_bloc.dart';
import '../features/payments/presentation/bloc/payment_bloc.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';
import 'locale_controller.dart';
import 'lux_locale.dart';
import 'router/router.dart';
import 'theme/app_theme.dart';

class LuxelaneApp extends StatefulWidget {
  const LuxelaneApp({super.key});

  @override
  State<LuxelaneApp> createState() => _LuxelaneAppState();
}

class _LuxelaneAppState extends State<LuxelaneApp> {
  // ── BLoCs — created once, never recreated ──────────────────────────────
  late final AuthBloc _authBloc;
  late final BookingBloc _bookingBloc;
  late final PaymentBloc _paymentBloc;
  late final ProfileBloc _profileBloc;
  late final DriverBloc _driverBloc;
  late final NotificationBloc _notificationBloc;
  final LocaleController _locale = sl<LocaleController>();

  // ── Routers — created once ─────────────────────────────────────────────
  late final dynamic _router;

  @override
  void initState() {
    super.initState();

    _authBloc = sl<AuthBloc>()..add(const AuthStarted());
    _bookingBloc = sl<BookingBloc>();
    _paymentBloc = sl<PaymentBloc>();
    _profileBloc = sl<ProfileBloc>();
    _driverBloc = sl<DriverBloc>();
    _notificationBloc = sl<NotificationBloc>();
    _locale.load();

    _router = buildRouter(_authBloc);

    // Tocar el aviso de una reserva la abre.
    sl<NotificationService>().openedBookings.listen((id) {
      (_router as GoRouter).go('/ride/$id');
    });

    // Start DriverBloc + NotificationBloc only when authenticated. El estado
    // se repite al cambiar el perfil: solo se arranca al entrar un usuario.
    String? sessionUid;
    _authBloc.stream.listen((state) {
      if (state is! AuthAuthenticated) {
        // Sin sesión no quedan a la vista las tarjetas del usuario anterior.
        if (sessionUid != null) _paymentBloc.add(const PaymentReset());
        sessionUid = null;
        return;
      }
      if (state.user.id == sessionUid) return;
      sessionUid = state.user.id;
      {
        CrashService.setUser(state.user.id);
        if (state.user.role == UserRole.driver &&
            _driverBloc.state is DriverInitial) {
          _driverBloc.add(DriverStarted(userId: state.user.id));
        }
        _notificationBloc.add(NotificationWatchStarted(userId: state.user.id));
        // Primer inicio de sesión: guarda el idioma del teléfono en la cuenta.
        sl<LocaleSync>().onSignedIn(
          serverLocale: state.user.locale,
          serverSource: state.user.localeSource,
        );
        // Registra el dispositivo para los avisos de la reserva aunque el
        // pasajero no abra la pantalla del viaje.
        sl<NotificationService>().init(
          userId: state.user.id,
          role: state.user.role,
        );
      }
    });
  }

  @override
  void dispose() {
    _authBloc.close();
    _bookingBloc.close();
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
        BlocProvider<PaymentBloc>.value(value: _paymentBloc),
        BlocProvider<ProfileBloc>.value(value: _profileBloc),
        BlocProvider<DriverBloc>.value(value: _driverBloc),
        BlocProvider<NotificationBloc>.value(value: _notificationBloc),
      ],
      // El idioma cambia al instante al elegirlo en el perfil.
      child: ValueListenableBuilder<LocaleChoice>(
        valueListenable: _locale,
        builder: (context, choice, _) => MaterialApp.router(
          title: kAppTitle,
          debugShowCheckedModeBanner: false,
          locale: choice == LocaleChoice.system ? null : Locale(choice.name),
          localeListResolutionCallback: LuxLocale.resolveList,
          supportedLocales: LuxLocale.supportedLocales,
          localizationsDelegates: LuxLocale.delegates,
          builder: (context, child) => LuxConnectionBanner(
            online: ConnectionStatus.watch(sl<FirebaseFirestore>()),
            child: child ?? const SizedBox.shrink(),
          ),
          theme: luxTheme,
          routerConfig: _router,
        ),
      ),
    );
  }
}
