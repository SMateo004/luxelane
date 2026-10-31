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
}
