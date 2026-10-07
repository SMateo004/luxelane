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
  String get servicesAirportFaq3A => 'Um traslado pago é um serviço de transporte com motorista profissional reservado com antecedência. O preço inclui gorjetas, pedágios e quaisquer outros custos adicionais.';

  @override
  String get servicesAirportFaq3Q => 'O que é um traslado pago para o aeroporto?';

  @override
  String get servicesAirportFeatureFlexBody => 'Planos mudam. Cancelar ou alterar qualquer viagem é rápido e fácil.';

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
  String get servicesHourlyBullet4 => 'Tarifas competitivas: 40 km de percurso incluídos por hora';

  @override
  String get servicesHourlyBullet5 => 'Confiabilidade: motoristas treinados nos mais altos padrões';

  @override
  String get servicesHourlyBullet6 => 'Sustentabilidade: as emissões de carbono de cada viagem são compensadas';

  @override
  String get servicesHourlyBullet7 => 'Wi-Fi disponível na maioria dos veículos';

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
  String get servicesHourlyFaq3A => 'Uma hora antes do embarque, você receberá um SMS e um e-mail com o nome e o telefone do motorista.';

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
  String get servicesHourlyReachBanner => 'Disponível em mais de 60 países · Centenas de cidades';

  @override
  String get servicesHourlyReview1 => 'O motorista foi incrível: me ajudou com as malas e parou em todos os lugares que eu queria ver.';

  @override
  String get servicesHourlyReview1Origin => 'Estados Unidos';

  @override
  String get servicesHourlyReview2 => 'Os motoristas não são simples condutores, e sim profissionais altamente qualificados.';

  @override
  String get servicesHourlyReview2Origin => 'Portugal';

  @override
  String get servicesHourlyReview3 => 'O app que todo viajante precisa conhecer. Ainda não encontrei um lugar onde ele não funcione.';

  @override
  String get servicesHourlyReview3Origin => 'Canadá';

  @override
  String get servicesHourlyReviewsTitle => 'O que dizem nossos clientes';

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
  String get servicesVehicleMostCities => 'Disponível na maioria das cidades';

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
