// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Luxelane';

  @override
  String get appNameDriver => 'Luxelane Chófer';

  @override
  String get commonBack => 'Volver';

  @override
  String get commonCall => 'Llamar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonConnectionError => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonCopy => 'Copiar';

  @override
  String get commonCouldNotOpenApp => 'No se pudo abrir la aplicación';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonGenericError => 'Algo no salió bien';

  @override
  String get commonLoading => 'Cargando';

  @override
  String get commonOptional => 'Opcional';

  @override
  String get commonRefresh => 'Actualizar';

  @override
  String get commonRequired => 'Requerido';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSend => 'Enviar';

  @override
  String get commonWhatsApp => 'WhatsApp';

  @override
  String get flightCancelled => 'Cancelado';

  @override
  String flightDelayed(int minutes) {
    return 'Retrasado $minutes min';
  }

  @override
  String get flightLanded => 'Aterrizó';

  @override
  String get flightOnTime => 'A tiempo';

  @override
  String get serviceByTheHour => 'Por horas';

  @override
  String get serviceByTheHourDesc => 'Chófer a tu disposición por un tiempo determinado';

  @override
  String get serviceOneWay => 'Solo ida';

  @override
  String get serviceOneWayDesc => 'Traslado a precio fijo a tu destino';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusConfirmed => 'Confirmado';

  @override
  String get statusDriverArrived => 'Chófer llegó';

  @override
  String get statusDriverArriving => 'En camino';

  @override
  String get statusInProgress => 'En progreso';

  @override
  String get statusPending => 'Pendiente';

  @override
  String unitBags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count maletas',
      one: '1 maleta',
    );
    return '$_temp0';
  }

  @override
  String unitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String unitHoursMinutes(int hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String unitMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String unitPassengers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pasajeros',
      one: '1 pasajero',
    );
    return '$_temp0';
  }

  @override
  String unitTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viajes',
      one: '1 viaje',
    );
    return '$_temp0';
  }

  @override
  String get vehicleBusiness => 'Business Class';

  @override
  String get vehicleBusinessDesc => 'Mercedes E-Class o similar';

  @override
  String get vehicleBusinessVan => 'Business Van';

  @override
  String get vehicleBusinessVanDesc => 'Mercedes V-Class · Hasta 7';

  @override
  String get vehicleElectric => 'Eléctrico';

  @override
  String get vehicleElectricDesc => 'Tesla Model S o similar';

  @override
  String get vehicleFirstClass => 'First Class';

  @override
  String get vehicleFirstClassDesc => 'Mercedes S-Class o similar';

  @override
  String waitAirportSummary(int minutes) {
    return '$minutes min de espera gratuita desde el aterrizaje';
  }

  @override
  String waitCitySummary(int minutes) {
    return '$minutes min de espera gratuita';
  }
}
