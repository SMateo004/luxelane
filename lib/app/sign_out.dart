import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/driver/presentation/bloc/driver_bloc.dart';

/// Cierra sesión dejando antes al chófer desconectado: con la sesión ya
/// cerrada Firestore no aceptaría la escritura y seguiría recibiendo viajes.
Future<void> signOut(BuildContext context) async {
  final auth = context.read<AuthBloc>();
  DriverBloc? driver;
  try {
    driver = context.read<DriverBloc>();
  } catch (_) {
    driver = null;
  }
  if (driver != null && driver.state is DriverLoaded) {
    driver.add(const DriverSignedOut());
    try {
      await driver.stream
          .firstWhere((s) => s is DriverInitial)
          .timeout(const Duration(seconds: 4));
    } on TimeoutException {
      // Sin conexión: el servidor ignora a chóferes sin señal reciente.
    }
  }
  auth.add(const LogoutRequested());
}
