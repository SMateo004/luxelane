// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authLoginWelcomeBack => 'Welcome back to Luxelane.';

  @override
  String get authHomeLinkSemantics => 'Luxelane, go to home';

  @override
  String get authLoginEyebrow => 'WELCOME';

  @override
  String get authLoginHeadline => 'Your chauffeur,\njust as you remember.';

  @override
  String get authLoginSubtitle => 'Sign in to book and follow your trips.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailInvalid => 'Enter a valid email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordMinLength => 'At least 6 characters';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authResetNeedsEmail =>
      'Enter your email above and we will send you a link.';

  @override
  String get authNoAccount => 'Don\'t have an account? ';

  @override
  String get authCreateOne => 'Create one';

  @override
  String get authBrandSubtitle =>
      'Your addresses, preferences and trips, always at hand.';

  @override
  String get authBrandPointBooking => 'Book in under 2 minutes';

  @override
  String get authBrandPointTrips => 'All your trips in one place';

  @override
  String get authBrandPointTracking => 'Follow your chauffeur in real time';

  @override
  String get authRegisterEyebrow => 'CREATE ACCOUNT';

  @override
  String get authRegisterHeadline => 'Welcome\nto Luxelane.';

  @override
  String get authRegisterSubtitle => 'Create your account in under a minute.';

  @override
  String get authRegisterBrandSubtitle =>
      'One account to book, follow and remember every journey.';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authRegisterWebSubtitle =>
      'We only ask for what your chauffeur needs.';

  @override
  String get authGoogleRegister => 'Sign up with Google';

  @override
  String get authNameLabel => 'Full name';

  @override
  String get authNameRequired =>
      'Enter your name so your chauffeur can greet you';

  @override
  String get authPhoneLabel => 'Phone (with country code)';

  @override
  String get authPhoneRequired => 'Your chauffeur needs it to contact you';

  @override
  String get authTermsRequired =>
      'Accept the Terms and the Privacy Policy to continue';

  @override
  String get authRegisterDataNote =>
      'Your name and phone let your chauffeur greet and contact you.';

  @override
  String get authHaveAccount => 'Already have an account? ';

  @override
  String get authSignInLink => 'Sign in';

  @override
  String get authTermsCheckboxSemantics =>
      'I accept the Terms and the Privacy Policy';

  @override
  String get authTermsReadPrefix => 'I have read and accept the ';

  @override
  String get authTermsLink => 'Terms';

  @override
  String get authTermsAnd => ' and the ';

  @override
  String get authPrivacyLink => 'Privacy Policy';

  @override
  String get authGoogleContinue => 'Continue with Google';

  @override
  String get authOrWithEmail => 'or with your email';

  @override
  String get authVerifyTitle => 'Verify your email';

  @override
  String get authVerifySentGeneric => 'We sent a link to your email.';

  @override
  String authVerifySentTo(String email) {
    return 'We sent a link to $email.';
  }

  @override
  String get authVerifyBody =>
      'Open it and come back here. You need a verified email to book. If the link has expired or has not arrived, request a new one (also check your spam folder).';

  @override
  String get authVerifyResent => 'We sent you a new link.';

  @override
  String get authVerifyDone => 'Email verified. You can now book.';

  @override
  String get authVerifyNotYet =>
      'Your email is not verified yet. Open the link we sent you and try again.';

  @override
  String get authVerifyResendLimit => 'Resend limit reached';

  @override
  String authVerifyResendIn(int seconds) {
    return 'Resend link ($seconds s)';
  }

  @override
  String get authVerifyResend => 'Resend link';

  @override
  String get authVerifyConfirm => 'I have verified it';

  @override
  String get authVerifyLater => 'Later';

  @override
  String get authMfaTitle => 'Two-step verification';

  @override
  String get authMfaCodeDigits => 'Enter the 6 digits of the code.';

  @override
  String get authCancel => 'Cancel';

  @override
  String get authMfaSignInPrompt =>
      'Open your authenticator app and enter the Luxelane code.';

  @override
  String get authMfaCodeLabel => 'Code';

  @override
  String get authMfaSignInButton => 'Sign in';

  @override
  String get authMfaLostAccess =>
      'Lost access to your authenticator app? Contact our operations team to recover your account.';

  @override
  String get authMfaEnrollDone =>
      'Done. From now on, we will ask for the code from your authenticator app when you sign in.';

  @override
  String get authMfaBack => 'Back';

  @override
  String get authMfaEnrollIntro =>
      'Protect your account with an authenticator app (for example, the one on your phone or your password manager). It will ask for a 6-digit code when you sign in.';

  @override
  String get authMfaStart => 'Start';

  @override
  String get authMfaScanStep =>
      '1. Scan this code with your authenticator app.';

  @override
  String get authMfaQrSemantics => 'QR code for the authenticator app';

  @override
  String get authMfaOpenInApp => 'Open in authenticator app';

  @override
  String authMfaManualKey(String key) {
    return 'Can\'t scan? Enter this key: $key';
  }

  @override
  String get authMfaHideKey => 'Hide key';

  @override
  String get authMfaShowKey => 'Show key';

  @override
  String get authMfaNoShare =>
      'Do not share this code or the key, and do not take screenshots.';

  @override
  String get authMfaCodeStep => '2. Enter the code shown in the app.';

  @override
  String get authMfaActivate => 'Turn on';

  @override
  String get authMfaReminderTitle => 'Turn on two-step verification';

  @override
  String get authMfaReminderBody =>
      'It will soon be required to sign in. It takes a minute.';

  @override
  String get authReauthConfirmed =>
      'Identity confirmed. Please repeat the action.';

  @override
  String get authReauthPasswordEmpty => 'Enter your password.';

  @override
  String get authReauthTitle => 'Confirm it\'s you';

  @override
  String get authReauthPassword =>
      'For your security, enter your password to continue.';

  @override
  String get authReauthGoogle =>
      'For your security, sign in again with Google to continue.';

  @override
  String get authReauthNone =>
      'For your security, sign out and sign in again to continue.';

  @override
  String get authConfirm => 'Confirm';

  @override
  String get authTermsAcceptedSnack => 'Done. You can now book.';

  @override
  String get authTermsDialogTitle => 'Accept the terms to book';

  @override
  String get authTermsDialogBody =>
      'To book, we need you to accept the current version of the Terms and the Privacy Policy.';

  @override
  String get authTermsRead => 'Read the Terms';

  @override
  String get authPrivacyRead => 'Read the Privacy Policy';

  @override
  String get authNotNow => 'Not now';

  @override
  String get authAccept => 'I accept';

  @override
  String get authErrorOffline =>
      'No connection. Check your internet and try again.';

  @override
  String get authGoogleGenericError =>
      'We could not sign you in with Google. Please try again.';

  @override
  String get authGoogleAccountExists =>
      'You already have an account with this email. Sign in with your password.';

  @override
  String get authGooglePopupBlocked =>
      'Your browser blocked the Google window. Allow pop-ups and try again.';

  @override
  String get authGoogleUnauthorizedDomain =>
      'This domain is not authorized for Google sign-in.';

  @override
  String get authGoogleNotEnabled => 'Google sign-in is not enabled.';

  @override
  String get authDeleteAccountError =>
      'We could not delete your account. Check your connection.';

  @override
  String get authResetLinkError =>
      'We could not send the link. Please try again.';

  @override
  String get authVerifyTooMany =>
      'We sent several links in a row. Wait a few minutes before requesting another.';

  @override
  String get authVerifyOffline =>
      'No connection. Check your network and try again.';

  @override
  String get authVerifyFailed =>
      'We could not complete the verification. Please try again.';

  @override
  String get formatToday => 'Today';

  @override
  String get formatTomorrow => 'Tomorrow';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get driverErrorNotEnabled =>
      'This account is not yet enabled as a chauffeur. Luxelane activates it after reviewing your application.';

  @override
  String get driverErrorLoadAccount =>
      'We couldn\'t load your account. Check your connection and try again.';

  @override
  String get driverNoticeTripsLoadFailed => 'Your trips could not be loaded.';

  @override
  String get driverNoticeRequestsLoadFailed =>
      'Trip requests could not be loaded.';

  @override
  String get driverNoticeFinishTripFirst =>
      'Finish your current trip before going online.';

  @override
  String get driverNoticeStatusChangeFailed =>
      'Your status could not be changed. Try again.';

  @override
  String get driverNoticeLocationRequired =>
      'Turn on location to receive trips and let the passenger see where you are.';

  @override
  String get driverNoticeNoShowLocationRequired =>
      'Turn on location: our operations team needs to know where you waited.';

  @override
  String get driverNoticeNoShowReported =>
      'We notified our operations team. You are now free for other trips.';

  @override
  String get driverNoticeReleaseOffline =>
      'No connection: the trip was not released. Try again.';

  @override
  String get driverNoticeReleased =>
      'You released the trip. Our operations team will look for another chauffeur.';

  @override
  String get driverNoticeStepOffline =>
      'No connection: the step was not saved. Try again; it will not be duplicated.';

  @override
  String get driverNoticeRequestAccepted => 'Trip accepted';

  @override
  String get driverHomeLoadError => 'We couldn\'t open your dashboard.';

  @override
  String get driverRetry => 'Try again';

  @override
  String get driverHomeOnlineTitle => 'You are online.';

  @override
  String get driverHomeOfflineTitle => 'You are offline.';

  @override
  String get driverHomeDocumentsPending =>
      'Your documents are under review. You can accept trips once Luxelane verifies them.';

  @override
  String get driverHomeNoVehicle =>
      'You have no active vehicle registered. Ask Luxelane to activate it to receive requests.';

  @override
  String get driverHomeToday => 'Today';

  @override
  String get driverHomeNetEarnings => 'Net earnings';

  @override
  String get driverHomeTrips => 'Trips';

  @override
  String get driverHomeRating => 'Rating';

  @override
  String get driverHomeUpcoming => 'Your upcoming bookings';

  @override
  String driverHourlyFrom(int hours, String place) {
    return '$hours h from $place';
  }

  @override
  String get driverGoOffline => 'Go offline';

  @override
  String get driverGoOnline => 'Go online';

  @override
  String get driverOnlineBadge => 'Online';

  @override
  String get driverSearching => 'Looking for trips';

  @override
  String driverSearchingClass(String vehicleClass) {
    return 'Looking for $vehicleClass trips';
  }

  @override
  String get driverConnectToReceive => 'Go online to receive requests';

  @override
  String get driverDisconnectMe => 'Go offline';

  @override
  String get driverMapsNone => 'No map apps available';

  @override
  String driverMapsNavigateTo(String address) {
    return 'Navigate to $address';
  }

  @override
  String get driverMapsOpenFailed => 'Maps could not be opened';

  @override
  String get driverStopPickup => 'Pickup';

  @override
  String get driverStopDestination => 'Destination';

  @override
  String driverGuestPassenger(String name) {
    return 'Passenger: $name';
  }

  @override
  String get driverRiderNote => 'Passenger\'s note';

  @override
  String get driverNavigateToPickup => 'Navigate to pickup';

  @override
  String get driverNavigateToDestination => 'Navigate to destination';

  @override
  String get driverRequestNow => 'Now';

  @override
  String driverRequestInMinutes(int minutes) {
    return 'In $minutes min';
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
    return 'NEW REQUEST · $vehicleClass';
  }

  @override
  String get driverRequestPickupZone => 'PICKUP AREA';

  @override
  String get driverRequestDropoffZone => 'DESTINATION AREA';

  @override
  String get driverRequestHourly => 'HOURLY';

  @override
  String driverHoursAvailable(int hours) {
    return '$hours h hourly service';
  }

  @override
  String driverRequestPassengers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passengers',
      one: '1 passenger',
    );
    return '$_temp0';
  }

  @override
  String driverRequestLuggage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bags',
      one: '1 bag',
    );
    return '$_temp0';
  }

  @override
  String get driverRequestDetailsOnAccept =>
      'Exact address and details once accepted';

  @override
  String get driverAcceptTrip => 'Accept trip';

  @override
  String get driverDecline => 'Decline';

  @override
  String get driverTripNotFound => 'Trip not found';

  @override
  String get driverBack => 'Back';

  @override
  String get driverEstimatedFare => 'Estimated fare';

  @override
  String get driverQueueTitle => 'Requests';

  @override
  String get driverQueueEmptyOnline => 'New requests\nwill appear here.';

  @override
  String get driverQueueEmptyOffline => 'Go online to\nreceive requests.';

  @override
  String get driverQueueAvailable => 'Available to you';

  @override
  String get driverQueueAssigned => 'Your assigned trips';

  @override
  String driverQueueFrom(String date, String place) {
    return '$date · from $place';
  }

  @override
  String driverQueuePax(int count) {
    return '$count pax';
  }

  @override
  String get driverQueueLoading => 'Loading…';

  @override
  String get driverQueuePendingVerification => 'Pending verification';

  @override
  String get driverQueueFinishCurrent => 'Finish your current trip';

  @override
  String get driverQueueConnectToAccept => 'Go online to accept';

  @override
  String get driverOnboardingDefaultColor => 'Black';

  @override
  String get driverOnboardingVehicleError =>
      'The vehicle could not be registered. Check the details and try again.';

  @override
  String get driverOnboardingLicenseError =>
      'Your license could not be saved. Check your connection and try again.';

  @override
  String get driverOnboardingGenericError =>
      'Registration could not be completed. Try again.';

  @override
  String get driverSignOut => 'Sign out';

  @override
  String get driverOnboardingVehicleTitle => 'Your vehicle';

  @override
  String get driverOnboardingVehicleSubtitle =>
      'Register the vehicle you will drive.';

  @override
  String get driverContinue => 'Continue';

  @override
  String get driverOnboardingLicenseTitle => 'Driver\'s license';

  @override
  String get driverOnboardingLicenseSubtitle =>
      'Your documents will be reviewed before you can accept trips.';

  @override
  String get driverOnboardingReviewNotice =>
      'An administrator will verify your documents before you can go online.';

  @override
  String get driverOnboardingBack => 'Back';

  @override
  String get driverOnboardingSubmit => 'Submit';

  @override
  String get driverOnboardingClass => 'Vehicle class';

  @override
  String get driverOnboardingMake => 'Make';

  @override
  String get driverOnboardingModel => 'Model';

  @override
  String get driverOnboardingPlate => 'License plate';

  @override
  String get driverOnboardingYear => 'Year';

  @override
  String get driverOnboardingColor => 'Color';

  @override
  String get driverFieldRequired => 'Required';

  @override
  String get driverFieldInvalid => 'Invalid';

  @override
  String get driverOnboardingLicenseNumber => 'License number';

  @override
  String get driverOnboardingLicenseExpiry => 'Expiry date (MM/YYYY)';

  @override
  String get driverOnboardingExpiryFormat => 'Use MM/YYYY';

  @override
  String get driverOnboardingInvalidMonth => 'Invalid month';

  @override
  String get driverOnboardingLicenseExpired => 'License expired';

  @override
  String get driverEarningsTitle => 'Earnings';

  @override
  String get driverEarningsCompleted => 'Completed trips';

  @override
  String get driverEarningsNetTitle => 'YOUR NET EARNINGS';

  @override
  String driverEarningsRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed trips',
      one: '1 completed trip',
    );
    return '$_temp0';
  }

  @override
  String get driverEarningsFares => 'Fares for your trips';

  @override
  String get driverEarningsCommission => 'Luxelane commission';

  @override
  String driverEarningsProvisionalNote(String pct) {
    return 'Provisional trips are calculated with a $pct % commission until their settlement is confirmed.';
  }

  @override
  String driverEarningsRefunded(String date) {
    return '$date · refunded';
  }

  @override
  String driverEarningsFareLine(String date, String fare, String pct) {
    return '$date · fare $fare · $pct %';
  }

  @override
  String get driverEarningsProvisional => 'Provisional';

  @override
  String get driverEarningsEmpty => 'Your first trip\nwill appear here.';

  @override
  String get driverSlideDepart => 'Head to pickup';

  @override
  String get driverSlideArrived => 'I have arrived';

  @override
  String get driverSlideStart => 'Start trip';

  @override
  String get driverSlideComplete => 'Complete trip';

  @override
  String get driverStepConfirmed => 'Head to the pickup point.';

  @override
  String get driverStepArriving => 'On the way to pickup.';

  @override
  String get driverStepLocked =>
      'Verification locked. Contact our operations team.';

  @override
  String get driverStepAskCode => 'Ask the passenger for their pickup code.';

  @override
  String get driverStepVerified => 'Passenger verified. Slide to start.';

  @override
  String get driverStepInProgress =>
      'Trip in progress · heading to destination.';

  @override
  String get driverStepNoShow =>
      'You reported that the passenger did not show up. Our operations team is reviewing it.';

  @override
  String get driverStepActive => 'Active trip.';

  @override
  String get driverLockedFiveCodes =>
      'Five incorrect codes: our operations team must verify this trip.';

  @override
  String get driverEnterCode => 'Enter passenger\'s code';

  @override
  String get driverCannotDoTrip => 'I can\'t do this trip';

  @override
  String get driverReleaseTitle => 'Release this trip';

  @override
  String get driverReleaseBody =>
      'The trip goes back to finding a chauffeur and our operations team is notified. It is recorded in your history.';

  @override
  String get driverReleaseConfirm => 'Release trip';

  @override
  String get driverReleaseReasonVehicleIssue => 'Vehicle problem';

  @override
  String get driverReleaseReasonPersonalEmergency => 'Personal emergency';

  @override
  String get driverReleaseReasonUnsafeConditions => 'Unsafe conditions';

  @override
  String get driverReleaseReasonScheduleConflict => 'Schedule conflict';

  @override
  String get driverReleaseReasonOther => 'Other reason';

  @override
  String get driverNoShowTitle => 'Passenger not showing up?';

  @override
  String get driverNoShowBody =>
      'Our operations team will receive a notice with your location and review the booking. You will be free for other trips.';

  @override
  String get driverNoShowKeepWaiting => 'Keep waiting';

  @override
  String get driverNoShowNotify => 'Notify operations team';

  @override
  String get driverNoShowButton => 'Passenger not showing up';

  @override
  String driverNoShowAvailableAt(String time) {
    return 'Available from $time.';
  }

  @override
  String get driverFlightAirportPickup => 'Airport pickup';

  @override
  String get driverFlightExitLabel => 'Your passenger comes out through';

  @override
  String get driverFlightAskType =>
      'Ask the passenger whether their flight is domestic or international';

  @override
  String driverFlightNumber(String flight) {
    return 'Flight $flight';
  }

  @override
  String get driverFlightCheckStatus => 'Check status at mivuelo.att.gob.bo';

  @override
  String get driverFlightYourCityAirport => 'your city\'s airport';

  @override
  String get driverFlightDialogTitle => 'Change the airport first';

  @override
  String driverFlightDialogBody(String airport, String flight) {
    return 'When you open mivuelo.att.gob.bo, first change the airport to $airport, the one for your city. Then look for flight $flight under arrivals.\n\nWe will copy the flight number so you only need to paste it.';
  }

  @override
  String get driverCancel => 'Cancel';

  @override
  String get driverFlightDialogOpen => 'Understood, open';

  @override
  String get driverFlightOpenFailed => 'mivuelo.att.gob.bo could not be opened';

  @override
  String get driverCallDispatch => 'Call operations team';

  @override
  String get driverCodeLockedSecurity =>
      'For security, verification has been locked. Contact our operations team.';

  @override
  String get driverCodeAsk => 'Ask the passenger for the code';

  @override
  String get driverCodeHint =>
      'They can see it in their app. Without it the trip cannot start.';

  @override
  String driverCodeSemantics(int entered, int length) {
    return 'Code, $entered of $length digits';
  }

  @override
  String get driverCodeDelete => 'Delete';

  @override
  String get driverCodeVerified => 'Passenger verified';

  @override
  String get driverCodeVerifiedHint =>
      'Slide “Start trip” when you are both ready.';

  @override
  String get driverCodeContactDispatch => 'Contact our operations team';

  @override
  String get driverNavDrive => 'Drive';

  @override
  String get driverNavRequests => 'Requests';

  @override
  String get driverNavEarnings => 'Earnings';

  @override
  String get driverNavProfile => 'Profile';

  @override
  String incidentSmsHeader(String id) {
    return 'SOS. Booking #$id.';
  }

  @override
  String incidentSmsLocation(String link) {
    return 'Location: $link';
  }

  @override
  String get incidentSmsNoLocation => 'Location not available.';

  @override
  String get incidentNoNumbersHelp => 'Contact the local authorities.';

  @override
  String get incidentSendingTitle => 'Notifying our operations team…';

  @override
  String get incidentSendingBody => 'Do not close the app.';

  @override
  String get incidentFailedTitle => 'We could not notify our operations team';

  @override
  String get incidentOfflineBody =>
      'There is no connection. Call or send the prepared message.';

  @override
  String get incidentCancelledTitle => 'Alert cancelled';

  @override
  String get incidentCancelledBody =>
      'Our operations team has been notified. We are no longer sharing your location.';

  @override
  String get incidentOpenTitle => 'We notified our operations team';

  @override
  String get incidentOpenBody =>
      'Our operations team has been notified. We share your location while the alert is active.';

  @override
  String get incidentAckTitle => 'Our operations team received your alert';

  @override
  String get incidentAckBody =>
      'A member of our operations team is handling it.';

  @override
  String get incidentClosedTitle => 'Alert closed';

  @override
  String get incidentClosedBody =>
      'Our operations team closed the alert. We are no longer sharing your location.';

  @override
  String get incidentCancelRequestedBody =>
      'Our operations team will call you to check that you are safe. We are no longer sharing your location.';

  @override
  String get incidentHelp => 'Help';

  @override
  String get incidentIdleBody =>
      'Press and hold SOS to notify our operations team.';

  @override
  String get incidentFalseAlarmQuestion => 'Was it a false alarm?';

  @override
  String get incidentFalseAlarmBody =>
      'We will cancel the alert. Our operations team will still see it and it remains on record.';

  @override
  String get incidentBack => 'Back';

  @override
  String get incidentCancelAlert => 'Cancel alert';

  @override
  String incidentSentTimes(int count) {
    return 'Alert sent $count times.';
  }

  @override
  String get incidentCallDispatch => 'Call our operations team';

  @override
  String get incidentSmsDispatch => 'Text our operations team';

  @override
  String get incidentRetry => 'Retry the alert';

  @override
  String get incidentAlertAgain => 'Alert again';

  @override
  String get incidentHoldToAlertAgain => 'Press and hold to alert again';

  @override
  String get incidentFalseAlarm => 'It was a false alarm';

  @override
  String get incidentConfirmTitle => 'Notify our operations team?';

  @override
  String get incidentConfirmBody =>
      'Our operations team will receive your alert and your location while it is active.';

  @override
  String get incidentConfirmCancel => 'Cancel';

  @override
  String get incidentConfirmSend => 'Notify operations team';

  @override
  String incidentSosSemantics(String label) {
    return '$label SOS';
  }

  @override
  String get incidentSosHint =>
      'Press and hold for two seconds to notify our operations team. With a screen reader, double-tap and confirm.';

  @override
  String get incidentLive => 'Help in progress';

  @override
  String get incidentErrorOffline =>
      'We could not notify our operations team: no connection.';

  @override
  String get incidentErrorOutsideWindow =>
      'The help button works during the trip.';

  @override
  String get incidentErrorRateLimited =>
      'You have already sent several alerts. Call our operations team if you need to.';

  @override
  String get incidentErrorNotAllowed => 'This trip is no longer in your name.';

  @override
  String get incidentErrorGeneric => 'We could not notify our operations team.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String languageSystemDetail(String language) {
    return 'Uses your phone\'s language: $language';
  }

  @override
  String get languageSaveError =>
      'Your language could not be saved to your account. It will be used on this device.';

  @override
  String get legalSpanishOnlyNotice =>
      'This document is currently available in Spanish only.';

  @override
  String get paymentOurFault =>
      'We could not complete the payment due to an issue on our side. Please try again in a few minutes.';

  @override
  String get paymentMethodDisabled =>
      'This payment method is not available at the moment. Choose another one or contact our operations team.';

  @override
  String get paymentAlreadyPaid => 'This booking has already been paid.';

  @override
  String get paymentNotAwaiting =>
      'This booking no longer accepts payments. Check its status in My trips.';

  @override
  String get paymentBookingNotFound => 'We could not find this booking.';

  @override
  String get paymentInvalidOperationNumber =>
      'Check the transaction number: use only letters, numbers, spaces and . _ / -';

  @override
  String get paymentAccountNotEnabled =>
      'your account does not have payments enabled yet';

  @override
  String get paymentServerUnreachable =>
      'the payment server could not be reached';

  @override
  String get paymentCardInUse =>
      'This card is paying for a pending booking. Cancel the booking or wait until it ends before removing the card.';

  @override
  String get paymentRemoveCardError =>
      'We could not remove the card. Please try again.';

  @override
  String get paymentSetDefaultError =>
      'We could not change your default card. Please try again.';

  @override
  String get paymentProfileError =>
      'We could not set up your payment profile. Please try again.';

  @override
  String get paymentLoadError =>
      'We could not load the payment for your booking. Check your connection.';

  @override
  String get paymentCardUnavailable =>
      'Card payment is not available at the moment. Choose another method.';

  @override
  String get paymentCardFailed =>
      'The card payment could not be completed. Check the details and try again.';

  @override
  String get paymentCardIncomplete => 'Enter all the card details';

  @override
  String get paymentCardAdded => 'Card added';

  @override
  String get paymentAddMethodTitle => 'Add payment method';

  @override
  String get paymentBack => 'Back';

  @override
  String get paymentCardDetails => 'Card details';

  @override
  String get paymentAddCardSecure => 'Protected by Stripe · PCI DSS compliant';

  @override
  String get paymentAddCard => 'Add card';

  @override
  String get paymentBookingTitle => 'Booking payment';

  @override
  String get paymentViewTrip => 'View my trip';

  @override
  String get paymentNoPending => 'This booking has no pending payment.';

  @override
  String get paymentConfirmedTitle => 'Payment confirmed';

  @override
  String get paymentConfirmedMessage =>
      'We are looking for your chauffeur. We will let you know once one is assigned.';

  @override
  String get paymentExpiredTitle => 'The payment window has ended';

  @override
  String paymentExpiredMessage(String reference) {
    return 'The booking was cancelled because we did not receive the payment in time. If you had already paid, contact our operations team and quote the reference $reference.';
  }

  @override
  String get paymentNewBooking => 'Make a new booking';

  @override
  String get paymentClosedTitle => 'This booking no longer accepts payments';

  @override
  String get paymentClosedMessage =>
      'See the details and the receipt in your trip.';

  @override
  String get paymentRejected =>
      'We could not confirm your payment. Check the details and let us know again, or contact our operations team.';

  @override
  String get paymentNoMethods =>
      'We cannot take the payment here at the moment. Contact our operations team to complete your booking.';

  @override
  String get paymentChangeMethod => 'Change payment method';

  @override
  String get paymentSearchAfterConfirm =>
      'We look for a chauffeur once the payment is confirmed.';

  @override
  String get paymentAmountDueEyebrow => 'AMOUNT DUE';

  @override
  String get paymentReference => 'Reference';

  @override
  String paymentDeadlinePassed(String time) {
    return 'The payment window ended at $time.';
  }

  @override
  String paymentTimeLeft(String span, String time) {
    return '$span left to pay (until $time).';
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
    return 'Copy $label';
  }

  @override
  String paymentCopied(String label) {
    return '$label copied.';
  }

  @override
  String get paymentMethodManualQr => 'QR or bank transfer';

  @override
  String get paymentMethodCard => 'Card';

  @override
  String get paymentHowToPay => 'HOW WOULD YOU LIKE TO PAY?';

  @override
  String get paymentManualEyebrow => 'PAY BY QR OR TRANSFER';

  @override
  String get paymentQrLabel => 'QR code to pay';

  @override
  String get paymentQrError =>
      'We could not show the QR code. Use the account details.';

  @override
  String get paymentHolder => 'Account holder';

  @override
  String get paymentBank => 'Bank';

  @override
  String get paymentAccountType => 'Account type';

  @override
  String get paymentAccount => 'Account';

  @override
  String paymentPayExactly(String amount, String reference) {
    return 'Pay exactly $amount and enter the reference $reference in the payment description.';
  }

  @override
  String get paymentOperationLabel => 'Transaction number (optional)';

  @override
  String get paymentOperationHint => 'The one shown on your bank receipt';

  @override
  String get paymentIPaid => 'I have paid';

  @override
  String get paymentWaitingTitle => 'Awaiting confirmation';

  @override
  String get paymentWaitingMessage =>
      'Our operations team is reviewing your payment. We will let you know here and in your notifications once it is confirmed.';

  @override
  String paymentOperationNumber(String number) {
    return 'Transaction number: $number';
  }

  @override
  String get paymentConfirming => 'Confirming your payment…';

  @override
  String get paymentPayWithCard => 'Pay by card';

  @override
  String get paymentRetry => 'Try again';

  @override
  String get paymentAddCardsOnPhone =>
      'Add your cards from the Luxelane app on your phone.';

  @override
  String get paymentRemoveCardTitle => 'Remove this card?';

  @override
  String get paymentRemoveCardMessage =>
      'It will no longer be available for your upcoming bookings.';

  @override
  String get paymentCancel => 'Cancel';

  @override
  String get paymentRemove => 'Remove';

  @override
  String get paymentMethodsTitle => 'Payment methods';

  @override
  String get paymentPerBooking =>
      'Each booking is paid in its own payment step.';

  @override
  String get paymentSavedCards => 'Saved cards';

  @override
  String get paymentSetDefaultHint =>
      'Tap a card to use it by default when booking.';

  @override
  String get paymentEncrypted => 'Payments encrypted and protected by Stripe';

  @override
  String get paymentEmptyCards => 'Pay without a second thought.';

  @override
  String paymentCardDefaultExpires(String expiry) {
    return 'Default · expires $expiry';
  }

  @override
  String paymentCardExpires(String expiry) {
    return 'Expires $expiry';
  }

  @override
  String get paymentRemoveCard => 'Remove card';

  @override
  String get paymentReceiptMethodManual => 'QR or transfer';

  @override
  String get paymentPendingTitle => 'Payment pending';

  @override
  String paymentReportedMessage(String amount) {
    return 'You let us know you paid $amount. Our operations team is reviewing it.';
  }

  @override
  String paymentPendingMessage(String amount) {
    return 'Pay $amount so we can look for your chauffeur.';
  }

  @override
  String get paymentViewPayment => 'View payment';

  @override
  String get paymentPayNow => 'Pay now';

  @override
  String get paymentReceiptTitle => 'Payment receipt';

  @override
  String get paymentReceiptHide => 'Hide receipt';

  @override
  String get paymentReceiptShow => 'View receipt';

  @override
  String get paymentReceiptNotInvoice => 'This receipt is not an invoice.';

  @override
  String get paymentReceiptPaid => 'Paid';

  @override
  String get paymentReceiptDate => 'Date';

  @override
  String get paymentReceiptMethod => 'Method';

  @override
  String get paymentReceiptRetained => 'Cancellation fee';

  @override
  String get paymentReceiptRefundPending => 'Refund pending';

  @override
  String get paymentReceiptRefundPendingNote =>
      'Our operations team will record it and we will let you know once it is done.';

  @override
  String get paymentReceiptRefunded => 'Refunded';

  @override
  String get paymentReceiptRefundedNote =>
      'The money is returned to the method you paid with.';

  @override
  String get paymentReceiptBalanceDue => 'Balance due';

  @override
  String get paymentReceiptBalanceNote =>
      'The final trip amount was higher than the amount paid.';

  @override
  String get profileSaveError =>
      'We couldn\'t save your changes. Please try again.';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileRideStyle => 'Your travel style';

  @override
  String get profileDriverDocuments => 'Licence and vehicle';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileEmail => 'Email';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profilePhoneMissing => 'Add it for your chauffeur';

  @override
  String get profilePaymentMethods => 'Payment methods';

  @override
  String get profileTwoStep => 'Two-step verification';

  @override
  String get profileAuthenticatorApp => 'Authenticator app';

  @override
  String get profileLegal => 'Legal';

  @override
  String get profileTerms => 'Terms and conditions';

  @override
  String get profilePrivacy => 'Privacy';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profilePreferencesFooter =>
      'Your chauffeur will see this before your pickup. It applies to your upcoming bookings.';

  @override
  String get profileQuietRide => 'Quiet ride';

  @override
  String get profileQuietRideDetail => 'No conversation beyond what is needed';

  @override
  String get profileSoftMusic => 'Soft music';

  @override
  String get profileTemperature => 'Temperature';

  @override
  String get profileTemperatureAny => 'No preference';

  @override
  String get profileLuggageHelp => 'Help with luggage';

  @override
  String get profileOpenDoor => 'Open the door for me';

  @override
  String get profileAccountDeleted => 'Your account has been deleted.';

  @override
  String get profileDeleteTitle => 'Delete your account?';

  @override
  String get profileDeleteBody =>
      'We will delete your profile, your saved cards and your notifications, and you will not be able to sign in with this account again. We keep the trip and payment records required by law.\n\nThis cannot be undone.';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileDelete => 'Delete';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileName => 'Name';

  @override
  String get profileRequired => 'Required';

  @override
  String get profilePhoneInvalid => 'Your chauffeur needs it to contact you';

  @override
  String get profileSaveChanges => 'Save changes';

  @override
  String get profileRoleAdmin => 'Administration';

  @override
  String get profileRoleDriver => 'Luxelane chauffeur';

  @override
  String profileMemberSince(int year) {
    return 'Member since $year';
  }

  @override
  String profileRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '$count trip',
    );
    return '$_temp0';
  }

  @override
  String get profileVehicleColorTitle => 'Vehicle colour';

  @override
  String get profileColor => 'Colour';

  @override
  String get profileSave => 'Save';

  @override
  String get profileLocked => 'Locked';

  @override
  String get profileLicence => 'Licence';

  @override
  String profileLicenceDetail(String number, String expiry) {
    return '$number · expires $expiry';
  }

  @override
  String profileVehicleDetail(String vehicleClass, String plate) {
    return '$vehicleClass · plate $plate';
  }

  @override
  String get rideLoadNotFound =>
      'We could not find this booking in your account.';

  @override
  String get rideLoadOffline =>
      'We could not load your booking. Check your connection.';

  @override
  String get rideLoadFailed =>
      'We could not load your booking. Please try again.';

  @override
  String get ridePendingSearching =>
      'We are assigning your chauffeur. We will let you know once it is confirmed.';

  @override
  String get ridePendingReleasedCall =>
      'Your previous chauffeur could not take the trip. We are looking for another one and our operations team has been notified. If you need to, call our operations team.';

  @override
  String get ridePendingReleased =>
      'Your previous chauffeur could not take the trip. We are looking for another one and our operations team has been notified.';

  @override
  String get ridePendingPickupPassedCall =>
      'The pickup time has passed and no chauffeur has been assigned yet. Call our operations team or cancel the booking.';

  @override
  String get ridePendingPickupPassed =>
      'The pickup time has passed and no chauffeur has been assigned yet. You can wait or cancel the booking.';

  @override
  String rideCodeShareText(String code) {
    return 'Your pickup code is $code. Give it to your chauffeur when you get in; without it the trip cannot start.';
  }

  @override
  String get rideCodeLoading => 'Loading your pickup code';

  @override
  String get rideCodeTitle => 'PICKUP CODE';

  @override
  String rideCodeSemantics(String digits) {
    return 'Pickup code $digits';
  }

  @override
  String get rideCodeHint =>
      'Give it to your chauffeur when you get in. Without it the trip cannot start.';

  @override
  String rideCodeGuestHint(String guest) {
    return 'Share it with $guest: they will give it to the chauffeur when they get in.';
  }

  @override
  String get rideCodeShare => 'Share code';

  @override
  String get rideRetry => 'Retry';

  @override
  String get rideCancelledSnack => 'Booking cancelled';

  @override
  String get rideCancelFeeChangedAgain =>
      'The cancellation fee changed again. Please try again.';

  @override
  String get rideCancelBooking => 'Cancel booking';

  @override
  String rideCancelFee(String amount) {
    return 'Under the cancellation policy, if you cancel now $amount of what you paid will be retained.';
  }

  @override
  String rideCancelFeeChanged(String amount) {
    return 'The cancellation fee changed. Under the cancellation policy, if you cancel now $amount of what you paid will be retained.';
  }

  @override
  String rideCancelRefund(String amount) {
    return '$amount remain pending refund. We will let you know when our operations team records it.';
  }

  @override
  String get rideCancelReasonLabel => 'Reason';

  @override
  String get rideCancelReasonChangedPlans => 'My plans changed';

  @override
  String get rideCancelReasonOtherTransport => 'I found other transport';

  @override
  String get rideCancelReasonDriverLate => 'The chauffeur is taking too long';

  @override
  String get rideCancelReasonOther => 'Other reason';

  @override
  String get rideBack => 'Back';

  @override
  String get rideCancelWithFee => 'Cancel with fee';

  @override
  String get rideCancelledMessage => 'This booking was cancelled.';

  @override
  String rideCancelledWithFee(String amount) {
    return 'This booking was cancelled. Cancellation fee: $amount.';
  }

  @override
  String get rideStatusLoading => 'Loading your booking…';

  @override
  String get rideStatusAwaitingPayment =>
      'Your booking is awaiting payment. We look for a chauffeur once it is confirmed.';

  @override
  String get rideStatusConfirmed =>
      'Your booking is confirmed. We will let you know when your chauffeur sets off.';

  @override
  String get rideStatusDriverArriving =>
      'Your chauffeur is on the way to the pickup point.';

  @override
  String get rideStatusDriverArrived =>
      'Your chauffeur has arrived and is waiting for you. Take your time.';

  @override
  String get rideStatusVerified =>
      'Code verified. Your trip will begin shortly.';

  @override
  String get rideStatusInProgress =>
      'Enjoy the journey. You will reach your destination shortly.';

  @override
  String get rideStatusCompleted =>
      'You have arrived. Thank you for traveling with Luxelane.';

  @override
  String get rideStatusNoShow =>
      'Your chauffeur could not find you at the pickup point. Our operations team has been notified.';

  @override
  String get rideYourDriverLower => 'your chauffeur';

  @override
  String get rideYourDriver => 'Your chauffeur';

  @override
  String get rideRatingThanks => 'Thank you for your rating.';

  @override
  String get rideRateTrip => 'Rate trip';

  @override
  String get rideCallDriver => 'Call your chauffeur';

  @override
  String get rideCancelling => 'Cancelling…';

  @override
  String get rideBackHome => 'Back to home';

  @override
  String ridePreferencesKnown(String preferences) {
    return 'Your chauffeur knows your style: $preferences';
  }

  @override
  String get rideAssigningTitle => 'Assigning your chauffeur';

  @override
  String get rideAssigningDetail =>
      'You will see their name, vehicle and rating here.';

  @override
  String get rideCodeVerified => 'Code verified';

  @override
  String get rideCodeVerifiedDetail => 'Your chauffeur can now start the trip.';

  @override
  String get rideCompleted => 'Trip completed';

  @override
  String get rideRatingTitle => 'Rate your trip';

  @override
  String get rideRatingLater => 'Not now';

  @override
  String get rideRatingSend => 'Send';

  @override
  String get rideRating5 => 'Excellent';

  @override
  String get rideRating4 => 'Good';

  @override
  String get rideRating3 => 'Fair';

  @override
  String get rideRating2 => 'Poor';

  @override
  String get rideRating1 => 'Very poor';

  @override
  String get rideErrorNetwork =>
      'No connection. Check your network and try again.';

  @override
  String get rideErrorNotAtPickup =>
      'The code appears when your chauffeur arrives at the pickup point.';

  @override
  String get rideErrorWrongCode => 'Incorrect code.';

  @override
  String get rideErrorWrongCodeOne =>
      'Incorrect code. You have 1 attempt left.';

  @override
  String rideErrorWrongCodeMany(int left) {
    return 'Incorrect code. You have $left attempts left.';
  }

  @override
  String get rideErrorLocked =>
      'For security, verification has been locked. Contact our operations team.';

  @override
  String get rideErrorExpired =>
      'The code has expired. Contact our operations team to continue.';

  @override
  String get rideErrorUnavailable =>
      'The code is not available right now. Contact our operations team.';

  @override
  String get rideErrorNotYours => 'This trip is no longer assigned to you.';

  @override
  String get rideErrorTooEarly =>
      'The waiting time is not over yet. Please wait a little longer.';

  @override
  String get rideErrorNoShowDisabled =>
      'This option is not available. Contact our operations team.';

  @override
  String get rideErrorLocationRequired =>
      'Turn on location: our operations team needs to know where you waited.';

  @override
  String get rideErrorNotReleasable =>
      'You can no longer release this trip. Contact our operations team.';

  @override
  String get rideErrorInvalidTransition =>
      'The trip status changed. We have updated the screen.';

  @override
  String get rideErrorGeneric =>
      'This could not be completed. Please try again.';

  @override
  String get tripsTitle => 'My trips';

  @override
  String get tripsRetry => 'Try again';

  @override
  String get tripsUpcoming => 'Upcoming';

  @override
  String get tripsPast => 'Past';

  @override
  String get tripsEmptyMessage => 'Your first journey\nis waiting for you.';

  @override
  String get tripsEmptyAction => 'Book now';

  @override
  String tripsHourlyTitle(int hours) {
    return '$hours h at your disposal';
  }

  @override
  String tripsFrom(String when, String origin) {
    return '$when · from $origin';
  }

  @override
  String get tripsTrackOnMap => 'Track on map';

  @override
  String get tripsRate => 'Rate trip';

  @override
  String get tripsViewBooking => 'View booking';

  @override
  String get tripsAwaitingPayment => 'Awaiting payment';

  @override
  String get tripsPaid => 'Paid';
}
