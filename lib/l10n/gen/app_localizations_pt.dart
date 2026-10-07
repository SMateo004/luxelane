// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get adminActionFailed => 'Não foi possível concluir a ação. Tente novamente.';

  @override
  String get adminActive => 'Ativo';

  @override
  String get adminAppVersion => 'Versão do app';

  @override
  String get adminAssignNearest => 'Atribuir motorista mais próximo';

  @override
  String adminAttentionBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reservas sem motorista, embarque em menos de 2 horas',
      one: '1 reserva sem motorista, embarque em menos de 2 horas',
    );
    return '$_temp0';
  }

  @override
  String get adminAttentionView => 'Ver';

  @override
  String adminAuditBy(String id) {
    return 'Admin: $id';
  }

  @override
  String get adminBackend => 'Back-end';

  @override
  String get adminBookingActions => 'Ações';

  @override
  String adminBookingDriver(String name) {
    return 'Motorista: $name';
  }

  @override
  String adminBookingRider(String name) {
    return 'Passageiro: $name';
  }

  @override
  String get adminBusinessPerformance => 'Desempenho do negócio';

  @override
  String get adminCancelBooking => 'Cancelar reserva';

  @override
  String get adminCancelBookingBody => 'O passageiro e o motorista designado serão avisados.';

  @override
  String adminCancelBookingTitle(String code) {
    return 'Cancelar a reserva $code?';
  }

  @override
  String adminChangeRoleTitle(String name) {
    return 'Alterar função de $name';
  }

  @override
  String get adminCurrency => 'Moeda';

  @override
  String get adminCurrencyValue => 'Bolivianos (Bs)';

  @override
  String adminDeleteBookingBody(String id) {
    return 'A reserva #$id será excluída permanentemente. Esta ação não pode ser desfeita.';
  }

  @override
  String get adminDeleteBookingTitle => 'Excluir reserva?';

  @override
  String get adminDeleteBookingTooltip => 'Excluir reserva';

  @override
  String get adminDisable => 'Desativar';

  @override
  String get adminDocumentsVerified => 'Documentos verificados';

  @override
  String get adminFieldBase => 'Base (Bs)';

  @override
  String get adminFieldMinimum => 'Mínimo (Bs)';

  @override
  String get adminFieldPerHour => 'Por hora (Bs)';

  @override
  String get adminFieldPerKm => 'Por km (Bs)';

  @override
  String get adminFilterAll => 'Todas';

  @override
  String get adminFilterUnassigned => 'Sem motorista';

  @override
  String get adminFirestoreRules => 'Regras de preços do Firestore';

  @override
  String get adminGlobalSettings => 'Configurações globais do app';

  @override
  String get adminInactive => 'Inativo';

  @override
  String get adminKpiAwaitingDriver => 'Aguardando motorista';

  @override
  String get adminKpiCompleted => 'Viagens concluídas';

  @override
  String adminKpiDriversCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count motoristas',
      one: '1 motorista',
    );
    return '$_temp0';
  }

  @override
  String adminKpiInProgress(int count) {
    return '$count em andamento';
  }

  @override
  String get adminKpiPending => 'Reservas pendentes';

  @override
  String adminKpiToday(String amount) {
    return 'Hoje: $amount';
  }

  @override
  String get adminKpiTotalRevenue => 'Receita total';

  @override
  String get adminKpiUsers => 'Usuários cadastrados';

  @override
  String adminLicense(String number) {
    return 'CNH: $number';
  }

  @override
  String get adminLiveStats => 'Estatísticas ao vivo';

  @override
  String get adminMaintenanceBanner => 'MODO DE MANUTENÇÃO ATIVO — Os passageiros não podem reservar novas viagens.';

  @override
  String get adminMaintenanceMode => 'Modo de manutenção';

  @override
  String get adminMaintenanceModeDesc => 'Desativa todas as reservas e mostra a tela de manutenção aos usuários.';

  @override
  String adminMemberSince(String date) {
    return 'Membro desde $date';
  }

  @override
  String get adminNoAuditLogs => 'Nenhum registro de auditoria ainda';

  @override
  String get adminNoAuditLogsHint => 'As ações administrativas aparecerão aqui em tempo real';

  @override
  String get adminNoBookings => 'Nenhuma reserva encontrada';

  @override
  String get adminNoDrivers => 'Nenhum motorista encontrado';

  @override
  String get adminNoUsersMatch => 'Nenhum usuário corresponde à busca';

  @override
  String get adminNoVehicles => 'Nenhum veículo cadastrado ainda';

  @override
  String get adminNoVehiclesHint => 'Os veículos vinculados a motoristas aparecem aqui';

  @override
  String get adminNoticeBookingCancelled => 'Reserva cancelada';

  @override
  String get adminNoticeBookingDeleted => 'Reserva excluída';

  @override
  String get adminNoticeDriverAssigned => 'Motorista designado';

  @override
  String get adminNoticeDriverVerified => 'Motorista verificado';

  @override
  String get adminNoticeMaintenanceOff => 'Modo de manutenção desativado';

  @override
  String get adminNoticeMaintenanceOn => 'Modo de manutenção ativado';

  @override
  String get adminNoticeNoDriver => 'Nenhum motorista disponível por perto para esta categoria';

  @override
  String get adminNoticePricingUpdated => 'Regra de preço atualizada';

  @override
  String get adminNoticeRoleUpdated => 'Função atualizada';

  @override
  String get adminNoticeSettingsSaved => 'Configurações salvas';

  @override
  String get adminOffline => 'Offline';

  @override
  String get adminOnline => 'Online';

  @override
  String get adminOverview => 'Visão geral';

  @override
  String get adminPanelBadge => 'Painel admin';

  @override
  String get adminPlatform => 'Plataforma';

  @override
  String get adminPlatformValue => 'Flutter Web + mobile';

  @override
  String adminPriceBaseAndKm(String base, String perKm) {
    return '$base base + $perKm/km';
  }

  @override
  String adminPriceBasePlusKm(String base, String perKm) {
    return '$base + $perKm/km';
  }

  @override
  String adminPriceMinimum(String amount) {
    return 'Mín.: $amount';
  }

  @override
  String adminPricePerHour(String amount) {
    return '$amount/h';
  }

  @override
  String get adminPricingNote => 'Os preços refletem o modelo DefaultPricing. Se a coleção pricingRules estiver vazia, os preços são calculados localmente.';

  @override
  String get adminPricingRules => 'Regras de preços (Bs)';

  @override
  String get adminPushNotifications => 'Notificações push';

  @override
  String get adminPushNotificationsDesc => 'Ativa notificações em todo o sistema para novas reservas.';

  @override
  String get adminRecentActivity => 'Atividade recente';

  @override
  String get adminRegisteredDrivers => 'Motoristas cadastrados';

  @override
  String get adminRegisteredVehicles => 'Veículos cadastrados';

  @override
  String get adminReportsAvgRating => 'Avaliação média';

  @override
  String get adminReportsAvgTicket => 'Tíquete médio';

  @override
  String get adminReportsByAdmin => 'Operações';

  @override
  String get adminReportsByRider => 'Passageiro';

  @override
  String get adminReportsBySystem => 'Automático';

  @override
  String get adminReportsByUnknown => 'Sem registro';

  @override
  String get adminReportsCancellationRate => 'Taxa de cancelamento';

  @override
  String get adminReportsCancellations => 'Cancelamentos por origem';

  @override
  String adminReportsCancelledOf(int cancelled, int total) {
    return '$cancelled de $total reservas';
  }

  @override
  String get adminReportsColDate => 'Data';

  @override
  String get adminReportsColDriver => 'Motorista';

  @override
  String get adminReportsColRating => 'Avaliação';

  @override
  String get adminReportsColRevenue => 'Receita (Bs)';

  @override
  String get adminReportsColTrips => 'Viagens';

  @override
  String get adminReportsCopied => 'CSV copiado para a área de transferência';

  @override
  String get adminReportsDailyTable => 'Ver dados por dia';

  @override
  String adminReportsDays(int days) {
    return '$days dias';
  }

  @override
  String get adminReportsDownloaded => 'CSV baixado';

  @override
  String get adminReportsDrivers => 'Desempenho dos motoristas';

  @override
  String get adminReportsEmpty => 'Nenhuma reserva com embarque neste período.';

  @override
  String get adminReportsExportDaily => 'Exportar dias (CSV)';

  @override
  String get adminReportsExportDrivers => 'Exportar motoristas (CSV)';

  @override
  String get adminReportsLateCancellations => 'Cancelamentos tardios';

  @override
  String get adminReportsLateHint => 'Do passageiro, dentro da janela com cobrança';

  @override
  String get adminReportsNoCancellations => 'Nenhum cancelamento neste período.';

  @override
  String get adminReportsNoDrivers => 'Nenhum motorista concluiu viagens neste período.';

  @override
  String get adminReportsNoPrevious => 'Sem dados do período anterior';

  @override
  String adminReportsPeakHour(String hour) {
    return 'Horário de pico: $hour';
  }

  @override
  String get adminReportsPeakHours => 'Demanda por hora de embarque';

  @override
  String get adminReportsPeakHoursHint => 'Todas as reservas do período, incluindo as canceladas.';

  @override
  String get adminReportsPerTrip => 'Por viagem concluída';

  @override
  String adminReportsRange(String from, String to) {
    return 'Embarques de $from a $to (hora local)';
  }

  @override
  String adminReportsRatingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avaliações',
      one: '1 avaliação',
      zero: 'Sem avaliações',
    );
    return '$_temp0';
  }

  @override
  String get adminReportsRevenue => 'Receita';

  @override
  String get adminReportsRevenuePerDay => 'Receita por dia (Bs)';

  @override
  String get adminReportsServiceMix => 'Viagens por tipo de serviço';

  @override
  String get adminReportsTitle => 'Relatórios de operações';

  @override
  String adminReportsTooltipBookings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reservas',
      one: '1 reserva',
    );
    return '$_temp0';
  }

  @override
  String adminReportsTooltipTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viagens',
      one: '1 viagem',
    );
    return '$_temp0';
  }

  @override
  String get adminReportsTrips => 'Viagens concluídas';

  @override
  String get adminReportsTripsPerDay => 'Viagens concluídas por dia';

  @override
  String get adminReportsUnknownDriver => 'Motorista sem nome';

  @override
  String get adminReportsUnserved => 'Sem motorista designado';

  @override
  String get adminReportsUnservedHint => 'Canceladas automaticamente';

  @override
  String get adminReportsVehicleMix => 'Viagens por categoria';

  @override
  String adminReportsVsPrevious(String delta) {
    return '$delta vs. período anterior';
  }

  @override
  String get adminRevenueTrend => 'Tendência de receita em 7 dias (Bs)';

  @override
  String get adminSearchUsers => 'Buscar usuários…';

  @override
  String get adminSectionAudit => 'Auditoria';

  @override
  String get adminSectionBookings => 'Reservas';

  @override
  String get adminSectionCompanies => 'Empresas';

  @override
  String get adminSectionDashboard => 'Painel';

  @override
  String get adminSectionDrivers => 'Motoristas';

  @override
  String get adminSectionPricing => 'Preços';

  @override
  String get adminSectionReports => 'Relatórios';

  @override
  String get adminSectionSettings => 'Configurações';

  @override
  String get adminSectionUsers => 'Usuários';

  @override
  String get adminSectionVehicles => 'Veículos';

  @override
  String get adminSignOutConfirm => 'Tem certeza de que deseja sair do painel de administração?';

  @override
  String get adminSystemInfo => 'Informações do sistema';

  @override
  String get adminTitle => 'Administrador';

  @override
  String get adminTotalBookings => 'Total de reservas';

  @override
  String get adminTwoFactor => 'Autenticação de dois fatores para admins';

  @override
  String get adminTwoFactorDesc => 'Exige 2FA para todas as ações administrativas.';

  @override
  String adminVehicleDetails(String plate, String vehicleClass) {
    return 'Placa: $plate · Categoria: $vehicleClass';
  }

  @override
  String get adminVerifiedDrivers => 'Motoristas verificados';

  @override
  String get adminVerify => 'Verificar';

  @override
  String get appName => 'Luxelane';

  @override
  String get appNameDriver => 'Luxelane Motorista';

  @override
  String get authAlreadyHaveAccount => 'Já tem uma conta?';

  @override
  String get authBrandHeadline => 'Serviço de motorista\npremium.';

  @override
  String get authBrandTagline => 'Preço fixo. Motoristas verificados.';

  @override
  String get authConsentPrivacyLink => 'Política de Privacidade';

  @override
  String get authConsentRequired => 'Você precisa aceitar os termos e a política de privacidade';

  @override
  String get authConsentTermsLink => 'Termos e Condições';

  @override
  String authConsentText(String terms, String privacy) {
    return 'Aceito os $terms e a $privacy';
  }

  @override
  String get authCreateOne => 'Criar conta';

  @override
  String get authEmailInvalid => 'Digite um e-mail válido';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authErrorEmailInUse => 'Já existe uma conta com este e-mail';

  @override
  String get authErrorGeneric => 'Não foi possível concluir a solicitação. Tente novamente.';

  @override
  String get authErrorInvalidEmail => 'Esse e-mail não é válido';

  @override
  String get authErrorTooManyRequests => 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';

  @override
  String get authErrorUserDisabled => 'Esta conta foi desativada. Entre em contato conosco para mais informações.';

  @override
  String get authErrorUserNotFound => 'Não existe uma conta com este e-mail';

  @override
  String get authErrorWeakPassword => 'A senha é muito fraca. Use pelo menos 6 caracteres.';

  @override
  String get authErrorWrongCredentials => 'E-mail ou senha incorretos';

  @override
  String get authForgotPassword => 'Esqueceu sua senha?';

  @override
  String get authFullNameLabel => 'Nome completo';

  @override
  String get authLoginHeadline => 'Que bom\nte ver.';

  @override
  String get authLoginSubtitle => 'Entre na sua conta';

  @override
  String get authLoginTitle => 'Entrar';

  @override
  String get authLoginWelcomeBack => 'Que bom ter você de volta à Luxelane.';

  @override
  String get authNoAccount => 'Não tem uma conta?';

  @override
  String get authPasswordLabel => 'Senha';

  @override
  String authPasswordTooShort(int count) {
    return 'Mínimo de $count caracteres';
  }

  @override
  String get authPhoneLabel => 'Telefone';

  @override
  String get authRegisterHeadline => 'Crie sua conta.';

  @override
  String get authRegisterSubtitle => 'Junte-se à Luxelane hoje';

  @override
  String get authRegisterTitle => 'Criar conta';

  @override
  String get authResetEmailSent => 'E-mail de redefinição de senha enviado';

  @override
  String get authResetNeedsEmail => 'Digite seu e-mail para redefinir a senha';

  @override
  String get authSignInLink => 'Entrar';

  @override
  String get bookingAllFeesIncluded => 'Todas as taxas incluídas';

  @override
  String get bookingApplyOffer => 'Aplicar oferta';

  @override
  String get bookingAssuranceFixedPrice => 'Preço fixo, sem surpresas';

  @override
  String get bookingAssuranceVerified => 'Motoristas verificados';

  @override
  String get bookingAuthCreateAccountCta => 'Criar conta';

  @override
  String get bookingAuthEmail => 'E-mail';

  @override
  String get bookingAuthEmailHint => 'voce@exemplo.com';

  @override
  String get bookingAuthFullName => 'Nome completo';

  @override
  String get bookingAuthFullNameHint => 'Seu nome';

  @override
  String get bookingAuthHaveAccount => 'Já tem uma conta? Entre';

  @override
  String get bookingAuthHidePassword => 'Ocultar senha';

  @override
  String get bookingAuthNoAccount => 'Não tem uma conta? Crie uma';

  @override
  String get bookingAuthPassword => 'Senha';

  @override
  String get bookingAuthShowPassword => 'Mostrar senha';

  @override
  String get bookingAuthSignInCta => 'Entrar';

  @override
  String get bookingAuthSubtitleLogin => 'Entre para confirmar sua reserva.';

  @override
  String get bookingAuthSubtitleRegister => 'Crie sua conta Luxelane para concluir a reserva.';

  @override
  String get bookingAuthTitleLogin => 'Entre para continuar';

  @override
  String get bookingAuthTitleRegister => 'Criar uma conta';

  @override
  String get bookingBackHome => 'Voltar ao início';

  @override
  String get bookingBaseFare => 'Tarifa base';

  @override
  String get bookingBreakdownHeading => 'DETALHAMENTO';

  @override
  String get bookingCapacityLuggageInfo => 'Com base em tamanhos padrão de bagagem, que podem ser diferentes dos seus. Você pode detalhar sua bagagem nas \"Observações de embarque\" na próxima etapa.';

  @override
  String get bookingCapacityTitle => 'Capacidade';

  @override
  String get bookingCardFallback => 'Cartão';

  @override
  String bookingChauffeurAtDisposal(int hours) {
    return 'Motorista à disposição · $hours h';
  }

  @override
  String get bookingChooseExperience => 'Escolha sua experiência';

  @override
  String get bookingChooseService => 'Escolha o serviço';

  @override
  String get bookingConfirmCta => 'Confirmar reserva';

  @override
  String get bookingConfirmedEyebrow => 'RESERVA CONFIRMADA';

  @override
  String get bookingConfirmedHeadline => 'Seu motorista estará à sua espera.';

  @override
  String get bookingConfirmedSemantics => 'Reserva confirmada';

  @override
  String get bookingCountdownOnTheWay => 'Seu motorista está a caminho.';

  @override
  String bookingDateTime(String date, String time) {
    return '$date · $time';
  }

  @override
  String get bookingDescriptiveText => 'O premium, de forma prática. Assentos espaçosos, uma viagem suave e embarques pontuais que mantêm o seu dia no ritmo.';

  @override
  String get bookingDestinationLabel => 'Destino';

  @override
  String bookingDistanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get bookingErrorCreateFailed => 'Não foi possível concluir a reserva';

  @override
  String get bookingErrorInvalidFlight => 'Verifique o número do voo (ex.: LA 8810).';

  @override
  String get bookingErrorPaymentNotAuthorised => 'Não conseguimos autorizar seu cartão. Tente novamente ou escolha outro.';

  @override
  String get bookingErrorQuoteExpired => 'A cotação expirou. Confirme novamente para ver o preço atualizado.';

  @override
  String get bookingErrorQuoteFailed => 'Não foi possível calcular o preço da viagem';

  @override
  String get bookingErrorQuoteMissing => 'A viagem ainda não foi cotada';

  @override
  String get bookingErrorRateFailed => 'Não foi possível enviar sua avaliação';

  @override
  String get bookingErrorTooManyPassengers => 'O número de passageiros excede a capacidade do veículo.';

  @override
  String get bookingEstimatedTax => 'Imposto estimado';

  @override
  String get bookingEstimatedTotal => 'TOTAL ESTIMADO';

  @override
  String get bookingFixedPriceLabel => 'PREÇO FIXO';

  @override
  String get bookingFixedPricePaidByCard => 'Preço fixo · cartão autorizado';

  @override
  String get bookingFixedPricePayDriver => 'Preço fixo · pagamento ao motorista';

  @override
  String bookingFlight(String flight) {
    return 'Voo $flight';
  }

  @override
  String get bookingFlightNumber => 'Número do voo';

  @override
  String get bookingFlightNumberHint => 'ex.: LA 8810 (opcional)';

  @override
  String get bookingForGuest => 'Reservar para um convidado';

  @override
  String get bookingForGuestSubtitle => 'Selecionar ou adicionar um convidado';

  @override
  String get bookingForMyself => 'Reservar para mim';

  @override
  String get bookingForMyselfSubtitle => 'Reserve com os dados da sua conta';

  @override
  String get bookingFreeCancellationShort => 'Cancelamento grátis até 1 h antes';

  @override
  String get bookingGuestDialogBody => 'Informe os dados do seu convidado e ofereça a ele um serviço premium. Vamos mantê-lo informado sobre a viagem durante todo o trajeto. Fique tranquilo: não compartilharemos nenhuma informação de pagamento ou cobrança com ele.';

  @override
  String get bookingGuestDialogTitle => 'Adicionar novo convidado';

  @override
  String bookingGuestDisplayName(String title, String firstName, String lastName) {
    return '$title $firstName $lastName';
  }

  @override
  String get bookingGuestEmailHint => 'E-mail do convidado';

  @override
  String get bookingGuestFirstName => 'Nome';

  @override
  String get bookingGuestFirstNameHint => 'Nome do convidado';

  @override
  String get bookingGuestLastName => 'Sobrenome';

  @override
  String get bookingGuestLastNameHint => 'Sobrenome do convidado';

  @override
  String get bookingGuestPhone => 'Celular do convidado';

  @override
  String get bookingGuestPhoneHelp => 'Seu convidado receberá as notificações da viagem neste número';

  @override
  String get bookingGuestTitleDr => 'Dr.';

  @override
  String get bookingGuestTitleLabel => 'Tratamento';

  @override
  String get bookingGuestTitleMr => 'Sr.';

  @override
  String get bookingGuestTitleMrs => 'Sra.';

  @override
  String get bookingGuestTitleMs => 'Srta.';

  @override
  String get bookingGuestTitleProf => 'Prof.';

  @override
  String get bookingHeroTagline => 'Preço fixo · Sem surpresas · Motoristas verificados';

  @override
  String get bookingHeroTitle => 'Escolha sua\nexperiência';

  @override
  String bookingHoursShort(int hours) {
    return '$hours h';
  }

  @override
  String get bookingIncludedChargers => 'Carregadores para iOS e Android a bordo';

  @override
  String get bookingIncludedFreeCancellation => 'Cancelamento grátis até 1 hora antes do embarque';

  @override
  String get bookingIncludedMeetGreet => 'Recepção personalizada';

  @override
  String get bookingIncludedTissues => 'Lenços e lenços umedecidos higienizantes de cortesia';

  @override
  String get bookingIncludedTitle => 'O que está incluído';

  @override
  String bookingIncludedWaiting(int minutes) {
    return 'Até $minutes minutos de espera grátis';
  }

  @override
  String get bookingIncludedWater => 'Espera grátis incluída: 60 min no aeroporto, 15 na cidade';

  @override
  String get bookingLoadErrorTitle => 'Não conseguimos carregar sua reserva';

  @override
  String get bookingLuggage => 'Bagagem';

  @override
  String bookingLuggageCarryOn(int count) {
    return '$count × De mão';
  }

  @override
  String bookingLuggageChecked(int count) {
    return '$count × Despachada padrão';
  }

  @override
  String bookingLuggageExtraLarge(int count) {
    return '$count × Extragrande';
  }

  @override
  String get bookingNotFound => 'Esta reserva não está mais disponível.';

  @override
  String get bookingNoteCapacity => 'Os limites de passageiros e bagagem devem ser respeitados por motivos de segurança. Se forem excedidos, o motorista poderá recusar o serviço.';

  @override
  String get bookingNoteExtras => 'Necessidades adicionais (cadeira de rodas, assento infantil, itens extras) podem ser incluídas em \"Observações de embarque\". Escolha a Business Van para grupos maiores ou bagagem extra.';

  @override
  String get bookingNoteImages => 'As imagens do veículo são apenas ilustrativas. O veículo real pode variar, sempre com qualidade equivalente ou superior.';

  @override
  String get bookingPassengers => 'Passageiros';

  @override
  String bookingPassengersAndBags(String passengers, String bags) {
    return '$passengers · $bags';
  }

  @override
  String get bookingPayOnTripBody => 'Você paga o preço fixo ao seu motorista em dinheiro ou via QR. Nada é cobrado na reserva.';

  @override
  String get bookingPayOnTripTitle => 'Pagamento ao final da viagem';

  @override
  String get bookingPaymentFailed => 'Não foi possível concluir o pagamento';

  @override
  String get bookingPaymentMethodHeading => 'FORMA DE PAGAMENTO';

  @override
  String bookingPickupInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Embarque em $days dias',
      one: 'Embarque em 1 dia',
    );
    return '$_temp0';
  }

  @override
  String bookingPickupInHours(int hours) {
    return 'Embarque em $hours h';
  }

  @override
  String bookingPickupInHoursMinutes(int hours, int minutes) {
    return 'Embarque em $hours h $minutes min';
  }

  @override
  String bookingPickupInMinutes(int minutes) {
    return 'Embarque em $minutes min';
  }

  @override
  String get bookingPickupLabel => 'Embarque';

  @override
  String get bookingPleaseNote => 'Observação importante:';

  @override
  String get bookingPriceBreakdownTitle => 'Detalhamento do preço';

  @override
  String bookingPriceConfirmedBody(String price) {
    return 'O preço fixo da sua viagem é $price. Ele não muda, mesmo com trânsito.';
  }

  @override
  String get bookingPriceConfirmedTitle => 'Preço confirmado';

  @override
  String bookingReference(String code) {
    return 'Código da reserva: $code';
  }

  @override
  String bookingReserveCta(String vehicle) {
    return 'RESERVAR $vehicle';
  }

  @override
  String get bookingRoutePreview => 'Prévia da rota';

  @override
  String get bookingSeating => 'Assentos';

  @override
  String get bookingSeatingFive => 'Cinco passageiros';

  @override
  String get bookingSeatingInfantSeat => 'Assento de bebê';

  @override
  String get bookingSeatingInfo => 'Escolha a configuração de assentos que melhor atende às suas necessidades. Assentos especiais (infantil / bebê) devem ser solicitados com antecedência e estão sujeitos à disponibilidade.';

  @override
  String get bookingSeatingThree => 'Três passageiros';

  @override
  String get bookingSeatingTwo => 'Dois passageiros';

  @override
  String bookingSeatsUpTo(int count) {
    return 'Até $count pax';
  }

  @override
  String get bookingSelectRouteError => 'Selecione o local de embarque e o destino';

  @override
  String get bookingSelectedBadge => 'SELECIONADO';

  @override
  String get bookingSlideBusiness1 => 'Conforto executivo em cada trajeto';

  @override
  String get bookingSlideBusiness2 => 'Pontual, profissional e perfeitamente refinado';

  @override
  String get bookingSlideBusiness3 => 'Chegue com confiança, em todas as ocasiões';

  @override
  String get bookingSlideBusiness4 => 'O premium, de forma prática, para o executivo moderno';

  @override
  String get bookingSlideElectric1 => 'Totalmente elétrico, silencioso e de nível executivo';

  @override
  String get bookingSlideElectric2 => 'Zero emissões, máxima experiência de luxo';

  @override
  String get bookingSlideFirst1 => 'Um nível extraordinário de luxo espera por você';

  @override
  String get bookingSlideFirst2 => 'Pensado para quem exige o melhor';

  @override
  String get bookingSlideFirst3 => 'Privacidade e elegância em cada traslado';

  @override
  String get bookingSlideFirst4 => 'Primeira classe, de porta a porta';

  @override
  String get bookingSlideVan1 => 'Espaço e conforto para toda a sua equipe';

  @override
  String get bookingSlideVan2 => 'Traslados em grupo pontuais e sem estresse';

  @override
  String get bookingSlideVan3 => 'A viagem perfeita para famílias e grupos';

  @override
  String get bookingSlideVan4 => 'Capacidade premium, sem abrir mão do conforto';

  @override
  String get bookingSpecialRequests => 'Pedidos especiais';

  @override
  String get bookingSpecialRequestsHint => 'Assento infantil, placa de recepção…';

  @override
  String get bookingStepDetails => 'Detalhes';

  @override
  String bookingStepOf(int step, int total) {
    return 'ETAPA $step DE $total';
  }

  @override
  String get bookingStepVehicle => 'Veículo';

  @override
  String get bookingSummaryDistance => 'Distância';

  @override
  String get bookingSummaryDuration => 'Duração';

  @override
  String get bookingSummaryEstDuration => 'Duração est.';

  @override
  String get bookingSummaryFlight => 'Voo';

  @override
  String get bookingSummaryFrom => 'De';

  @override
  String get bookingSummaryHeading => 'RESUMO DA RESERVA';

  @override
  String get bookingSummaryNotes => 'Observações';

  @override
  String get bookingSummaryService => 'Serviço';

  @override
  String get bookingSummaryTo => 'Para';

  @override
  String get bookingTripDetailsHeading => 'DETALHES DA VIAGEM';

  @override
  String get bookingViewMyBooking => 'VER MINHA RESERVA';

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
  String get coreClearField => 'Limpar';

  @override
  String get coreConfirmBooking => 'Confirmar reserva';

  @override
  String get coreDriverLocationNotification => 'Compartilhando sua localização enquanto você está disponível';

  @override
  String get coreErrorBody => 'Já fomos notificados e estamos trabalhando em uma solução.';

  @override
  String get coreErrorTitle => 'Algo deu errado';

  @override
  String get coreFixedPrice => 'Preço fixo';

  @override
  String coreHoursTotal(int hours) {
    return '$hours h no total';
  }

  @override
  String get coreMapKeyMissing => 'Adicione a GOOGLE_MAPS_KEY para ativar o mapa';

  @override
  String get coreMapPickerHint => 'Mova o mapa para selecionar um local';

  @override
  String get coreMapPickerSelected => 'Local selecionado';

  @override
  String get coreMapPickerTitle => 'Selecionar local';

  @override
  String get coreMapView => 'Visualização do mapa';

  @override
  String get coreRoleAdmin => 'Admin';

  @override
  String get coreRoleDriver => 'Motorista';

  @override
  String get coreRoleRider => 'Passageiro';

  @override
  String coreVehicleCapacity(int count) {
    return 'Até $count';
  }

  @override
  String get corpAddCostCenter => 'Adicionar centro de custo';

  @override
  String get corpAddMember => 'Adicionar membro';

  @override
  String get corpAddMemberAction => 'Adicionar';

  @override
  String get corpAddMemberHint => 'Poderá faturar suas viagens para a empresa. Se ainda não tiver conta, entrará ao se cadastrar com este e-mail.';

  @override
  String get corpAdminEmail => 'E-mail do administrador';

  @override
  String get corpAdminEmailHint => 'Se ainda não tiver conta, entrará ao se cadastrar com este e-mail.';

  @override
  String get corpAdminEmpty => 'Ainda não há empresas.';

  @override
  String get corpAdminIntro => 'As empresas recebem uma fatura mensal pelas viagens dos seus membros. O administrador de cada empresa gerencia membros e centros de custo no seu portal.';

  @override
  String get corpAdminTitle => 'Contas corporativas';

  @override
  String get corpBillCompanyHint => 'Fatura mensal para a empresa';

  @override
  String corpBillCompanyNotice(String company) {
    return 'Esta viagem entra na fatura mensal de $company. Você não paga nada ao motorista.';
  }

  @override
  String get corpBillPersonal => 'Pessoal';

  @override
  String get corpBillPersonalHint => 'Você paga';

  @override
  String get corpBillTo => 'Faturar para';

  @override
  String corpBilledTo(String company) {
    return 'Faturado para $company';
  }

  @override
  String get corpBillingDetails => 'Dados de faturamento';

  @override
  String get corpBillingEmail => 'E-mail de faturamento';

  @override
  String get corpByCostCenter => 'Por centro de custo';

  @override
  String get corpByTraveler => 'Por pessoa';

  @override
  String get corpCancelInvite => 'Cancelar convite';

  @override
  String get corpColAmount => 'Valor (Bs)';

  @override
  String get corpColBookedBy => 'Reservado por';

  @override
  String get corpColDate => 'Data';

  @override
  String get corpColFrom => 'Origem';

  @override
  String get corpColPassenger => 'Passageiro';

  @override
  String get corpColTo => 'Destino';

  @override
  String get corpColVehicle => 'Veículo';

  @override
  String get corpCompanyCreated => 'Empresa criada';

  @override
  String get corpCompanyName => 'Razão social';

  @override
  String get corpCostCenter => 'Centro de custo';

  @override
  String get corpCostCenterNone => 'Nenhum';

  @override
  String get corpCostCenterOptional => 'Centro de custo (opcional)';

  @override
  String get corpCostCenterRequired => 'Centro de custo (obrigatório)';

  @override
  String get corpCostCenters => 'Centros de custo';

  @override
  String get corpCostCentersHint => 'Aparecem ao reservar para que cada viagem fique atribuída a uma área ou projeto.';

  @override
  String get corpCreate => 'Criar';

  @override
  String get corpCreateCompany => 'Nova empresa';

  @override
  String corpDriverNoCollect(String company) {
    return 'Conta corporativa ($company): não cobre do passageiro.';
  }

  @override
  String get corpEmail => 'E-mail';

  @override
  String get corpErrorCompanyInactive => 'A conta corporativa está suspensa.';

  @override
  String get corpErrorCostCenterRequired => 'Escolha um centro de custo para faturar para a empresa.';

  @override
  String get corpErrorCostCentersEmpty => 'Adicione pelo menos um centro de custo antes de exigi-lo.';

  @override
  String get corpErrorInvalidEmail => 'Verifique o e-mail.';

  @override
  String get corpErrorInvalidName => 'Digite a razão social.';

  @override
  String get corpErrorInvalidTaxId => 'O NIT deve ter apenas números (5 a 15).';

  @override
  String get corpErrorLastAdmin => 'A empresa precisa de pelo menos um administrador.';

  @override
  String get corpErrorNotARider => 'Essa conta é de motorista ou de administração; apenas passageiros podem ser membros.';

  @override
  String get corpErrorNotAllowed => 'Você não pode faturar esta viagem para a empresa. Escolha pagamento pessoal.';

  @override
  String get corpErrorOtherCompany => 'Essa pessoa já pertence a outra empresa.';

  @override
  String get corpExportCsv => 'Exportar detalhe (CSV)';

  @override
  String get corpFormerMember => 'Ex-membro';

  @override
  String get corpInviteCancelled => 'Convite cancelado';

  @override
  String corpKpiCancelled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cancelamentos no total',
      one: '1 cancelamento no total',
      zero: 'Sem cancelamentos',
    );
    return '$_temp0';
  }

  @override
  String get corpKpiCompleted => 'Viagens concluídas';

  @override
  String get corpKpiLateCancellations => 'Cancelamentos tardios';

  @override
  String get corpKpiToInvoice => 'A faturar';

  @override
  String get corpKpiToInvoiceHint => 'Viagens concluídas no mês';

  @override
  String get corpKpiUpcoming => 'Próximas ou em andamento';

  @override
  String get corpMakeAdmin => 'Tornar administrador';

  @override
  String get corpMakeMember => 'Remover permissões de administrador';

  @override
  String get corpMemberActions => 'Opções do membro';

  @override
  String get corpMemberAdded => 'Pronto. Se a pessoa já tinha conta, foi adicionada; se não, entrará ao se cadastrar.';

  @override
  String get corpMemberRemoved => 'Membro removido';

  @override
  String get corpMemberUpdated => 'Permissões atualizadas';

  @override
  String get corpMembers => 'Membros';

  @override
  String get corpNewCostCenter => 'Novo centro de custo';

  @override
  String get corpNextMonth => 'Próximo mês';

  @override
  String get corpNoAccess => 'Apenas os administradores da empresa podem ver este portal.';

  @override
  String get corpNoCostCenter => 'Sem centro de custo';

  @override
  String get corpNoMembers => 'Ainda não há membros.';

  @override
  String get corpNoRidesMonth => 'Nenhuma viagem faturada para a empresa neste mês.';

  @override
  String get corpOpenPortal => 'Abrir portal';

  @override
  String get corpPendingInvites => 'Convites pendentes';

  @override
  String get corpPendingInvitesHint => 'Entrarão ao criar a conta com estes e-mails.';

  @override
  String get corpPortalTitle => 'Conta corporativa';

  @override
  String get corpPrevMonth => 'Mês anterior';

  @override
  String get corpProfileAdminHint => 'Você administra esta conta: extrato, membros e ajustes';

  @override
  String get corpProfileMemberHint => 'Você pode faturar suas viagens para a empresa';

  @override
  String get corpProfileSection => 'Conta corporativa';

  @override
  String get corpReactivate => 'Reativar conta';

  @override
  String get corpReactivated => 'Conta reativada';

  @override
  String get corpReference => 'Referência';

  @override
  String get corpReferenceHint => 'Projeto, ordem de compra, cliente…';

  @override
  String get corpRemoveCostCenter => 'Remover';

  @override
  String get corpRemoveMember => 'Remover da empresa';

  @override
  String corpRemoveMemberBody(String name) {
    return '$name não poderá mais faturar viagens para a empresa. As viagens anteriores continuam no extrato.';
  }

  @override
  String get corpRequireCostCenter => 'Exigir centro de custo';

  @override
  String get corpRequireCostCenterHint => 'Não será possível reservar pela empresa sem escolher um.';

  @override
  String get corpRidesOfMonth => 'Viagens do mês';

  @override
  String get corpRoleAdmin => 'Administrador';

  @override
  String get corpRoleMember => 'Membro';

  @override
  String corpRoute(String from, String to) {
    return '$from → $to';
  }

  @override
  String get corpSave => 'Salvar alterações';

  @override
  String get corpSettingsSaved => 'Alterações salvas';

  @override
  String get corpSuspend => 'Suspender conta';

  @override
  String get corpSuspended => 'Conta suspensa';

  @override
  String get corpSuspendedBanner => 'A conta está suspensa: os membros não podem faturar viagens para a empresa. Fale conosco para reativá-la.';

  @override
  String get corpSuspendedShort => 'Conta suspensa';

  @override
  String get corpTabMembers => 'Membros';

  @override
  String get corpTabSettings => 'Ajustes';

  @override
  String get corpTabStatement => 'Extrato';

  @override
  String get corpTaxId => 'NIT';

  @override
  String corpTaxIdShort(String taxId) {
    return 'NIT $taxId';
  }

  @override
  String get driverAcceptRide => 'Aceitar viagem';

  @override
  String get driverActionArrived => 'Cheguei';

  @override
  String get driverActionCompleteTrip => 'Concluir viagem';

  @override
  String get driverActionGoToPickup => 'Ir ao local de embarque';

  @override
  String get driverActionGoToPickupShort => 'Ir ao embarque';

  @override
  String get driverActionStartTrip => 'Iniciar viagem';

  @override
  String get driverActiveRide => 'Viagem ativa';

  @override
  String driverCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viagens concluídas',
      one: '1 viagem concluída',
    );
    return '$_temp0';
  }

  @override
  String get driverCompletedTrips => 'Viagens concluídas';

  @override
  String get driverConnectionErrorTitle => 'Erro de conexão';

  @override
  String get driverDecline => 'Recusar';

  @override
  String get driverErrorUnauthorized => 'Esta conta não tem acesso de motorista.';

  @override
  String get driverEstimatedFare => 'Tarifa estimada';

  @override
  String get driverGoOnline => 'Ficar online';

  @override
  String get driverMapsOpenError => 'Não foi possível abrir os mapas';

  @override
  String get driverMsgHeadToPickup => 'Siga para o local de embarque';

  @override
  String get driverMsgInProgress => 'Viagem em andamento · siga para o destino';

  @override
  String get driverMsgOnTheWay => 'A caminho do embarque · chegando em breve';

  @override
  String get driverMsgWaitingPassenger => 'Aguardando o passageiro';

  @override
  String driverNavigateTo(String address) {
    return 'Navegar até $address';
  }

  @override
  String get driverNavigateToDestination => 'Navegar até o destino';

  @override
  String get driverNavigateToPickup => 'Navegar até o embarque';

  @override
  String get driverNoCompletedTrips => 'Ainda não há viagens concluídas';

  @override
  String get driverNoMapsApps => 'Nenhum aplicativo de mapas disponível';

  @override
  String get driverOfferExpiring => 'Oferta prestes a expirar';

  @override
  String get driverOfflineSubtitle => 'Ative a chave para ficar online';

  @override
  String get driverOfflineTitle => 'Você está offline';

  @override
  String get driverOnbBack => 'Voltar';

  @override
  String get driverOnbColor => 'Cor';

  @override
  String get driverOnbDefaultColor => 'Preto';

  @override
  String get driverOnbExpiryFormat => 'Use MM/AAAA';

  @override
  String get driverOnbInvalid => 'Inválido';

  @override
  String get driverOnbInvalidMonth => 'Mês inválido';

  @override
  String get driverOnbLicenseExpired => 'Carteira vencida';

  @override
  String get driverOnbLicenseExpiry => 'Data de validade (MM/AAAA)';

  @override
  String get driverOnbLicenseNumber => 'Número da CNH';

  @override
  String get driverOnbLicenseSubtitle => 'Seus documentos serão analisados antes que você possa aceitar viagens.';

  @override
  String get driverOnbLicenseTitle => 'Carteira de motorista';

  @override
  String get driverOnbLogout => 'Sair';

  @override
  String get driverOnbMake => 'Marca';

  @override
  String get driverOnbModel => 'Modelo';

  @override
  String get driverOnbPlate => 'Placa';

  @override
  String get driverOnbReviewNotice => 'Um administrador vai verificar seus documentos antes que você possa ficar online.';

  @override
  String get driverOnbSaveError => 'Não foi possível salvar seus dados. Tente novamente.';

  @override
  String get driverOnbVehicleClass => 'Categoria do veículo';

  @override
  String get driverOnbVehicleSubtitle => 'Cadastre o veículo que você vai dirigir.';

  @override
  String get driverOnbVehicleTitle => 'Seu veículo';

  @override
  String get driverOnbYear => 'Ano';

  @override
  String get driverOnlineSubtitle => 'Aguardando novas solicitações de viagem';

  @override
  String get driverOnlineTitle => 'Você está online';

  @override
  String get driverPaid => 'PAGO';

  @override
  String get driverQueueAvailable => 'SOLICITAÇÕES DISPONÍVEIS';

  @override
  String get driverQueueEmptyBody => 'As novas reservas aparecerão aqui';

  @override
  String get driverQueueEmptyTitle => 'Nenhum serviço ainda';

  @override
  String get driverQueueMyActive => 'MEUS SERVIÇOS ATIVOS';

  @override
  String get driverQueueOfflineBody => 'Ative sua disponibilidade na aba Início';

  @override
  String get driverQueueOfflineTitle => 'Fique online para receber serviços';

  @override
  String get driverQueueTitle => 'Fila de serviços';

  @override
  String get driverRequestExclusive => 'SOLICITAÇÃO EXCLUSIVA PARA VOCÊ';

  @override
  String get driverRequestNew => 'NOVA SOLICITAÇÃO DE VIAGEM';

  @override
  String driverRespondIn(int seconds) {
    return 'Responda em ${seconds}s';
  }

  @override
  String get driverStatCompleted => 'Concluídas';

  @override
  String get driverStatEarnings => 'Ganhos';

  @override
  String get driverTabHome => 'Início';

  @override
  String get driverTabJobs => 'Serviços';

  @override
  String get driverTabProfile => 'Perfil';

  @override
  String get driverTodaySummary => 'Resumo de hoje';

  @override
  String get driverTotalEarnings => 'Ganhos totais';

  @override
  String get driverTripNotFound => 'Viagem não encontrada';

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
  String get homeBarDateTime => 'Data e hora';

  @override
  String get homeBarDestination => 'Destino';

  @override
  String get homeBarDestinationHint => 'Para onde você vai?';

  @override
  String get homeBarDuration => 'Duração';

  @override
  String get homeBarPickup => 'Embarque';

  @override
  String get homeBarPickupHint => 'Onde você está?';

  @override
  String get homeBarSeeOptions => 'Ver opções';

  @override
  String get homeBookBulletAdvance => 'Reserve com antecedência';

  @override
  String get homeBookBulletDirectContact => 'Contato direto com seu motorista';

  @override
  String get homeBookBulletFixedPrice => 'Preço fixo, sempre';

  @override
  String get homeBookBulletFlightTracking => 'Monitoramento de voos';

  @override
  String get homeBookBulletFreeWait => 'Espera grátis incluída';

  @override
  String get homeBookBulletGuests => 'Reservas para convidados';

  @override
  String get homeBookBulletMeetGreet => 'Meet & greet com placa';

  @override
  String get homeBookBulletReceipts => 'Recibo de cada viagem';

  @override
  String get homeBookBulletTracking => 'Acompanhamento em tempo real';

  @override
  String get homeBookBusinessSub => 'Viagens corporativas redefinidas';

  @override
  String get homeBookCoverSubtitle => 'Serviço de motorista premium';

  @override
  String get homeBookExperienceBody => 'Do aeroporto ao seu destino: acompanhamos seu voo, seu motorista espera você com uma placa com seu nome e a espera está incluída — 60 min no aeroporto, 15 na cidade.';

  @override
  String get homeBookExperienceHeadline => 'Cada detalhe,\ncuidado.';

  @override
  String get homeBookExperienceLabel => 'A experiência';

  @override
  String get homeBookExperienceSub => 'Cada detalhe pensado';

  @override
  String get homeBookEyebrow => 'Nossa experiência exclusiva';

  @override
  String get homeBookRide => 'Reservar uma viagem';

  @override
  String get homeBookScrollCue => 'Role';

  @override
  String get homeBookStandardBody => 'Cada motorista é verificado pela nossa equipe: revisamos a habilitação, os documentos e o veículo antes da primeira viagem.';

  @override
  String get homeBookStandardHeadline => 'O padrão que\nos outros seguem.';

  @override
  String get homeBookStandardLabel => 'O padrão';

  @override
  String get homeBookStandardSub => 'A promessa que cumprimos';

  @override
  String get homeBookStandardTag => 'O padrão Luxelane';

  @override
  String get homeBusinessBody => 'Reserve para sua equipe e seus convidados com preço fixo em bolivianos, acompanhamento ao vivo e recibo de cada viagem.';

  @override
  String get homeBusinessEyebrow => 'Para empresas';

  @override
  String get homeBusinessLearnMore => 'Saiba mais';

  @override
  String get homeBusinessPerkFixedPrice => 'Preço fixo confirmado antes de reservar';

  @override
  String get homeBusinessPerkFlights => 'Monitoramento de voos com embarque ajustado';

  @override
  String get homeBusinessPerkGuests => 'Reservas para convidados e equipes';

  @override
  String get homeBusinessPerkMeetGreet => 'Meet & greet com placa no aeroporto';

  @override
  String get homeBusinessPerkMonitoring => 'Acompanhamento ao vivo de cada viagem';

  @override
  String get homeBusinessPerkReceipts => 'Recibo de cada viagem no app';

  @override
  String get homeBusinessTitle => 'Viagens corporativas,\nredefinidas.';

  @override
  String get homeCtaEyebrow => 'Quando quiser. Onde quiser.';

  @override
  String get homeCtaHighlights => 'Preço fixo  ·  Motoristas verificados  ·  Reserva antecipada';

  @override
  String get homeCtaTitle => 'Sua próxima viagem,\n<i>do seu jeito.</i>';

  @override
  String get homeCtaViewFleet => 'Ver a frota';

  @override
  String homeDateTimeShort(String date, String time) {
    return '$date, $time';
  }

  @override
  String get homeErrorDestinationRequired => 'Informe um destino';

  @override
  String get homeErrorPickupRequired => 'Informe um local de embarque';

  @override
  String get homeFleetEyebrow => 'Nossa frota';

  @override
  String get homeFleetModelVan => 'Mercedes Classe V ou similar';

  @override
  String get homeFleetSwipeHint => 'Deslize para explorar →';

  @override
  String get homeFleetTagExtraLuggage => 'Espaço extra para bagagem';

  @override
  String get homeFleetTagFixedPrice => 'Preço fixo';

  @override
  String get homeFleetTagGroups => 'Ideal para grupos';

  @override
  String get homeFleetTagTracking => 'Acompanhamento ao vivo';

  @override
  String get homeFleetTagVerified => 'Motorista verificado';

  @override
  String get homeFleetTitle => 'Veículos premium,\nsem exceções.';

  @override
  String get homeFooterContact => 'Contato';

  @override
  String homeFooterCopyright(String year) {
    return '© $year Luxelane. Todos os direitos reservados.';
  }

  @override
  String get homeFooterPrivacy => 'Privacidade';

  @override
  String get homeFooterTerms => 'Termos';

  @override
  String get homeFormPickupHint => 'Rua, bairro, aeroporto…';

  @override
  String get homeFormPickupLabel => 'Local de embarque';

  @override
  String get homeHeroTitle => 'Seu motorista <i>aguarda você.</i>';

  @override
  String homeHoursShort(int hours) {
    return '$hours h';
  }

  @override
  String get homeHowItWorksEyebrow => 'Como funciona';

  @override
  String get homeLocateMe => 'Usar minha localização';

  @override
  String get homeMapChangeLocation => 'Alterar local';

  @override
  String get homeMarqueeAirportTransfers => 'Traslados aeroportuários';

  @override
  String get homeMarqueeBookInMinutes => 'Reserve em minutos';

  @override
  String get homeMarqueeCorporateTravel => 'Viagens corporativas';

  @override
  String get homeMarqueeFixedPrices => 'Preços fixos em Bs';

  @override
  String get homeMarqueeFreeWait => 'Espera grátis';

  @override
  String get homeMarqueeHourly => 'Motorista por hora';

  @override
  String get homeMarqueePremiumFleet => 'Frota premium';

  @override
  String get homeNavBusiness => 'Para empresas';

  @override
  String get homeNavFleet => 'Frota';

  @override
  String get homeNavServices => 'Serviços';

  @override
  String get homePickDestinationTitle => 'Escolher destino';

  @override
  String get homePickPickupTitle => 'Escolher local de embarque';

  @override
  String get homePromiseCancelBody => 'Cancele sem custo até 1 hora antes do embarque, direto pelo app.';

  @override
  String get homePromiseCancelTitle => 'Cancelamento grátis';

  @override
  String homePromiseFixedPriceBody(int airportMinutes, int cityMinutes) {
    return 'Você vê o preço final antes de reservar, sem acréscimos por trânsito. Inclui $airportMinutes min de espera no aeroporto e $cityMinutes na cidade.';
  }

  @override
  String get homePromiseFixedPriceTitle => 'Preço fixo em Bs';

  @override
  String get homePromiseTrackingBody => 'Acompanhe seu motorista no mapa e receba avisos quando ele estiver a caminho e quando chegar.';

  @override
  String get homePromiseTrackingTitle => 'Acompanhamento ao vivo';

  @override
  String get homePromiseVerifiedBody => 'Habilitação e documentos revisados pela nossa equipe antes da primeira viagem.';

  @override
  String get homePromiseVerifiedTitle => 'Motoristas verificados';

  @override
  String homeRouteSummary(String distance, String duration) {
    return '$distance km · $duration';
  }

  @override
  String get homeSearchVehicles => 'Buscar veículos';

  @override
  String get homeServiceAirportTransfer => 'Traslado ao aeroporto';

  @override
  String get homeServiceHourly => 'Motorista por hora';

  @override
  String get homeServiceImmediatePickup => 'Embarque imediato';

  @override
  String get homeShellMyTrips => 'Minhas viagens';

  @override
  String get homeShellSignIn => 'Entrar';

  @override
  String get homeShellSignOut => 'Sair';

  @override
  String get homeShellTabHome => 'Início';

  @override
  String get homeShellTabProfile => 'Perfil';

  @override
  String get homeShellTabTrips => 'Viagens';

  @override
  String get homeStepBookBody => 'Escolha origem, destino, data e categoria do veículo.';

  @override
  String get homeStepBookTitle => 'Reserve em um minuto';

  @override
  String get homeStepChauffeurBody => 'Receba os dados do seu motorista e acompanhe-o em tempo real.';

  @override
  String get homeStepChauffeurTitle => 'Seu motorista aguarda você';

  @override
  String get homeStepPriceBody => 'Mostramos o preço final em bolivianos. É exatamente o que você paga.';

  @override
  String get homeStepPriceTitle => 'Confirme seu preço fixo';

  @override
  String get homeTrustEyebrow => 'A promessa Luxelane';

  @override
  String get homeTrustTitle => 'Viaje com tranquilidade,\ndo início ao fim.';

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
  String notifBellUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificações não lidas',
      one: '1 notificação não lida',
    );
    return '$_temp0';
  }

  @override
  String get notifEmpty => 'Ainda não há notificações';

  @override
  String notifHoursAgo(int hours) {
    return 'Há $hours h';
  }

  @override
  String get notifJustNow => 'Agora';

  @override
  String get notifMarkAllRead => 'Marcar tudo como lido';

  @override
  String notifMinutesAgo(int minutes) {
    return 'Há $minutes min';
  }

  @override
  String get notifTitle => 'Notificações';

  @override
  String get paymentsAccountNotSetUp => 'Sua conta ainda não está configurada para pagamentos';

  @override
  String get paymentsAdd => 'Adicionar';

  @override
  String get paymentsAddCard => 'Adicionar cartão';

  @override
  String get paymentsAddMethodTitle => 'Adicionar forma de pagamento';

  @override
  String get paymentsAddNewCard => 'Adicionar novo cartão';

  @override
  String get paymentsCardAdded => 'Cartão adicionado com sucesso';

  @override
  String get paymentsCardDetails => 'Dados do cartão';

  @override
  String paymentsCardExpires(String month, String year) {
    return 'Validade $month/$year';
  }

  @override
  String get paymentsCardFallback => 'Cartão';

  @override
  String get paymentsCardIncomplete => 'Preencha todos os dados do cartão';

  @override
  String get paymentsDefault => 'Padrão';

  @override
  String get paymentsEmptyBody => 'Adicione um cartão para reservar viagens';

  @override
  String get paymentsEmptyTitle => 'Nenhuma forma de pagamento';

  @override
  String get paymentsError => 'Não foi possível concluir a operação com o cartão. Tente novamente.';

  @override
  String get paymentsMethodsTitle => 'Formas de pagamento';

  @override
  String get paymentsRemoveCard => 'Remover cartão';

  @override
  String get paymentsSavedCards => 'Cartões salvos';

  @override
  String get paymentsSecured => 'Protegido pela Stripe';

  @override
  String get paymentsSecuredPci => 'Protegido pela Stripe · Em conformidade com o PCI DSS';

  @override
  String get paymentsSetDefault => 'Tornar padrão';

  @override
  String get profileContactHelp => 'Contato e ajuda';

  @override
  String get profileDeleteAccount => 'Excluir conta';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileLoadError => 'Não foi possível carregar seu perfil';

  @override
  String get profileNameLabel => 'Nome';

  @override
  String get profileSaveChanges => 'Salvar alterações';

  @override
  String get profileSectionAccount => 'Conta';

  @override
  String get profileSectionHelp => 'Ajuda e informações legais';

  @override
  String get profileSectionStats => 'Estatísticas';

  @override
  String get profileSignOut => 'Sair';

  @override
  String get profileStatRating => 'Avaliação';

  @override
  String get profileStatTrips => 'Viagens';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileUpdated => 'Perfil atualizado';

  @override
  String profileVersion(String version) {
    return 'Luxelane v$version';
  }

  @override
  String get rideArrived => 'Você chegou!';

  @override
  String rideArrivesIn(String eta) {
    return 'Chega em $eta';
  }

  @override
  String get rideAssigning => 'Designando seu motorista';

  @override
  String get rideAssigningBody => 'Estamos confirmando seu motorista. Avisaremos assim que ele for designado.';

  @override
  String get rideBackHome => 'Voltar ao início';

  @override
  String get rideCancelBooking => 'Cancelar reserva';

  @override
  String get rideCancelChauffeurNotified => 'Avisaremos o seu motorista.';

  @override
  String get rideCancelConfirm => 'Sim, cancelar';

  @override
  String get rideCancelDone => 'Sua reserva foi cancelada.';

  @override
  String get rideCancelFailed => 'Não foi possível cancelar a reserva. Tente novamente.';

  @override
  String get rideCancelFree => 'O cancelamento é grátis: falta mais de 1 hora para o embarque.';

  @override
  String get rideCancelKeep => 'Manter reserva';

  @override
  String get rideCancelLate => 'Falta menos de 1 hora para o embarque. Consulte nossos termos sobre cancelamentos tardios.';

  @override
  String get rideCancelNotAllowed => 'Esta reserva não pode mais ser cancelada pelo app.';

  @override
  String get rideCancelTitle => 'Cancelar esta reserva?';

  @override
  String get rideCancelled => 'Reserva cancelada';

  @override
  String rideChauffeurArrivesIn(String eta) {
    return 'Seu motorista chega em $eta';
  }

  @override
  String get rideChauffeurConfirmed => 'Motorista confirmado';

  @override
  String get rideChauffeurOnTheWay => 'Seu motorista está a caminho';

  @override
  String get rideChauffeurWaiting => 'Seu motorista está esperando';

  @override
  String rideFlightArrivesAt(String time) {
    return 'Chega $time';
  }

  @override
  String rideFlightLandedAt(String time) {
    return 'Pousou $time';
  }

  @override
  String rideFlightTitle(String number) {
    return 'Voo $number';
  }

  @override
  String rideFlightTitleTerminal(String number, String terminal) {
    return 'Voo $number · Terminal $terminal';
  }

  @override
  String get rideHeadingToDestination => 'A caminho do seu destino';

  @override
  String get rideLive => 'AO VIVO';

  @override
  String get rideLoading => 'Carregando sua reserva…';

  @override
  String get rideNotifArrivedBody => 'Seu motorista está esperando você no local de embarque.';

  @override
  String get rideNotifArrivedTitle => 'O motorista chegou';

  @override
  String get rideNotifArrivingBody => 'Seu motorista está indo até o local de embarque.';

  @override
  String get rideNotifArrivingTitle => 'O motorista está a caminho';

  @override
  String get rideNotifAssignedBody => 'Seu motorista confirmou a reserva.';

  @override
  String get rideNotifAssignedTitle => 'Motorista designado';

  @override
  String get rideNotifCompletedBody => 'Você chegou! Obrigado por viajar com a Luxelane.';

  @override
  String get rideNotifCompletedTitle => 'Viagem concluída';

  @override
  String get rideNotifStartedBody => 'Você já está a caminho do seu destino.';

  @override
  String get rideNotifStartedTitle => 'Viagem iniciada';

  @override
  String ridePickupAt(String time) {
    return 'Embarque $time';
  }

  @override
  String get rideRateTrip => 'Avaliar viagem';

  @override
  String get rideRatingCommentHint => 'Comentário (opcional)';

  @override
  String get rideRatingExcellent => 'Excelente';

  @override
  String get rideRatingFair => 'Regular';

  @override
  String get rideRatingGood => 'Bom';

  @override
  String get rideRatingPoor => 'Ruim';

  @override
  String rideRatingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrelas',
      one: '1 estrela',
    );
    return '$_temp0';
  }

  @override
  String get rideRatingThanks => 'Obrigado pela sua avaliação!';

  @override
  String get rideRatingTitle => 'Avalie sua viagem';

  @override
  String get rideRatingVeryPoor => 'Muito ruim';

  @override
  String get rideThanks => 'Obrigado por viajar com a Luxelane';

  @override
  String get rideThanksForRating => 'Obrigado pela avaliação';

  @override
  String get rideVerifiedChauffeur => 'Motorista verificado';

  @override
  String rideVerifiedTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verificado · $count viagens',
      one: 'Verificado · 1 viagem',
    );
    return '$_temp0';
  }

  @override
  String get rideViewReceipt => 'Ver recibo';

  @override
  String rideYouArriveIn(String eta) {
    return 'Você chega em $eta';
  }

  @override
  String get rideYourChauffeur => 'Seu motorista';

  @override
  String get routerGoHome => 'Ir para o início';

  @override
  String get routerNotFoundBody => 'A página que você procura não existe ou foi movida.';

  @override
  String get routerNotFoundTitle => 'Página não encontrada';

  @override
  String get serviceByTheHour => 'Por hora';

  @override
  String get serviceByTheHourDesc => 'Motorista à sua disposição por um tempo determinado';

  @override
  String get serviceOneWay => 'Só ida';

  @override
  String get serviceOneWayDesc => 'Traslado com preço fixo até o seu destino';

  @override
  String get servicesAirportArriveBody => 'Cada serviço de motorista Luxelane busca os mais altos padrões para todos os passageiros. Nossos motoristas profissionais podem acompanhar o seu voo e ajustar o horário do embarque se houver atrasos fora do seu controle.';

  @override
  String get servicesAirportArriveTitle => 'Chegadas e partidas, sem preocupação';

  @override
  String get servicesAirportClassesTitle => 'Conheça nossas categorias de serviço';

  @override
  String get servicesAirportConnectionsBody => 'Reservar com a Luxelane é simples. Basta informar o local de embarque e o destino e escolher a categoria do veículo. O preço que você vê é o preço que você paga, sem taxas ocultas.';

  @override
  String get servicesAirportConnectionsTitle => 'Conexões entre aeroportos';

  @override
  String get servicesAirportFaq1A => 'Um traslado para o aeroporto é um serviço de carro particular que leva passageiros de avião de e para o aeroporto. Motoristas profissionais podem receber os passageiros no terminal depois que eles retirarem a bagagem.';

  @override
  String get servicesAirportFaq1Q => 'O que é um traslado para o aeroporto?';

  @override
  String get servicesAirportFaq2A => 'Um traslado é uma ótima forma de evitar o estresse no início e no fim de qualquer voo. A Luxelane oferece uma ampla gama de opções de traslado que se adaptam às suas necessidades.';

  @override
  String get servicesAirportFaq2Q => 'Vale a pena reservar um traslado do aeroporto?';

  @override
  String get servicesAirportFaq3A => 'Um traslado pago ao aeroporto é um serviço de transporte com motorista profissional reservado com antecedência, com preço fixo em bolivianos confirmado antes da reserva.';

  @override
  String get servicesAirportFaq3Q => 'O que é um traslado pago para o aeroporto?';

  @override
  String get servicesAirportFeatureFlexBody => 'Fique tranquilo: cancele sem custo até 1 hora antes do embarque, direto no app.';

  @override
  String get servicesAirportFeatureFlexTitle => 'Flexibilidade na viagem';

  @override
  String get servicesAirportFeatureFlightBody => 'Relaxe com uma hora de espera gratuita e o acompanhamento do seu voo.';

  @override
  String get servicesAirportFeatureFlightTitle => 'Ida ao aeroporto sem complicações';

  @override
  String get servicesAirportFeaturePriceBody => 'Serviço de primeira linha, com preço justo calculado pela distância.';

  @override
  String servicesAirportFreeWait(int minutes) {
    return 'Seu motorista aguarda até $minutes minutos sem custo adicional.';
  }

  @override
  String get servicesAirportHeroEyebrow => 'SERVIÇO DE TRASLADOS';

  @override
  String get servicesAirportHeroTitle => 'Ao aeroporto sem\nestresse nem espera';

  @override
  String get servicesAirportPanelSubtitle => 'Só ida ou por hora · Sem espera';

  @override
  String get servicesAirportPanelTitle => 'Traslados para o aeroporto';

  @override
  String get servicesBackHome => '← Voltar ao início';

  @override
  String get servicesBookNow => 'RESERVAR AGORA';

  @override
  String get servicesBookRide => 'RESERVAR VIAGEM';

  @override
  String get servicesFaqTitle => 'Perguntas frequentes';

  @override
  String get servicesFeaturePriceTitle => 'Preços competitivos';

  @override
  String servicesFooterRights(String year) {
    return '© $year Luxelane · Todos os direitos reservados';
  }

  @override
  String get servicesFromHint => 'De – endereço, aeroporto, hotel…';

  @override
  String get servicesHourlyBullet1 => 'Seu roteiro: você decide aonde ir e quando';

  @override
  String get servicesHourlyBullet2 => 'Economize tempo: embarque e desembarque na porta de cada parada';

  @override
  String get servicesHourlyBullet3 => 'Tranquilidade total: viaje em um veículo premium';

  @override
  String get servicesHourlyBullet4 => 'Tarifa fixa por hora: você sabe o preço antes de reservar';

  @override
  String get servicesHourlyBullet5 => 'Confiabilidade: motoristas treinados nos mais altos padrões';

  @override
  String get servicesHourlyBullet6 => 'Motoristas verificados pela nossa equipe';

  @override
  String get servicesHourlyBullet7 => 'Acompanhe seu motorista ao vivo pelo app';

  @override
  String get servicesHourlyBullet8 => 'Feito para a cidade: começa e termina na mesma cidade';

  @override
  String servicesHourlyDurationField(String duration) {
    return 'Duração – $duration';
  }

  @override
  String get servicesHourlyFaq1A => 'Selecione o local de embarque, escolha a duração, o dia e o horário, escolha a categoria do veículo e conclua sua reserva.';

  @override
  String get servicesHourlyFaq1Q => 'Como reservo um motorista por hora?';

  @override
  String get servicesHourlyFaq2A => 'Sim. O motorista e o veículo ficam à sua disposição durante todo o período da reserva.';

  @override
  String get servicesHourlyFaq2Q => 'Posso alterar meu roteiro durante a viagem?';

  @override
  String get servicesHourlyFaq3A => 'Assim que seu motorista for designado, você receberá uma notificação e verá no app o nome, o veículo, a placa e o telefone dele.';

  @override
  String get servicesHourlyFaq3Q => 'Quando vou receber os dados do motorista?';

  @override
  String get servicesHourlyFaq4A => 'Sim, a reserva pode começar ou terminar em um aeroporto. Os locais de início e término devem estar na mesma cidade.';

  @override
  String get servicesHourlyFaq4Q => 'A reserva pode começar em um aeroporto?';

  @override
  String servicesHourlyFaq5A(int min, int max) {
    return 'Sim, você pode editar a reserva antes do horário de início. A duração mínima é de $min horas e a máxima, de $max horas.';
  }

  @override
  String get servicesHourlyFaq5Q => 'Posso aumentar o número de horas?';

  @override
  String get servicesHourlyHeroEyebrow => 'CONTRATAÇÃO POR HORA';

  @override
  String get servicesHourlyHeroTitle => 'Motorista particular\npor hora ou por dia';

  @override
  String get servicesHourlyPanelSubtitle => 'Seu roteiro · Seu ritmo';

  @override
  String get servicesHourlyPanelTitle => 'Motorista por hora';

  @override
  String get servicesHourlyReachBanner => 'Disponível em Santa Cruz de la Sierra · Reserve pelo app ou pela web';

  @override
  String get servicesHourlyServiceBody => 'Chega de trocar de transporte em um dia cheio de paradas. Com a Luxelane, você define o roteiro: você decide aonde ir e quando.';

  @override
  String get servicesHourlyServiceTitle => 'Serviço de motorista por hora';

  @override
  String get servicesHourlyUseBusinessBody => 'Concentre-se no que importa. Desloque-se entre reuniões com facilidade, sem se preocupar com a logística.';

  @override
  String get servicesHourlyUseBusinessTitle => 'Viagens de negócios';

  @override
  String get servicesHourlyUseCasesTitle => 'Pensado para cada ocasião';

  @override
  String get servicesHourlyUseEventsBody => 'Garanta uma chegada triunfal e uma saída tranquila de qualquer evento.';

  @override
  String get servicesHourlyUseEventsTitle => 'Shows e eventos';

  @override
  String get servicesHourlyUseLeisureBody => 'Almoço, compras ou uma lista de afazeres: seu motorista estará pronto quando você precisar.';

  @override
  String get servicesHourlyUseLeisureTitle => 'Lazer';

  @override
  String get servicesHourlyUseSightseeingBody => 'Descubra a cidade do seu jeito, no seu ritmo, com um motorista local sempre à disposição.';

  @override
  String get servicesHourlyUseSightseeingTitle => 'Passeios turísticos';

  @override
  String get servicesNavBusiness => 'PARA EMPRESAS';

  @override
  String get servicesNavFleet => 'FROTA';

  @override
  String get servicesNavHome => 'INÍCIO';

  @override
  String get servicesNavServices => 'SERVIÇOS';

  @override
  String get servicesPickupChauffeursBody => 'Viaje com confiança, acompanhado por motoristas experientes que oferecem a melhor qualidade e total discrição.';

  @override
  String get servicesPickupChauffeursTitle => 'Motoristas profissionais';

  @override
  String get servicesPickupComfortBody => 'Uma viagem particular em um veículo de alto padrão transforma cada trajeto em um prazer.';

  @override
  String get servicesPickupComfortTitle => 'Conforto';

  @override
  String get servicesPickupConvenienceBody => 'Uma viagem com motorista de porta a porta no momento em que você precisar, com poucos toques.';

  @override
  String get servicesPickupConvenienceTitle => 'Praticidade';

  @override
  String get servicesPickupHeroSubtitle => 'Motoristas profissionais ao seu alcance';

  @override
  String get servicesPickupHeroTitle => 'Motorista\nna hora!';

  @override
  String get servicesPickupIntroBody => 'Tenha uma viagem com motorista de porta a porta no momento em que precisar, com apenas alguns toques no app Luxelane.';

  @override
  String get servicesPickupIntroEyebrow => 'MOTORISTA NA HORA';

  @override
  String get servicesPickupIntroTitle => 'Conheça o serviço Motorista na hora';

  @override
  String get servicesPickupPriceBody => 'Serviço de primeira linha com preços baseados na distância, justos para todos.';

  @override
  String get servicesPickupQualityBody => 'Tornar sua experiência excelente é nossa maior prioridade em todas as viagens.';

  @override
  String get servicesPickupQualityTitle => 'Qualidade';

  @override
  String get servicesPickupReliabilityBody => 'Reserve com segurança e fique por dentro de tudo com atualizações da viagem em tempo real.';

  @override
  String get servicesPickupReliabilityTitle => 'Confiabilidade';

  @override
  String get servicesPickupSplitBody => 'Sempre que precisar de uma forma segura de se deslocar pela cidade, conte com o Motorista na hora da Luxelane: a combinação perfeita entre o serviço tradicional de traslados e o transporte particular.';

  @override
  String get servicesPickupSplitEyebrow => 'CONFORTÁVEL · SEGURO · IMEDIATO';

  @override
  String get servicesPickupSplitTitle => 'Viagens confortáveis sob demanda, em minutos';

  @override
  String servicesQuote(String quote) {
    return '“$quote”';
  }

  @override
  String get servicesSelect => 'SELECIONAR';

  @override
  String get servicesToHint => 'Para – endereço, aeroporto, hotel…';

  @override
  String get servicesToggleOneWay => 'Só ida';

  @override
  String servicesUpToLargeBags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Até $count malas grandes',
      one: 'Até 1 mala grande',
    );
    return '$_temp0';
  }

  @override
  String servicesUpToPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Até $count passageiros',
      one: 'Até 1 passageiro',
    );
    return '$_temp0';
  }

  @override
  String get servicesVehicleBusinessModels => 'Mercedes Classe E, BMW Série 5 ou similar';

  @override
  String get servicesVehicleFirstModels => 'Mercedes Classe S, BMW Série 7 ou similar';

  @override
  String get servicesVehicleGroups => 'Ideal para grupos e famílias';

  @override
  String get servicesVehicleMostCities => 'Disponível em Santa Cruz de la Sierra';

  @override
  String get servicesVehiclePremiumLuxury => 'Nossa experiência mais sofisticada';

  @override
  String get servicesVehicleVanModels => 'Mercedes Classe V, Toyota Alphard ou similar';

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
  String get tripDestination => 'Destino';

  @override
  String tripFlightNumber(String number) {
    return 'Voo $number';
  }

  @override
  String tripFreeWaitLeft(int minutes) {
    return 'Espera grátis: $minutes min';
  }

  @override
  String tripFreeWaitOver(String time) {
    return 'Espera grátis encerrada às $time';
  }

  @override
  String get tripFreeWaitOverDriver => 'Entre em contato com o passageiro antes de sair.';

  @override
  String get tripFreeWaitOverRider => 'Seu motorista continua esperando por você. Avise-o se precisar de mais tempo.';

  @override
  String tripFreeWaitUntil(String time, String summary) {
    return 'Até às $time · $summary';
  }

  @override
  String get tripMeetGreetBody => 'Seu motorista vai esperar você na saída do desembarque com uma placa com o seu nome.';

  @override
  String tripMeetGreetBodyNamed(String name) {
    return 'Seu motorista vai esperar você na saída do desembarque com uma placa com o nome “$name”.';
  }

  @override
  String get tripMeetGreetTitle => 'Recepção no desembarque';

  @override
  String tripMeetGreetWait(int minutes) {
    return '$minutes min de espera grátis a partir do pouso do seu voo.';
  }

  @override
  String tripNameSignSemantics(String name) {
    return 'Placa com o nome $name. Toque para fechar.';
  }

  @override
  String get tripNameSignTapToClose => 'Toque na tela para fechar';

  @override
  String get tripPassenger => 'Passageiro';

  @override
  String get tripPickup => 'Embarque';

  @override
  String get tripPriceBaseFare => 'Tarifa base';

  @override
  String get tripPriceBreakdown => 'Detalhamento do preço';

  @override
  String tripPriceDistanceLine(String km, String rate) {
    return '$km km × $rate';
  }

  @override
  String get tripPriceEstimatedTotal => 'Total estimado';

  @override
  String get tripPriceFinalNote => 'O preço fixo final é confirmado antes da reserva.';

  @override
  String tripPriceHoursLine(int hours, String rate) {
    return '$hours h × $rate';
  }

  @override
  String get tripPriceMinimumAdjustment => 'Ajuste para tarifa mínima';

  @override
  String get tripReceiptAdjustment => 'Ajuste';

  @override
  String get tripReceiptCancelled => 'RESERVA CANCELADA';

  @override
  String get tripReceiptCard => 'Cartão';

  @override
  String get tripReceiptCompleted => 'VIAGEM CONCLUÍDA';

  @override
  String get tripReceiptCopied => 'Recibo copiado para a área de transferência';

  @override
  String get tripReceiptCopy => 'Copiar recibo';

  @override
  String get tripReceiptCurrencyNote => 'Valores em bolivianos (BOB).';

  @override
  String get tripReceiptDuration => 'Duração';

  @override
  String get tripReceiptFixedPrice => 'Preço fixo';

  @override
  String get tripReceiptFlight => 'Voo';

  @override
  String get tripReceiptNoCharge => 'Sem cobrança';

  @override
  String tripReceiptNumber(String code) {
    return 'Nº $code';
  }

  @override
  String get tripReceiptPassengers => 'Passageiros';

  @override
  String get tripReceiptPayChauffeur => 'Pagamento ao motorista';

  @override
  String get tripReceiptPaymentMethod => 'Forma de pagamento';

  @override
  String tripReceiptPlainFrom(String place) {
    return 'De: $place';
  }

  @override
  String tripReceiptPlainHeader(String code) {
    return 'Luxelane — Recibo $code';
  }

  @override
  String tripReceiptPlainTo(String place) {
    return 'Para: $place';
  }

  @override
  String tripReceiptPlainTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get tripReceiptService => 'Serviço';

  @override
  String get tripReceiptTitle => 'Recibo';

  @override
  String get tripReceiptTotal => 'Total';

  @override
  String get tripReceiptVehicle => 'Veículo';

  @override
  String get tripShowSign => 'Mostrar placa';

  @override
  String get tripsBookNow => 'Reservar agora';

  @override
  String get tripsEmpty => 'Você ainda não tem viagens.\nReserve sua primeira experiência.';

  @override
  String get tripsLoadError => 'Não foi possível carregar suas viagens. Verifique sua conexão.';

  @override
  String get tripsPast => 'ANTERIORES';

  @override
  String tripsRouteByHour(String origin, int hours) {
    return '$origin · $hours h';
  }

  @override
  String get tripsTitle => 'Minhas viagens';

  @override
  String get tripsUpcoming => 'PRÓXIMAS';

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
