import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/mfa_enroll_page.dart';
import '../../../driver/presentation/bloc/driver_bloc.dart';
import '../../data/driver_registration_repository.dart';
import '../../data/image_prep.dart';
import '../../data/photo_picker.dart';
import '../bloc/registration_cubit.dart';
import 'driver_application_intro_page.dart';
import 'driver_registration_page.dart';

/// /driver/onboarding: pantalla previa (cuenta de pasajero) o registro por
/// pasos (chófer sin verificar). Sustituye al alta antigua, que escribía
/// driverProfiles y vehicles desde el cliente.
class DriverRegistrationEntry extends StatelessWidget {
  const DriverRegistrationEntry({
    super.key,
    this.repository,
    this.imagePrep,
    this.picker,
  });

  final DriverRegistrationRepository? repository;
  final ImagePrep? imagePrep;
  final PhotoPicker? picker;

  DriverRegistrationRepository get _repo =>
      repository ?? sl<DriverRegistrationRepository>();

  void _restart(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<DriverBloc>().add(DriverStarted(userId: auth.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverBloc>().state;
    final auth = context.watch<AuthBloc>().state;
    // En la app del pasajero el DriverBloc no arranca para un pasajero: el
    // rol de la sesión también cuenta.
    final isRider =
        auth is AuthAuthenticated && auth.user.role == UserRole.rider;
    if (driver is DriverApplicationStartRequired || isRider) {
      return DriverApplicationIntroPage(
        repository: _repo,
        onStarted: () => _restart(context),
      );
    }
    return BlocProvider(
      create: (_) => RegistrationCubit(
        repository: _repo,
        imagePrep: imagePrep ?? DeviceImagePrep(),
      )..load(),
      child: DriverRegistrationPage(
        picker: picker ?? SystemPhotoPicker(),
        onEnrollMfa: (c) async {
          final auth = c.read<AuthBloc>().state;
          if (auth is! AuthAuthenticated) return;
          await Navigator.of(c).push(MaterialPageRoute<void>(
            builder: (_) => MfaEnrollPage(accountName: auth.user.email),
          ));
        },
      ),
    );
  }
}
