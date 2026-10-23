import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/config/remote_flags.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/services/maps_service.dart';
import '../bloc/incident_bloc.dart';
import 'incident_help_sheet.dart';
import 'sos_button.dart';

/// Ventana del botón: del chófer en camino al final del viaje.
bool sosAvailable(BookingStatus s) => const {
      BookingStatus.driverArriving,
      BookingStatus.driverArrived,
      BookingStatus.verified,
      BookingStatus.inProgress,
    }.contains(s);

/// Abre la pantalla de ayuda con los números de config/global.
Future<void> showIncidentHelp(BuildContext context, IncidentBloc bloc) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: LuxColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(LuxRadius.xl))),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: SingleChildScrollView(
          child: ValueListenableBuilder<String?>(
            valueListenable: RemoteFlags.instance.dispatchPhone,
            builder: (_, phone, __) =>
                ValueListenableBuilder<Map<String, String>>(
              valueListenable: RemoteFlags.instance.emergencyNumbers,
              builder: (_, numbers, __) => IncidentHelpSheet(
                bookingId: bloc.bookingId,
                dispatchPhone: phone,
                emergencyNumbers: numbers,
              ),
            ),
          ),
        ),
      ),
    );

/// SOS de la pantalla del viaje, para el pasajero o el chófer: solo lo ve
/// quien lo usa (la contraparte nunca se entera).
class SosEntry extends StatelessWidget {
  const SosEntry({
    super.key,
    required this.bookingId,
    required this.uid,
    required this.status,
    this.repository,
    this.openHelp = showIncidentHelp,
  });

  final String bookingId;
  final String uid;
  final BookingStatus status;
  final IncidentRepository? repository;
  final Future<void> Function(BuildContext, IncidentBloc) openHelp;

  @override
  Widget build(BuildContext context) => BlocProvider(
        key: ValueKey('sos-$bookingId'),
        create: (_) => IncidentBloc(
          repository: repository ?? sl<IncidentRepository>(),
          bookingId: bookingId,
          uid: uid,
          currentLocation: () async {
            final p = await sl<MapsService>().getCurrentPosition();
            return p == null ? null : (lat: p.latitude, lng: p.longitude);
          },
        )..add(const IncidentWatched()),
        child: BlocBuilder<IncidentBloc, IncidentState>(
          builder: (context, s) {
            final bloc = context.read<IncidentBloc>();
            if (s.live) {
              // Aviso en curso: acceso directo a la pantalla de ayuda.
              return ActionChip(
                key: const ValueKey('sos-live'),
                avatar: const Icon(Icons.support_agent_rounded,
                    size: 18, color: LuxColors.error),
                label: const Text('Ayuda en curso'),
                onPressed: () => openHelp(context, bloc),
              );
            }
            if (!sosAvailable(status)) return const SizedBox.shrink();
            return SosButton(
              onActivated: () {
                bloc.add(const IncidentRaised());
                openHelp(context, bloc);
              },
            );
          },
        ),
      );
}
