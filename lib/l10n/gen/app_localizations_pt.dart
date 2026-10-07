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
