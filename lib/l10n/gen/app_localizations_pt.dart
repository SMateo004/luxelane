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
  String get businessEyebrow => 'Para Empresas';

  @override
  String get businessTitle => 'Viagens corporativas, redefinidas.';

  @override
  String get businessLead =>
      'Motoristas particulares para sua equipe e seus convidados, com faturamento centralizado. Conte o que você precisa e entraremos em contato em menos de um dia útil.';

  @override
  String get businessSendError =>
      'Não foi possível enviar sua solicitação. Tente novamente.';

  @override
  String get businessRequired => 'Campo obrigatório';

  @override
  String businessThanks(String name, String email) {
    return 'Obrigado, $name. Recebemos sua solicitação e vamos escrever para $email.';
  }

  @override
  String get businessPerkBilling =>
      'Faturamento mensal centralizado para sua empresa';

  @override
  String get businessPerkPriority =>
      'Reservas prioritárias para executivos e convidados';

  @override
  String get businessCompany => 'Empresa';

  @override
  String get businessName => 'Seu nome';

  @override
  String get businessEmail => 'E-mail corporativo';

  @override
  String get businessEmailInvalid => 'Digite um e-mail válido';

  @override
  String get businessPhone => 'Telefone';

  @override
  String get businessTravellers => 'Quantas pessoas viajariam?';

  @override
  String get businessTravellersOver200 => 'Mais de 200';

  @override
  String get businessMessage => 'Conte o que você precisa (opcional)';

  @override
  String get businessSubmit => 'Enviar solicitação';

  @override
  String get commonLockedDocuments =>
      'Para alterar estes dados, entre em contato com a central.';

  @override
  String get commonStartupErrorTitle => 'Não foi possível iniciar o app';

  @override
  String get commonStartupErrorBody =>
      'Feche o app e abra-o novamente em alguns minutos.';

  @override
  String commonSeatingPassengers(int count) {
    return '$count passageiros';
  }

  @override
  String get commonSeatingMaxDetail => 'Capacidade máxima';

  @override
  String get commonSeatingRoomierDetail => 'Mais espaço para cada um';

  @override
  String get commonSeatingChildSeat => 'Com assento infantil';

  @override
  String get commonSeatingChildSeatDetail => 'Mediante solicitação prévia';

  @override
  String get commonHighlightBusiness1 =>
      'Sedã executivo, discreto e silencioso';

  @override
  String get commonHighlightBusiness2 => 'Bancos traseiros de couro para três';

  @override
  String get commonHighlightBusiness3 =>
      'Porta-malas para três malas despachadas';

  @override
  String get commonHighlightSuv1 => 'SUV executivo, posição de direção elevada';

  @override
  String get commonHighlightSuv2 => 'Cabine ampla para quatro passageiros';

  @override
  String get commonHighlightSuv3 => 'Porta-malas para quatro malas despachadas';

  @override
  String get commonHighlightVan1 => 'Van executiva para grupos e famílias';

  @override
  String get commonHighlightVan2 => 'Até sete passageiros em três fileiras';

  @override
  String get commonHighlightVan3 => 'Espaço para duas malas despachadas';

  @override
  String get commonHighlightFirst1 => 'Sedã topo de linha, nosso nível máximo';

  @override
  String get commonHighlightFirst2 =>
      'Bancos traseiros com apoio de braço central';

  @override
  String get commonHighlightTwoCheckedBags =>
      'Porta-malas para duas malas despachadas';

  @override
  String get commonHighlightElectric1 => 'Sedã executivo totalmente elétrico';

  @override
  String get commonHighlightElectric2 => 'Silencioso e sem emissões';

  @override
  String get commonLuggageCabinOne => 'mala de mão';

  @override
  String get commonLuggageCheckedOne => 'mala despachada';

  @override
  String get commonLuggageOversizeOne => 'mala extragrande';

  @override
  String get commonLuggageCabinMany => 'malas de mão';

  @override
  String get commonLuggageCheckedMany => 'malas despachadas';

  @override
  String get commonLuggageOversizeMany => 'malas extragrandes';

  @override
  String get commonLuggageCabinSize => 'Até 55 × 40 × 20 cm';

  @override
  String get commonLuggageCheckedSize => 'Até 75 × 50 × 30 cm';

  @override
  String get commonLuggageOversizeSize => 'Mais de 80 cm';

  @override
  String get commonPromiseFixedPrice => 'Preço fixo ao reservar';

  @override
  String get commonPromiseFixedPriceLong =>
      'O preço que você vê ao confirmar é calculado pela Luxelane para o seu trajeto.';

  @override
  String get commonPromiseChauffeurs => 'Motoristas com documentos verificados';

  @override
  String get commonPromiseChauffeursLong =>
      'A Luxelane verifica os documentos de cada motorista antes que ele receba viagens.';

  @override
  String get commonVehicleElectric => 'Elétrico';

  @override
  String get commonVehicleBusinessDescription => 'Sedã executivo';

  @override
  String get commonVehicleSuvDescription => 'SUV executivo, mais espaço';

  @override
  String get commonVehicleFirstDescription => 'Sedã topo de linha';

  @override
  String get commonVehicleVanDescription => 'Van executiva para grupos';

  @override
  String get commonVehicleElectricDescription => 'Sedã executivo elétrico';

  @override
  String get commonServiceOneWay => 'Só ida';

  @override
  String get commonServiceByTheHour => 'Por hora';

  @override
  String get commonServiceOneWayDescription =>
      'Transfer com preço fixo até o seu destino';

  @override
  String get commonServiceByTheHourDescription =>
      'Motorista à sua disposição por um tempo determinado';

  @override
  String get commonStatusPending => 'Pendente';

  @override
  String get commonStatusConfirmed => 'Confirmada';

  @override
  String get commonStatusDriverArriving => 'A caminho';

  @override
  String get commonStatusDriverArrived => 'Motorista chegou';

  @override
  String get commonStatusVerified => 'Verificada';

  @override
  String get commonStatusInProgress => 'Em andamento';

  @override
  String get commonStatusCompleted => 'Concluída';

  @override
  String get commonStatusCancelled => 'Cancelada';

  @override
  String get commonStatusNoShow => 'Não comparecimento';

  @override
  String get commonCabinCool => 'Fresca';

  @override
  String get commonCabinMild => 'Amena';

  @override
  String get commonCabinWarm => 'Quente';

  @override
  String get commonPrefOpenDoor => 'Abrir a porta';

  @override
  String get commonPrefLuggageHelp => 'Ajuda com a bagagem';

  @override
  String commonPrefCabin(String temperature, String hint) {
    return 'Cabine $temperature ($hint)';
  }

  @override
  String get commonPrefQuiet => 'Viagem em silêncio';

  @override
  String get commonPrefNoMusic => 'Sem música';

  @override
  String get commonCancelReasonChangedPlans => 'Mudei de planos';

  @override
  String get commonCancelReasonOtherTransport => 'Encontrei outro transporte';

  @override
  String get commonCancelReasonDriverLate => 'O motorista está demorando muito';

  @override
  String get commonReasonOther => 'Outro motivo';

  @override
  String get commonReleaseReasonVehicle => 'Problema com o veículo';

  @override
  String get commonReleaseReasonEmergency => 'Emergência pessoal';

  @override
  String get commonReleaseReasonUnsafe => 'Condições inseguras';

  @override
  String get commonReleaseReasonSchedule => 'Conflito de horário';

  @override
  String get commonFeeBasisNoPolicy => 'Sem política de cancelamento';

  @override
  String get commonFeeBasisPolicyInvalid => 'Política inválida (sem taxa)';

  @override
  String get commonFeeBasisPaymentFailed => 'Falha no pagamento';

  @override
  String get commonFeeBasisNoDriver => 'Sem motorista atribuído';

  @override
  String get commonFeeBasisGrace => 'Dentro do prazo após reservar';

  @override
  String get commonFeeBasisEarly => 'Com antecedência suficiente';

  @override
  String get commonFeeBasisLate => 'Tarde (taxa aplicada)';

  @override
  String get commonFeeBasisNoShowAdmin =>
      'Não comparecimento (decisão da central)';

  @override
  String get commonPickupArea => 'Área de embarque';

  @override
  String get commonDropoffArea => 'Área de destino';

  @override
  String get commonTariffNegative => 'Os valores não podem ser negativos';

  @override
  String get commonTariffZeroTransfer => 'Um transfer não pode custar Bs0';

  @override
  String get commonTariffHourlyPrice =>
      'O serviço por hora precisa de um preço por hora';

  @override
  String get commonLocationNotificationTitle =>
      'Luxelane · você está conectado';

  @override
  String get commonLocationNotificationText =>
      'Compartilhamos sua localização para atribuir viagens e orientar o passageiro.';

  @override
  String get commonLocationChannelName => 'Localização do motorista';

  @override
  String get commonPricingLoading =>
      'Carregando as tarifas vigentes… tente novamente em alguns segundos.';

  @override
  String get commonPricingMaintenance =>
      'As reservas estão pausadas para manutenção. Tente novamente em alguns minutos.';

  @override
  String commonPricingUnavailable(String vehicleClass, String serviceType) {
    return '$vehicleClass não está disponível para \"$serviceType\" no momento.';
  }

  @override
  String get commonPromptEnjoyJourney => 'Aproveite o trajeto.';

  @override
  String get commonPromptChauffeurWaiting =>
      'Seu motorista já está esperando por você.';

  @override
  String get commonPromptChauffeurOnTheWay => 'Seu motorista está a caminho.';

  @override
  String get commonPromptNextTripSoon => 'Seu próximo trajeto está próximo.';

  @override
  String get commonPromptMorning => 'Onde começa o seu dia?';

  @override
  String get commonPromptMidday => 'Para onde levamos você?';

  @override
  String get commonPromptAfternoon => 'Vamos encerrar o dia com calma?';

  @override
  String get commonPromptEvening => 'Vamos voltar com calma?';

  @override
  String get commonPromptLateNight => 'Estamos aqui a qualquer hora.';

  @override
  String get commonFlightDomestic => 'Nacional';

  @override
  String get commonFlightInternational => 'Internacional';

  @override
  String get commonAirportDomesticExit => 'Saída do desembarque nacional';

  @override
  String get commonAirportInternationalExit =>
      'Saída do desembarque internacional';

  @override
  String get commonOriginNoCoords =>
      'Não foi possível localizar o embarque no mapa. Escolha outro endereço.';

  @override
  String commonOriginOutsideArea(String cities) {
    return 'Por enquanto operamos em $cities. Escolha um embarque em uma dessas cidades.';
  }

  @override
  String commonDestinationOtherCity(String city) {
    return 'O destino deve estar em $city, a mesma cidade do embarque.';
  }

  @override
  String get commonDestinationSameCity =>
      'O destino deve estar na mesma cidade do embarque.';

  @override
  String get commonFlightNumberMissing =>
      'Informe o número do seu voo para buscarmos você a tempo.';

  @override
  String get commonFlightNumberInvalid =>
      'Número de voo inválido. Exemplo: OB 760 ou Z8 315.';

  @override
  String get commonAppTitle => 'Luxelane — Serviço de motorista executivo';

  @override
  String get commonTabBook => 'Reservar';

  @override
  String get commonTabMyTrips => 'Minhas viagens';

  @override
  String get commonTabProfile => 'Perfil';

  @override
  String get commonSignIn => 'Entrar';

  @override
  String get commonMyProfile => 'Meu perfil';

  @override
  String get commonNotFoundTitle => 'Esta página não existe.';

  @override
  String get commonNotFoundBody => 'Vamos levar você de volta ao início.';

  @override
  String get commonNotFoundBack => 'VOLTAR AO INÍCIO';

  @override
  String get commonUpdateTitleDriver => 'Atualize o app para continuar';

  @override
  String get commonUpdateTitleRider => 'Atualize o app para reservar';

  @override
  String get commonUpdateBodyWeb =>
      'Há uma nova versão do site. Recarregue a página para continuar reservando.';

  @override
  String get commonUpdateBodyApp =>
      'Há uma nova versão do app. Atualize-o para continuar reservando.';

  @override
  String get commonUpdateGoToStore => 'Ir para a loja';

  @override
  String get commonGotIt => 'Entendi';

  @override
  String get commonEmailNotVerifiedTitle =>
      'Verifique seu e-mail para reservar';

  @override
  String get commonEmailNotVerifiedBody =>
      'Por segurança, só é possível reservar com o e-mail verificado. Abra o link que enviamos ou peça um novo.';

  @override
  String get commonNotNow => 'Agora não';

  @override
  String get commonVerifyMyEmail => 'Verificar meu e-mail';

  @override
  String get commonErrorTitle => 'Algo deu errado';

  @override
  String get commonErrorBody =>
      'Fomos notificados e estamos trabalhando em uma solução.';

  @override
  String get commonTryAgain => 'Tentar novamente';

  @override
  String get commonOfflineBanner =>
      'Sem conexão. O que você vê pode não estar atualizado.';

  @override
  String get commonLoading => 'Carregando';

  @override
  String get commonDone => 'Pronto';

  @override
  String commonStepOf(int step, int total) {
    return 'Etapa $step de $total';
  }

  @override
  String get commonSlideToConfirm => 'Deslize para confirmar';

  @override
  String commonUpTo(int count) {
    return 'Até $count';
  }

  @override
  String commonHoursTotal(int hours) {
    return '${hours}h no total';
  }

  @override
  String get commonFixedPriceLower => 'preço fixo';

  @override
  String get commonRiderStyle => 'PREFERÊNCIAS DO PASSAGEIRO';

  @override
  String get commonConfirmBooking => 'Confirmar reserva';

  @override
  String get commonFixedPriceUpper => 'PREÇO FIXO';

  @override
  String get commonMapUnavailable => 'Mapa indisponível';

  @override
  String get commonMapUnavailableDetail =>
      'O mapa não pode ser exibido agora. Os dados da viagem continuam aqui.';

  @override
  String get commonPointOnMap => 'Ponto escolhido no mapa';

  @override
  String get commonSelectLocation => 'Selecionar local';

  @override
  String get commonMoveMapToChoose => 'Mova o mapa para escolher o local';

  @override
  String get commonSelectedLocation => 'LOCAL SELECIONADO';

  @override
  String get commonConfirmUpper => 'CONFIRMAR';

  @override
  String get commonAddressNotFound =>
      'Não foi possível localizar esse endereço. Tente outro ou escolha-o no mapa.';

  @override
  String get commonSelectPickupPlace => 'Selecionar ponto de embarque';

  @override
  String get commonSelectDestination => 'Selecionar destino';

  @override
  String get commonDestinationWasOtherCity =>
      'O destino estava em outra cidade. Escolha um na cidade de embarque.';

  @override
  String get commonPickupDateUpper => 'DATA DE EMBARQUE';

  @override
  String get commonPickupTimeUpper => 'HORÁRIO DE EMBARQUE';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonNext => 'Próximo';

  @override
  String get commonPickupMissing => 'Informe onde buscamos você.';

  @override
  String commonPickupMovedLater(String when) {
    return 'Não há mais tempo para esse horário: mudamos para $when. Confira e continue.';
  }

  @override
  String get commonDestinationMissing =>
      'Informe seu destino para calcular o preço fixo.';

  @override
  String get commonPickupHintAirport =>
      'Embarque — aeroporto, hotel ou endereço';

  @override
  String get commonPickupHint => 'Embarque — endereço, hotel ou local';

  @override
  String get commonDestinationHintAirport =>
      'Destino — aeroporto, hotel ou endereço';

  @override
  String get commonDestinationOptional => 'Destino (opcional)';

  @override
  String get commonDestinationHint => 'Destino — endereço, hotel ou local';

  @override
  String get commonBookYourChauffeur => 'RESERVE SEU MOTORISTA';

  @override
  String get commonPickup => 'Embarque';

  @override
  String get commonDestination => 'Destino';

  @override
  String get commonNow => 'Agora';

  @override
  String get commonSchedule => 'Agendar';

  @override
  String get commonChange => 'Alterar';

  @override
  String get commonSeeVehiclesAndPrices => 'VER VEÍCULOS E PREÇOS';

  @override
  String get commonNoCommitment =>
      'Sem compromisso: você verá o preço final antes de confirmar.';

  @override
  String get commonChooseOnMap => 'Escolher no mapa';

  @override
  String get commonDuration => 'Duração';

  @override
  String get commonFewerHours => 'Menos horas';

  @override
  String get commonMoreHours => 'Mais horas';

  @override
  String get commonServiceAirportTransfer => 'Transfer para o aeroporto';

  @override
  String get commonServiceHourly => 'Motorista por hora';

  @override
  String get commonServiceImmediate => 'Embarque imediato';

  @override
  String get commonHomeLinkLabel => 'Luxelane, início';

  @override
  String get commonFleet => 'Frota';

  @override
  String get commonForBusiness => 'Para empresas';

  @override
  String get commonServicesUpper => 'SERVIÇOS';

  @override
  String get commonBookUpper => 'RESERVAR';

  @override
  String get commonBookATripUpper => 'RESERVAR UMA VIAGEM';

  @override
  String get commonMenu => 'Menu';

  @override
  String get commonCloseMenu => 'Fechar menu';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonServices => 'Serviços';

  @override
  String get commonFooterTagline =>
      'Serviço de motorista particular para quem valoriza seu tempo, sua privacidade e cada detalhe do caminho.';

  @override
  String get commonDriveWithUs => 'Dirija conosco';

  @override
  String get commonTerms => 'Termos e condições';

  @override
  String get commonPrivacy => 'Política de privacidade';

  @override
  String get commonOurPromise => 'Nossa promessa';

  @override
  String commonCopyright(String year) {
    return '© $year Luxelane. Todos os direitos reservados.';
  }

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
  String get errorTooManyAttempts =>
      'Muitas tentativas. Aguarde alguns minutos e tente novamente.';

  @override
  String get errorSessionExpired => 'Sua sessão expirou. Entre novamente.';

  @override
  String get errorMfaRequired =>
      'Ative a verificação em duas etapas (Perfil) e entre novamente para continuar.';

  @override
  String get errorReauthRequired =>
      'Por segurança, entre novamente para continuar.';

  @override
  String get errorNoConnection =>
      'Sem conexão com o servidor. Verifique sua rede e tente novamente.';

  @override
  String get errorReauthWrongPassword => 'A senha não confere.';

  @override
  String get errorReauthUserMismatch =>
      'Use a mesma conta com que você entrou.';

  @override
  String get errorReauthFailed =>
      'Não foi possível confirmar sua identidade. Tente novamente.';

  @override
  String get errorInvalidArgument => 'Verifique os dados e tente novamente.';

  @override
  String get errorPermissionDenied => 'Você não tem permissão para fazer isso.';

  @override
  String get errorFailedPrecondition => 'Isso não pode ser feito no momento.';

  @override
  String get errorNotFound => 'Não encontramos o registro.';

  @override
  String get errorGeneric => 'Não foi possível concluir. Tente novamente.';

  @override
  String get errorDeleteActiveBookings =>
      'Você tem viagens ativas ou reservadas. Cancele-as ou aguarde que terminem antes de excluir sua conta.';

  @override
  String get errorDeleteAdminAccount =>
      'Contas de administração são excluídas pelo console.';

  @override
  String get errorDeleteAccountFailed =>
      'Não foi possível excluir sua conta. Tente novamente.';

  @override
  String get errorTermsOutdated =>
      'Os termos acabaram de ser atualizados. Abra-os novamente e aceite-os outra vez.';

  @override
  String get errorAcceptTermsFailed =>
      'Não foi possível registrar sua aceitação. Tente novamente.';

  @override
  String get errorBusinessLeadTooMany =>
      'Já recebemos várias solicitações daqui. Tente mais tarde ou escreva para nós.';

  @override
  String get errorBusinessLeadInvalid => 'Verifique os dados do formulário.';

  @override
  String get errorBusinessLeadFailed =>
      'Não foi possível enviar sua solicitação. Tente novamente.';

  @override
  String get errorBadCredentials => 'E-mail ou senha incorretos.';

  @override
  String errorPasswordResetSent(String email) {
    return 'Se houver uma conta com $email, enviamos um link para redefinir sua senha. Verifique também a caixa de spam.';
  }

  @override
  String get errorLoginFailed => 'Não foi possível entrar. Tente novamente.';

  @override
  String get errorRegisterEmailInUse =>
      'Não foi possível criar a conta com esse e-mail. Se você já se cadastrou, entre ou recupere sua senha.';

  @override
  String get errorInvalidEmail => 'Esse e-mail não é válido. Verifique-o.';

  @override
  String get errorWeakPassword =>
      'A senha é muito fraca: use pelo menos 6 caracteres.';

  @override
  String get errorRegisterFailed =>
      'Não foi possível criar a conta. Tente novamente.';

  @override
  String get errorPasswordResetFailed =>
      'Não foi possível enviar o link. Tente novamente.';

  @override
  String get errorServerDefault => 'Erro do servidor';

  @override
  String get errorEmailNotVerified =>
      'Verifique seu e-mail para poder reservar.';

  @override
  String get errorTermsRequired =>
      'Aceite os termos vigentes para poder reservar.';

  @override
  String get errorAuthDefault => 'Erro de autenticação';

  @override
  String get errorAuthCancelledDefault => 'Login cancelado';

  @override
  String get errorNetworkDefault => 'Sem conexão com a internet';

  @override
  String get errorNotFoundDefault => 'Recurso não encontrado';

  @override
  String get errorPaymentDefault => 'Erro no pagamento';

  @override
  String get errorPermissionDefault => 'Permissão negada';

  @override
  String get errorPriceChanged => 'O preço desta viagem mudou.';

  @override
  String get errorCancellationFeeChanged => 'A taxa de cancelamento mudou.';

  @override
  String get errorAppUpdateDriver =>
      'Atualize o app para continuar com suas viagens.';

  @override
  String get errorAppUpdateRider => 'Atualize o app para reservar.';

  @override
  String get errorValidationDefault => 'Erro de validação';

  @override
  String get errorMfaEnterCode => 'Digite o código do seu app autenticador.';

  @override
  String get errorMfaWrongCode =>
      'Código incorreto. Use o código atual do seu app autenticador (e verifique se a hora do celular está automática).';

  @override
  String get errorMfaRecentLogin =>
      'Por segurança, saia, entre novamente e repita a configuração.';

  @override
  String get errorMfaUnverifiedEmail =>
      'Verifique seu e-mail antes de ativar a verificação em duas etapas.';

  @override
  String get errorMfaNoConnection =>
      'Sem conexão. Verifique sua rede e tente novamente.';

  @override
  String get errorMfaQrExpired =>
      'O código QR expirou. Comece a configuração novamente.';

  @override
  String get errorMfaNotEnabled =>
      'A verificação em duas etapas ainda não está ativada. Avise a central.';

  @override
  String get errorMfaNoTotp =>
      'Sua conta não tem um app autenticador registrado. Entre em contato com a central.';

  @override
  String get errorMfaFailed =>
      'Não foi possível concluir a verificação. Tente novamente.';

  @override
  String get errorAccountBlocked =>
      'Sua conta está bloqueada. Escreva para o suporte se achar que é um erro.';

  @override
  String get errorDriverSuspended =>
      'Conta suspensa. Entre em contato com a central.';

  @override
  String get errorAppCheckFailed =>
      'Não foi possível verificar o app. Atualize-o ou tente mais tarde.';

  @override
  String get homePickOriginTitle => 'Selecionar ponto de embarque';

  @override
  String get homePickDestinationTitle => 'Selecionar destino';

  @override
  String get homeDestinationOtherCity =>
      'O destino estava em outra cidade. Escolha um na cidade de embarque.';

  @override
  String get homeEnterPickup => 'Informe um ponto de embarque';

  @override
  String homePickupMoved(String when) {
    return 'Esse horário já não é possível: nós o mudamos para $when. Confira e continue.';
  }

  @override
  String get homeEnterDestination => 'Informe um destino';

  @override
  String get homeLocationUnavailable =>
      'Não foi possível usar sua localização. Permita o acesso à localização no navegador ou nas configurações do celular, ou escolha o ponto no mapa.';

  @override
  String get homeMyProfile => 'Meu perfil';

  @override
  String get homeSeeVehicles => 'Ver veículos e preços';

  @override
  String homeHourlyFrom(int hours, String place) {
    return '$hours h a partir de $place';
  }

  @override
  String get homeNextTripSemantics => 'Ver sua próxima viagem';

  @override
  String get homeNextTripEyebrow => 'SUA PRÓXIMA VIAGEM';

  @override
  String get homePickupLabel => 'Ponto de embarque';

  @override
  String get homePickupHint => 'Embarque';

  @override
  String get homeUseMyLocation => 'Usar minha localização';

  @override
  String get homeDestinationLabel => 'Destino';

  @override
  String get homeDestinationHint => 'Para onde você vai?';

  @override
  String get homeChooseOnMap => 'Escolher no mapa';

  @override
  String get homeRepeatLast => 'Repetir última viagem';

  @override
  String homeRouteSummary(String km, int minutes) {
    return '$km km · $minutes min';
  }

  @override
  String homePreferredClass(String vehicleClass) {
    return 'Categoria: $vehicleClass';
  }

  @override
  String get homePickupDateHelp => 'DATA DE EMBARQUE';

  @override
  String get homePickupTimeHelp => 'HORÁRIO DE EMBARQUE';

  @override
  String get homePickerCancel => 'Cancelar';

  @override
  String get homePickerNext => 'Próximo';

  @override
  String get homePickerDone => 'Concluído';

  @override
  String get homeChangePickupTime => 'Alterar data e horário de embarque';

  @override
  String homeAsap(String time) {
    return 'O quanto antes · $time';
  }

  @override
  String get homeSchedule => 'Agendar';

  @override
  String get homeDuration => 'Duração';

  @override
  String get homeWebHeadlineStart => 'Seu motorista ';

  @override
  String get homeWebHeadlineEnd => 'espera por você.';

  @override
  String get homeWebPickup => 'EMBARQUE';

  @override
  String get homeWebWhereAreYou => 'Onde você está?';

  @override
  String get homeWebDestination => 'DESTINO';

  @override
  String get homeWebDuration => 'DURAÇÃO';

  @override
  String get homeWebDateTime => 'DATA E HORA';

  @override
  String get homeWebChangeLocation => 'ALTERAR LOCAL';

  @override
  String get homeWebOneWay => 'Só ida';

  @override
  String get homeWebHourly => 'Por hora';

  @override
  String get homeWebSeePrices => 'VER PREÇOS';

  @override
  String get homeWebConfirm => 'CONFIRMAR';

  @override
  String homeWebHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String get homeWebMarqueeFixedPrices => 'Preços Fixos';

  @override
  String get homeWebMarqueeChauffeurs => 'Motoristas Profissionais';

  @override
  String get homeWebMarqueeFleet => 'Frota Premium';

  @override
  String get homeWebMarqueeAirport => 'Transfers para o Aeroporto';

  @override
  String get homeWebMarqueeCorporate => 'Viagens Corporativas';

  @override
  String get homeWebFleetEyebrow => 'Nossa Frota';

  @override
  String get homeWebFleetTitle => 'Veículos premium,\nsem exceção.';

  @override
  String get homeWebFleetSwipe => 'DESLIZE PARA EXPLORAR →';

  @override
  String get homeWebReview1Quote =>
      'Absolutamente impecável do início ao fim. O motorista chegou antes do horário e o carro estava imaculado. Não vou usar outro serviço.';

  @override
  String get homeWebReview1Location => 'Londres, Reino Unido';

  @override
  String get homeWebReview2Quote =>
      'Os preços fixos e os motoristas confiáveis fazem da Luxelane o único serviço em que confio para todas as minhas viagens de negócios.';

  @override
  String get homeWebReview2Location => 'Nova York, EUA';

  @override
  String get homeWebReview3Quote =>
      'Do aeroporto ao hotel, cada detalhe foi cuidado com perfeição. É assim que uma viagem de luxo deve ser.';

  @override
  String get homeWebReview3Location => 'Paris, França';

  @override
  String get homeWebBusinessPerkBilling =>
      'Faturamento e cobranças centralizados';

  @override
  String get homeWebBusinessPerkPriority =>
      'Reservas prioritárias para executivos';

  @override
  String get homeWebBusinessEyebrow => 'Para Empresas';

  @override
  String get homeWebBusinessTitle => 'Viagens corporativas,\nredefinidas.';

  @override
  String get homeWebBusinessBody =>
      'A Luxelane para Empresas oferece à sua equipe acesso a um serviço de motorista premium com os controles e relatórios que sua equipe financeira exige.';

  @override
  String get homeWebLearnMore => 'Saiba mais';

  @override
  String get homeWebCtaEyebrow => 'QUANDO QUISER. ONDE QUISER.';

  @override
  String get homeWebCtaTitleStart => 'Sua próxima viagem,';

  @override
  String get homeWebCtaTitleEnd => 'do seu jeito.';

  @override
  String get homeWebCtaPromise => 'Preço fixo  ·  Motoristas profissionais';

  @override
  String get homeWebCtaBook => 'Reservar uma viagem';

  @override
  String get homeWebCtaFleet => 'Ver frota';

  @override
  String get homeWebBookTagline => 'Serviço de Motorista Premium';

  @override
  String get homeWebBookStandardLabel => 'O Padrão';

  @override
  String get homeWebBookStandardSub => 'A Promessa Que Cumprimos';

  @override
  String get homeWebBookStandardTag => 'O Padrão Luxelane';

  @override
  String get homeWebBookStandardHeadline => 'O padrão que\noutros seguem.';

  @override
  String get homeWebBookStandardBullet1 =>
      'Motoristas com documentos verificados';

  @override
  String get homeWebBookStandardBullet2 => 'Preço fixo ao reservar';

  @override
  String get homeWebBookExperienceLabel => 'A Experiência';

  @override
  String get homeWebBookExperienceSub => 'Cada Detalhe Pensado';

  @override
  String get homeWebBookExperienceHeadline => 'Cada detalhe,\ncuidado.';

  @override
  String get homeWebBookExperienceBody =>
      'De playlists selecionadas à privacidade com cancelamento de ruído — suas preferências, lembradas.';

  @override
  String get homeWebBookExperienceBullet1 => 'Interiores em couro premium';

  @override
  String get homeWebBookExperienceBullet2 => 'Wi-Fi e carregamento sem fio';

  @override
  String get homeWebBookExperienceBullet3 => 'Serviço de champanhe disponível';

  @override
  String get homeWebBookExperienceBullet4 => 'Controle de climatização';

  @override
  String get homeWebBookBusinessSub => 'Viagens Corporativas Redefinidas';

  @override
  String get homeWebBookBusinessBullet1 => 'Faturamento centralizado';

  @override
  String get homeWebBookEyebrow => 'NOSSA EXPERIÊNCIA EXCLUSIVA';

  @override
  String get homeWebBookScroll => 'ROLE';

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
  String get servicesPromiseEyebrow => 'Nossa promessa';

  @override
  String get servicesPromiseTitle => 'Tranquilidade, por escrito.';

  @override
  String get servicesStepsEyebrow => 'Como funciona';

  @override
  String get servicesStepsTitle => 'Três passos.\nNada mais.';

  @override
  String get servicesFleetEyebrow => 'A frota';

  @override
  String get servicesFleetTitle => 'Escolha como chegar.';

  @override
  String get servicesFleetBody =>
      'Veículos de alto padrão, impecáveis e preparados antes de cada serviço.';

  @override
  String get servicesMostChosen => 'A MAIS ESCOLHIDA';

  @override
  String servicesCapacity(int count) {
    return 'Até $count passageiros';
  }

  @override
  String get servicesPriceFrom => 'A PARTIR DE';

  @override
  String get servicesQuoteOnBooking => 'Cotação ao reservar';

  @override
  String get servicesFaqEyebrow => 'Perguntas frequentes';

  @override
  String get servicesFaqTitle => 'Tudo o que\nvocê quer saber.';

  @override
  String get servicesBookNow => 'RESERVAR AGORA';

  @override
  String get servicesAirportEyebrow => 'Transfer para o aeroporto';

  @override
  String get servicesAirportTitle => 'Aterrisse.\nNós cuidamos\ndo resto.';

  @override
  String get servicesAirportLead =>
      'Seu motorista espera por você no desembarque com seu nome e cuida da bagagem. Você só precisa sair pela porta.';

  @override
  String get servicesAirportStep1Title => 'Reserve em 2 minutos';

  @override
  String get servicesAirportStep1Body =>
      'Informe o aeroporto, o destino e o horário. Adicione o número do seu voo e você verá o preço final.';

  @override
  String get servicesAirportStep2Title => 'Conheça seu motorista';

  @override
  String get servicesAirportStep2Body =>
      'Antes do embarque, você terá o nome, o veículo e o contato dele no app.';

  @override
  String get servicesAirportStep3Title => 'Saia e relaxe';

  @override
  String get servicesAirportStep3Body =>
      'Ele espera por você no desembarque, cuida da bagagem e leva você direto ao destino.';

  @override
  String get servicesAirportStoryEyebrow => 'A chegada';

  @override
  String get servicesAirportStoryTitle =>
      'O primeiro momento\nda sua viagem, resolvido.';

  @override
  String get servicesAirportStoryBody =>
      'Depois de um voo longo, a última coisa que você quer são filas, negociações ou incerteza. Um motorista Luxelane transforma a chegada em uma transição tranquila até seu hotel, sua reunião ou sua casa.';

  @override
  String get servicesAirportStoryPoint1 =>
      'Ajuda com a bagagem, da esteira ao porta-malas';

  @override
  String get servicesAirportStoryPoint2 =>
      'Conexões entre aeroportos e hotéis sem complicações';

  @override
  String get servicesAirportFaq1Question => 'Onde o motorista vai me esperar?';

  @override
  String get servicesAirportFaq1Answer =>
      'Na área de desembarque. Você receberá os dados de contato dele no app antes do embarque.';

  @override
  String get servicesAirportFaq2Question => 'Posso cancelar minha reserva?';

  @override
  String get servicesAirportFaq2Answer =>
      'Sim, pelo app antes do início da viagem. Se a política de cancelamento previr uma taxa, você a verá antes de confirmar.';

  @override
  String get servicesAirportFaq3Question => 'Quanta bagagem posso levar?';

  @override
  String get servicesAirportFaq3Answer =>
      'Depende da categoria do veículo. Se você viaja com muita bagagem ou em grupo, a Business Van tem espaço para até 7 passageiros.';

  @override
  String get servicesAirportClosingTitle =>
      'Seu próximo voo\njá tem motorista.';

  @override
  String get servicesAirportClosingBody =>
      'Reserve agora. Preço fixo ao reservar e motoristas com documentos verificados.';

  @override
  String get servicesHourlyEyebrow => 'Motorista por hora';

  @override
  String get servicesHourlyTitle => 'Sua agenda.\nSeu ritmo.\nSeu motorista.';

  @override
  String get servicesHourlyLead =>
      'Um motorista e um veículo exclusivamente para você, de 2 a 24 horas. Mude de planos quantas vezes quiser: ele se adapta.';

  @override
  String get servicesHourlyStopsTitle => 'Paradas ilimitadas';

  @override
  String get servicesHourlyStopsDetail =>
      'Reuniões, compras ou visitas: seu motorista espera por você em cada parada.';

  @override
  String get servicesHourlyStep1Title => 'Escolha a duração';

  @override
  String get servicesHourlyStep1Body =>
      'Informe o ponto de embarque, o dia e quantas horas você precisa. Mínimo 2, máximo 24.';

  @override
  String get servicesHourlyStep2Title => 'Planeje seu dia';

  @override
  String get servicesHourlyStep2Body =>
      'Compartilhe seu roteiro nas observações ou decida no caminho. Não é preciso um destino final.';

  @override
  String get servicesHourlyStep3Title => 'Aproveite sem olhar o relógio';

  @override
  String get servicesHourlyStep3Body =>
      'Seu motorista e seu veículo ficam à sua disposição durante todo o tempo reservado.';

  @override
  String get servicesHourlyStoryEyebrow => 'Para cada ocasião';

  @override
  String get servicesHourlyStoryTitle =>
      'Um dia inteiro,\nsem pensar em como se locomover.';

  @override
  String get servicesHourlyStoryBody =>
      'De uma agenda de reuniões a uma tarde descobrindo a cidade, o serviço por hora dá a você a liberdade de um veículo particular sem nenhuma das preocupações.';

  @override
  String get servicesHourlyStoryPoint1 =>
      'Viagens de negócios: de reunião em reunião, sem esperas';

  @override
  String get servicesHourlyStoryPoint2 =>
      'Eventos e jantares: chegada impecável, saída sem pressa';

  @override
  String get servicesHourlyStoryPoint3 =>
      'Turismo particular: a cidade no seu ritmo, com um motorista local';

  @override
  String get servicesHourlyStoryPoint4 =>
      'Compras e lazer: seu motorista guarda suas sacolas e espera por você';

  @override
  String get servicesHourlyFaq1Question =>
      'Como reservo um motorista por hora?';

  @override
  String get servicesHourlyFaq1Answer =>
      'Selecione o ponto de embarque, a duração, o dia e o horário. Depois escolha a categoria do veículo e confirme. Você verá o preço final antes de pagar.';

  @override
  String get servicesHourlyFaq2Question =>
      'Posso mudar o roteiro durante o serviço?';

  @override
  String get servicesHourlyFaq2Answer =>
      'Sim. O motorista e o veículo ficam à sua disposição durante todas as horas reservadas, com quantas paradas você precisar.';

  @override
  String get servicesHourlyFaq3Question => 'Posso aumentar o número de horas?';

  @override
  String get servicesHourlyFaq3Answer =>
      'Sim, você pode alterar a reserva antes do horário de início. A duração mínima é de 2 horas e a máxima, de 24.';

  @override
  String get servicesHourlyFaq4Question =>
      'Pode começar ou terminar em um aeroporto?';

  @override
  String get servicesHourlyFaq4Answer =>
      'Sim. O serviço pode começar ou terminar em um aeroporto, desde que o início e o fim estejam na mesma cidade.';

  @override
  String get servicesHourlyFaq5Question =>
      'Quando vou receber os dados do motorista?';

  @override
  String get servicesHourlyFaq5Answer =>
      'Antes do embarque, você terá no app o nome do motorista, o veículo e o contato dele.';

  @override
  String get servicesHourlyClosingTitle =>
      'Reserve o tempo.\nNós cuidamos do caminho.';

  @override
  String get servicesHourlyClosingBody =>
      'A partir de 2 horas, com preço fixo e um motorista profissional à sua inteira disposição.';

  @override
  String get servicesImmediateEyebrow => 'Embarque sob demanda';

  @override
  String get servicesImmediateTitle => 'Quando você\nprecisar.';

  @override
  String get servicesImmediateLead =>
      'A mesma excelência de uma reserva antecipada, sem planejar.';

  @override
  String get servicesImmediateTrackingTitle => 'Acompanhamento em tempo real';

  @override
  String get servicesImmediateTrackingDetail =>
      'Veja no mapa onde está seu motorista e quando ele chega.';

  @override
  String get servicesImmediateStep1Title => 'Informe origem e destino';

  @override
  String get servicesImmediateStep1Body =>
      'Digite o endereço ou escolha no mapa. Você verá o preço final antes de confirmar.';

  @override
  String get servicesImmediateStep2Title => 'Confirme com um toque';

  @override
  String get servicesImmediateStep2Body =>
      'Você paga a reserva. Com o pagamento confirmado, buscamos um motorista e mostramos o nome e o veículo dele.';

  @override
  String get servicesImmediateStep3Title => 'Acompanhe no mapa';

  @override
  String get servicesImmediateStep3Body =>
      'Receba uma notificação quando seu motorista estiver a caminho e outra quando ele tiver chegado.';

  @override
  String get servicesImmediateStoryEyebrow => 'Sem planejar';

  @override
  String get servicesImmediateStoryTitle =>
      'O imprevisto,\ncom a mesma elegância.';

  @override
  String get servicesImmediateStoryBody =>
      'Uma reunião que se estende, uma mudança de planos, um jantar que merece um final à altura. O embarque sob demanda coloca um veículo premium e um motorista profissional ao seu alcance.';

  @override
  String get servicesImmediateStoryPoint1 =>
      'Veículos premium, impecáveis em cada serviço';

  @override
  String get servicesImmediateStoryPoint2 =>
      'Motoristas com documentos verificados';

  @override
  String get servicesImmediateStoryPoint3 =>
      'Preço fixo calculado antes de confirmar, sem tarifas dinâmicas';

  @override
  String get servicesImmediateFaq1Question =>
      'Quanto tempo o motorista leva para chegar?';

  @override
  String get servicesImmediateFaq1Answer =>
      'Depende da sua localização e da disponibilidade. Você verá o horário estimado de chegada antes de confirmar e poderá acompanhar o motorista no mapa.';

  @override
  String get servicesImmediateFaq2Question =>
      'O preço muda conforme a demanda?';

  @override
  String get servicesImmediateFaq2Answer =>
      'Não. O preço é definido antes de confirmar e não muda: sem tarifas dinâmicas nem cobranças ocultas.';

  @override
  String get servicesImmediateFaq3Question =>
      'Posso agendar a viagem para mais tarde?';

  @override
  String get servicesImmediateFaq3Answer =>
      'Sim. Escolha \"Agendar\" no formulário e selecione o dia e o horário que preferir.';

  @override
  String get servicesImmediateFaq4Question => 'E se eu precisar cancelar?';

  @override
  String get servicesImmediateFaq4Answer =>
      'Você pode cancelar pelo app antes do início da viagem. Se a política de cancelamento previr uma taxa, você a verá antes de confirmar.';

  @override
  String get servicesImmediateClosingTitle => 'Seu motorista,\na um toque.';

  @override
  String get servicesImmediateClosingBody =>
      'Confirme agora e acompanhe seu motorista em tempo real até a porta.';

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
