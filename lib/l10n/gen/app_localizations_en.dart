// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get adminActionFailed => 'That action couldn\'t be completed. Please try again.';

  @override
  String get adminActive => 'Active';

  @override
  String get adminAppVersion => 'App version';

  @override
  String get adminAssignNearest => 'Assign nearest chauffeur';

  @override
  String adminAttentionBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bookings without a chauffeur, pickup within 2 hours',
      one: '1 booking without a chauffeur, pickup within 2 hours',
    );
    return '$_temp0';
  }

  @override
  String get adminAttentionView => 'View';

  @override
  String adminAuditBy(String id) {
    return 'Admin: $id';
  }

  @override
  String get adminBackend => 'Backend';

  @override
  String get adminBookingActions => 'Actions';

  @override
  String adminBookingDriver(String name) {
    return 'Chauffeur: $name';
  }

  @override
  String adminBookingRider(String name) {
    return 'Passenger: $name';
  }

  @override
  String get adminBusinessPerformance => 'Business performance';

  @override
  String get adminCancelBooking => 'Cancel booking';

  @override
  String get adminCancelBookingBody => 'The passenger and the assigned chauffeur will be notified.';

  @override
  String adminCancelBookingTitle(String code) {
    return 'Cancel booking $code?';
  }

  @override
  String adminChangeRoleTitle(String name) {
    return 'Change role for $name';
  }

  @override
  String get adminCurrency => 'Currency';

  @override
  String get adminCurrencyValue => 'Bolivianos (Bs)';

  @override
  String adminDeleteBookingBody(String id) {
    return 'Booking #$id will be permanently deleted. This can\'t be undone.';
  }

  @override
  String get adminDeleteBookingTitle => 'Delete booking?';

  @override
  String get adminDeleteBookingTooltip => 'Delete booking';

  @override
  String get adminDisable => 'Disable';

  @override
  String get adminDocumentsVerified => 'Documents verified';

  @override
  String get adminFieldBase => 'Base (Bs)';

  @override
  String get adminFieldMinimum => 'Minimum (Bs)';

  @override
  String get adminFieldPerHour => 'Per hour (Bs)';

  @override
  String get adminFieldPerKm => 'Per km (Bs)';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminFilterUnassigned => 'Unassigned';

  @override
  String get adminFirestoreRules => 'Firestore pricing rules';

  @override
  String get adminGlobalSettings => 'Global app settings';

  @override
  String get adminInactive => 'Inactive';

  @override
  String get adminKpiAwaitingDriver => 'Awaiting chauffeur';

  @override
  String get adminKpiCompleted => 'Completed rides';

  @override
  String adminKpiDriversCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chauffeurs',
      one: '1 chauffeur',
    );
    return '$_temp0';
  }

  @override
  String adminKpiInProgress(int count) {
    return '$count in progress';
  }

  @override
  String get adminKpiPending => 'Pending bookings';

  @override
  String adminKpiToday(String amount) {
    return 'Today: $amount';
  }

  @override
  String get adminKpiTotalRevenue => 'Total revenue';

  @override
  String get adminKpiUsers => 'Registered users';

  @override
  String adminLicense(String number) {
    return 'License: $number';
  }

  @override
  String get adminLiveStats => 'Live stats';

  @override
  String get adminMaintenanceBanner => 'MAINTENANCE MODE ON — Passengers can\'t book new rides.';

  @override
  String get adminMaintenanceMode => 'Maintenance mode';

  @override
  String get adminMaintenanceModeDesc => 'Turns off all bookings and shows users the maintenance screen.';

  @override
  String adminMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get adminNoAuditLogs => 'No audit entries yet';

  @override
  String get adminNoAuditLogsHint => 'Admin actions will appear here in real time';

  @override
  String get adminNoBookings => 'No bookings found';

  @override
  String get adminNoDrivers => 'No chauffeurs found';

  @override
  String get adminNoUsersMatch => 'No users match your search';

  @override
  String get adminNoVehicles => 'No vehicles registered yet';

  @override
  String get adminNoVehiclesHint => 'Vehicles linked to chauffeurs appear here';

  @override
  String get adminNoticeBookingCancelled => 'Booking cancelled';

  @override
  String get adminNoticeBookingDeleted => 'Booking deleted';

  @override
  String get adminNoticeDriverAssigned => 'Chauffeur assigned';

  @override
  String get adminNoticeDriverVerified => 'Chauffeur verified';

  @override
  String get adminNoticeMaintenanceOff => 'Maintenance mode turned off';

  @override
  String get adminNoticeMaintenanceOn => 'Maintenance mode turned on';

  @override
  String get adminNoticeNoDriver => 'No nearby chauffeurs available for this vehicle class';

  @override
  String get adminNoticePricingUpdated => 'Pricing rule updated';

  @override
  String get adminNoticeRoleUpdated => 'Role updated';

  @override
  String get adminNoticeSettingsSaved => 'Settings saved';

  @override
  String get adminOffline => 'Offline';

  @override
  String get adminOnline => 'Online';

  @override
  String get adminOverview => 'Overview';

  @override
  String get adminPanelBadge => 'Admin panel';

  @override
  String get adminPlatform => 'Platform';

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
    return 'Min: $amount';
  }

  @override
  String adminPricePerHour(String amount) {
    return '$amount/h';
  }

  @override
  String get adminPricingNote => 'Prices reflect the DefaultPricing model. If the pricingRules collection is empty, prices are calculated locally.';

  @override
  String get adminPricingRules => 'Pricing rules (Bs)';

  @override
  String get adminPushNotifications => 'Push notifications';

  @override
  String get adminPushNotificationsDesc => 'Enables system-wide notifications for new bookings.';

  @override
  String get adminRecentActivity => 'Recent activity';

  @override
  String get adminRegisteredDrivers => 'Registered chauffeurs';

  @override
  String get adminRegisteredVehicles => 'Registered vehicles';

  @override
  String get adminReportsAvgRating => 'Average rating';

  @override
  String get adminReportsAvgTicket => 'Average fare';

  @override
  String get adminReportsByAdmin => 'Operations';

  @override
  String get adminReportsByRider => 'Rider';

  @override
  String get adminReportsBySystem => 'Automatic';

  @override
  String get adminReportsByUnknown => 'Not recorded';

  @override
  String get adminReportsCancellationRate => 'Cancellation rate';

  @override
  String get adminReportsCancellations => 'Cancellations by source';

  @override
  String adminReportsCancelledOf(int cancelled, int total) {
    return '$cancelled of $total bookings';
  }

  @override
  String get adminReportsColDate => 'Date';

  @override
  String get adminReportsColDriver => 'Chauffeur';

  @override
  String get adminReportsColRating => 'Rating';

  @override
  String get adminReportsColRevenue => 'Revenue (Bs)';

  @override
  String get adminReportsColTrips => 'Trips';

  @override
  String get adminReportsCopied => 'CSV copied to the clipboard';

  @override
  String get adminReportsDailyTable => 'Show daily data';

  @override
  String adminReportsDays(int days) {
    return '$days days';
  }

  @override
  String get adminReportsDownloaded => 'CSV downloaded';

  @override
  String get adminReportsDrivers => 'Chauffeur performance';

  @override
  String get adminReportsEmpty => 'No bookings with a pickup in this period.';

  @override
  String get adminReportsExportDaily => 'Export days (CSV)';

  @override
  String get adminReportsExportDrivers => 'Export chauffeurs (CSV)';

  @override
  String get adminReportsLateCancellations => 'Late cancellations';

  @override
  String get adminReportsLateHint => 'By the rider, inside the charged window';

  @override
  String get adminReportsNoCancellations => 'No cancellations in this period.';

  @override
  String get adminReportsNoDrivers => 'No chauffeur completed trips in this period.';

  @override
  String get adminReportsNoPrevious => 'No data for the previous period';

  @override
  String adminReportsPeakHour(String hour) {
    return 'Peak hour: $hour';
  }

  @override
  String get adminReportsPeakHours => 'Demand by pickup hour';

  @override
  String get adminReportsPeakHoursHint => 'Every booking in the period, cancelled ones included.';

  @override
  String get adminReportsPerTrip => 'Per completed trip';

  @override
  String adminReportsRange(String from, String to) {
    return 'Pickups from $from to $to (local time)';
  }

  @override
  String adminReportsRatingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ratings',
      one: '1 rating',
      zero: 'No ratings',
    );
    return '$_temp0';
  }

  @override
  String get adminReportsRevenue => 'Revenue';

  @override
  String get adminReportsRevenuePerDay => 'Revenue per day (Bs)';

  @override
  String get adminReportsServiceMix => 'Trips by service type';

  @override
  String get adminReportsTitle => 'Operations reports';

  @override
  String adminReportsTooltipBookings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bookings',
      one: '1 booking',
    );
    return '$_temp0';
  }

  @override
  String adminReportsTooltipTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '1 trip',
    );
    return '$_temp0';
  }

  @override
  String get adminReportsTrips => 'Completed trips';

  @override
  String get adminReportsTripsPerDay => 'Completed trips per day';

  @override
  String get adminReportsUnknownDriver => 'Unnamed chauffeur';

  @override
  String get adminReportsUnserved => 'No chauffeur assigned';

  @override
  String get adminReportsUnservedHint => 'Cancelled automatically';

  @override
  String get adminReportsVehicleMix => 'Trips by vehicle class';

  @override
  String adminReportsVsPrevious(String delta) {
    return '$delta vs. previous period';
  }

  @override
  String get adminRevenueTrend => '7-day revenue trend (Bs)';

  @override
  String get adminSearchUsers => 'Search users…';

  @override
  String get adminSectionAudit => 'Audit log';

  @override
  String get adminSectionBookings => 'Bookings';

  @override
  String get adminSectionCompanies => 'Companies';

  @override
  String get adminSectionDashboard => 'Dashboard';

  @override
  String get adminSectionDrivers => 'Chauffeurs';

  @override
  String get adminSectionHealth => 'Health';

  @override
  String get adminSectionHotels => 'Hotels';

  @override
  String get adminSectionLoyalty => 'Loyalty';

  @override
  String get adminSectionPricing => 'Pricing';

  @override
  String get adminSectionPromos => 'Promotions';

  @override
  String get adminSectionReports => 'Reports';

  @override
  String get adminSectionSettings => 'Settings';

  @override
  String get adminSectionSettlements => 'Settlements';

  @override
  String get adminSectionSupport => 'Support';

  @override
  String get adminSectionUsers => 'Users';

  @override
  String get adminSectionVehicles => 'Vehicles';

  @override
  String get adminSignOutConfirm => 'Are you sure you want to sign out of the admin dashboard?';

  @override
  String get adminSystemInfo => 'System information';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminTotalBookings => 'Total bookings';

  @override
  String get adminTwoFactor => 'Admin two-factor authentication';

  @override
  String get adminTwoFactorDesc => 'Requires 2FA for all admin actions.';

  @override
  String adminVehicleDetails(String plate, String vehicleClass) {
    return 'Plate: $plate · Class: $vehicleClass';
  }

  @override
  String get adminVerifiedDrivers => 'Verified chauffeurs';

  @override
  String get adminVerify => 'Verify';

  @override
  String get appName => 'Luxelane';

  @override
  String get appNameDriver => 'Luxelane Chauffeur';

  @override
  String get authAlreadyHaveAccount => 'Already have an account?';

  @override
  String get authBrandHeadline => 'Premium chauffeur\nservice.';

  @override
  String get authBrandTagline => 'Fixed prices. Vetted chauffeurs.';

  @override
  String get authConsentPrivacyLink => 'Privacy Policy';

  @override
  String get authConsentRequired => 'You need to accept the terms and the privacy policy';

  @override
  String get authConsentTermsLink => 'Terms and Conditions';

  @override
  String authConsentText(String terms, String privacy) {
    return 'I accept the $terms and the $privacy';
  }

  @override
  String get authCreateOne => 'Create one';

  @override
  String get authEmailInvalid => 'Enter a valid email address';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authErrorEmailInUse => 'An account with this email already exists';

  @override
  String get authErrorGeneric => 'We couldn\'t complete your request. Please try again.';

  @override
  String get authErrorInvalidEmail => 'That email address isn\'t valid';

  @override
  String get authErrorTooManyRequests => 'Too many attempts. Wait a few minutes and try again.';

  @override
  String get authErrorUserDisabled => 'This account has been disabled. Contact us for more information.';

  @override
  String get authErrorUserNotFound => 'There\'s no account with this email';

  @override
  String get authErrorWeakPassword => 'That password is too weak. Use at least 6 characters.';

  @override
  String get authErrorWrongCredentials => 'Incorrect email or password';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authFullNameLabel => 'Full name';

  @override
  String get authLoginHeadline => 'Welcome\nback.';

  @override
  String get authLoginSubtitle => 'Sign in to your account';

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authLoginWelcomeBack => 'Welcome back to Luxelane.';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String authPasswordTooShort(int count) {
    return 'At least $count characters';
  }

  @override
  String get authPhoneLabel => 'Phone';

  @override
  String get authRegisterHeadline => 'Create an account.';

  @override
  String get authRegisterSubtitle => 'Join Luxelane today';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authResetEmailSent => 'Password reset email sent';

  @override
  String get authResetNeedsEmail => 'Enter your email to reset your password';

  @override
  String get authSignInLink => 'Sign in';

  @override
  String get bookingAllFeesIncluded => 'All fees included';

  @override
  String get bookingApplyOffer => 'Apply offer';

  @override
  String get bookingAssuranceFixedPrice => 'Fixed price, no surprises';

  @override
  String get bookingAssuranceVerified => 'Vetted chauffeurs';

  @override
  String get bookingAuthCreateAccountCta => 'Create account';

  @override
  String get bookingAuthEmail => 'Email';

  @override
  String get bookingAuthEmailHint => 'you@example.com';

  @override
  String get bookingAuthFullName => 'Full name';

  @override
  String get bookingAuthFullNameHint => 'Your name';

  @override
  String get bookingAuthHaveAccount => 'Already have an account? Sign in';

  @override
  String get bookingAuthHidePassword => 'Hide password';

  @override
  String get bookingAuthNoAccount => 'Don\'t have an account? Create one';

  @override
  String get bookingAuthPassword => 'Password';

  @override
  String get bookingAuthShowPassword => 'Show password';

  @override
  String get bookingAuthSignInCta => 'Sign in';

  @override
  String get bookingAuthSubtitleLogin => 'Sign in to confirm your booking.';

  @override
  String get bookingAuthSubtitleRegister => 'Create your Luxelane account to complete your booking.';

  @override
  String get bookingAuthTitleLogin => 'Sign in to continue';

  @override
  String get bookingAuthTitleRegister => 'Create an account';

  @override
  String get bookingBackHome => 'Back to home';

  @override
  String get bookingBaseFare => 'Base fare';

  @override
  String get bookingBreakdownHeading => 'BREAKDOWN';

  @override
  String get bookingCapacityLuggageInfo => 'Based on standard luggage sizes, which may differ from yours. You can add details about your luggage in \"Pickup notes\" at the next step.';

  @override
  String get bookingCapacityTitle => 'Capacity';

  @override
  String get bookingCardFallback => 'Card';

  @override
  String bookingChauffeurAtDisposal(int hours) {
    return 'Chauffeur at your disposal · $hours h';
  }

  @override
  String bookingChauffeurAtDisposalDays(int days, int hours) {
    return 'Chauffeur at your disposal · $days days, $hours h per day';
  }

  @override
  String get bookingChooseExperience => 'Choose your experience';

  @override
  String get bookingChooseService => 'Choose a service';

  @override
  String get bookingConfirmCta => 'Confirm booking';

  @override
  String get bookingConfirmedEyebrow => 'BOOKING CONFIRMED';

  @override
  String get bookingConfirmedHeadline => 'Your chauffeur will be waiting.';

  @override
  String get bookingConfirmedSemantics => 'Booking confirmed';

  @override
  String get bookingCountdownOnTheWay => 'Your chauffeur is on the way.';

  @override
  String bookingDateTime(String date, String time) {
    return '$date · $time';
  }

  @override
  String get bookingDaysLabel => 'Days';

  @override
  String bookingDaysSummary(int days, int hours) {
    return '$days days · $hours h per day';
  }

  @override
  String get bookingDescriptiveText => 'Premium, made practical. Spacious seating, a smooth ride and punctual pickups that keep your day on schedule.';

  @override
  String get bookingDestinationLabel => 'Destination';

  @override
  String bookingDistanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get bookingErrorCreateFailed => 'We couldn\'t complete your booking';

  @override
  String get bookingErrorInvalidFlight => 'Please check the flight number (e.g. LA 8810).';

  @override
  String get bookingErrorPaymentNotAuthorised => 'We couldn\'t authorize your card. Please try again or choose another.';

  @override
  String get bookingErrorQuoteExpired => 'Your quote has expired. Confirm again to see the updated price.';

  @override
  String get bookingErrorQuoteFailed => 'We couldn\'t price your journey';

  @override
  String get bookingErrorQuoteMissing => 'Your journey hasn\'t been priced yet';

  @override
  String get bookingErrorRateFailed => 'We couldn\'t send your rating';

  @override
  String get bookingErrorTooManyPassengers => 'The number of passengers exceeds the vehicle\'s capacity.';

  @override
  String get bookingEstimatedTax => 'Estimated tax';

  @override
  String get bookingEstimatedTotal => 'ESTIMATED TOTAL';

  @override
  String get bookingFixedPriceLabel => 'FIXED PRICE';

  @override
  String get bookingFixedPricePaidByCard => 'Fixed price · card authorized';

  @override
  String get bookingFixedPricePayDriver => 'Fixed price · pay your chauffeur';

  @override
  String bookingFlight(String flight) {
    return 'Flight $flight';
  }

  @override
  String get bookingFlightNumber => 'Flight number';

  @override
  String get bookingFlightNumberHint => 'e.g. LA 8810 (optional)';

  @override
  String get bookingForGuest => 'Book for a guest';

  @override
  String get bookingForGuestSubtitle => 'Select or add a guest';

  @override
  String get bookingForMyself => 'Book for myself';

  @override
  String get bookingForMyselfSubtitle => 'Book using your account details';

  @override
  String get bookingFreeCancellationShort => 'Free cancellation up to 1 h before';

  @override
  String get bookingGuestDialogBody => 'Enter your guest\'s details and treat them to a first-class experience. We\'ll keep them updated on their journey every step of the way. Rest assured, we never share any payment or billing information with them.';

  @override
  String get bookingGuestDialogTitle => 'Add a new guest';

  @override
  String bookingGuestDisplayName(String title, String firstName, String lastName) {
    return '$title $firstName $lastName';
  }

  @override
  String get bookingGuestEmailHint => 'Guest\'s email';

  @override
  String get bookingGuestFirstName => 'First name';

  @override
  String get bookingGuestFirstNameHint => 'Guest\'s first name';

  @override
  String get bookingGuestLastName => 'Last name';

  @override
  String get bookingGuestLastNameHint => 'Guest\'s last name';

  @override
  String get bookingGuestPhone => 'Guest\'s mobile number';

  @override
  String get bookingGuestPhoneHelp => 'Your guest will receive trip updates on this number';

  @override
  String get bookingGuestTitleDr => 'Dr.';

  @override
  String get bookingGuestTitleLabel => 'Title';

  @override
  String get bookingGuestTitleMr => 'Mr.';

  @override
  String get bookingGuestTitleMrs => 'Mrs.';

  @override
  String get bookingGuestTitleMs => 'Ms.';

  @override
  String get bookingGuestTitleProf => 'Prof.';

  @override
  String get bookingHeroTagline => 'Fixed price · No surprises · Vetted chauffeurs';

  @override
  String get bookingHeroTitle => 'Choose your\nexperience';

  @override
  String bookingHoursShort(int hours) {
    return '$hours h';
  }

  @override
  String get bookingIncludedChargers => 'iOS and Android chargers on board';

  @override
  String get bookingIncludedFreeCancellation => 'Free cancellation up to 1 hour before pickup';

  @override
  String get bookingIncludedMeetGreet => 'Personal meet & greet';

  @override
  String get bookingIncludedTissues => 'Complimentary tissues and sanitizing wipes';

  @override
  String get bookingIncludedTitle => 'What\'s included';

  @override
  String bookingIncludedWaiting(int minutes) {
    return 'Up to $minutes minutes of complimentary waiting time';
  }

  @override
  String get bookingIncludedWater => 'Free waiting included: 60 min at the airport, 15 in the city';

  @override
  String get bookingLoadErrorTitle => 'We couldn\'t load your booking';

  @override
  String get bookingLuggage => 'Luggage';

  @override
  String bookingLuggageCarryOn(int count) {
    return '$count × Carry-on';
  }

  @override
  String bookingLuggageChecked(int count) {
    return '$count × Standard checked';
  }

  @override
  String bookingLuggageExtraLarge(int count) {
    return '$count × Extra large';
  }

  @override
  String get bookingNotFound => 'This booking is no longer available.';

  @override
  String get bookingNoteCapacity => 'Passenger and luggage limits must be respected for safety reasons. If they are exceeded, the chauffeur may decline the service.';

  @override
  String get bookingNoteExtras => 'Additional needs (wheelchair, child seat, extra items) can be added in \"Pickup notes\". Choose Business Van for larger groups or extra luggage.';

  @override
  String get bookingNoteImages => 'Vehicle images are for reference only. The actual vehicle may vary, always of equal or higher quality.';

  @override
  String get bookingPassengers => 'Passengers';

  @override
  String bookingPassengersAndBags(String passengers, String bags) {
    return '$passengers · $bags';
  }

  @override
  String get bookingPayOnTripBody => 'You pay the fixed price to your chauffeur in cash or by QR code. Nothing is charged when you book.';

  @override
  String get bookingPayOnTripTitle => 'Pay at the end of your journey';

  @override
  String get bookingPaymentFailed => 'The payment didn\'t go through';

  @override
  String get bookingPaymentMethodHeading => 'PAYMENT METHOD';

  @override
  String bookingPickupInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Pickup in $days days',
      one: 'Pickup in 1 day',
    );
    return '$_temp0';
  }

  @override
  String bookingPickupInHours(int hours) {
    return 'Pickup in $hours h';
  }

  @override
  String bookingPickupInHoursMinutes(int hours, int minutes) {
    return 'Pickup in $hours h $minutes min';
  }

  @override
  String bookingPickupInMinutes(int minutes) {
    return 'Pickup in $minutes min';
  }

  @override
  String get bookingPickupLabel => 'Pickup';

  @override
  String get bookingPleaseNote => 'Please note:';

  @override
  String get bookingPriceBreakdownTitle => 'Price breakdown';

  @override
  String bookingPriceConfirmedBody(String price) {
    return 'The fixed price for your journey is $price. It won\'t change, whatever the traffic.';
  }

  @override
  String get bookingPriceConfirmedTitle => 'Price confirmed';

  @override
  String bookingReference(String code) {
    return 'Booking reference: $code';
  }

  @override
  String bookingReserveCta(String vehicle) {
    return 'BOOK $vehicle';
  }

  @override
  String get bookingReturnTooEarly => 'The return must be after the outbound pickup.';

  @override
  String get bookingReturnTrip => 'Book the return trip';

  @override
  String get bookingReturnWhen => 'When should we pick you up for the return?';

  @override
  String get bookingRoutePreview => 'Route preview';

  @override
  String get bookingSeating => 'Seating';

  @override
  String get bookingSeatingFive => 'Five passengers';

  @override
  String get bookingSeatingInfantSeat => 'Infant seat';

  @override
  String get bookingSeatingInfo => 'Choose the seating layout that best suits your needs. Child and infant seats must be requested in advance and are subject to availability.';

  @override
  String get bookingSeatingThree => 'Three passengers';

  @override
  String get bookingSeatingTwo => 'Two passengers';

  @override
  String bookingSeatsUpTo(int count) {
    return 'Seats up to $count';
  }

  @override
  String get bookingSelectRouteError => 'Please choose a pickup point and a destination';

  @override
  String get bookingSelectedBadge => 'SELECTED';

  @override
  String get bookingSlideBusiness1 => 'Executive comfort on every journey';

  @override
  String get bookingSlideBusiness2 => 'Punctual, professional and perfectly refined';

  @override
  String get bookingSlideBusiness3 => 'Arrive with confidence, every time';

  @override
  String get bookingSlideBusiness4 => 'Premium made practical for the modern executive';

  @override
  String get bookingSlideElectric1 => 'Fully electric, whisper-quiet and executive-class';

  @override
  String get bookingSlideElectric2 => 'Zero emissions, the ultimate luxury experience';

  @override
  String get bookingSlideFirst1 => 'An extraordinary level of luxury awaits';

  @override
  String get bookingSlideFirst2 => 'Designed for those who expect the very best';

  @override
  String get bookingSlideFirst3 => 'Privacy and elegance on every transfer';

  @override
  String get bookingSlideFirst4 => 'First class, door to door';

  @override
  String get bookingSlideVan1 => 'Space and comfort for your whole team';

  @override
  String get bookingSlideVan2 => 'Stress-free, punctual group transfers';

  @override
  String get bookingSlideVan3 => 'The perfect ride for families and groups';

  @override
  String get bookingSlideVan4 => 'Premium capacity, with no compromise on comfort';

  @override
  String get bookingSpecialRequests => 'Special requests';

  @override
  String get bookingSpecialRequestsHint => 'Child seat, name sign…';

  @override
  String get bookingStepDetails => 'Details';

  @override
  String bookingStepOf(int step, int total) {
    return 'STEP $step OF $total';
  }

  @override
  String get bookingStepVehicle => 'Vehicle';

  @override
  String get bookingSummaryDistance => 'Distance';

  @override
  String get bookingSummaryDuration => 'Duration';

  @override
  String get bookingSummaryEstDuration => 'Est. duration';

  @override
  String get bookingSummaryFlight => 'Flight';

  @override
  String get bookingSummaryFrom => 'From';

  @override
  String get bookingSummaryHeading => 'BOOKING SUMMARY';

  @override
  String get bookingSummaryNotes => 'Notes';

  @override
  String get bookingSummaryService => 'Service';

  @override
  String get bookingSummaryTo => 'To';

  @override
  String get bookingTripDetailsHeading => 'TRIP DETAILS';

  @override
  String get bookingViewMyBooking => 'VIEW MY BOOKING';

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
  String get coreClearField => 'Clear';

  @override
  String get coreConfirmBooking => 'Confirm booking';

  @override
  String get coreDriverLocationNotification => 'Sharing your location while you\'re available';

  @override
  String get coreErrorBody => 'We\'ve been notified and are working on a fix.';

  @override
  String get coreErrorTitle => 'Something went wrong';

  @override
  String get coreFixedPrice => 'Fixed price';

  @override
  String coreHoursTotal(int hours) {
    return '$hours h total';
  }

  @override
  String get coreMapKeyMissing => 'Add GOOGLE_MAPS_KEY to enable the map';

  @override
  String get coreMapPickerHint => 'Move the map to select a location';

  @override
  String get coreMapPickerSelected => 'Selected location';

  @override
  String get coreMapPickerTitle => 'Select location';

  @override
  String get coreMapView => 'Map view';

  @override
  String get coreRoleAdmin => 'Admin';

  @override
  String get coreRoleDriver => 'Chauffeur';

  @override
  String get coreRoleRider => 'Passenger';

  @override
  String coreVehicleCapacity(int count) {
    return 'Up to $count';
  }

  @override
  String get corpAddCostCenter => 'Add cost center';

  @override
  String get corpAddMember => 'Add member';

  @override
  String get corpAddMemberAction => 'Add';

  @override
  String get corpAddMemberHint => 'They\'ll be able to bill rides to the company. If they don\'t have an account yet, they join when they sign up with this e-mail.';

  @override
  String get corpAdminEmail => 'Admin\'s e-mail';

  @override
  String get corpAdminEmailHint => 'If they don\'t have an account yet, they join when they sign up with this e-mail.';

  @override
  String get corpAdminEmpty => 'No companies yet.';

  @override
  String get corpAdminIntro => 'Companies get a monthly invoice for their members\' rides. Each company\'s admin manages members and cost centers from their portal.';

  @override
  String get corpAdminTitle => 'Corporate accounts';

  @override
  String get corpBillCompanyHint => 'Monthly invoice to the company';

  @override
  String corpBillCompanyNotice(String company) {
    return 'This ride goes on $company\'s monthly invoice. You don\'t pay the chauffeur anything.';
  }

  @override
  String get corpBillPersonal => 'Personal';

  @override
  String get corpBillPersonalHint => 'You pay for it';

  @override
  String get corpBillTo => 'Bill to';

  @override
  String corpBilledTo(String company) {
    return 'Billed to $company';
  }

  @override
  String get corpBillingDetails => 'Billing details';

  @override
  String get corpBillingEmail => 'Billing e-mail';

  @override
  String get corpByCostCenter => 'By cost center';

  @override
  String get corpByTraveler => 'By person';

  @override
  String get corpCancelInvite => 'Cancel invite';

  @override
  String get corpColAmount => 'Amount (Bs)';

  @override
  String get corpColBookedBy => 'Booked by';

  @override
  String get corpColDate => 'Date';

  @override
  String get corpColFrom => 'From';

  @override
  String get corpColPassenger => 'Passenger';

  @override
  String get corpColTo => 'To';

  @override
  String get corpColVehicle => 'Vehicle';

  @override
  String get corpCompanyCreated => 'Company created';

  @override
  String get corpCompanyName => 'Company name';

  @override
  String get corpCostCenter => 'Cost center';

  @override
  String get corpCostCenterNone => 'None';

  @override
  String get corpCostCenterOptional => 'Cost center (optional)';

  @override
  String get corpCostCenterRequired => 'Cost center (required)';

  @override
  String get corpCostCenters => 'Cost centers';

  @override
  String get corpCostCentersHint => 'They show up when booking so each ride is assigned to a department or project.';

  @override
  String get corpCreate => 'Create';

  @override
  String get corpCreateCompany => 'New company';

  @override
  String corpDriverNoCollect(String company) {
    return 'Corporate account ($company): don\'t collect from the passenger.';
  }

  @override
  String get corpEmail => 'E-mail';

  @override
  String get corpErrorCompanyInactive => 'The corporate account is suspended.';

  @override
  String get corpErrorCostCenterRequired => 'Choose a cost center to bill the company.';

  @override
  String get corpErrorCostCentersEmpty => 'Add at least one cost center before requiring it.';

  @override
  String get corpErrorInvalidEmail => 'Check the e-mail address.';

  @override
  String get corpErrorInvalidName => 'Enter the company name.';

  @override
  String get corpErrorInvalidTaxId => 'The tax ID must be 5–15 digits.';

  @override
  String get corpErrorLastAdmin => 'The company needs at least one admin.';

  @override
  String get corpErrorNotARider => 'That account belongs to a chauffeur or an admin; only passengers can be members.';

  @override
  String get corpErrorNotAllowed => 'You can\'t bill this ride to the company. Choose personal payment.';

  @override
  String get corpErrorOtherCompany => 'That person already belongs to another company.';

  @override
  String get corpExportCsv => 'Export detail (CSV)';

  @override
  String get corpFormerMember => 'Former member';

  @override
  String get corpInviteCancelled => 'Invite cancelled';

  @override
  String corpKpiCancelled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cancellations in total',
      one: '1 cancellation in total',
      zero: 'No cancellations',
    );
    return '$_temp0';
  }

  @override
  String get corpKpiCompleted => 'Completed rides';

  @override
  String get corpKpiLateCancellations => 'Late cancellations';

  @override
  String get corpKpiToInvoice => 'To be invoiced';

  @override
  String get corpKpiToInvoiceHint => 'Completed rides this month';

  @override
  String get corpKpiUpcoming => 'Upcoming or in progress';

  @override
  String get corpMakeAdmin => 'Make admin';

  @override
  String get corpMakeMember => 'Remove admin rights';

  @override
  String get corpMemberActions => 'Member options';

  @override
  String get corpMemberAdded => 'Done. If they already had an account they were added; otherwise they\'ll join when they sign up.';

  @override
  String get corpMemberRemoved => 'Member removed';

  @override
  String get corpMemberUpdated => 'Permissions updated';

  @override
  String get corpMembers => 'Members';

  @override
  String get corpNewCostCenter => 'New cost center';

  @override
  String get corpNextMonth => 'Next month';

  @override
  String get corpNoAccess => 'Only the company\'s admins can see this portal.';

  @override
  String get corpNoCostCenter => 'No cost center';

  @override
  String get corpNoMembers => 'No members yet.';

  @override
  String get corpNoRidesMonth => 'No rides billed to the company this month.';

  @override
  String get corpOpenPortal => 'Open portal';

  @override
  String get corpPendingInvites => 'Pending invites';

  @override
  String get corpPendingInvitesHint => 'They\'ll join when they create their account with these e-mails.';

  @override
  String get corpPortalTitle => 'Corporate account';

  @override
  String get corpPrevMonth => 'Previous month';

  @override
  String get corpProfileAdminHint => 'You manage this account: statement, members and settings';

  @override
  String get corpProfileMemberHint => 'You can bill your rides to the company';

  @override
  String get corpProfileSection => 'Corporate account';

  @override
  String get corpReactivate => 'Reactivate account';

  @override
  String get corpReactivated => 'Account reactivated';

  @override
  String get corpReference => 'Reference';

  @override
  String get corpReferenceHint => 'Project, purchase order, client…';

  @override
  String get corpRemoveCostCenter => 'Remove';

  @override
  String get corpRemoveMember => 'Remove from company';

  @override
  String corpRemoveMemberBody(String name) {
    return '$name will no longer be able to bill rides to the company. Their past rides stay on the statement.';
  }

  @override
  String get corpRequireCostCenter => 'Require a cost center';

  @override
  String get corpRequireCostCenterHint => 'Company bookings can\'t be made without choosing one.';

  @override
  String get corpRidesOfMonth => 'Rides this month';

  @override
  String get corpRoleAdmin => 'Admin';

  @override
  String get corpRoleMember => 'Member';

  @override
  String corpRoute(String from, String to) {
    return '$from → $to';
  }

  @override
  String get corpSave => 'Save changes';

  @override
  String get corpSettingsSaved => 'Changes saved';

  @override
  String get corpSuspend => 'Suspend account';

  @override
  String get corpSuspended => 'Account suspended';

  @override
  String get corpSuspendedBanner => 'This account is suspended: members can\'t bill rides to the company. Contact us to reactivate it.';

  @override
  String get corpSuspendedShort => 'Account suspended';

  @override
  String get corpTabMembers => 'Members';

  @override
  String get corpTabSettings => 'Settings';

  @override
  String get corpTabStatement => 'Statement';

  @override
  String get corpTaxId => 'Tax ID (NIT)';

  @override
  String corpTaxIdShort(String taxId) {
    return 'Tax ID $taxId';
  }

  @override
  String docApprovedCount(int approved, int total) {
    return '$approved of $total approved';
  }

  @override
  String docBannerExpiring(String doc) {
    return 'Your $doc expires soon. Upload the renewed one.';
  }

  @override
  String get docBannerInReview => 'We\'re reviewing your documents. We\'ll let you know once approved.';

  @override
  String docBannerToUpload(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents missing before you can receive rides.',
      one: '1 document missing before you can receive rides.',
    );
    return '$_temp0';
  }

  @override
  String get docCriminalRecord => 'Criminal record certificate';

  @override
  String get docCriminalRecordHint => 'REJAP or FELCC, issued in the last 3 months';

  @override
  String get docErrorAlreadyExpired => 'That document has already expired.';

  @override
  String get docErrorExpiryRequired => 'Enter the expiry date.';

  @override
  String get docErrorFailed => 'That didn\'t work. Please try again.';

  @override
  String get docErrorReasonRequired => 'Enter the reason for rejecting it.';

  @override
  String get docErrorTooLarge => 'The file is larger than 10 MB.';

  @override
  String docExpiredOn(String date) {
    return 'Expired $date';
  }

  @override
  String docExpiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String docExpiryPickerTitle(String doc) {
    return 'When does your $doc expire?';
  }

  @override
  String get docIdCard => 'ID card';

  @override
  String get docIdCardHint => 'Both sides, readable';

  @override
  String get docLicense => 'Driver\'s license';

  @override
  String get docLicenseHint => 'Professional category, both sides';

  @override
  String docPendingCount(int count) {
    return '$count in review';
  }

  @override
  String get docPendingHint => 'We usually review it within 24 hours.';

  @override
  String get docPrivacyNote => 'Only the Luxelane team sees your documents, to verify you. They\'re deleted if you delete your account.';

  @override
  String get docProfileLink => 'My documents and verification';

  @override
  String docRejectedReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get docReplace => 'Replace';

  @override
  String get docReviewAction => 'Review documents';

  @override
  String get docReviewAllApproved => 'All documents are approved and current.';

  @override
  String get docReviewApprove => 'Approve';

  @override
  String get docReviewApproved => 'Document approved';

  @override
  String get docReviewConfirmExpiry => 'Confirm the expiry date';

  @override
  String get docReviewOpen => 'Open file';

  @override
  String get docReviewReject => 'Reject';

  @override
  String get docReviewRejectReason => 'Reason';

  @override
  String get docReviewRejectReasonHint => 'E.g. the photo is blurry';

  @override
  String get docReviewRejectTitle => 'Reject document';

  @override
  String get docReviewRejected => 'Document rejected; the chauffeur was notified';

  @override
  String docReviewTitle(String name) {
    return '$name\'s documents';
  }

  @override
  String get docSoat => 'SOAT insurance';

  @override
  String get docSoatHint => 'The vehicle\'s current mandatory insurance';

  @override
  String get docStatusApproved => 'Approved';

  @override
  String get docStatusExpired => 'Expired';

  @override
  String get docStatusExpiring => 'Expiring';

  @override
  String get docStatusMissing => 'Missing';

  @override
  String get docStatusPending => 'In review';

  @override
  String get docStatusRejected => 'Rejected';

  @override
  String get docSummaryBody => 'To receive rides we review and approve these documents. Upload clear photos or PDFs; we\'ll let you know once they\'re reviewed.';

  @override
  String get docSummaryTitle => 'Verification pending';

  @override
  String get docSummaryVerified => 'Verified chauffeur';

  @override
  String get docSummaryVerifiedBody => 'All your documents are approved. We\'ll remind you 30 and 7 days before any of them expires.';

  @override
  String get docTitle => 'Documents';

  @override
  String docToUploadCount(int count) {
    return '$count to upload';
  }

  @override
  String get docUpload => 'Upload';

  @override
  String get docUploaded => 'Document sent for review';

  @override
  String docUploadedOn(String date) {
    return 'Uploaded $date';
  }

  @override
  String get docVehicleRegistration => 'Vehicle registration (RUAT)';

  @override
  String get docVehicleRegistrationHint => 'Ownership certificate or RUAT in your name or authorised';

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
  String get healthAlertsNote => 'Admins get a notification when a booking has no chauffeur 30 minutes before pickup, and when no chauffeur is online with bookings coming up (at most once an hour).';

  @override
  String healthBuildInfo(String env, String version) {
    return 'Environment: $env · version $version';
  }

  @override
  String get healthEnvDev => 'development';

  @override
  String get healthEnvProd => 'production';

  @override
  String get healthErrors24h => 'Distinct errors in 24 h';

  @override
  String get healthErrorsNote => 'Grouped: the same error from many users appears once with its count. Android and iOS errors are in Firebase Crashlytics.';

  @override
  String get healthErrorsTitle => 'Web app errors';

  @override
  String get healthHideResolved => 'Hide resolved';

  @override
  String healthLastSeen(String date) {
    return 'last: $date';
  }

  @override
  String get healthMarkResolved => 'Mark resolved';

  @override
  String healthMonitorOk(String time) {
    return 'Monitor running · last check at $time';
  }

  @override
  String get healthMonitorStale => 'The monitor hasn\'t reported for over 15 minutes. Check that the Cloud Functions are deployed.';

  @override
  String get healthNeedsAttention => 'Needs attention';

  @override
  String get healthNoErrors => 'No pending errors.';

  @override
  String healthOccurrences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get healthOnlineDrivers => 'Verified chauffeurs online';

  @override
  String get healthPendingNext2h => 'Bookings in the next 2 h';

  @override
  String get healthReopen => 'Reopen';

  @override
  String get healthShowResolved => 'Show resolved';

  @override
  String get healthTitle => 'System health';

  @override
  String get healthUnassignedSoon => 'No chauffeur, pickup in < 30 min';

  @override
  String get healthUrgentTickets => 'Open safety reports';

  @override
  String get homeBarDateTime => 'Date & time';

  @override
  String get homeBarDestination => 'Destination';

  @override
  String get homeBarDestinationHint => 'Where to?';

  @override
  String get homeBarDuration => 'Duration';

  @override
  String get homeBarPickup => 'Pickup';

  @override
  String get homeBarPickupHint => 'Where are you?';

  @override
  String get homeBarSeeOptions => 'See options';

  @override
  String get homeBookBulletAdvance => 'Book ahead';

  @override
  String get homeBookBulletDirectContact => 'Direct contact with your chauffeur';

  @override
  String get homeBookBulletFixedPrice => 'Fixed price, always';

  @override
  String get homeBookBulletFlightTracking => 'Flight tracking';

  @override
  String get homeBookBulletFreeWait => 'Free waiting included';

  @override
  String get homeBookBulletGuests => 'Bookings for guests';

  @override
  String get homeBookBulletMeetGreet => 'Meet & greet with a name sign';

  @override
  String get homeBookBulletReceipts => 'A receipt for every ride';

  @override
  String get homeBookBulletTracking => 'Real-time tracking';

  @override
  String get homeBookBusinessSub => 'Corporate travel, redefined';

  @override
  String get homeBookCoverSubtitle => 'Premium chauffeur service';

  @override
  String get homeBookExperienceBody => 'From the airport to your door: we track your flight, your chauffeur meets you with a name sign, and waiting time is included — 60 min at the airport, 15 in the city.';

  @override
  String get homeBookExperienceHeadline => 'Every detail,\ntaken care of.';

  @override
  String get homeBookExperienceLabel => 'The experience';

  @override
  String get homeBookExperienceSub => 'Every detail considered';

  @override
  String get homeBookEyebrow => 'Our signature experience';

  @override
  String get homeBookRide => 'Book a ride';

  @override
  String get homeBookScrollCue => 'Scroll';

  @override
  String get homeBookStandardBody => 'Every chauffeur is vetted by our team: we review their license, documents and vehicle before their first ride.';

  @override
  String get homeBookStandardHeadline => 'The standard\nothers follow.';

  @override
  String get homeBookStandardLabel => 'The standard';

  @override
  String get homeBookStandardSub => 'The promise we keep';

  @override
  String get homeBookStandardTag => 'The Luxelane standard';

  @override
  String get homeBusinessBody => 'Book for your team and your guests with fixed prices in bolivianos, live tracking and a receipt for every ride.';

  @override
  String get homeBusinessEyebrow => 'For business';

  @override
  String get homeBusinessLearnMore => 'Learn more';

  @override
  String get homeBusinessPerkFixedPrice => 'Fixed price confirmed before booking';

  @override
  String get homeBusinessPerkFlights => 'Flight tracking with adjusted pickup';

  @override
  String get homeBusinessPerkGuests => 'Bookings for guests and teams';

  @override
  String get homeBusinessPerkMeetGreet => 'Meet & greet with a name sign at the airport';

  @override
  String get homeBusinessPerkMonitoring => 'Live tracking of every ride';

  @override
  String get homeBusinessPerkReceipts => 'A receipt for every ride in the app';

  @override
  String get homeBusinessTitle => 'Corporate travel,\nredefined.';

  @override
  String get homeCtaEyebrow => 'Whenever you want. Wherever you go.';

  @override
  String get homeCtaHighlights => 'Fixed price  ·  Vetted chauffeurs  ·  Advance booking';

  @override
  String get homeCtaTitle => 'Your next ride,\n<i>on your terms.</i>';

  @override
  String get homeCtaViewFleet => 'View the fleet';

  @override
  String homeDateTimeShort(String date, String time) {
    return '$date, $time';
  }

  @override
  String get homeErrorDestinationRequired => 'Enter a destination';

  @override
  String get homeErrorPickupRequired => 'Enter a pickup location';

  @override
  String get homeFleetEyebrow => 'Our fleet';

  @override
  String get homeFleetModelVan => 'Mercedes V-Class or similar';

  @override
  String get homeFleetSwipeHint => 'Swipe to explore →';

  @override
  String get homeFleetTagExtraLuggage => 'Extra luggage space';

  @override
  String get homeFleetTagFixedPrice => 'Fixed price';

  @override
  String get homeFleetTagGroups => 'Ideal for groups';

  @override
  String get homeFleetTagTracking => 'Live tracking';

  @override
  String get homeFleetTagVerified => 'Vetted chauffeur';

  @override
  String get homeFleetTitle => 'Premium vehicles,\nno exceptions.';

  @override
  String get homeFooterContact => 'Contact';

  @override
  String homeFooterCopyright(String year) {
    return '© $year Luxelane. All rights reserved.';
  }

  @override
  String get homeFooterPrivacy => 'Privacy';

  @override
  String get homeFooterTerms => 'Terms';

  @override
  String get homeFormPickupHint => 'Street, neighborhood, airport…';

  @override
  String get homeFormPickupLabel => 'Pickup location';

  @override
  String get homeHeroTitle => 'Your chauffeur <i>awaits.</i>';

  @override
  String homeHoursShort(int hours) {
    return '$hours h';
  }

  @override
  String get homeHowItWorksEyebrow => 'How it works';

  @override
  String get homeLocateMe => 'Use my location';

  @override
  String get homeMapChangeLocation => 'Change location';

  @override
  String get homeMarqueeAirportTransfers => 'Airport transfers';

  @override
  String get homeMarqueeBookInMinutes => 'Book in minutes';

  @override
  String get homeMarqueeCorporateTravel => 'Corporate travel';

  @override
  String get homeMarqueeFixedPrices => 'Fixed prices in Bs';

  @override
  String get homeMarqueeFreeWait => 'Free waiting';

  @override
  String get homeMarqueeHourly => 'Chauffeur by the hour';

  @override
  String get homeMarqueePremiumFleet => 'Premium fleet';

  @override
  String get homeNavBusiness => 'For business';

  @override
  String get homeNavFleet => 'Fleet';

  @override
  String get homeNavServices => 'Services';

  @override
  String get homePickDestinationTitle => 'Choose destination';

  @override
  String get homePickPickupTitle => 'Choose pickup location';

  @override
  String get homePromiseCancelBody => 'Cancel at no cost up to 1 hour before pickup, right from the app.';

  @override
  String get homePromiseCancelTitle => 'Free cancellation';

  @override
  String homePromiseFixedPriceBody(int airportMinutes, int cityMinutes) {
    return 'See your final price before you book, with no traffic surcharges. Includes $airportMinutes min of waiting time at the airport and $cityMinutes in the city.';
  }

  @override
  String get homePromiseFixedPriceTitle => 'Fixed price in Bs';

  @override
  String get homePromiseTrackingBody => 'Follow your chauffeur on the map and get notified when they\'re on the way and when they arrive.';

  @override
  String get homePromiseTrackingTitle => 'Live tracking';

  @override
  String get homePromiseVerifiedBody => 'Every license and document is reviewed by our team before their first ride.';

  @override
  String get homePromiseVerifiedTitle => 'Vetted chauffeurs';

  @override
  String homeRouteSummary(String distance, String duration) {
    return '$distance km · $duration';
  }

  @override
  String get homeSearchVehicles => 'Find vehicles';

  @override
  String get homeServiceAirportTransfer => 'Airport transfers';

  @override
  String get homeServiceHotels => 'Hotel transfers';

  @override
  String get homeServiceHourly => 'Chauffeur by the hour';

  @override
  String get homeServiceImmediatePickup => 'On-demand pickup';

  @override
  String get homeServiceIntercity => 'City to city';

  @override
  String get homeShellMyTrips => 'My trips';

  @override
  String get homeShellSignIn => 'Sign in';

  @override
  String get homeShellSignOut => 'Sign out';

  @override
  String get homeShellTabHome => 'Home';

  @override
  String get homeShellTabProfile => 'Profile';

  @override
  String get homeShellTabTrips => 'Trips';

  @override
  String get homeStepBookBody => 'Choose your pickup, destination, date and vehicle class.';

  @override
  String get homeStepBookTitle => 'Book in a minute';

  @override
  String get homeStepChauffeurBody => 'Get your chauffeur\'s details and follow them in real time.';

  @override
  String get homeStepChauffeurTitle => 'Your chauffeur awaits';

  @override
  String get homeStepPriceBody => 'We show you the final price in bolivianos. That\'s exactly what you pay.';

  @override
  String get homeStepPriceTitle => 'Confirm your fixed price';

  @override
  String get homeTrustEyebrow => 'The Luxelane promise';

  @override
  String get homeTrustTitle => 'Travel with confidence,\nfrom start to finish.';

  @override
  String get hotelAdminAdd => 'Add hotel';

  @override
  String get hotelAdminAddress => 'Address';

  @override
  String get hotelAdminAddressHint => 'Search for the hotel';

  @override
  String get hotelAdminCopyLink => 'Copy link';

  @override
  String get hotelAdminEdit => 'Edit';

  @override
  String hotelAdminEditTitle(String name) {
    return 'Edit $name';
  }

  @override
  String get hotelAdminEmpty => 'No partner hotels yet. The public page says they\'re coming soon.';

  @override
  String get hotelAdminHidden => 'Hidden';

  @override
  String get hotelAdminHide => 'Hide from the page';

  @override
  String get hotelAdminIntro => 'Visible hotels appear on the hotel transfers page. Each one has a link for a QR code at reception: it opens the page with that hotel already chosen. To bill transfers to the hotel, create a company account for it.';

  @override
  String get hotelAdminLinkCopied => 'Link copied. You can turn it into a QR code.';

  @override
  String get hotelAdminMeetingPoint => 'Meeting point (optional)';

  @override
  String get hotelAdminMeetingPointHint => 'E.g. Main lobby';

  @override
  String get hotelAdminName => 'Hotel name';

  @override
  String get hotelAdminSave => 'Save';

  @override
  String get hotelAdminSaved => 'Hotel saved';

  @override
  String get hotelAdminShow => 'Show on the page';

  @override
  String get hotelAdminTitle => 'Partner hotels';

  @override
  String get hotelAdminVisible => 'Visible';

  @override
  String get hotelErrorMeetingPoint => 'The meeting point allows up to 120 characters.';

  @override
  String get hotelErrorName => 'Enter the hotel\'s name (up to 80 characters).';

  @override
  String get hotelErrorPlace => 'Choose the hotel\'s address from the list.';

  @override
  String get hotelEyebrow => 'Hotel transfers';

  @override
  String get hotelFromAirport => 'From the airport';

  @override
  String hotelFromAirportHint(int minutes) {
    return 'Enter your flight\'s arrival time and, in the next step, the flight number: we track it and waiting is free for up to $minutes min after landing.';
  }

  @override
  String get hotelHomeLink => 'Hotel transfers';

  @override
  String hotelIncFlightBody(int minutes) {
    return 'Arriving at the airport? We track your flight: free waiting up to $minutes min after landing.';
  }

  @override
  String get hotelIncFlightTitle => 'Flight tracking';

  @override
  String get hotelIncLobbyBody => 'Your chauffeur waits at the meeting point agreed with the hotel.';

  @override
  String get hotelIncLobbyTitle => 'Pickup at the hotel';

  @override
  String get hotelIntro => 'Private transfers between our partner hotels and Viru Viru International Airport. Choose your hotel, direction and time; the price is fixed before you confirm.';

  @override
  String hotelLandingAt(String when) {
    return 'Flight arrival: $when';
  }

  @override
  String hotelMeetingPoint(String place) {
    return 'Meeting point: $place';
  }

  @override
  String get hotelMeetingPointLabel => 'Meeting point';

  @override
  String get hotelNoneBody => 'Meanwhile, you can book a transfer to or from any hotel with a regular booking.';

  @override
  String get hotelNoneTitle => 'Our partner hotels are coming soon';

  @override
  String get hotelOtherHotel => 'Another hotel or address';

  @override
  String get hotelPartnerCta => 'Own a hotel? Contact us';

  @override
  String hotelPickupAt(String when) {
    return 'Pickup: $when';
  }

  @override
  String get hotelTitle => 'From hotel to airport, without a second thought';

  @override
  String get hotelToAirport => 'To the airport';

  @override
  String get hotelToAirportHint => 'Your chauffeur picks you up at the hotel at the time you choose. For domestic flights leave about 2 h before; for international, about 3 h.';

  @override
  String get intercityBuenaVista => 'Gateway to Amboró National Park';

  @override
  String intercityCardMeta(String km, String price) {
    return '≈ $km km · from $price';
  }

  @override
  String get intercityCochabamba => 'The valley city';

  @override
  String get intercityConcepcion => 'Jesuit Missions of Chiquitos';

  @override
  String get intercityContinue => 'See vehicles and price';

  @override
  String get intercityEstimateNote => 'Estimated distance and price from the city centre in Business. The final price uses your real address and is fixed when you book.';

  @override
  String get intercityEyebrow => 'City to city';

  @override
  String get intercityFormEyebrow => 'Private trip';

  @override
  String intercityFormTitle(String city) {
    return 'To $city';
  }

  @override
  String get intercityHomeLink => 'Trips to other cities';

  @override
  String get intercityIncChauffeurBody => 'With license, criminal record and SOAT reviewed and current.';

  @override
  String get intercityIncChauffeurTitle => 'Verified chauffeur';

  @override
  String get intercityIncFixedBody => 'You see and confirm it before booking; it doesn\'t change on the way.';

  @override
  String get intercityIncFixedTitle => 'Fixed price';

  @override
  String get intercityIncTrackingBody => 'See where your chauffeur is and how long until you arrive.';

  @override
  String get intercityIncTrackingTitle => 'Live tracking';

  @override
  String get intercityIncludedTitle => 'On every trip';

  @override
  String get intercityIntro => 'We pick you up wherever you are and take you door to door, with the price fixed before you leave. Choose a destination to start.';

  @override
  String get intercityMontero => 'Santa Cruz\'s northern hub';

  @override
  String get intercityOtherDestination => 'Another destination? Enter it on the home page';

  @override
  String get intercityPickupRequired => 'Tell us where to pick you up.';

  @override
  String get intercitySamaipata => 'Valleys and El Fuerte, a World Heritage Site';

  @override
  String get intercitySanJose => 'Jesuit Missions of Chiquitos';

  @override
  String get intercityTimeInPast => 'Choose a future date and time.';

  @override
  String get intercityTitle => 'Private trips from Santa Cruz';

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
  String get loyaltyAdminIntro => 'Tiered loyalty program based on rides completed in the last 12 months. Each tier gives a discount on the fare. You decide the thresholds and percentages.';

  @override
  String get loyaltyAdminTitle => 'Luxelane Circle';

  @override
  String loyaltyBenefit(String pct) {
    return 'You get $pct % off every ride.';
  }

  @override
  String get loyaltyDisabledHint => 'Off: no one sees the program or gets discounts.';

  @override
  String loyaltyDiscountLine(String tier) {
    return 'Circle $tier discount';
  }

  @override
  String get loyaltyDiscountPct => 'Discount %';

  @override
  String get loyaltyEnable => 'Program active';

  @override
  String get loyaltyEnabledHint => 'Riders see their tier in their profile and the discount applies when quoting.';

  @override
  String get loyaltyErrorDiscounts => 'Each tier must give at least the same discount as the one before.';

  @override
  String get loyaltyErrorMinRides => 'Enter at least 1 ride for each tier.';

  @override
  String get loyaltyErrorRange => 'The discount must be between 0 and 20 %.';

  @override
  String get loyaltyErrorThresholds => 'Each tier must require more rides than the one before.';

  @override
  String get loyaltyGold => 'Gold';

  @override
  String get loyaltyHowItWorks => 'Rides completed in the last 12 months count. Doesn\'t stack with promo codes.';

  @override
  String get loyaltyMember => 'Member';

  @override
  String get loyaltyMinRides => 'Rides in 12 months';

  @override
  String get loyaltyNoBenefitYet => 'Complete rides to move up a tier and earn discounts.';

  @override
  String get loyaltyPlatinum => 'Platinum';

  @override
  String get loyaltyProgramName => 'Luxelane Circle';

  @override
  String get loyaltyRulesNote => 'The discount doesn\'t stack with a promo code: the larger of the two applies. Only completed rides count.';

  @override
  String get loyaltySave => 'Save';

  @override
  String get loyaltySaved => 'Loyalty program saved';

  @override
  String loyaltySavedLine(String amount, String tier) {
    return 'You save $amount as Circle $tier';
  }

  @override
  String get loyaltySilver => 'Silver';

  @override
  String loyaltyToNext(int count, String tier, String pct) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more rides to $tier ($pct %)',
      one: '1 more ride to $tier ($pct %)',
    );
    return '$_temp0';
  }

  @override
  String loyaltyTopTier(int rides) {
    String _temp0 = intl.Intl.pluralLogic(
      rides,
      locale: localeName,
      other: 'Top tier · $rides rides in 12 months',
      one: 'Top tier · 1 ride in 12 months',
    );
    return '$_temp0';
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
  String get paymentsAccountNotSetUp => 'Your account isn\'t set up for payments yet';

  @override
  String get paymentsAdd => 'Add';

  @override
  String get paymentsAddCard => 'Add card';

  @override
  String get paymentsAddMethodTitle => 'Add payment method';

  @override
  String get paymentsAddNewCard => 'Add new card';

  @override
  String get paymentsCardAdded => 'Card added successfully';

  @override
  String get paymentsCardDetails => 'Card details';

  @override
  String paymentsCardExpires(String month, String year) {
    return 'Expires $month/$year';
  }

  @override
  String get paymentsCardFallback => 'Card';

  @override
  String get paymentsCardIncomplete => 'Enter your full card details';

  @override
  String get paymentsDefault => 'Default';

  @override
  String get paymentsEmptyBody => 'Add a card to book rides';

  @override
  String get paymentsEmptyTitle => 'No payment methods';

  @override
  String get paymentsError => 'We couldn\'t complete that card operation. Please try again.';

  @override
  String get paymentsMethodsTitle => 'Payment methods';

  @override
  String get paymentsRemoveCard => 'Remove card';

  @override
  String get paymentsSavedCards => 'Saved cards';

  @override
  String get paymentsSecured => 'Secured by Stripe';

  @override
  String get paymentsSecuredPci => 'Secured by Stripe · PCI DSS compliant';

  @override
  String get paymentsSetDefault => 'Set default';

  @override
  String get profileContactHelp => 'Contact & help';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileLoadError => 'We couldn\'t load your profile';

  @override
  String get profileNameLabel => 'Name';

  @override
  String get profileSaveChanges => 'Save changes';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileSectionHelp => 'Help & legal';

  @override
  String get profileSectionStats => 'Stats';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileStatRating => 'Rating';

  @override
  String get profileStatTrips => 'Trips';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String profileVersion(String version) {
    return 'Luxelane v$version';
  }

  @override
  String get promoAdminActive => 'Active';

  @override
  String get promoAdminCap => 'Cap (Bs, optional)';

  @override
  String get promoAdminClasses => 'Vehicle classes (none selected = all)';

  @override
  String get promoAdminCode => 'Code';

  @override
  String get promoAdminCodeHint => 'E.g. WELCOME';

  @override
  String get promoAdminCreate => 'New code';

  @override
  String get promoAdminDescription => 'Internal description';

  @override
  String get promoAdminDescriptionHint => 'E.g. launch campaign';

  @override
  String get promoAdminEdit => 'Edit';

  @override
  String promoAdminEditTitle(String code) {
    return 'Edit $code';
  }

  @override
  String get promoAdminEmpty => 'No codes yet.';

  @override
  String get promoAdminErrorCode => 'The code must be 3–20 letters, digits, hyphens or underscores.';

  @override
  String get promoAdminErrorDates => 'The end date must be after the start date.';

  @override
  String get promoAdminErrorExists => 'A code with that name already exists.';

  @override
  String get promoAdminErrorValue => 'Check the discount: a percentage is 1–100 and an amount must be above 0.';

  @override
  String get promoAdminExhausted => 'Used up';

  @override
  String get promoAdminExpired => 'Expired';

  @override
  String get promoAdminFirstRide => 'First ride only';

  @override
  String get promoAdminFirstRideSwitch => 'Only for the passenger\'s first ride';

  @override
  String get promoAdminFixed => 'Fixed amount';

  @override
  String promoAdminFrom(String date) {
    return 'From $date';
  }

  @override
  String get promoAdminFromAny => 'From: today';

  @override
  String get promoAdminIntro => 'The discount is validated by the server and fixed in the booking price. If the booking is cancelled, the use is released.';

  @override
  String get promoAdminMaxUses => 'Total uses (empty = unlimited)';

  @override
  String promoAdminMinFare(String amount) {
    return 'Minimum $amount';
  }

  @override
  String get promoAdminMinFareLabel => 'Minimum fare (Bs, optional)';

  @override
  String get promoAdminPause => 'Pause';

  @override
  String get promoAdminPaused => 'Paused';

  @override
  String get promoAdminPerUser => 'Uses per passenger';

  @override
  String get promoAdminPercent => 'Percentage';

  @override
  String get promoAdminResume => 'Resume';

  @override
  String get promoAdminSave => 'Save';

  @override
  String get promoAdminSaved => 'Code saved';

  @override
  String get promoAdminTitle => 'Promo codes';

  @override
  String promoAdminUntil(String date) {
    return 'Until $date';
  }

  @override
  String get promoAdminUntilAny => 'Until: no end date';

  @override
  String promoAdminUsage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uses',
      one: '1 use',
      zero: 'Not used',
    );
    return '$_temp0';
  }

  @override
  String promoAdminUsageOf(int used, int max) {
    return '$used of $max uses';
  }

  @override
  String promoAdminValueCapped(String value, String cap) {
    return '$value (max $cap)';
  }

  @override
  String get promoAdminValueFixed => 'Discount (Bs)';

  @override
  String get promoAdminValuePercent => 'Discount (%)';

  @override
  String promoApplied(String code) {
    return 'Code $code applied';
  }

  @override
  String promoAppliedWithDiscount(String code, String amount) {
    return '$code: −$amount';
  }

  @override
  String get promoApply => 'Apply';

  @override
  String promoDiscountLine(String code) {
    return 'Discount $code';
  }

  @override
  String get promoErrorAlreadyUsed => 'You\'ve already used this code.';

  @override
  String get promoErrorExhausted => 'That code has reached its usage limit.';

  @override
  String get promoErrorExpired => 'That code has expired.';

  @override
  String get promoErrorFailed => 'We couldn\'t check the code. Please try again.';

  @override
  String get promoErrorFirstRideOnly => 'This code is only for your first ride.';

  @override
  String get promoErrorInvalid => 'That code doesn\'t exist or isn\'t active.';

  @override
  String get promoErrorMinFare => 'This ride doesn\'t reach the code\'s minimum fare.';

  @override
  String get promoErrorNoLongerValid => 'The code is no longer valid. Check the price and try again.';

  @override
  String get promoErrorNotStarted => 'That code isn\'t valid yet.';

  @override
  String get promoErrorVehicleClass => 'This code doesn\'t apply to this vehicle class.';

  @override
  String get promoFieldLabel => 'Promo code';

  @override
  String get promoLoyaltyBetter => 'Your Circle discount is larger than the code\'s, so we applied Circle.';

  @override
  String get promoRemove => 'Remove code';

  @override
  String promoSavedLine(String amount, String code) {
    return 'You save $amount with $code';
  }

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
  String get rideCancelBooking => 'Cancel booking';

  @override
  String get rideCancelChauffeurNotified => 'We will let your chauffeur know.';

  @override
  String get rideCancelConfirm => 'Yes, cancel';

  @override
  String get rideCancelDone => 'Your booking has been cancelled.';

  @override
  String get rideCancelFailed => 'We couldn’t cancel the booking. Please try again.';

  @override
  String get rideCancelFree => 'Cancellation is free: pickup is more than 1 hour away.';

  @override
  String get rideCancelKeep => 'Keep booking';

  @override
  String get rideCancelLate => 'Pickup is less than 1 hour away. Please review our terms on late cancellations.';

  @override
  String get rideCancelNotAllowed => 'This booking can no longer be cancelled in the app.';

  @override
  String get rideCancelTitle => 'Cancel this booking?';

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
  String get routerGoHome => 'Go home';

  @override
  String get routerNotFoundBody => 'The page you\'re looking for doesn\'t exist or has moved.';

  @override
  String get routerNotFoundTitle => 'Page not found';

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
  String settleChangedSincePaid(String amount) {
    return 'Changed since it was settled (then: $amount)';
  }

  @override
  String get settleColBalance => 'Balance (+ Luxelane pays)';

  @override
  String get settleColByDriver => 'Collected by chauffeur';

  @override
  String get settleColByLuxelane => 'Collected by Luxelane';

  @override
  String get settleColCommission => 'Commission';

  @override
  String get settleColGross => 'Ride total';

  @override
  String get settleCommissionEdit => 'Change';

  @override
  String get settleCommissionHelp => 'Percentage Luxelane keeps from each completed ride. It applies to the weeks you settle from now on; settled weeks keep the percentage they were settled with.';

  @override
  String settleCommissionIs(String pct) {
    return 'Luxelane commission: $pct % per ride';
  }

  @override
  String get settleCommissionLabel => 'Commission (%)';

  @override
  String get settleCommissionMissing => 'Luxelane\'s commission isn\'t set yet. Set it to calculate settlements.';

  @override
  String get settleCommissionRange => 'Enter a percentage between 0 and 50.';

  @override
  String get settleCommissionSaved => 'Commission saved';

  @override
  String get settleCommissionSet => 'Set';

  @override
  String get settleCommissionTitle => 'Luxelane commission';

  @override
  String settleDriverBreakdown(String gross, String pct, String commission) {
    return '$gross in rides − $pct % commission ($commission)';
  }

  @override
  String settleDriverEarnings(String amount) {
    return 'Your earnings: $amount';
  }

  @override
  String settleDriverGrossOnly(String amount) {
    return 'Your rides total: $amount';
  }

  @override
  String get settleDriverHow => 'What you collected in cash or QR is already yours: on those rides you owe the commission. On company or card rides, Luxelane pays you the fare minus commission.';

  @override
  String get settleDriverNoCommission => 'The commission isn\'t configured yet; you\'ll see your balance once it is.';

  @override
  String get settleDriverNoTrips => 'No completed rides.';

  @override
  String settleDriverOwes(String amount) {
    return 'The chauffeur owes $amount';
  }

  @override
  String settleDriverPays(String amount) {
    return 'You owe Luxelane $amount';
  }

  @override
  String settleDriverReceives(String amount) {
    return 'Luxelane pays you $amount';
  }

  @override
  String get settleDriverTitle => 'Weekly settlement';

  @override
  String get settleEven => 'Balance is zero';

  @override
  String get settleExport => 'Export week (CSV)';

  @override
  String get settleIntro => 'Weekly (Monday to Sunday). On rides the chauffeur collects (cash or QR), the chauffeur owes Luxelane the commission. On rides Luxelane collects (companies or card), Luxelane pays the chauffeur the fare minus commission. The balance says who pays whom.';

  @override
  String get settleLastWeek => 'Last week';

  @override
  String settleLuxelanePays(String amount) {
    return 'Luxelane pays $amount';
  }

  @override
  String get settleMarkPaid => 'Mark settled';

  @override
  String get settleNeedsCommission => 'Set the commission to see settlements.';

  @override
  String get settleNextWeek => 'Next week';

  @override
  String get settleNoTrips => 'No completed rides this week.';

  @override
  String get settlePaid => 'Settled';

  @override
  String settlePaidOn(String date) {
    return 'Settled on $date';
  }

  @override
  String get settlePrevWeek => 'Previous week';

  @override
  String get settleSave => 'Save';

  @override
  String get settleStatCommission => 'Luxelane commission';

  @override
  String get settleStatToCollect => 'Chauffeurs owe';

  @override
  String get settleStatToPay => 'Luxelane must pay';

  @override
  String get settleThisWeek => 'This week';

  @override
  String get settleTitle => 'Chauffeur settlements';

  @override
  String get settleUndo => 'Undo';

  @override
  String settleWeekRange(String from, String to) {
    return '$from – $to';
  }

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
  String get supportAdminEmpty => 'No requests in this view.';

  @override
  String get supportAdminTitle => 'Support requests';

  @override
  String get supportCatApp => 'The app';

  @override
  String get supportCatBilling => 'Payments and billing';

  @override
  String get supportCatChauffeur => 'The chauffeur';

  @override
  String get supportCatLostItem => 'Lost item';

  @override
  String get supportCatOther => 'Other';

  @override
  String get supportCatSafety => 'Safety';

  @override
  String get supportCatTrip => 'A trip';

  @override
  String get supportCategoryQuestion => 'What is it about?';

  @override
  String get supportContactBody => 'Write to us and a person from the Luxelane team will reply. We\'ll let you know when there\'s an answer.';

  @override
  String get supportContactTitle => 'Need help?';

  @override
  String get supportEmergencyNote => 'In an emergency, call 110 (Police) first.';

  @override
  String get supportFaqCancelA => 'Yes, from the trip in the app, until it starts. It\'s free if pickup is more than 1 hour away; later than that it counts as a late cancellation under our terms.';

  @override
  String get supportFaqCancelQ => 'Can I cancel a booking?';

  @override
  String get supportFaqChauffeursA => 'Before receiving rides, we review and approve their license, ID card, criminal record certificate, SOAT insurance and vehicle registration. If a document expires, they stop receiving rides until it\'s renewed.';

  @override
  String get supportFaqChauffeursQ => 'How are chauffeurs verified?';

  @override
  String get supportFaqCorporateA => 'Your company\'s admin adds you with your e-mail. When booking you choose \"Bill to company\", with a cost center and reference if needed. The company gets a monthly statement.';

  @override
  String get supportFaqCorporateQ => 'How does the corporate account work?';

  @override
  String get supportFaqLostA => 'Open the trip\'s receipt, tap \"Help with this trip\" and choose \"Lost item\". We\'ll contact the chauffeur and arrange the return with you.';

  @override
  String get supportFaqLostQ => 'I left something in the car';

  @override
  String get supportFaqPayA => 'The price in bolivianos is fixed when you book. You pay the chauffeur at the end of the trip, in cash or by QR. If your company has a corporate account, the ride goes on its monthly invoice and you pay nothing.';

  @override
  String get supportFaqPayQ => 'How do I pay?';

  @override
  String get supportFaqPromoA => 'Enter it when booking, before confirming. You\'ll see the discount right away and it\'s fixed in the price. If you cancel, you can use it again.';

  @override
  String get supportFaqPromoQ => 'How do I use a promo code?';

  @override
  String get supportFaqTitle => 'Frequently asked questions';

  @override
  String supportFaqWaitA(int airport, int city) {
    return 'At the airport, $airport free minutes from your flight\'s landing (we track it live). In the city, $city free minutes from the pickup time or from when the chauffeur arrives.';
  }

  @override
  String get supportFaqWaitQ => 'How long will the chauffeur wait?';

  @override
  String get supportFillFields => 'Fill in the subject and the message.';

  @override
  String get supportFilterAnswered => 'Waiting on customer';

  @override
  String supportFilterPending(int count) {
    return 'To answer ($count)';
  }

  @override
  String get supportFilterResolved => 'Resolved';

  @override
  String supportFromUser(String name, String role) {
    return '$name ($role)';
  }

  @override
  String get supportHelpCenter => 'Help center';

  @override
  String get supportHours24h => '24 hours';

  @override
  String get supportHoursAlways => 'Support every day, 24 hours';

  @override
  String get supportHoursClear => 'Remove hours';

  @override
  String supportHoursClosedUntil(String when) {
    return 'Outside hours: we\'ll answer from $when. You can still write to us.';
  }

  @override
  String supportHoursClosesAt(String time) {
    return 'Closes: $time';
  }

  @override
  String get supportHoursEdit => 'Edit';

  @override
  String get supportHoursErrorDays => 'Choose at least one day.';

  @override
  String get supportHoursErrorTimes => 'Closing time must be after opening time.';

  @override
  String get supportHoursEveryDay => 'Every day';

  @override
  String get supportHoursIntro => 'Days and hours the team answers requests, in Bolivia time. Shown in the help center, with a note when it\'s outside hours.';

  @override
  String get supportHoursMidnight => 'midnight';

  @override
  String get supportHoursOpenNow => 'We\'re answering now';

  @override
  String supportHoursOpensAt(String time) {
    return 'Opens: $time';
  }

  @override
  String get supportHoursSave => 'Save';

  @override
  String get supportHoursSaved => 'Hours saved';

  @override
  String get supportHoursSet => 'Set';

  @override
  String supportHoursSummary(String days, String times) {
    return 'Support: $days, $times (Bolivia time)';
  }

  @override
  String get supportHoursTitle => 'Support hours';

  @override
  String get supportHoursUnset => 'Not set: the app doesn\'t show any hours.';

  @override
  String supportLinkedTrip(String code) {
    return 'Linked to trip $code';
  }

  @override
  String get supportMessage => 'Message';

  @override
  String get supportMessageHint => 'Tell us what happened';

  @override
  String get supportMyRequests => 'My requests';

  @override
  String get supportNewRequest => 'New request';

  @override
  String get supportPickCategory => 'Choose an option.';

  @override
  String get supportReopen => 'Reopen';

  @override
  String get supportReopenedDone => 'Request reopened';

  @override
  String get supportResolve => 'It\'s solved';

  @override
  String get supportResolveTeam => 'Mark resolved';

  @override
  String get supportResolvedDone => 'Request resolved';

  @override
  String get supportResolvedHint => 'This request is resolved. Writing again reopens it.';

  @override
  String get supportSafetyNote => 'Safety reports are handled first. If you\'re in danger now, call 110.';

  @override
  String get supportSend => 'Send';

  @override
  String get supportSendFailed => 'Couldn\'t send. Check your connection and try again.';

  @override
  String get supportSent => 'Request sent. We\'ll let you know when we reply.';

  @override
  String get supportStatusAnswered => 'Answered';

  @override
  String get supportStatusAnsweredTeam => 'Waiting on customer';

  @override
  String get supportStatusOpen => 'Sent';

  @override
  String get supportStatusOpenTeam => 'To answer';

  @override
  String get supportStatusResolved => 'Resolved';

  @override
  String get supportSubject => 'Subject';

  @override
  String get supportSubjectHint => 'In a few words';

  @override
  String get supportTeamName => 'Luxelane team';

  @override
  String get supportTitle => 'Help';

  @override
  String get supportTripHelpBody => 'Your request will be linked to the trip so the team sees all the details.';

  @override
  String get supportTripHelpCta => 'Help with this trip';

  @override
  String get supportTripHelpTitle => 'Help with this trip';

  @override
  String supportTripRef(String code) {
    return 'Trip $code';
  }

  @override
  String get supportUnread => 'Unread';

  @override
  String get supportUrgent => 'Urgent';

  @override
  String supportUrgentBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unanswered safety reports',
      one: '1 unanswered safety report',
    );
    return '$_temp0';
  }

  @override
  String get supportWriteHint => 'Write a message';

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
  String tripPriceDaysLine(int days, int hours, String rate) {
    return '$days days × $hours h × $rate';
  }

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
  String tripsRouteByDays(String origin, int days, int hours) {
    return '$origin · $days days × $hours h';
  }

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
