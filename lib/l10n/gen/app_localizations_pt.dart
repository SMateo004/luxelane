// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Luxelane';

  @override
  String get appNameDriver => 'Luxelane Motorista';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonCall => 'Ligar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonConnectionError => 'Verifique sua conexão e tente novamente.';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonCopy => 'Copiar';

  @override
  String get commonCouldNotOpenApp => 'Não foi possível abrir o aplicativo';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonGenericError => 'Algo deu errado';

  @override
  String get commonLoading => 'Carregando';

  @override
  String get commonOptional => 'Opcional';

  @override
  String get commonRefresh => 'Atualizar';

  @override
  String get commonRequired => 'Obrigatório';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonSend => 'Enviar';

  @override
  String get commonWhatsApp => 'WhatsApp';

  @override
  String get flightCancelled => 'Cancelado';

  @override
  String flightDelayed(int minutes) {
    return 'Atrasado $minutes min';
  }

  @override
  String get flightLanded => 'Pousou';

  @override
  String get flightOnTime => 'No horário';

  @override
  String legalCompanyDetails(String nit, String address) {
    return 'NIT (identificação fiscal) $nit · $address';
  }

  @override
  String get legalContactComingSoon => 'Os canais de contato serão publicados em breve.';

  @override
  String get legalContactEmail => 'E-mail';

  @override
  String get legalContactHeadline => 'Estamos aqui para ajudar';

  @override
  String get legalContactIntro => 'Escreva para nós com qualquer dúvida sobre uma reserva, sua conta ou seus dados. Se você tiver uma viagem em andamento, use os botões de contato com seu motorista na tela da viagem.';

  @override
  String get legalContactTitle => 'Contato';

  @override
  String get legalDeleteActiveTrip => 'Você tem uma viagem em andamento. Poderá excluir sua conta quando ela terminar.';

  @override
  String get legalDeleteButton => 'Excluir minha conta';

  @override
  String legalDeleteConfirmPrompt(String keyword) {
    return 'Digite $keyword para confirmar.';
  }

  @override
  String get legalDeleteConnectionError => 'Não conseguimos excluir sua conta. Verifique sua conexão.';

  @override
  String get legalDeleteEffectBookings => 'Cancelamos suas reservas pendentes.';

  @override
  String get legalDeleteEffectDriver => 'Se você for motorista, também apagamos seu perfil de motorista e desativamos seu veículo.';

  @override
  String get legalDeleteEffectPermanent => 'Esta ação não pode ser desfeita.';

  @override
  String get legalDeleteEffectProfile => 'Apagamos seu perfil, suas notificações e seu acesso.';

  @override
  String get legalDeleteEffectTrips => 'Removemos seu nome, telefone e observações das suas viagens anteriores. Os registros dessas viagens são mantidos sem dados de contato por obrigações contábeis.';

  @override
  String get legalDeleteFailed => 'Não conseguimos excluir sua conta. Tente novamente ou fale conosco.';

  @override
  String get legalDeleteHeadline => 'Excluir sua conta';

  @override
  String get legalDeleteIntro => 'Ao excluir sua conta:';

  @override
  String get legalDeleteKeyword => 'EXCLUIR';

  @override
  String get legalDeleteSignIn => 'Entrar';

  @override
  String get legalDeleteSignInPrompt => 'Entre com a conta que você deseja excluir.';

  @override
  String get legalDeleteSuccess => 'Sua conta foi excluída.';

  @override
  String get legalDeleteTitle => 'Excluir conta';

  @override
  String get legalDraftBanner => 'Rascunho: este documento contém dados pendentes entre colchetes e deve ser revisado por um advogado antes de ser publicado.';

  @override
  String legalLastUpdated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Última atualização: $dateString';
  }

  @override
  String get serviceByTheHour => 'Por hora';

  @override
  String get serviceByTheHourDesc => 'Motorista à sua disposição por um tempo determinado';

  @override
  String get serviceOneWay => 'Só ida';

  @override
  String get serviceOneWayDesc => 'Traslado com preço fixo até o seu destino';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get statusCompleted => 'Concluído';

  @override
  String get statusConfirmed => 'Confirmado';

  @override
  String get statusDriverArrived => 'Motorista chegou';

  @override
  String get statusDriverArriving => 'A caminho';

  @override
  String get statusInProgress => 'Em andamento';

  @override
  String get statusPending => 'Pendente';

  @override
  String unitBags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count malas',
      one: '1 mala',
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
      other: '$count passageiros',
      one: '1 passageiro',
    );
    return '$_temp0';
  }

  @override
  String unitTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viagens',
      one: '1 viagem',
    );
    return '$_temp0';
  }

  @override
  String get vehicleBusiness => 'Business Class';

  @override
  String get vehicleBusinessDesc => 'Mercedes Classe E ou similar';

  @override
  String get vehicleBusinessVan => 'Business Van';

  @override
  String get vehicleBusinessVanDesc => 'Mercedes Classe V · Até 7';

  @override
  String get vehicleElectric => 'Elétrico';

  @override
  String get vehicleElectricDesc => 'Tesla Model S ou similar';

  @override
  String get vehicleFirstClass => 'First Class';

  @override
  String get vehicleFirstClassDesc => 'Mercedes Classe S ou similar';

  @override
  String waitAirportSummary(int minutes) {
    return '$minutes min de espera grátis a partir do pouso';
  }

  @override
  String waitCitySummary(int minutes) {
    return '$minutes min de espera grátis';
  }
}
