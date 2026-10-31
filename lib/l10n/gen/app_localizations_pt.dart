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
}
