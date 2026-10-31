import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../l10n/l10n.dart';
import '../../../driver/presentation/widgets/driver_preferences_card.dart';

/// Preferencias del pasajero en el detalle de una reserva del panel: la
/// copia bookings/{id}/driverView/preferences, que el admin puede leer
/// siempre. Misma tarjeta que ve el chófer (la URL de la lista nunca se
/// muestra; el botón avisa antes y la abre fuera de la app). Sin copia, o
/// si no se pudo leer, un texto sobrio.
class AdminBookingPreferences extends StatelessWidget {
  const AdminBookingPreferences({
    super.key,
    required this.bookingId,
    this.repository,
    this.launch,
  });

  final String bookingId;

  /// Por defecto, el del contenedor de dependencias.
  final PreferencesRepository? repository;

  /// Por defecto, abrir en otra aplicación (url_launcher).
  final ExternalLauncher? launch;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final repo = repository ??
        (sl.isRegistered<PreferencesRepository>()
            ? sl<PreferencesRepository>()
            : null);
    final empty = Text(
      t.adminPrefsEmpty,
      style: LuxTypography.bodyMedium.copyWith(color: LuxColors.inkTertiary),
    );
    if (repo == null || bookingId.isEmpty) return empty;
    return StreamBuilder<TripPreferences?>(
      stream: repo.watchBookingPreferences(bookingId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return Semantics(
            label: t.adminPrefsLoadingLabel,
            child: const LinearProgressIndicator(),
          );
        }
        final prefs = snap.data;
        if (prefs == null || prefs.isEmpty) return empty;
        return launch == null
            ? DriverPreferencesView(preferences: prefs)
            : DriverPreferencesView(preferences: prefs, launch: launch!);
      },
    );
  }
}
