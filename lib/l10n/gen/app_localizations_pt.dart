// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get authLoginTitle => 'Entrar';

  @override
  String get authLoginWelcomeBack => 'Bem-vindo de volta à Luxelane.';

  @override
  String get authHomeLinkSemantics => 'Luxelane, ir para o início';

  @override
  String get authLoginEyebrow => 'BEM-VINDO';

  @override
  String get authLoginHeadline => 'Seu motorista,\ncomo você se lembra.';

  @override
  String get authLoginSubtitle =>
      'Entre para reservar e acompanhar seus trajetos.';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authEmailInvalid => 'Digite um e-mail válido';

  @override
  String get authPasswordLabel => 'Senha';

  @override
  String get authPasswordMinLength => 'Mínimo de 6 caracteres';

  @override
  String get authForgotPassword => 'Esqueceu sua senha?';

  @override
  String get authResetNeedsEmail =>
      'Digite seu e-mail acima e enviaremos um link.';

  @override
  String get authNoAccount => 'Não tem conta? ';

  @override
  String get authCreateOne => 'Criar uma';

  @override
  String get authBrandSubtitle =>
      'Seus endereços, preferências e viagens, sempre à mão.';

  @override
  String get authBrandPointBooking => 'Reserve em menos de 2 minutos';

  @override
  String get authBrandPointTrips => 'Todas as suas viagens em um só lugar';

  @override
  String get authBrandPointTracking => 'Acompanhe seu motorista em tempo real';

  @override
  String get authRegisterEyebrow => 'CRIAR CONTA';

  @override
  String get authRegisterHeadline => 'Bem-vindo\nà Luxelane.';

  @override
  String get authRegisterSubtitle => 'Crie sua conta em menos de um minuto.';

  @override
  String get authRegisterBrandSubtitle =>
      'Uma conta para reservar, acompanhar e lembrar cada trajeto.';

  @override
  String get authRegisterTitle => 'Criar conta';

  @override
  String get authRegisterWebSubtitle =>
      'Pediremos apenas o necessário para o seu motorista.';

  @override
  String get authGoogleRegister => 'Cadastrar-se com o Google';

  @override
  String get authNameLabel => 'Nome completo';

  @override
  String get authNameRequired =>
      'Informe seu nome para que seu motorista possa receber você';

  @override
  String get authPhoneLabel => 'Telefone (com código do país)';

  @override
  String get authPhoneRequired =>
      'Seu motorista precisa dele para entrar em contato com você';

  @override
  String get authTermsRequired =>
      'Aceite os Termos e a Política de Privacidade para continuar';

  @override
  String get authRegisterDataNote =>
      'Seu nome e telefone permitem que seu motorista receba você e entre em contato.';

  @override
  String get authHaveAccount => 'Já tem conta? ';

  @override
  String get authSignInLink => 'Entrar';

  @override
  String get authTermsCheckboxSemantics =>
      'Aceito os Termos e a Política de Privacidade';

  @override
  String get authTermsReadPrefix => 'Li e aceito os ';

  @override
  String get authTermsLink => 'Termos';

  @override
  String get authTermsAnd => ' e a ';

  @override
  String get authPrivacyLink => 'Política de Privacidade';

  @override
  String get authGoogleContinue => 'Continuar com o Google';

  @override
  String get authOrWithEmail => 'ou com seu e-mail';

  @override
  String get authVerifyTitle => 'Verifique seu e-mail';

  @override
  String get authVerifySentGeneric => 'Enviamos um link para o seu e-mail.';

  @override
  String authVerifySentTo(String email) {
    return 'Enviamos um link para $email.';
  }

  @override
  String get authVerifyBody =>
      'Abra o link e volte aqui. Você precisa do e-mail verificado para reservar. Se o link expirou ou não chegou, peça um novo (confira também a pasta de spam).';

  @override
  String get authVerifyResent => 'Enviamos um novo link para você.';

  @override
  String get authVerifyDone => 'E-mail verificado. Você já pode reservar.';

  @override
  String get authVerifyNotYet =>
      'Ainda não vemos seu e-mail verificado. Abra o link que enviamos e tente novamente.';

  @override
  String get authVerifyResendLimit => 'Limite de reenvios atingido';

  @override
  String authVerifyResendIn(int seconds) {
    return 'Reenviar link ($seconds s)';
  }

  @override
  String get authVerifyResend => 'Reenviar link';

  @override
  String get authVerifyConfirm => 'Já verifiquei';

  @override
  String get authVerifyLater => 'Mais tarde';

  @override
  String get authMfaTitle => 'Verificação em duas etapas';

  @override
  String get authMfaCodeDigits => 'Digite os 6 dígitos do código.';

  @override
  String get authCancel => 'Cancelar';

  @override
  String get authMfaSignInPrompt =>
      'Abra seu app autenticador e digite o código da Luxelane.';

  @override
  String get authMfaCodeLabel => 'Código';

  @override
  String get authMfaSignInButton => 'Entrar';

  @override
  String get authMfaLostAccess =>
      'Perdeu o acesso ao seu app autenticador? Fale com a central para recuperar a conta.';

  @override
  String get authMfaEnrollDone =>
      'Pronto. A partir de agora, ao entrar, pediremos o código do seu app autenticador.';

  @override
  String get authMfaBack => 'Voltar';

  @override
  String get authMfaEnrollIntro =>
      'Proteja sua conta com um app autenticador (por exemplo, o do seu celular ou o seu gerenciador de senhas). Ele pedirá um código de 6 dígitos ao entrar.';

  @override
  String get authMfaStart => 'Começar';

  @override
  String get authMfaScanStep =>
      '1. Escaneie este código com seu app autenticador.';

  @override
  String get authMfaQrSemantics => 'Código QR para o app autenticador';

  @override
  String get authMfaOpenInApp => 'Abrir no app autenticador';

  @override
  String authMfaManualKey(String key) {
    return 'Não consegue escanear? Digite esta chave: $key';
  }

  @override
  String get authMfaHideKey => 'Ocultar chave';

  @override
  String get authMfaShowKey => 'Mostrar chave';

  @override
  String get authMfaNoShare =>
      'Não compartilhe este código nem a chave, e não faça capturas de tela.';

  @override
  String get authMfaCodeStep => '2. Digite o código exibido no app.';

  @override
  String get authMfaActivate => 'Ativar';

  @override
  String get authMfaReminderTitle => 'Ative a verificação em duas etapas';

  @override
  String get authMfaReminderBody =>
      'Em breve será obrigatória para entrar. Leva um minuto.';

  @override
  String get authReauthConfirmed => 'Identidade confirmada. Repita a ação.';

  @override
  String get authReauthPasswordEmpty => 'Digite sua senha.';

  @override
  String get authReauthTitle => 'Confirme que é você';

  @override
  String get authReauthPassword =>
      'Por segurança, digite sua senha para continuar.';

  @override
  String get authReauthGoogle =>
      'Por segurança, entre novamente com o Google para continuar.';

  @override
  String get authReauthNone =>
      'Por segurança, saia e entre novamente para continuar.';

  @override
  String get authConfirm => 'Confirmar';

  @override
  String get authTermsAcceptedSnack => 'Pronto. Você já pode reservar.';

  @override
  String get authTermsDialogTitle => 'Aceite os termos para reservar';

  @override
  String get authTermsDialogBody =>
      'Para reservar, precisamos que você aceite a versão vigente dos Termos e da Política de Privacidade.';

  @override
  String get authTermsRead => 'Ler os Termos';

  @override
  String get authPrivacyRead => 'Ler a Política de Privacidade';

  @override
  String get authNotNow => 'Agora não';

  @override
  String get authAccept => 'Aceito';

  @override
  String get authErrorOffline =>
      'Sem conexão. Verifique sua internet e tente novamente.';

  @override
  String get authGoogleGenericError =>
      'Não foi possível entrar com o Google. Tente novamente.';

  @override
  String get authGoogleAccountExists =>
      'Você já tem uma conta com este e-mail. Entre com sua senha.';

  @override
  String get authGooglePopupBlocked =>
      'Seu navegador bloqueou a janela do Google. Permita janelas pop-up e tente novamente.';

  @override
  String get authGoogleUnauthorizedDomain =>
      'Este domínio não está autorizado para entrar com o Google.';

  @override
  String get authGoogleNotEnabled =>
      'O login com o Google não está habilitado.';

  @override
  String get authDeleteAccountError =>
      'Não foi possível excluir sua conta. Verifique sua conexão.';

  @override
  String get authResetLinkError =>
      'Não foi possível enviar o link. Tente novamente.';

  @override
  String get authVerifyTooMany =>
      'Enviamos vários links seguidos. Aguarde alguns minutos antes de pedir outro.';

  @override
  String get authVerifyOffline =>
      'Sem conexão. Verifique sua rede e tente novamente.';

  @override
  String get authVerifyFailed =>
      'Não foi possível concluir a verificação. Tente novamente.';

  @override
  String get formatToday => 'Hoje';

  @override
  String get formatTomorrow => 'Amanhã';

  @override
  String get greetingMorning => 'Bom dia';

  @override
  String get greetingAfternoon => 'Boa tarde';

  @override
  String get greetingEvening => 'Boa noite';

  @override
  String get driverErrorNotEnabled =>
      'Esta conta ainda não está habilitada como motorista. A Luxelane a ativa depois de revisar sua solicitação.';

  @override
  String get driverErrorLoadAccount =>
      'Não foi possível carregar sua conta. Verifique sua conexão e tente novamente.';

  @override
  String get driverNoticeTripsLoadFailed =>
      'Não foi possível carregar suas viagens.';

  @override
  String get driverNoticeRequestsLoadFailed =>
      'Não foi possível carregar as solicitações de viagem.';

  @override
  String get driverNoticeFinishTripFirst =>
      'Termine sua viagem atual antes de ficar online.';

  @override
  String get driverNoticeStatusChangeFailed =>
      'Não foi possível alterar seu status. Tente novamente.';

  @override
  String get driverNoticeLocationRequired =>
      'Ative a localização para receber viagens e para que o passageiro veja onde você está.';

  @override
  String get driverNoticeNoShowLocationRequired =>
      'Ative a localização: a central precisa saber onde você esperou.';

  @override
  String get driverNoticeNoShowReported =>
      'Avisamos a central. Você já está livre para outras viagens.';

  @override
  String get driverNoticeReleaseOffline =>
      'Sem conexão: a viagem não foi liberada. Tente novamente.';

  @override
  String get driverNoticeReleased =>
      'Você liberou a viagem. A central vai procurar outro motorista.';

  @override
  String get driverNoticeStepOffline =>
      'Sem conexão: a etapa não foi salva. Tente novamente; ela não será duplicada.';

  @override
  String get driverNoticeRequestAccepted => 'Viagem aceita';

  @override
  String get driverHomeLoadError => 'Não foi possível abrir seu painel.';

  @override
  String get driverRetry => 'Tentar novamente';

  @override
  String get driverHomeOnlineTitle => 'Você está online.';

  @override
  String get driverHomeOfflineTitle => 'Você está offline.';

  @override
  String get driverHomeDocumentsPending =>
      'Seus documentos estão em análise. Você poderá aceitar viagens quando a Luxelane os verificar.';

  @override
  String get driverHomeNoVehicle =>
      'Você não tem um veículo ativo cadastrado. Peça à Luxelane que o ative para receber solicitações.';

  @override
  String get driverHomeToday => 'Hoje';

  @override
  String get driverHomeNetEarnings => 'Ganhos líquidos';

  @override
  String get driverHomeTrips => 'Viagens';

  @override
  String get driverHomeRating => 'Avaliação';

  @override
  String get driverHomeUpcoming => 'Suas próximas reservas';

  @override
  String driverHourlyFrom(int hours, String place) {
    return '$hours h saindo de $place';
  }

  @override
  String get driverGoOffline => 'Ficar offline';

  @override
  String get driverGoOnline => 'Ficar online';

  @override
  String get driverOnlineBadge => 'Online';

  @override
  String get driverSearching => 'Procurando viagens';

  @override
  String driverSearchingClass(String vehicleClass) {
    return 'Procurando viagens de $vehicleClass';
  }

  @override
  String get driverConnectToReceive => 'Fique online para receber solicitações';

  @override
  String get driverDisconnectMe => 'Ficar offline';

  @override
  String get driverMapsNone => 'Nenhum aplicativo de mapas disponível';

  @override
  String driverMapsNavigateTo(String address) {
    return 'Navegar até $address';
  }

  @override
  String get driverMapsOpenFailed => 'Não foi possível abrir os mapas';

  @override
  String get driverStopPickup => 'Embarque';

  @override
  String get driverStopDestination => 'Destino';

  @override
  String driverGuestPassenger(String name) {
    return 'Passageiro: $name';
  }

  @override
  String get driverRiderNote => 'Observação do passageiro';

  @override
  String get driverNavigateToPickup => 'Navegar até o embarque';

  @override
  String get driverNavigateToDestination => 'Navegar até o destino';

  @override
  String get driverRequestNow => 'Agora';

  @override
  String driverRequestInMinutes(int minutes) {
    return 'Em $minutes min';
  }

  @override
  String driverRouteDistanceDuration(String km, int minutes) {
    return '~$km km · $minutes min';
  }

  @override
  String driverRouteDistance(String km) {
    return '~$km km';
  }

  @override
  String driverRequestTitle(String vehicleClass) {
    return 'NOVA SOLICITAÇÃO · $vehicleClass';
  }

  @override
  String get driverRequestPickupZone => 'ÁREA DE EMBARQUE';

  @override
  String get driverRequestDropoffZone => 'ÁREA DE DESTINO';

  @override
  String get driverRequestHourly => 'POR HORA';

  @override
  String driverHoursAvailable(int hours) {
    return '$hours h à disposição';
  }

  @override
  String driverRequestPassengers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passageiros',
      one: '1 passageiro',
    );
    return '$_temp0';
  }

  @override
  String driverRequestLuggage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count malas',
      one: '1 mala',
    );
    return '$_temp0';
  }

  @override
  String get driverRequestDetailsOnAccept =>
      'Endereço exato e dados ao aceitar';

  @override
  String get driverAcceptTrip => 'Aceitar viagem';

  @override
  String get driverDecline => 'Recusar';

  @override
  String get driverTripNotFound => 'Viagem não encontrada';

  @override
  String get driverBack => 'Voltar';

  @override
  String get driverEstimatedFare => 'Tarifa estimada';

  @override
  String get driverQueueTitle => 'Solicitações';

  @override
  String get driverQueueEmptyOnline =>
      'As novas solicitações\naparecerão aqui.';

  @override
  String get driverQueueEmptyOffline =>
      'Fique online para\nreceber solicitações.';

  @override
  String get driverQueueAvailable => 'Disponíveis para você';

  @override
  String get driverQueueAssigned => 'Suas viagens atribuídas';

  @override
  String driverQueueFrom(String date, String place) {
    return '$date · saindo de $place';
  }

  @override
  String driverQueuePax(int count) {
    return '$count pax';
  }

  @override
  String get driverQueueLoading => 'Carregando…';

  @override
  String get driverQueuePendingVerification => 'Verificação pendente';

  @override
  String get driverQueueFinishCurrent => 'Termine sua viagem atual';

  @override
  String get driverQueueConnectToAccept => 'Fique online para aceitar';

  @override
  String get driverOnboardingDefaultColor => 'Preto';

  @override
  String get driverOnboardingVehicleError =>
      'Não foi possível cadastrar o veículo. Verifique os dados e tente novamente.';

  @override
  String get driverOnboardingLicenseError =>
      'Não foi possível salvar sua habilitação. Verifique sua conexão e tente novamente.';

  @override
  String get driverOnboardingGenericError =>
      'Não foi possível concluir o cadastro. Tente novamente.';

  @override
  String get driverSignOut => 'Sair';

  @override
  String get driverOnboardingVehicleTitle => 'Seu veículo';

  @override
  String get driverOnboardingVehicleSubtitle =>
      'Cadastre o veículo que você vai dirigir.';

  @override
  String get driverContinue => 'Continuar';

  @override
  String get driverOnboardingLicenseTitle => 'Carteira de habilitação';

  @override
  String get driverOnboardingLicenseSubtitle =>
      'Seus documentos serão analisados antes que você possa aceitar viagens.';

  @override
  String get driverOnboardingReviewNotice =>
      'Um administrador verificará seus documentos antes que você possa ficar online.';

  @override
  String get driverOnboardingBack => 'Voltar';

  @override
  String get driverOnboardingSubmit => 'Enviar';

  @override
  String get driverOnboardingClass => 'Categoria do veículo';

  @override
  String get driverOnboardingMake => 'Marca';

  @override
  String get driverOnboardingModel => 'Modelo';

  @override
  String get driverOnboardingPlate => 'Placa';

  @override
  String get driverOnboardingYear => 'Ano';

  @override
  String get driverOnboardingColor => 'Cor';

  @override
  String get driverFieldRequired => 'Obrigatório';

  @override
  String get driverFieldInvalid => 'Inválido';

  @override
  String get driverOnboardingLicenseNumber => 'Número da habilitação';

  @override
  String get driverOnboardingLicenseExpiry => 'Data de validade (MM/AAAA)';

  @override
  String get driverOnboardingExpiryFormat => 'Use MM/AAAA';

  @override
  String get driverOnboardingInvalidMonth => 'Mês inválido';

  @override
  String get driverOnboardingLicenseExpired => 'Habilitação vencida';

  @override
  String get driverEarningsTitle => 'Ganhos';

  @override
  String get driverEarningsCompleted => 'Viagens concluídas';

  @override
  String get driverEarningsNetTitle => 'SEUS GANHOS LÍQUIDOS';

  @override
  String driverEarningsRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viagens concluídas',
      one: '1 viagem concluída',
    );
    return '$_temp0';
  }

  @override
  String get driverEarningsFares => 'Tarifas das suas viagens';

  @override
  String get driverEarningsCommission => 'Comissão Luxelane';

  @override
  String driverEarningsProvisionalNote(String pct) {
    return 'As viagens provisórias são calculadas com uma comissão de $pct % até que a liquidação seja confirmada.';
  }

  @override
  String driverEarningsRefunded(String date) {
    return '$date · reembolsado';
  }

  @override
  String driverEarningsFareLine(String date, String fare, String pct) {
    return '$date · tarifa $fare · $pct %';
  }

  @override
  String get driverEarningsProvisional => 'Provisório';

  @override
  String get driverEarningsEmpty => 'Sua primeira viagem\naparecerá aqui.';

  @override
  String get driverSlideDepart => 'Sair para o embarque';

  @override
  String get driverSlideArrived => 'Cheguei';

  @override
  String get driverSlideStart => 'Iniciar viagem';

  @override
  String get driverSlideComplete => 'Concluir viagem';

  @override
  String get driverStepConfirmed => 'Siga até o ponto de embarque.';

  @override
  String get driverStepArriving => 'A caminho do embarque.';

  @override
  String get driverStepLocked => 'Verificação bloqueada. Fale com a central.';

  @override
  String get driverStepAskCode => 'Peça ao passageiro o código de embarque.';

  @override
  String get driverStepVerified =>
      'Passageiro verificado. Deslize para iniciar.';

  @override
  String get driverStepInProgress => 'Viagem em andamento · rumo ao destino.';

  @override
  String get driverStepNoShow =>
      'Você avisou que o passageiro não apareceu. A central está analisando.';

  @override
  String get driverStepActive => 'Viagem ativa.';

  @override
  String get driverLockedFiveCodes =>
      'Cinco códigos incorretos: a central precisa verificar esta viagem.';

  @override
  String get driverEnterCode => 'Inserir código do passageiro';

  @override
  String get driverCannotDoTrip => 'Não posso fazer esta viagem';

  @override
  String get driverReleaseTitle => 'Liberar esta viagem';

  @override
  String get driverReleaseBody =>
      'A viagem volta a procurar motorista e a central recebe um aviso. Fica registrado no seu histórico.';

  @override
  String get driverReleaseConfirm => 'Liberar viagem';

  @override
  String get driverReleaseReasonVehicleIssue => 'Problema com o veículo';

  @override
  String get driverReleaseReasonPersonalEmergency => 'Emergência pessoal';

  @override
  String get driverReleaseReasonUnsafeConditions => 'Condições inseguras';

  @override
  String get driverReleaseReasonScheduleConflict => 'Conflito de horário';

  @override
  String get driverReleaseReasonOther => 'Outro motivo';

  @override
  String get driverNoShowTitle => 'O passageiro não apareceu?';

  @override
  String get driverNoShowBody =>
      'A central receberá um aviso com sua localização e analisará a reserva. Você ficará livre para outras viagens.';

  @override
  String get driverNoShowKeepWaiting => 'Continuar esperando';

  @override
  String get driverNoShowNotify => 'Avisar a central';

  @override
  String get driverNoShowButton => 'O passageiro não apareceu';

  @override
  String driverNoShowAvailableAt(String time) {
    return 'Disponível a partir das $time.';
  }

  @override
  String get driverFlightAirportPickup => 'Embarque no aeroporto';

  @override
  String get driverFlightExitLabel => 'Seu passageiro sai por';

  @override
  String get driverFlightAskType =>
      'Pergunte ao passageiro se o voo é nacional ou internacional';

  @override
  String driverFlightNumber(String flight) {
    return 'Voo $flight';
  }

  @override
  String get driverFlightCheckStatus => 'Ver status em mivuelo.att.gob.bo';

  @override
  String get driverFlightYourCityAirport => 'o aeroporto da sua cidade';

  @override
  String get driverFlightDialogTitle => 'Primeiro mude o aeroporto';

  @override
  String driverFlightDialogBody(String airport, String flight) {
    return 'Ao abrir mivuelo.att.gob.bo, mude primeiro o aeroporto para $airport, o que corresponde à sua cidade. Depois procure o voo $flight nas chegadas.\n\nVamos copiar o número do voo para que você só precise colá-lo.';
  }

  @override
  String get driverCancel => 'Cancelar';

  @override
  String get driverFlightDialogOpen => 'Entendi, abrir';

  @override
  String get driverFlightOpenFailed =>
      'Não foi possível abrir mivuelo.att.gob.bo';

  @override
  String get driverCallDispatch => 'Ligar para a central';

  @override
  String get driverCodeLockedSecurity =>
      'Por segurança, a verificação foi bloqueada. Fale com a central.';

  @override
  String get driverCodeAsk => 'Peça o código ao passageiro';

  @override
  String get driverCodeHint =>
      'Ele aparece no app do passageiro. Sem ele não é possível iniciar a viagem.';

  @override
  String driverCodeSemantics(int entered, int length) {
    return 'Código, $entered de $length dígitos';
  }

  @override
  String get driverCodeDelete => 'Apagar';

  @override
  String get driverCodeVerified => 'Passageiro verificado';

  @override
  String get driverCodeVerifiedHint =>
      'Deslize «Iniciar viagem» quando estiverem prontos.';

  @override
  String get driverCodeContactDispatch => 'Fale com a central';

  @override
  String get driverNavDrive => 'Dirigir';

  @override
  String get driverNavRequests => 'Solicitações';

  @override
  String get driverNavEarnings => 'Ganhos';

  @override
  String get driverNavProfile => 'Perfil';

  @override
  String incidentSmsHeader(String id) {
    return 'SOS. Reserva #$id.';
  }

  @override
  String incidentSmsLocation(String link) {
    return 'Localização: $link';
  }

  @override
  String get incidentSmsNoLocation => 'Localização indisponível.';

  @override
  String get incidentNoNumbersHelp =>
      'Entre em contato com as autoridades locais.';

  @override
  String get incidentSendingTitle => 'Avisando a central…';

  @override
  String get incidentSendingBody => 'Não feche o app.';

  @override
  String get incidentFailedTitle => 'Não foi possível avisar a central';

  @override
  String get incidentOfflineBody =>
      'Sem conexão. Ligue ou envie a mensagem já preparada.';

  @override
  String get incidentCancelledTitle => 'Alerta cancelado';

  @override
  String get incidentCancelledBody =>
      'A central foi avisada. Não compartilhamos mais sua localização.';

  @override
  String get incidentOpenTitle => 'Avisamos a central';

  @override
  String get incidentOpenBody =>
      'A central foi avisada. Compartilhamos sua localização enquanto o alerta estiver ativo.';

  @override
  String get incidentAckTitle => 'A central recebeu seu alerta';

  @override
  String get incidentAckBody => 'Uma pessoa da central está cuidando dele.';

  @override
  String get incidentClosedTitle => 'Alerta encerrado';

  @override
  String get incidentClosedBody =>
      'A central encerrou o alerta. Não compartilhamos mais sua localização.';

  @override
  String get incidentCancelRequestedBody =>
      'A central vai ligar para você para verificar se está tudo bem. Não compartilhamos mais sua localização.';

  @override
  String get incidentHelp => 'Ajuda';

  @override
  String get incidentIdleBody =>
      'Mantenha SOS pressionado para avisar a central.';

  @override
  String get incidentFalseAlarmQuestion => 'Foi um alarme falso?';

  @override
  String get incidentFalseAlarmBody =>
      'Vamos cancelar o alerta. A central o verá mesmo assim e ele fica registrado.';

  @override
  String get incidentBack => 'Voltar';

  @override
  String get incidentCancelAlert => 'Cancelar alerta';

  @override
  String incidentSentTimes(int count) {
    return 'Alerta enviado $count vezes.';
  }

  @override
  String get incidentCallDispatch => 'Ligar para a central';

  @override
  String get incidentSmsDispatch => 'Enviar SMS para a central';

  @override
  String get incidentRetry => 'Tentar o alerta novamente';

  @override
  String get incidentAlertAgain => 'Avisar de novo';

  @override
  String get incidentHoldToAlertAgain =>
      'Mantenha pressionado para avisar de novo';

  @override
  String get incidentFalseAlarm => 'Foi um alarme falso';

  @override
  String get incidentConfirmTitle => 'Avisar a central?';

  @override
  String get incidentConfirmBody =>
      'A central receberá seu alerta e sua localização enquanto ele estiver ativo.';

  @override
  String get incidentConfirmCancel => 'Cancelar';

  @override
  String get incidentConfirmSend => 'Avisar a central';

  @override
  String incidentSosSemantics(String label) {
    return '$label SOS';
  }

  @override
  String get incidentSosHint =>
      'Mantenha pressionado por dois segundos para avisar a central. Com leitor de tela, toque duas vezes e confirme.';

  @override
  String get incidentLive => 'Ajuda em andamento';

  @override
  String get incidentErrorOffline =>
      'Não foi possível avisar a central: sem conexão.';

  @override
  String get incidentErrorOutsideWindow =>
      'O botão de ajuda funciona durante a viagem.';

  @override
  String get incidentErrorRateLimited =>
      'Você já enviou vários alertas. Ligue para a central se precisar.';

  @override
  String get incidentErrorNotAllowed =>
      'Esta viagem não está mais no seu nome.';

  @override
  String get incidentErrorGeneric => 'Não foi possível avisar a central.';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String languageSystemDetail(String language) {
    return 'Usa o idioma do celular: $language';
  }

  @override
  String get languageSaveError =>
      'Não foi possível salvar o idioma na sua conta. Ele será usado neste dispositivo.';

  @override
  String get legalSpanishOnlyNotice =>
      'No momento, este documento está disponível apenas em espanhol.';

  @override
  String get paymentOurFault =>
      'Não foi possível concluir o pagamento por um problema nosso. Tente novamente em alguns minutos.';

  @override
  String get paymentMethodDisabled =>
      'Este método de pagamento não está disponível no momento. Escolha outro ou fale com a central.';

  @override
  String get paymentAlreadyPaid => 'Esta reserva já está paga.';

  @override
  String get paymentNotAwaiting =>
      'Esta reserva não aceita mais pagamentos. Confira o status em Minhas viagens.';

  @override
  String get paymentBookingNotFound => 'Não encontramos esta reserva.';

  @override
  String get paymentInvalidOperationNumber =>
      'Confira o número da operação: use apenas letras, números, espaços e . _ / -';

  @override
  String get paymentAccountNotEnabled =>
      'sua conta ainda não tem pagamentos habilitados';

  @override
  String get paymentServerUnreachable =>
      'não foi possível contatar o servidor de pagamentos';

  @override
  String get paymentCardInUse =>
      'Este cartão paga uma reserva pendente. Cancele a reserva ou aguarde até que termine antes de remover o cartão.';

  @override
  String get paymentRemoveCardError =>
      'Não foi possível remover o cartão. Tente novamente.';

  @override
  String get paymentSetDefaultError =>
      'Não foi possível alterar o cartão padrão. Tente novamente.';

  @override
  String get paymentProfileError =>
      'Não foi possível preparar seu perfil de pagamentos. Tente novamente.';

  @override
  String get paymentLoadError =>
      'Não foi possível carregar o pagamento da sua reserva. Verifique sua conexão.';

  @override
  String get paymentCardUnavailable =>
      'O pagamento com cartão não está disponível no momento. Escolha outro método.';

  @override
  String get paymentCardFailed =>
      'Não foi possível concluir o pagamento com cartão. Confira os dados e tente novamente.';

  @override
  String get paymentCardIncomplete => 'Informe todos os dados do cartão';

  @override
  String get paymentCardAdded => 'Cartão adicionado';

  @override
  String get paymentAddMethodTitle => 'Adicionar método de pagamento';

  @override
  String get paymentBack => 'Voltar';

  @override
  String get paymentCardDetails => 'Dados do cartão';

  @override
  String get paymentAddCardSecure =>
      'Protegido pela Stripe · Conformidade PCI DSS';

  @override
  String get paymentAddCard => 'Adicionar cartão';

  @override
  String get paymentBookingTitle => 'Pagamento da sua reserva';

  @override
  String get paymentViewTrip => 'Ver minha viagem';

  @override
  String get paymentNoPending => 'Esta reserva não tem pagamento pendente.';

  @override
  String get paymentConfirmedTitle => 'Pagamento confirmado';

  @override
  String get paymentConfirmedMessage =>
      'Já estamos buscando seu motorista. Avisaremos você quando ele for designado.';

  @override
  String get paymentExpiredTitle => 'O prazo para pagamento terminou';

  @override
  String paymentExpiredMessage(String reference) {
    return 'A reserva foi cancelada porque não recebemos o pagamento a tempo. Se você já tinha pago, fale com a central e informe a referência $reference.';
  }

  @override
  String get paymentNewBooking => 'Fazer uma nova reserva';

  @override
  String get paymentClosedTitle => 'Esta reserva não aceita mais pagamentos';

  @override
  String get paymentClosedMessage =>
      'Consulte os detalhes e o comprovante na sua viagem.';

  @override
  String get paymentRejected =>
      'Não foi possível confirmar seu pagamento. Confira os dados e nos avise novamente, ou fale com a central.';

  @override
  String get paymentNoMethods =>
      'No momento não podemos receber o pagamento por aqui. Fale com a central para concluir sua reserva.';

  @override
  String get paymentChangeMethod => 'Alterar método de pagamento';

  @override
  String get paymentSearchAfterConfirm =>
      'Buscamos um motorista quando o pagamento é confirmado.';

  @override
  String get paymentAmountDueEyebrow => 'VALOR A PAGAR';

  @override
  String get paymentReference => 'Referência';

  @override
  String paymentDeadlinePassed(String time) {
    return 'O prazo para pagamento terminou às $time.';
  }

  @override
  String paymentTimeLeft(String span, String time) {
    return 'Restam $span para pagar (até às $time).';
  }

  @override
  String paymentSpanMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String paymentSpanHours(int hours) {
    return '$hours h';
  }

  @override
  String paymentSpanHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String paymentCopy(String label) {
    return 'Copiar $label';
  }

  @override
  String paymentCopied(String label) {
    return '$label copiada.';
  }

  @override
  String get paymentMethodManualQr => 'QR ou transferência bancária';

  @override
  String get paymentMethodCard => 'Cartão';

  @override
  String get paymentHowToPay => 'COMO VOCÊ QUER PAGAR?';

  @override
  String get paymentManualEyebrow => 'PAGUE POR QR OU TRANSFERÊNCIA';

  @override
  String get paymentQrLabel => 'Código QR para pagar';

  @override
  String get paymentQrError =>
      'Não foi possível exibir o QR. Use os dados da conta.';

  @override
  String get paymentHolder => 'Titular';

  @override
  String get paymentBank => 'Banco';

  @override
  String get paymentAccountType => 'Tipo de conta';

  @override
  String get paymentAccount => 'Conta';

  @override
  String paymentPayExactly(String amount, String reference) {
    return 'Pague exatamente $amount e informe a referência $reference na descrição do pagamento.';
  }

  @override
  String get paymentOperationLabel => 'Número da operação (opcional)';

  @override
  String get paymentOperationHint => 'O que aparece no seu comprovante';

  @override
  String get paymentIPaid => 'Já paguei';

  @override
  String get paymentWaitingTitle => 'Aguardando confirmação';

  @override
  String get paymentWaitingMessage =>
      'A central está revisando seu pagamento. Avisaremos você aqui e nas suas notificações quando ele for confirmado.';

  @override
  String paymentOperationNumber(String number) {
    return 'Número da operação: $number';
  }

  @override
  String get paymentConfirming => 'Confirmando seu pagamento…';

  @override
  String get paymentPayWithCard => 'Pagar com cartão';

  @override
  String get paymentRetry => 'Tentar novamente';

  @override
  String get paymentAddCardsOnPhone =>
      'Adicione seus cartões pelo app Luxelane no seu celular.';

  @override
  String get paymentRemoveCardTitle => 'Remover este cartão?';

  @override
  String get paymentRemoveCardMessage =>
      'Ele deixará de estar disponível para suas próximas reservas.';

  @override
  String get paymentCancel => 'Cancelar';

  @override
  String get paymentRemove => 'Remover';

  @override
  String get paymentMethodsTitle => 'Métodos de pagamento';

  @override
  String get paymentPerBooking =>
      'Cada reserva é paga na sua própria etapa de pagamento.';

  @override
  String get paymentSavedCards => 'Cartões salvos';

  @override
  String get paymentSetDefaultHint =>
      'Toque em um cartão para usá-lo como padrão ao reservar.';

  @override
  String get paymentEncrypted =>
      'Pagamentos criptografados e protegidos pela Stripe';

  @override
  String get paymentEmptyCards => 'Pague sem preocupação.';

  @override
  String paymentCardDefaultExpires(String expiry) {
    return 'Padrão · vence em $expiry';
  }

  @override
  String paymentCardExpires(String expiry) {
    return 'Vence em $expiry';
  }

  @override
  String get paymentRemoveCard => 'Remover cartão';

  @override
  String get paymentReceiptMethodManual => 'QR ou transferência';

  @override
  String get paymentPendingTitle => 'Pagamento pendente';

  @override
  String paymentReportedMessage(String amount) {
    return 'Você avisou que pagou $amount. A central está revisando.';
  }

  @override
  String paymentPendingMessage(String amount) {
    return 'Pague $amount para buscarmos seu motorista.';
  }

  @override
  String get paymentViewPayment => 'Ver o pagamento';

  @override
  String get paymentPayNow => 'Pagar agora';

  @override
  String get paymentReceiptTitle => 'Comprovante de pagamento';

  @override
  String get paymentReceiptHide => 'Ocultar comprovante';

  @override
  String get paymentReceiptShow => 'Ver comprovante';

  @override
  String get paymentReceiptNotInvoice =>
      'Este comprovante não é uma nota fiscal.';

  @override
  String get paymentReceiptPaid => 'Pago';

  @override
  String get paymentReceiptDate => 'Data';

  @override
  String get paymentReceiptMethod => 'Método';

  @override
  String get paymentReceiptRetained => 'Taxa de cancelamento';

  @override
  String get paymentReceiptRefundPending => 'Reembolso pendente';

  @override
  String get paymentReceiptRefundPendingNote =>
      'A central vai registrá-lo e avisaremos você quando for concluído.';

  @override
  String get paymentReceiptRefunded => 'Reembolsado';

  @override
  String get paymentReceiptRefundedNote =>
      'O valor é devolvido ao método com que você pagou.';

  @override
  String get paymentReceiptBalanceDue => 'Saldo pendente';

  @override
  String get paymentReceiptBalanceNote =>
      'O valor final da viagem foi maior que o valor pago.';

  @override
  String get profileSaveError =>
      'Não foi possível salvar as alterações. Tente novamente.';

  @override
  String get profileUpdated => 'Perfil atualizado';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileEdit => 'Editar';

  @override
  String get profileRideStyle => 'Seu estilo de viagem';

  @override
  String get profileDriverDocuments => 'Habilitação e veículo';

  @override
  String get profileAccount => 'Conta';

  @override
  String get profileEmail => 'E-mail';

  @override
  String get profilePhone => 'Telefone';

  @override
  String get profilePhoneMissing => 'Adicione para o seu motorista';

  @override
  String get profilePaymentMethods => 'Formas de pagamento';

  @override
  String get profileTwoStep => 'Verificação em duas etapas';

  @override
  String get profileAuthenticatorApp => 'App autenticador';

  @override
  String get profileLegal => 'Legal';

  @override
  String get profileTerms => 'Termos e condições';

  @override
  String get profilePrivacy => 'Privacidade';

  @override
  String get profileSignOut => 'Sair';

  @override
  String get profileDeleteAccount => 'Excluir conta';

  @override
  String get profilePreferencesFooter =>
      'Seu motorista verá isto antes do embarque. Vale para suas próximas reservas.';

  @override
  String get profileQuietRide => 'Viagem em silêncio';

  @override
  String get profileQuietRideDetail => 'Sem conversa, só o necessário';

  @override
  String get profileSoftMusic => 'Música suave';

  @override
  String get profileTemperature => 'Temperatura';

  @override
  String get profileTemperatureAny => 'Tanto faz';

  @override
  String get profileLuggageHelp => 'Ajuda com a bagagem';

  @override
  String get profileOpenDoor => 'Abrir a porta para mim';

  @override
  String get profileAccountDeleted => 'Sua conta foi excluída.';

  @override
  String get profileDeleteTitle => 'Excluir sua conta?';

  @override
  String get profileDeleteBody =>
      'Vamos apagar seu perfil, seus cartões salvos e suas notificações, e você não poderá entrar novamente com esta conta. Mantemos o registro de viagens e pagamentos exigido por lei.\n\nEsta ação não pode ser desfeita.';

  @override
  String get profileCancel => 'Cancelar';

  @override
  String get profileDelete => 'Excluir';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileName => 'Nome';

  @override
  String get profileRequired => 'Obrigatório';

  @override
  String get profilePhoneInvalid =>
      'Seu motorista precisa dele para falar com você';

  @override
  String get profileSaveChanges => 'Salvar alterações';

  @override
  String get profileRoleAdmin => 'Administração';

  @override
  String get profileRoleDriver => 'Motorista Luxelane';

  @override
  String profileMemberSince(int year) {
    return 'Membro desde $year';
  }

  @override
  String profileRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viagens',
      one: '$count viagem',
    );
    return '$_temp0';
  }

  @override
  String get profileVehicleColorTitle => 'Cor do veículo';

  @override
  String get profileColor => 'Cor';

  @override
  String get profileSave => 'Salvar';

  @override
  String get profileLocked => 'Bloqueado';

  @override
  String get profileLicence => 'Habilitação';

  @override
  String profileLicenceDetail(String number, String expiry) {
    return '$number · vence $expiry';
  }

  @override
  String profileVehicleDetail(String vehicleClass, String plate) {
    return '$vehicleClass · placa $plate';
  }

  @override
  String get rideLoadNotFound => 'Não encontramos esta reserva na sua conta.';

  @override
  String get rideLoadOffline =>
      'Não foi possível carregar sua reserva. Verifique sua conexão.';

  @override
  String get rideLoadFailed =>
      'Não foi possível carregar sua reserva. Tente novamente.';

  @override
  String get ridePendingSearching =>
      'Estamos designando seu motorista. Avisaremos você assim que for confirmado.';

  @override
  String get ridePendingReleasedCall =>
      'Seu motorista anterior não pôde fazer a viagem. Estamos buscando outro e a central já foi avisada. Se precisar, ligue para a central.';

  @override
  String get ridePendingReleased =>
      'Seu motorista anterior não pôde fazer a viagem. Estamos buscando outro e a central já foi avisada.';

  @override
  String get ridePendingPickupPassedCall =>
      'O horário de embarque já passou e ainda não há motorista designado. Ligue para a central ou cancele a reserva.';

  @override
  String get ridePendingPickupPassed =>
      'O horário de embarque já passou e ainda não há motorista designado. Você pode esperar ou cancelar a reserva.';

  @override
  String rideCodeShareText(String code) {
    return 'Seu código de embarque é $code. Informe-o ao motorista ao entrar no carro; sem ele a viagem não pode começar.';
  }

  @override
  String get rideCodeLoading => 'Carregando seu código de embarque';

  @override
  String get rideCodeTitle => 'CÓDIGO DE EMBARQUE';

  @override
  String rideCodeSemantics(String digits) {
    return 'Código de embarque $digits';
  }

  @override
  String get rideCodeHint =>
      'Informe-o ao motorista ao entrar no carro. Sem ele a viagem não pode começar.';

  @override
  String rideCodeGuestHint(String guest) {
    return 'Compartilhe-o com $guest: o convidado o informará ao motorista ao entrar no carro.';
  }

  @override
  String get rideCodeShare => 'Compartilhar código';

  @override
  String get rideRetry => 'Tentar novamente';

  @override
  String get rideCancelledSnack => 'Reserva cancelada';

  @override
  String get rideCancelFeeChangedAgain =>
      'A taxa de cancelamento mudou novamente. Tente outra vez.';

  @override
  String get rideCancelBooking => 'Cancelar reserva';

  @override
  String rideCancelFee(String amount) {
    return 'De acordo com a política de cancelamento, se você cancelar agora, $amount do valor pago serão retidos.';
  }

  @override
  String rideCancelFeeChanged(String amount) {
    return 'A taxa de cancelamento mudou. De acordo com a política de cancelamento, se você cancelar agora, $amount do valor pago serão retidos.';
  }

  @override
  String rideCancelRefund(String amount) {
    return '$amount ficam pendentes de reembolso. Avisaremos você quando a central registrá-lo.';
  }

  @override
  String get rideCancelReasonLabel => 'Motivo';

  @override
  String get rideCancelReasonChangedPlans => 'Mudei de planos';

  @override
  String get rideCancelReasonOtherTransport => 'Encontrei outro transporte';

  @override
  String get rideCancelReasonDriverLate => 'O motorista está demorando demais';

  @override
  String get rideCancelReasonOther => 'Outro motivo';

  @override
  String get rideBack => 'Voltar';

  @override
  String get rideCancelWithFee => 'Cancelar com taxa';

  @override
  String get rideCancelledMessage => 'Esta reserva foi cancelada.';

  @override
  String rideCancelledWithFee(String amount) {
    return 'Esta reserva foi cancelada. Taxa de cancelamento: $amount.';
  }

  @override
  String get rideStatusLoading => 'Carregando sua reserva…';

  @override
  String get rideStatusAwaitingPayment =>
      'Sua reserva aguarda o pagamento. Buscamos um motorista quando ele for confirmado.';

  @override
  String get rideStatusConfirmed =>
      'Sua reserva está confirmada. Avisaremos você quando seu motorista sair ao seu encontro.';

  @override
  String get rideStatusDriverArriving =>
      'Seu motorista está a caminho do ponto de embarque.';

  @override
  String get rideStatusDriverArrived =>
      'Seu motorista chegou e está esperando por você. Sem pressa.';

  @override
  String get rideStatusVerified =>
      'Código verificado. Sua viagem começa em instantes.';

  @override
  String get rideStatusInProgress =>
      'Aproveite o trajeto. Você chegará ao seu destino em breve.';

  @override
  String get rideStatusCompleted =>
      'Você chegou. Obrigado por viajar com a Luxelane.';

  @override
  String get rideStatusNoShow =>
      'Seu motorista não encontrou você no ponto de embarque. A central foi avisada.';

  @override
  String get rideYourDriverLower => 'seu motorista';

  @override
  String get rideYourDriver => 'Seu motorista';

  @override
  String get rideRatingThanks => 'Obrigado pela sua avaliação.';

  @override
  String get rideRateTrip => 'Avaliar viagem';

  @override
  String get rideCallDriver => 'Ligar para seu motorista';

  @override
  String get rideCancelling => 'Cancelando…';

  @override
  String get rideBackHome => 'Voltar ao início';

  @override
  String ridePreferencesKnown(String preferences) {
    return 'Seu motorista conhece seu estilo: $preferences';
  }

  @override
  String get rideAssigningTitle => 'Designando seu motorista';

  @override
  String get rideAssigningDetail =>
      'Você verá o nome, o veículo e a avaliação aqui.';

  @override
  String get rideCodeVerified => 'Código verificado';

  @override
  String get rideCodeVerifiedDetail =>
      'Seu motorista já pode iniciar a viagem.';

  @override
  String get rideCompleted => 'Viagem concluída';

  @override
  String get rideRatingTitle => 'Avalie sua viagem';

  @override
  String get rideRatingLater => 'Agora não';

  @override
  String get rideRatingSend => 'Enviar';

  @override
  String get rideRating5 => 'Excelente';

  @override
  String get rideRating4 => 'Bom';

  @override
  String get rideRating3 => 'Regular';

  @override
  String get rideRating2 => 'Ruim';

  @override
  String get rideRating1 => 'Muito ruim';

  @override
  String get rideErrorNetwork =>
      'Sem conexão. Verifique sua rede e tente novamente.';

  @override
  String get rideErrorNotAtPickup =>
      'O código aparece quando seu motorista chega ao ponto de embarque.';

  @override
  String get rideErrorWrongCode => 'Código incorreto.';

  @override
  String get rideErrorWrongCodeOne => 'Código incorreto. Resta 1 tentativa.';

  @override
  String rideErrorWrongCodeMany(int left) {
    return 'Código incorreto. Restam $left tentativas.';
  }

  @override
  String get rideErrorLocked =>
      'Por segurança, a verificação foi bloqueada. Entre em contato com a central.';

  @override
  String get rideErrorExpired =>
      'O código expirou. Entre em contato com a central para continuar.';

  @override
  String get rideErrorUnavailable =>
      'O código não está disponível agora. Entre em contato com a central.';

  @override
  String get rideErrorNotYours =>
      'Esta viagem não está mais sob sua responsabilidade.';

  @override
  String get rideErrorTooEarly =>
      'O tempo de espera ainda não terminou. Aguarde um pouco mais.';

  @override
  String get rideErrorNoShowDisabled =>
      'Esta opção não está disponível. Entre em contato com a central.';

  @override
  String get rideErrorLocationRequired =>
      'Ative a localização: a central precisa saber onde você esperou.';

  @override
  String get rideErrorNotReleasable =>
      'Você não pode mais liberar esta viagem. Entre em contato com a central.';

  @override
  String get rideErrorInvalidTransition =>
      'O status da viagem mudou. Atualizamos a tela.';

  @override
  String get rideErrorGeneric => 'Não foi possível concluir. Tente novamente.';

  @override
  String get tripsTitle => 'Minhas viagens';

  @override
  String get tripsRetry => 'Tentar novamente';

  @override
  String get tripsUpcoming => 'Próximas';

  @override
  String get tripsPast => 'Anteriores';

  @override
  String get tripsEmptyMessage =>
      'Seu primeiro trajeto\nestá esperando por você.';

  @override
  String get tripsEmptyAction => 'Reservar agora';

  @override
  String tripsHourlyTitle(int hours) {
    return '$hours h à disposição';
  }

  @override
  String tripsFrom(String when, String origin) {
    return '$when · de $origin';
  }

  @override
  String get tripsTrackOnMap => 'Acompanhar no mapa';

  @override
  String get tripsRate => 'Avaliar viagem';

  @override
  String get tripsViewBooking => 'Ver reserva';

  @override
  String get tripsAwaitingPayment => 'Aguardando pagamento';

  @override
  String get tripsPaid => 'Paga';
}
