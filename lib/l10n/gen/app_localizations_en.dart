// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Luxelane';

  @override
  String get appNameDriver => 'Luxelane Chauffeur';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCall => 'Call';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonConnectionError => 'Check your connection and try again.';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCouldNotOpenApp => 'Couldn\'t open the app';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonGenericError => 'Something went wrong';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonOptional => 'Optional';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSend => 'Send';

  @override
  String get commonWhatsApp => 'WhatsApp';

  @override
  String get flightCancelled => 'Cancelled';

  @override
  String flightDelayed(int minutes) {
    return 'Delayed $minutes min';
  }

  @override
  String get flightLanded => 'Landed';

  @override
  String get flightOnTime => 'On time';

  @override
  String legalCompanyDetails(String nit, String address) {
    return 'NIT (Tax ID) $nit · $address';
  }

  @override
  String get legalContactComingSoon => 'Contact channels will be published soon.';

  @override
  String get legalContactEmail => 'Email';

  @override
  String get legalContactHeadline => 'We\'re here to help';

  @override
  String get legalContactIntro => 'Write to us with any question about a booking, your account or your data. If you have a trip in progress, use the buttons to contact your chauffeur on the trip screen.';

  @override
  String get legalContactTitle => 'Contact';

  @override
  String get legalDeleteActiveTrip => 'You have a trip in progress. You can delete your account once it ends.';

  @override
  String get legalDeleteButton => 'Delete my account';

  @override
  String legalDeleteConfirmPrompt(String keyword) {
    return 'Type $keyword to confirm.';
  }

  @override
  String get legalDeleteConnectionError => 'We couldn\'t delete your account. Check your connection.';

  @override
  String get legalDeleteEffectBookings => 'We cancel your pending bookings.';

  @override
  String get legalDeleteEffectDriver => 'If you are a chauffeur, we also delete your chauffeur profile and deactivate your vehicle.';

  @override
  String get legalDeleteEffectPermanent => 'This action cannot be undone.';

  @override
  String get legalDeleteEffectProfile => 'We delete your profile, your notifications and your access.';

  @override
  String get legalDeleteEffectTrips => 'We remove your name, phone number and notes from your past trips. The records of those trips are kept without contact details for accounting obligations.';

  @override
  String get legalDeleteFailed => 'We couldn\'t delete your account. Try again or contact us.';

  @override
  String get legalDeleteHeadline => 'Delete your account';

  @override
  String get legalDeleteIntro => 'When you delete your account:';

  @override
  String get legalDeleteKeyword => 'DELETE';

  @override
  String get legalDeleteSignIn => 'Sign in';

  @override
  String get legalDeleteSignInPrompt => 'Sign in with the account you want to delete.';

  @override
  String get legalDeleteSuccess => 'Your account was deleted.';

  @override
  String get legalDeleteTitle => 'Delete account';

  @override
  String get legalDraftBanner => 'Draft: this document contains pending details in square brackets and must be reviewed by a lawyer before it is published.';

  @override
  String legalLastUpdated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Last updated: $dateString';
  }

  @override
  String get serviceByTheHour => 'By the hour';

  @override
  String get serviceByTheHourDesc => 'A chauffeur at your disposal for a set time';

  @override
  String get serviceOneWay => 'One way';

  @override
  String get serviceOneWayDesc => 'Fixed-price transfer to your destination';

  @override
  String get servicesAirportArriveBody => 'Every Luxelane chauffeur service is held to the highest standards, for every passenger. Our professional chauffeurs can track your flight and adjust your pickup time if delays beyond your control arise.';

  @override
  String get servicesAirportArriveTitle => 'Arrivals and departures, handled';

  @override
  String get servicesAirportClassesTitle => 'Discover our service classes';

  @override
  String get servicesAirportConnectionsBody => 'Booking Luxelane is effortless. Simply enter your pickup and destination and choose your vehicle class. The price you see is the price you pay, with no hidden fees.';

  @override
  String get servicesAirportConnectionsTitle => 'Airport-to-airport connections';

  @override
  String get servicesAirportFaq1A => 'An airport transfer is a private car service that takes air travelers to and from the airport. Professional chauffeurs can meet passengers at the terminal once they have collected their luggage.';

  @override
  String get servicesAirportFaq1Q => 'What is an airport transfer?';

  @override
  String get servicesAirportFaq2A => 'An airport transfer is a wonderful way to take the stress out of both ends of your flight. Luxelane offers a wide range of transfer options tailored to your needs.';

  @override
  String get servicesAirportFaq2Q => 'Is it worth booking an airport transfer?';

  @override
  String get servicesAirportFaq3A => 'A paid airport transfer is a transport service with a professional chauffeur booked in advance, at a fixed price in bolivianos confirmed before you book.';

  @override
  String get servicesAirportFaq3Q => 'What is a prebooked airport transfer?';

  @override
  String get servicesAirportFeatureFlexBody => 'Stay flexible: cancel free of charge up to 1 hour before pickup, right from the app.';

  @override
  String get servicesAirportFeatureFlexTitle => 'Flexible travel';

  @override
  String get servicesAirportFeatureFlightBody => 'Relax with a complimentary hour of waiting time and flight tracking.';

  @override
  String get servicesAirportFeatureFlightTitle => 'Effortless airport travel';

  @override
  String get servicesAirportFeaturePriceBody => 'First-class service, fairly priced by distance.';

  @override
  String servicesAirportFreeWait(int minutes) {
    return 'Your chauffeur will wait up to $minutes minutes at no extra cost.';
  }

  @override
  String get servicesAirportHeroEyebrow => 'TRANSFER SERVICE';

  @override
  String get servicesAirportHeroTitle => 'To the airport,\nwithout the stress';

  @override
  String get servicesAirportPanelSubtitle => 'One way or by the hour · No waiting';

  @override
  String get servicesAirportPanelTitle => 'Airport transfers';

  @override
  String get servicesBackHome => '← Back to home';

  @override
  String get servicesBookNow => 'BOOK NOW';

  @override
  String get servicesBookRide => 'BOOK A RIDE';

  @override
  String get servicesFaqTitle => 'Frequently asked questions';

  @override
  String get servicesFeaturePriceTitle => 'Competitive pricing';

  @override
  String servicesFooterRights(String year) {
    return '© $year Luxelane · All rights reserved';
  }

  @override
  String get servicesFromHint => 'From – address, airport, hotel…';

  @override
  String get servicesHourlyBullet1 => 'Your itinerary: you decide where to go, and when';

  @override
  String get servicesHourlyBullet2 => 'Save time: door-to-door drop-off and pickup at every stop';

  @override
  String get servicesHourlyBullet3 => 'Total peace of mind: travel in a premium vehicle';

  @override
  String get servicesHourlyBullet4 => 'Fixed hourly rate: you know the price before you book';

  @override
  String get servicesHourlyBullet5 => 'Reliability: chauffeurs trained to the highest standards';

  @override
  String get servicesHourlyBullet6 => 'Chauffeurs vetted by our team';

  @override
  String get servicesHourlyBullet7 => 'Live tracking of your chauffeur in the app';

  @override
  String get servicesHourlyBullet8 => 'Made for the city: starts and ends in the same city';

  @override
  String servicesHourlyDurationField(String duration) {
    return 'Duration – $duration';
  }

  @override
  String get servicesHourlyFaq1A => 'Choose your pickup location, select the duration, date and time, pick a vehicle class and complete your booking.';

  @override
  String get servicesHourlyFaq1Q => 'How do I book a chauffeur by the hour?';

  @override
  String get servicesHourlyFaq2A => 'Yes. Your chauffeur and vehicle are at your disposal for the entire duration of your booking.';

  @override
  String get servicesHourlyFaq2Q => 'Can I change my itinerary during the ride?';

  @override
  String get servicesHourlyFaq3A => 'Once your chauffeur is assigned you’ll get a notification and see their name, vehicle, plate and phone number in the app.';

  @override
  String get servicesHourlyFaq3Q => 'When will I receive my chauffeur\'s details?';

  @override
  String get servicesHourlyFaq4A => 'Yes, your booking can start or end at an airport. The start and end points must be in the same city.';

  @override
  String get servicesHourlyFaq4Q => 'Can my booking start at an airport?';

  @override
  String servicesHourlyFaq5A(int min, int max) {
    return 'Yes, you can edit your booking before the start time. The minimum duration is $min hours and the maximum is $max hours.';
  }

  @override
  String get servicesHourlyFaq5Q => 'Can I add more hours?';

  @override
  String get servicesHourlyHeroEyebrow => 'HOURLY HIRE';

  @override
  String get servicesHourlyHeroTitle => 'Chauffeur hire\nby the hour or day';

  @override
  String get servicesHourlyPanelSubtitle => 'Your itinerary · Your pace';

  @override
  String get servicesHourlyPanelTitle => 'Chauffeur by the hour';

  @override
  String get servicesHourlyReachBanner => 'Available in Santa Cruz de la Sierra · Book in the app or online';

  @override
  String get servicesHourlyServiceBody => 'No more switching between rides on a day full of stops. With Luxelane, you set the itinerary: you decide where to go, and when.';

  @override
  String get servicesHourlyServiceTitle => 'Hourly chauffeur service';

  @override
  String get servicesHourlyUseBusinessBody => 'Focus on what matters. Move seamlessly between meetings and leave the logistics to us.';

  @override
  String get servicesHourlyUseBusinessTitle => 'Business travel';

  @override
  String get servicesHourlyUseCasesTitle => 'Designed for every occasion';

  @override
  String get servicesHourlyUseEventsBody => 'Make a grand entrance, and an effortless exit, at any event.';

  @override
  String get servicesHourlyUseEventsTitle => 'Concerts and events';

  @override
  String get servicesHourlyUseLeisureBody => 'Lunch, shopping or a list of errands: your chauffeur is ready whenever you are.';

  @override
  String get servicesHourlyUseLeisureTitle => 'Leisure';

  @override
  String get servicesHourlyUseSightseeingBody => 'Explore the city your way, at your own pace, with a local chauffeur always at your disposal.';

  @override
  String get servicesHourlyUseSightseeingTitle => 'Sightseeing';

  @override
  String get servicesNavBusiness => 'FOR BUSINESS';

  @override
  String get servicesNavFleet => 'FLEET';

  @override
  String get servicesNavHome => 'HOME';

  @override
  String get servicesNavServices => 'SERVICES';

  @override
  String get servicesPickupChauffeursBody => 'Travel with confidence, accompanied by expert chauffeurs who offer the finest service and complete discretion.';

  @override
  String get servicesPickupChauffeursTitle => 'Professional chauffeurs';

  @override
  String get servicesPickupComfortBody => 'A private ride in a high-end vehicle turns every journey into a pleasure.';

  @override
  String get servicesPickupComfortTitle => 'Comfort';

  @override
  String get servicesPickupConvenienceBody => 'A door-to-door chauffeured ride the moment you need it, in just a few taps.';

  @override
  String get servicesPickupConvenienceTitle => 'Convenience';

  @override
  String get servicesPickupHeroSubtitle => 'Professional chauffeurs at your fingertips';

  @override
  String get servicesPickupHeroTitle => 'Instant\nPickup Service';

  @override
  String get servicesPickupIntroBody => 'Get a door-to-door chauffeured ride the moment you need it, with just a few taps in the Luxelane app.';

  @override
  String get servicesPickupIntroEyebrow => 'INSTANT PICKUP';

  @override
  String get servicesPickupIntroTitle => 'Discover Instant Pickup';

  @override
  String get servicesPickupPriceBody => 'First-class service at distance-based prices that are fair for everyone.';

  @override
  String get servicesPickupQualityBody => 'Making every ride exceptional is our highest priority.';

  @override
  String get servicesPickupQualityTitle => 'Quality';

  @override
  String get servicesPickupReliabilityBody => 'Book with confidence and stay informed with real-time ride updates.';

  @override
  String get servicesPickupReliabilityTitle => 'Reliability';

  @override
  String get servicesPickupSplitBody => 'Whenever you need a safe way to get around the city, think Luxelane Instant Pickup: the perfect blend of a classic chauffeur service and private transportation.';

  @override
  String get servicesPickupSplitEyebrow => 'COMFORTABLE · SAFE · IMMEDIATE';

  @override
  String get servicesPickupSplitTitle => 'Comfortable rides on demand, in minutes';

  @override
  String servicesQuote(String quote) {
    return '“$quote”';
  }

  @override
  String get servicesSelect => 'SELECT';

  @override
  String get servicesToHint => 'To – address, airport, hotel…';

  @override
  String get servicesToggleOneWay => 'One way';

  @override
  String servicesUpToLargeBags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Up to $count large suitcases',
      one: 'Up to 1 large suitcase',
    );
    return '$_temp0';
  }

  @override
  String servicesUpToPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Up to $count passengers',
      one: 'Up to 1 passenger',
    );
    return '$_temp0';
  }

  @override
  String get servicesVehicleBusinessModels => 'Mercedes E-Class, BMW 5 Series or similar';

  @override
  String get servicesVehicleFirstModels => 'Mercedes S-Class, BMW 7 Series or similar';

  @override
  String get servicesVehicleGroups => 'Ideal for groups and families';

  @override
  String get servicesVehicleMostCities => 'Available in Santa Cruz de la Sierra';

  @override
  String get servicesVehiclePremiumLuxury => 'Our most refined experience';

  @override
  String get servicesVehicleVanModels => 'Mercedes V-Class, Toyota Alphard or similar';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusDriverArrived => 'Chauffeur arrived';

  @override
  String get statusDriverArriving => 'On the way';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusPending => 'Pending';

  @override
  String unitBags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bags',
      one: '1 bag',
    );
    return '$_temp0';
  }

  @override
  String unitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
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
      other: '$count passengers',
      one: '1 passenger',
    );
    return '$_temp0';
  }

  @override
  String unitTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '1 trip',
    );
    return '$_temp0';
  }

  @override
  String get vehicleBusiness => 'Business Class';

  @override
  String get vehicleBusinessDesc => 'Mercedes E-Class or similar';

  @override
  String get vehicleBusinessVan => 'Business Van';

  @override
  String get vehicleBusinessVanDesc => 'Mercedes V-Class · Up to 7';

  @override
  String get vehicleElectric => 'Electric';

  @override
  String get vehicleElectricDesc => 'Tesla Model S or similar';

  @override
  String get vehicleFirstClass => 'First Class';

  @override
  String get vehicleFirstClassDesc => 'Mercedes S-Class or similar';

  @override
  String waitAirportSummary(int minutes) {
    return '$minutes min free waiting from landing';
  }

  @override
  String waitCitySummary(int minutes) {
    return '$minutes min free waiting';
  }
}
