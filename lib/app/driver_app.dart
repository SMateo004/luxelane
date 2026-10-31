import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/injection.dart';
import '../core/services/connection_status.dart';
import '../core/services/locale_sync.dart';
import '../core/services/notification_service.dart';
import '../core/widgets/lux_connection_banner.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/booking/presentation/bloc/booking_bloc.dart';
import '../features/driver/presentation/bloc/driver_bloc.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';
import '../features/payments/presentation/bloc/payment_bloc.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';
import '../l10n/l10n.dart';
import 'driver_router/driver_router.dart';
import 'locale_controller.dart';
import 'lux_locale.dart';
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
  final LocaleController _locale = sl<LocaleController>();
  late final dynamic _router;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthStarted());
    _driverBloc = sl<DriverBloc>();
    _notificationBloc = sl<NotificationBloc>();
    _locale.load();
    _router = buildDriverRouter(_authBloc, _driverBloc);

    // When auth completes, init driver + notifications. AuthAuthenticated se
    // repite al editar el perfil: arrancar de nuevo perdería los descartes.
    String? sessionUid;
    _authBloc.stream.listen((state) {
      if (state is AuthAuthenticated) {
        if (state.user.id == sessionUid) return;
        sessionUid = state.user.id;
        _driverBloc.add(DriverStarted(userId: state.user.id));
        _notificationBloc.add(NotificationWatchStarted(userId: state.user.id));
        // Primer inicio de sesión: guarda el idioma del teléfono en la cuenta.
        sl<LocaleSync>().onSignedIn(
          serverLocale: state.user.locale,
          serverSource: state.user.localeSource,
        );
        // Sin token FCM el chófer no recibe los avisos de viajes nuevos.
        sl<NotificationService>().init(
          userId: state.user.id,
          role: state.user.role,
        );
      } else if (state is AuthUnauthenticated || state is AuthError) {
        // Cerrar sesión o un bloqueo en vivo: se detiene el rastreo.
        if (sessionUid != null) _driverBloc.add(const DriverStopped());
        sessionUid = null;
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
      // El idioma cambia al instante al elegirlo en el perfil.
      child: ValueListenableBuilder<LocaleChoice>(
        valueListenable: _locale,
        builder: (context, choice, _) => MaterialApp.router(
          title: kAppTitle,
          // En la pestaña del navegador y el selector de apps, en el idioma
          // activo (en español es el mismo kAppTitle).
          onGenerateTitle: (context) => context.l10n.commonAppTitle,
          debugShowCheckedModeBanner: false,
          locale: choice == LocaleChoice.system ? null : Locale(choice.name),
          localeListResolutionCallback: LuxLocale.resolveList,
          supportedLocales: LuxLocale.supportedLocales,
          localizationsDelegates: LuxLocale.delegates,
          builder: (context, child) {
            // Textos fuera de los widgets (blocs, enums) en el idioma activo.
            L10n.use(Localizations.localeOf(context));
            return LuxConnectionBanner(
              online: ConnectionStatus.watch(sl<FirebaseFirestore>()),
              child: child ?? const SizedBox.shrink(),
            );
          },
          theme: luxTheme,
          routerConfig: _router,
        ),
      ),
    );
  }
}
