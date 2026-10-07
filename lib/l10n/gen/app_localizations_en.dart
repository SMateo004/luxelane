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
  String get driverAcceptRide => 'Accept ride';

  @override
  String get driverActionArrived => 'I\'ve arrived';

  @override
  String get driverActionCompleteTrip => 'Complete trip';

  @override
  String get driverActionGoToPickup => 'Head to pickup point';

  @override
  String get driverActionGoToPickupShort => 'Head to pickup';

  @override
  String get driverActionStartTrip => 'Start trip';

  @override
  String get driverActiveRide => 'Active ride';

  @override
  String driverCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed trips',
      one: '1 completed trip',
    );
    return '$_temp0';
  }

  @override
  String get driverCompletedTrips => 'Completed trips';

  @override
  String get driverConnectionErrorTitle => 'Connection error';

  @override
  String get driverDecline => 'Decline';

  @override
  String get driverErrorUnauthorized => 'This account doesn\'t have chauffeur access.';

  @override
  String get driverEstimatedFare => 'Estimated fare';

  @override
  String get driverGoOnline => 'Go online';

  @override
  String get driverMapsOpenError => 'Couldn\'t open maps';

  @override
  String get driverMsgHeadToPickup => 'Head to the pickup point';

  @override
  String get driverMsgInProgress => 'Trip in progress · head to destination';

  @override
  String get driverMsgOnTheWay => 'On the way to pickup · arriving soon';

  @override
  String get driverMsgWaitingPassenger => 'Waiting for the passenger';

  @override
  String driverNavigateTo(String address) {
    return 'Navigate to $address';
  }

  @override
  String get driverNavigateToDestination => 'Navigate to destination';

  @override
  String get driverNavigateToPickup => 'Navigate to pickup';

  @override
  String get driverNoCompletedTrips => 'No completed trips yet';

  @override
  String get driverNoMapsApps => 'No map apps available';

  @override
  String get driverOfferExpiring => 'Offer about to expire';

  @override
  String get driverOfflineSubtitle => 'Turn on the switch to go online';

  @override
  String get driverOfflineTitle => 'You\'re offline';

  @override
  String get driverOnbBack => 'Back';

  @override
  String get driverOnbColor => 'Color';

  @override
  String get driverOnbDefaultColor => 'Black';

  @override
  String get driverOnbExpiryFormat => 'Use MM/YYYY';

  @override
  String get driverOnbInvalid => 'Invalid';

  @override
  String get driverOnbInvalidMonth => 'Invalid month';

  @override
  String get driverOnbLicenseExpired => 'License expired';

  @override
  String get driverOnbLicenseExpiry => 'Expiration date (MM/YYYY)';

  @override
  String get driverOnbLicenseNumber => 'License number';

  @override
  String get driverOnbLicenseSubtitle => 'Your documents will be reviewed before you can accept rides.';

  @override
  String get driverOnbLicenseTitle => 'Driver\'s license';

  @override
  String get driverOnbLogout => 'Sign out';

  @override
  String get driverOnbMake => 'Make';

  @override
  String get driverOnbModel => 'Model';

  @override
  String get driverOnbPlate => 'License plate';

  @override
  String get driverOnbReviewNotice => 'An administrator will verify your documents before you can go online.';

  @override
  String get driverOnbSaveError => 'We couldn\'t save your details. Please try again.';

  @override
  String get driverOnbVehicleClass => 'Vehicle category';

  @override
  String get driverOnbVehicleSubtitle => 'Register the vehicle you\'ll be driving.';

  @override
  String get driverOnbVehicleTitle => 'Your vehicle';

  @override
  String get driverOnbYear => 'Year';

  @override
  String get driverOnlineSubtitle => 'Waiting for new ride requests';

  @override
  String get driverOnlineTitle => 'You\'re online';

  @override
  String get driverPaid => 'PAID';

  @override
  String get driverQueueAvailable => 'AVAILABLE REQUESTS';

  @override
  String get driverQueueEmptyBody => 'New bookings will appear here';

  @override
  String get driverQueueEmptyTitle => 'No jobs yet';

  @override
  String get driverQueueMyActive => 'MY ACTIVE JOBS';

  @override
  String get driverQueueOfflineBody => 'Turn on your availability in the Home tab';

  @override
  String get driverQueueOfflineTitle => 'Go online to receive jobs';

  @override
  String get driverQueueTitle => 'Job queue';

  @override
  String get driverRequestExclusive => 'EXCLUSIVE REQUEST FOR YOU';

  @override
  String get driverRequestNew => 'NEW RIDE REQUEST';

  @override
  String driverRespondIn(int seconds) {
    return 'Respond within ${seconds}s';
  }

  @override
  String get driverStatCompleted => 'Completed';

  @override
  String get driverStatEarnings => 'Earnings';

  @override
  String get driverTabHome => 'Home';

  @override
  String get driverTabJobs => 'Jobs';

  @override
  String get driverTabProfile => 'Profile';

  @override
  String get driverTodaySummary => 'Today\'s summary';

  @override
  String get driverTotalEarnings => 'Total earnings';

  @override
  String get driverTripNotFound => 'Trip not found';

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
  String notifBellUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread notifications',
      one: '1 unread notification',
    );
    return '$_temp0';
  }

  @override
  String get notifEmpty => 'No notifications yet';

  @override
  String notifHoursAgo(int hours) {
    return '$hours h ago';
  }

  @override
  String get notifJustNow => 'Now';

  @override
  String get notifMarkAllRead => 'Mark all as read';

  @override
  String notifMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String get notifTitle => 'Notifications';

  @override
  String get rideArrived => 'You\'ve arrived!';

  @override
  String rideArrivesIn(String eta) {
    return 'Arriving in $eta';
  }

  @override
  String get rideAssigning => 'Assigning your chauffeur';

  @override
  String get rideAssigningBody => 'We\'re confirming your chauffeur. We\'ll let you know as soon as one is assigned.';

  @override
  String get rideBackHome => 'Back to home';

  @override
  String get rideCancelled => 'Booking cancelled';

  @override
  String rideChauffeurArrivesIn(String eta) {
    return 'Your chauffeur arrives in $eta';
  }

  @override
  String get rideChauffeurConfirmed => 'Chauffeur confirmed';

  @override
  String get rideChauffeurOnTheWay => 'Your chauffeur is on the way';

  @override
  String get rideChauffeurWaiting => 'Your chauffeur is waiting';

  @override
  String rideFlightArrivesAt(String time) {
    return 'Arrives $time';
  }

  @override
  String rideFlightLandedAt(String time) {
    return 'Landed $time';
  }

  @override
  String rideFlightTitle(String number) {
    return 'Flight $number';
  }

  @override
  String rideFlightTitleTerminal(String number, String terminal) {
    return 'Flight $number · Terminal $terminal';
  }

  @override
  String get rideHeadingToDestination => 'On the way to your destination';

  @override
  String get rideLive => 'LIVE';

  @override
  String get rideLoading => 'Loading your booking…';

  @override
  String get rideNotifArrivedBody => 'Your chauffeur is waiting for you at the pickup point.';

  @override
  String get rideNotifArrivedTitle => 'Your chauffeur has arrived';

  @override
  String get rideNotifArrivingBody => 'Your chauffeur is heading to your pickup point.';

  @override
  String get rideNotifArrivingTitle => 'Your chauffeur is on the way';

  @override
  String get rideNotifAssignedBody => 'Your chauffeur has confirmed the booking.';

  @override
  String get rideNotifAssignedTitle => 'Chauffeur assigned';

  @override
  String get rideNotifCompletedBody => 'You\'ve arrived! Thank you for traveling with Luxelane.';

  @override
  String get rideNotifCompletedTitle => 'Trip completed';

  @override
  String get rideNotifStartedBody => 'You\'re on your way to your destination.';

  @override
  String get rideNotifStartedTitle => 'Trip started';

  @override
  String ridePickupAt(String time) {
    return 'Pickup $time';
  }

  @override
  String get rideRateTrip => 'Rate your trip';

  @override
  String get rideRatingCommentHint => 'Comment (optional)';

  @override
  String get rideRatingExcellent => 'Excellent';

  @override
  String get rideRatingFair => 'Fair';

  @override
  String get rideRatingGood => 'Good';

  @override
  String get rideRatingPoor => 'Poor';

  @override
  String rideRatingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get rideRatingThanks => 'Thank you for your rating!';

  @override
  String get rideRatingTitle => 'Rate your trip';

  @override
  String get rideRatingVeryPoor => 'Very poor';

  @override
  String get rideThanks => 'Thank you for traveling with Luxelane';

  @override
  String get rideThanksForRating => 'Thanks for your rating';

  @override
  String get rideVerifiedChauffeur => 'Verified chauffeur';

  @override
  String rideVerifiedTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verified · $count trips',
      one: 'Verified · 1 trip',
    );
    return '$_temp0';
  }

  @override
  String get rideViewReceipt => 'View receipt';

  @override
  String rideYouArriveIn(String eta) {
    return 'You\'ll arrive in $eta';
  }

  @override
  String get rideYourChauffeur => 'Your chauffeur';

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
  String get tripDestination => 'Destination';

  @override
  String tripFlightNumber(String number) {
    return 'Flight $number';
  }

  @override
  String tripFreeWaitLeft(int minutes) {
    return 'Free waiting: $minutes min';
  }

  @override
  String tripFreeWaitOver(String time) {
    return 'Free waiting ended at $time';
  }

  @override
  String get tripFreeWaitOverDriver => 'Contact the passenger before leaving.';

  @override
  String get tripFreeWaitOverRider => 'Your chauffeur is still waiting for you. Let them know if you need more time.';

  @override
  String tripFreeWaitUntil(String time, String summary) {
    return 'Until $time · $summary';
  }

  @override
  String get tripMeetGreetBody => 'Your chauffeur will wait for you at the arrivals exit with a sign bearing your name.';

  @override
  String tripMeetGreetBodyNamed(String name) {
    return 'Your chauffeur will wait for you at the arrivals exit with a sign reading “$name”.';
  }

  @override
  String get tripMeetGreetTitle => 'Meet & greet at arrivals';

  @override
  String tripMeetGreetWait(int minutes) {
    return '$minutes min of free waiting from when your flight lands.';
  }

  @override
  String tripNameSignSemantics(String name) {
    return 'Name sign for $name. Tap to close.';
  }

  @override
  String get tripNameSignTapToClose => 'Tap the screen to close';

  @override
  String get tripPassenger => 'Passenger';

  @override
  String get tripPickup => 'Pickup';

  @override
  String get tripPriceBaseFare => 'Base fare';

  @override
  String get tripPriceBreakdown => 'Price breakdown';

  @override
  String tripPriceDistanceLine(String km, String rate) {
    return '$km km × $rate';
  }

  @override
  String get tripPriceEstimatedTotal => 'Estimated total';

  @override
  String get tripPriceFinalNote => 'The final fixed price is confirmed before you book.';

  @override
  String tripPriceHoursLine(int hours, String rate) {
    return '$hours h × $rate';
  }

  @override
  String get tripPriceMinimumAdjustment => 'Minimum fare adjustment';

  @override
  String get tripReceiptAdjustment => 'Adjustment';

  @override
  String get tripReceiptCancelled => 'BOOKING CANCELLED';

  @override
  String get tripReceiptCard => 'Card';

  @override
  String get tripReceiptCompleted => 'TRIP COMPLETED';

  @override
  String get tripReceiptCopied => 'Receipt copied to clipboard';

  @override
  String get tripReceiptCopy => 'Copy receipt';

  @override
  String get tripReceiptCurrencyNote => 'Amounts in bolivianos (BOB).';

  @override
  String get tripReceiptDuration => 'Duration';

  @override
  String get tripReceiptFixedPrice => 'Fixed price';

  @override
  String get tripReceiptFlight => 'Flight';

  @override
  String get tripReceiptNoCharge => 'No charge';

  @override
  String tripReceiptNumber(String code) {
    return 'No. $code';
  }

  @override
  String get tripReceiptPassengers => 'Passengers';

  @override
  String get tripReceiptPayChauffeur => 'Paid to chauffeur';

  @override
  String get tripReceiptPaymentMethod => 'Payment method';

  @override
  String tripReceiptPlainFrom(String place) {
    return 'From: $place';
  }

  @override
  String tripReceiptPlainHeader(String code) {
    return 'Luxelane — Receipt $code';
  }

  @override
  String tripReceiptPlainTo(String place) {
    return 'To: $place';
  }

  @override
  String tripReceiptPlainTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get tripReceiptService => 'Service';

  @override
  String get tripReceiptTitle => 'Receipt';

  @override
  String get tripReceiptTotal => 'Total';

  @override
  String get tripReceiptVehicle => 'Vehicle';

  @override
  String get tripShowSign => 'Show name sign';

  @override
  String get tripsBookNow => 'Book now';

  @override
  String get tripsEmpty => 'You don\'t have any trips yet.\nBook your first experience.';

  @override
  String get tripsLoadError => 'We couldn\'t load your trips. Check your connection.';

  @override
  String get tripsPast => 'PAST';

  @override
  String tripsRouteByHour(String origin, int hours) {
    return '$origin · $hours h';
  }

  @override
  String get tripsTitle => 'My trips';

  @override
  String get tripsUpcoming => 'UPCOMING';

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
