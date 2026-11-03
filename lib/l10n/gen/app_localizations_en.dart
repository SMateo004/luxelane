// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get adminDrvAppSection => 'Driver applications';

  @override
  String get adminDrvAppSectionSubtitle =>
      'Details, vehicle and documents of people who want to drive.';

  @override
  String get adminDrvAppTabInbox => 'Applications';

  @override
  String get adminDrvAppTabExpiries => 'Upcoming expiries';

  @override
  String get adminDrvAppReload => 'Reload';

  @override
  String get adminDrvAppRetry => 'Try again';

  @override
  String get adminDrvAppStatusFilter => 'Filter by status';

  @override
  String get adminDrvAppInboxEmpty => 'No applications with this status';

  @override
  String get adminDrvAppInboxEmptyHint =>
      'Choose another status above to see more.';

  @override
  String get adminDrvAppInboxError => 'The applications could not be loaded.';

  @override
  String adminDrvAppInboxTruncated(String count) {
    return 'Showing the $count most recent.';
  }

  @override
  String adminDrvAppSubmittedAt(String date) {
    return 'Submitted on $date';
  }

  @override
  String adminDrvAppUpdatedAt(String date) {
    return 'Updated on $date';
  }

  @override
  String get adminDrvAppNoName => 'No name';

  @override
  String adminDrvAppOpen(String name) {
    return 'Open the application from $name';
  }

  @override
  String get adminDrvAppOpenShort => 'View application';

  @override
  String get adminDrvAppBack => 'Back to the inbox';

  @override
  String get adminDrvAppDetailError => 'The application could not be loaded.';

  @override
  String get adminDrvAppPersonalTitle => 'Personal details';

  @override
  String get adminDrvAppPersonalMissing =>
      'Personal details not completed yet.';

  @override
  String get adminDrvAppFullName => 'Full name';

  @override
  String get adminDrvAppNationalId => 'ID document number';

  @override
  String get adminDrvAppLicenseNumber => 'License number';

  @override
  String get adminDrvAppLicenseExpiry => 'License expiry';

  @override
  String get adminDrvAppEmail => 'Email';

  @override
  String get adminDrvAppStatus => 'Status';

  @override
  String get adminDrvAppVehicleTitle => 'Vehicle';

  @override
  String get adminDrvAppVehicleMissing => 'Vehicle not registered yet.';

  @override
  String get adminDrvAppMake => 'Make';

  @override
  String get adminDrvAppModel => 'Model';

  @override
  String get adminDrvAppYear => 'Year';

  @override
  String get adminDrvAppColor => 'Colour';

  @override
  String get adminDrvAppPlate => 'Plate';

  @override
  String get adminDrvAppBodyType => 'Body type';

  @override
  String get adminDrvAppPassengers => 'Passengers';

  @override
  String get adminDrvAppClass => 'Class';

  @override
  String get adminDrvAppPendingVehicle => 'Vehicle change pending review.';

  @override
  String get adminDrvAppDocsTitle => 'Documents';

  @override
  String get adminDrvAppRequirementsMissing => 'Requirements not configured';

  @override
  String get adminDrvAppRequirementsMissingBody =>
      'The driverRequirements list is missing from config/ops: the driver cannot submit the application and it cannot be approved. Uploaded documents are shown.';

  @override
  String get adminDrvAppRequired => 'Required';

  @override
  String get adminDrvAppOptional => 'Optional';

  @override
  String get adminDrvAppNotRequested => 'Not in the requirements';

  @override
  String adminDrvAppDocVersion(String version) {
    return 'Version $version';
  }

  @override
  String adminDrvAppDocExpires(String date) {
    return 'Expires on $date';
  }

  @override
  String adminDrvAppDocExpired(String date) {
    return 'Expired on $date';
  }

  @override
  String get adminDrvAppDocExpiryMissing => 'No expiry date';

  @override
  String adminDrvAppDocRejectReason(String reason) {
    return 'Rejection reason: $reason';
  }

  @override
  String adminDrvAppDocNote(String note) {
    return 'Note: $note';
  }

  @override
  String get adminDrvAppDocNotUploaded => 'Not uploaded';

  @override
  String get adminDrvAppViewDoc => 'View document';

  @override
  String adminDrvAppViewDocLabel(String document) {
    return 'View document: $document';
  }

  @override
  String get adminDrvAppApproveDoc => 'Approve';

  @override
  String adminDrvAppApproveDocLabel(String document) {
    return 'Approve document: $document';
  }

  @override
  String get adminDrvAppRejectDoc => 'Reject';

  @override
  String adminDrvAppRejectDocLabel(String document) {
    return 'Reject document: $document';
  }

  @override
  String adminDrvAppApproveTitle(String document) {
    return 'Approve $document?';
  }

  @override
  String adminDrvAppApproveBody(String version) {
    return 'Version $version will be approved. It is recorded in the audit log with your account.';
  }

  @override
  String get adminDrvAppApproveConfirm => 'Approve document';

  @override
  String get adminDrvAppDocApproved => 'Document approved.';

  @override
  String get adminDrvAppDocRejected =>
      'Document rejected. The driver will see the reason.';

  @override
  String adminDrvAppRejectTitle(String document) {
    return 'Reject $document';
  }

  @override
  String get adminDrvAppRejectReasonLabel => 'Rejection reason';

  @override
  String get adminDrvAppRejectReasonHint => 'Choose a reason';

  @override
  String get adminDrvAppRejectReasonRequired => 'Choose a reason to reject.';

  @override
  String get adminDrvAppRejectNoteLabel => 'Note for the driver (optional)';

  @override
  String get adminDrvAppRejectConfirm => 'Reject document';

  @override
  String get adminDrvAppCancel => 'Cancel';

  @override
  String get adminDrvAppClose => 'Close';

  @override
  String get adminDrvAppViewerLoading => 'Opening the document…';

  @override
  String get adminDrvAppViewerExpiry =>
      'The link expires 5 minutes after opening. If it expires, close the viewer and open it again.';

  @override
  String get adminDrvAppViewerLogged =>
      'Every opening is recorded in the access log.';

  @override
  String get adminDrvAppViewerPdf => 'This document is a PDF.';

  @override
  String get adminDrvAppViewerOpenPdf => 'Open PDF in a new tab';

  @override
  String get adminDrvAppViewerPdfError =>
      'The PDF could not be opened. Close the viewer and try again.';

  @override
  String get adminDrvAppViewerImageError =>
      'The image could not be shown. If the link expired, close the viewer and open it again.';

  @override
  String adminDrvAppViewerImageLabel(String document) {
    return 'Image of the document: $document';
  }

  @override
  String get adminDrvAppViewerError => 'The document could not be opened.';

  @override
  String get adminDrvAppDecide => 'Final decision';

  @override
  String get adminDrvAppDecisionTitle => 'Final decision on the application';

  @override
  String get adminDrvAppDecisionBody =>
      'Approving requires every required document to be approved and valid. The driver is notified of the result.';

  @override
  String get adminDrvAppDecisionApprove => 'Approve';

  @override
  String get adminDrvAppDecisionNeedsChanges => 'Request changes';

  @override
  String get adminDrvAppDecisionReject => 'Reject';

  @override
  String get adminDrvAppDecisionReasonLabel =>
      'Reason (recorded in the audit log)';

  @override
  String adminDrvAppDecisionReasonHint(String min, String max) {
    return 'Between $min and $max characters';
  }

  @override
  String adminDrvAppDecisionReasonShort(String min) {
    return 'Write at least $min characters.';
  }

  @override
  String get adminDrvAppDecisionConfirm => 'Confirm decision';

  @override
  String get adminDrvAppDecisionNotDecidable =>
      'Only submitted, in-review or changes-requested applications can be decided.';

  @override
  String adminDrvAppDecisionDone(String status) {
    return 'Decision saved: $status.';
  }

  @override
  String adminDrvAppErrDocsNotApproved(String documents) {
    return 'Cannot approve: these required documents are not approved or valid: $documents.';
  }

  @override
  String get adminDrvAppErrDocsNotApprovedAny =>
      'Cannot approve: some required documents are not approved or have expired.';

  @override
  String get adminDrvAppErrStaleVersion =>
      'The driver uploaded a new version; reload the application.';

  @override
  String get adminDrvAppErrNotReviewable =>
      'This document cannot be reviewed in its current state.';

  @override
  String get adminDrvAppErrNotDecidable =>
      'This application can no longer be decided; reload.';

  @override
  String get adminDrvAppErrRequirements =>
      'Requirements not configured: it cannot be approved.';

  @override
  String get adminDrvAppErrStepsIncomplete =>
      'Application steps are missing (personal details or vehicle).';

  @override
  String get adminDrvAppErrNotFound =>
      'The document or driver was not found; reload.';

  @override
  String get adminDrvAppErrInvalid =>
      'Check the details: the reason needs between 10 and 500 characters.';

  @override
  String get adminDrvAppErrPermission =>
      'Permission denied: an administrator role is required.';

  @override
  String get adminDrvAppErrGeneric =>
      'It could not be completed. Try again in a few minutes.';

  @override
  String get adminDrvAppAccessLog => 'Access log';

  @override
  String get adminDrvAppAccessLogHint =>
      'Who opened each document of this application and when, newest first.';

  @override
  String get adminDrvAppAccessLogEmpty =>
      'Nobody has opened the documents of this application yet.';

  @override
  String get adminDrvAppAccessLogError => 'The access log could not be loaded.';

  @override
  String adminDrvAppAccessLogEntry(String document, String version) {
    return '$document · version $version';
  }

  @override
  String adminDrvAppAccessLogWho(String who, String date) {
    return '$who · $date';
  }

  @override
  String adminDrvAppUnknownAdmin(String id) {
    return 'Administrator $id';
  }

  @override
  String adminDrvAppExpiriesPeriod(String days) {
    return 'Next $days days';
  }

  @override
  String adminDrvAppExpiriesEmpty(String days) {
    return 'No document expires in the next $days days.';
  }

  @override
  String get adminDrvAppExpiriesError => 'The expiries could not be loaded.';

  @override
  String adminDrvAppExpiriesTruncated(String count) {
    return 'There are more results; showing the first $count. Shorten the period to see the rest.';
  }

  @override
  String get adminDrvAppBlocked => 'Blocked from going online';

  @override
  String get adminDrvAppAllowOnline => 'Allow online';

  @override
  String adminDrvAppAllowOnlineLabel(String name) {
    return 'Allow $name to go online';
  }

  @override
  String get adminDrvAppAllowOnlineTitle =>
      'Allow going online with expired documents';

  @override
  String adminDrvAppAllowOnlineBody(String name) {
    return '$name will be able to go online despite the current expired documents, until another one expires. It is recorded in the audit log with your reason.';
  }

  @override
  String get adminDrvAppAllowOnlineConfirm => 'Allow';

  @override
  String get adminDrvAppAllowOnlineDone => 'Driver allowed to go online.';

  @override
  String get adminFlightsSection => 'Flights';

  @override
  String get adminFlightsSectionSubtitle =>
      'Arriving flights to review and airports with their pickup points.';

  @override
  String get adminFlightsTabInbox => 'Inbox';

  @override
  String get adminFlightsTabAirports => 'Airports';

  @override
  String get adminFlightsInboxToVerify => 'To verify';

  @override
  String get adminFlightsInboxNoData => 'No data';

  @override
  String get adminFlightsInboxDisrupted => 'Cancelled or diverted';

  @override
  String adminFlightsInboxTruncated(String count) {
    return 'Read the first $count bookings with a flight: there may be more.';
  }

  @override
  String get adminFlightsInboxEmptyToVerify => 'No flights to verify';

  @override
  String get adminFlightsInboxEmptyNoData => 'No flights without data';

  @override
  String get adminFlightsInboxEmptyDisrupted =>
      'No cancelled or diverted flights';

  @override
  String get adminFlightsInboxEmptyHint =>
      'Bookings with a flight that need review appear here.';

  @override
  String get adminFlightsInboxError => 'Could not load the flights inbox';

  @override
  String get adminFlightsRetry => 'Retry';

  @override
  String adminFlightsRowReadyAt(String time) {
    return 'Chauffeur at the point: $time';
  }

  @override
  String get adminFlightsRowNoReadyAt => 'No pickup time';

  @override
  String adminFlightsRowSemantics(String code, String flight, String status) {
    return 'Booking $code, flight $flight, $status. Open details';
  }

  @override
  String adminFlightsBookingTitle(String code) {
    return 'Booking #$code';
  }

  @override
  String get adminFlightsClose => 'Close';

  @override
  String get adminFlightCardTitle => 'Flight';

  @override
  String get adminFlightAirport => 'Airport';

  @override
  String get adminFlightAirline => 'Airline';

  @override
  String get adminFlightNumber => 'Flight number';

  @override
  String get adminFlightType => 'Type';

  @override
  String get adminFlightDate => 'Flight date';

  @override
  String get adminFlightScheduled => 'Scheduled arrival';

  @override
  String get adminFlightEstimated => 'Estimated arrival';

  @override
  String get adminFlightActual => 'Actual arrival';

  @override
  String get adminFlightStatus => 'Flight status';

  @override
  String get adminFlightQuality => 'Data quality';

  @override
  String get adminFlightQualityOk => 'Up to date';

  @override
  String get adminFlightQualityStale => 'Outdated';

  @override
  String get adminFlightQualityNone => 'No live data';

  @override
  String get adminFlightSource => 'Source';

  @override
  String get adminFlightSourcePassenger => 'Passenger';

  @override
  String get adminFlightSourceManual => 'Operations team';

  @override
  String get adminFlightSourceAuto => 'Automatic';

  @override
  String get adminFlightCheckedBag => 'Checked bag';

  @override
  String get adminFlightYes => 'Yes';

  @override
  String get adminFlightNo => 'No';

  @override
  String get adminFlightLastChange => 'Last change';

  @override
  String get adminFlightLastObserved => 'Last data read';

  @override
  String get adminFlightTimesNote => 'Times in Bolivia (La Paz, UTC−4).';

  @override
  String adminFlightReadyAt(String time) {
    return 'The chauffeur must be there at $time';
  }

  @override
  String get adminFlightNoReadyAt => 'No pickup time calculated';

  @override
  String get adminFlightLocked =>
      'Manual lock: automatic sources do not change this data.';

  @override
  String get adminFlightUnlocked => 'No manual lock';

  @override
  String get adminFlightLockTag => 'Manual lock';

  @override
  String adminFlightSetBy(String who, String date) {
    return 'Set by $who on $date';
  }

  @override
  String adminFlightLockClearedBy(String who, String date) {
    return 'Lock removed by $who on $date';
  }

  @override
  String adminFlightChangeReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get adminFlightAdminUnknown => 'an administrator';

  @override
  String get adminFlightLoadError => 'Could not read the flight data';

  @override
  String get adminFlightSetButton => 'Set flight data';

  @override
  String get adminFlightClearLockButton => 'Remove manual lock';

  @override
  String get adminFlightForceNoShowButton => 'Mark as no-show';

  @override
  String get adminFlightSetTitle => 'Set flight data';

  @override
  String get adminFlightSetMessage =>
      'The data is set manually, with a manual lock: no automatic source changes it until the lock is removed. The chauffeur\'s time is recalculated.';

  @override
  String get adminFlightSetStatusLabel => 'Flight status';

  @override
  String get adminFlightSetPick => 'Choose date and time';

  @override
  String get adminFlightSetClearTime => 'Clear time';

  @override
  String get adminFlightSetNoTime => 'No time';

  @override
  String adminFlightSetTimeSemantics(String label, String value) {
    return '$label: $value. Change';
  }

  @override
  String get adminFlightSetActualRequired =>
      'With «Landed» the actual arrival is required';

  @override
  String get adminFlightReasonLabel => 'Reason (10 to 500 characters)';

  @override
  String get adminFlightReasonShort =>
      'The reason needs at least 10 characters';

  @override
  String get adminFlightCancel => 'Cancel';

  @override
  String get adminFlightSetConfirm => 'Set data';

  @override
  String get adminFlightSetDone => 'Flight data set';

  @override
  String get adminFlightClearLockTitle => 'Remove manual lock';

  @override
  String get adminFlightClearLockMessage =>
      'Automatic sources will be able to update this flight again.';

  @override
  String get adminFlightClearLockConfirm => 'Remove lock';

  @override
  String get adminFlightClearLockDone => 'Manual lock removed';

  @override
  String get adminFlightForceNoShowTitle => 'Mark as no-show';

  @override
  String adminFlightForceNoShowMessage(String code) {
    return 'Booking #$code will change to «No-show». Nothing is charged: payment is decided later in the booking.';
  }

  @override
  String get adminFlightForceNoShowConfirm => 'Mark as no-show';

  @override
  String get adminFlightForceNoShowDone => 'Booking marked as no-show';

  @override
  String get adminFlightErrConfigMissing =>
      'The airport exit minutes are missing from the operations settings.';

  @override
  String get adminFlightErrNoFlight => 'This booking has no flight.';

  @override
  String get adminFlightErrNotFound => 'The booking no longer exists.';

  @override
  String get adminFlightErrInvalidTransition =>
      'The booking is no longer in «Chauffeur at the point».';

  @override
  String get adminFlightErrNoShowDisabled =>
      '«No-show» is not enabled: the cancellation policy is missing.';

  @override
  String get adminFlightErrInvalid => 'Check the data: something is not valid.';

  @override
  String get adminFlightErrPermission =>
      'You do not have permission for this action.';

  @override
  String get adminFlightErrGeneric =>
      'The action could not be completed. Try again.';

  @override
  String get adminAirportsAdd => 'New airport';

  @override
  String get adminAirportsEmpty => 'No airports yet';

  @override
  String get adminAirportsEmptyHint =>
      'Create one to define its pickup points.';

  @override
  String get adminAirportsError => 'Could not load the airports';

  @override
  String adminAirportPointSet(String type) {
    return '$type: point set';
  }

  @override
  String adminAirportPointMissing(String type) {
    return '$type: no point';
  }

  @override
  String adminAirportEditSemantics(String code) {
    return 'Edit airport $code';
  }

  @override
  String adminAirportEditTitle(String code) {
    return 'Edit airport $code';
  }

  @override
  String get adminAirportNewTitle => 'New airport';

  @override
  String get adminAirportCode => 'Code (3 letters)';

  @override
  String get adminAirportCodeInvalid =>
      'Three capital letters, for example VVI';

  @override
  String get adminAirportCodeLocked =>
      'The code cannot be changed once created';

  @override
  String get adminAirportName => 'Name';

  @override
  String get adminAirportNameInvalid => 'Between 2 and 120 characters';

  @override
  String get adminAirportCity => 'City';

  @override
  String get adminAirportCityInvalid => 'Between 2 and 80 characters';

  @override
  String get adminAirportTimeZone => 'Time zone: La Paz (UTC−4)';

  @override
  String adminAirportPointTitle(String type) {
    return 'Pickup point · $type';
  }

  @override
  String get adminAirportPointName => 'Point name';

  @override
  String get adminAirportPointNameInvalid => 'Between 1 and 80 characters';

  @override
  String get adminAirportPointInstructions => 'Directions';

  @override
  String get adminAirportPointInstructionsInvalid => 'Up to 500 characters';

  @override
  String get adminAirportLat => 'Latitude';

  @override
  String get adminAirportLng => 'Longitude';

  @override
  String get adminAirportLatInvalid => 'Latitude between -90 and 90';

  @override
  String get adminAirportLngInvalid => 'Longitude between -180 and 180';

  @override
  String get adminAirportZeroInvalid => 'Coordinates (0, 0) are not valid';

  @override
  String get adminAirportPointRemove => 'Remove point';

  @override
  String get adminAirportPointAdd => 'Add point';

  @override
  String get adminAirportPointNone =>
      'No point: the chauffeur will see «Pickup point to be confirmed by our team».';

  @override
  String get adminAirportPointWillRemove =>
      'The point will be removed when saving.';

  @override
  String get adminAirportSave => 'Save';

  @override
  String get adminAirportSaved => 'Airport saved';

  @override
  String get adminAirportFixErrors => 'Check the highlighted fields';

  @override
  String get adminAirportErrInvalid =>
      'Some data is not valid: check code, name, city and coordinates.';

  @override
  String get adminPrefsEmpty => 'No preferences for this trip';

  @override
  String get adminPrefsLoadingLabel => 'Loading trip preferences';

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
  String get bookingPriceOnRequest => 'Quoted when you book';

  @override
  String bookingPriceFrom(String price) {
    return 'from $price';
  }

  @override
  String get bookingPriceChangedTitle => 'The price has changed';

  @override
  String bookingPriceChangedBody(String newPrice, String previousPrice) {
    return 'The price of this trip is now $newPrice (previously $previousPrice). Do you want to book at the new price?';
  }

  @override
  String get bookingPriceChangedDecline => 'Don\'t book';

  @override
  String get bookingPriceChangedAccept => 'Book';

  @override
  String get bookingFlightTypeRequired =>
      'Indicate whether your flight is domestic or international.';

  @override
  String get bookingPickupMissing => 'Enter your pickup point again to book.';

  @override
  String get bookingPickupPast =>
      'The pickup time has passed. Choose a new time.';

  @override
  String get bookingQuoteFailed =>
      'We could not calculate the price. Please try again.';

  @override
  String bookingQuoteReady(String price) {
    return 'The price of your trip is $price. Tap Continue to payment to proceed.';
  }

  @override
  String get bookingHourlyDestination => 'Hourly service';

  @override
  String get bookingChooseExperience => 'Choose your experience';

  @override
  String get bookingPriceBreakdown => 'Price breakdown';

  @override
  String get bookingTotal => 'Total';

  @override
  String get bookingTotalEstimated => 'Estimated total';

  @override
  String get bookingImportantNote => 'Important note:';

  @override
  String get bookingNoteCapacity =>
      'Passenger and luggage capacity limits must be respected for safety reasons. If they are exceeded, the chauffeur may decline the service.';

  @override
  String get bookingNoteImages =>
      'Vehicle images are for reference only. The actual vehicle may vary while keeping equivalent or higher quality.';

  @override
  String get bookingNoteExtras =>
      'Additional needs (wheelchair, child seat, extra items) can be added in \"Pickup notes\". Choose Business Van for larger groups or extra luggage.';

  @override
  String get bookingForMe => 'Book for myself';

  @override
  String get bookingForMeDetail => 'Book with your account details';

  @override
  String get bookingForGuest => 'Book for a guest';

  @override
  String get bookingForGuestDetail => 'Select or add a guest';

  @override
  String get bookingPriceFinal => 'Final price';

  @override
  String get bookingPriceEstimated => 'Estimated price';

  @override
  String get bookingPickup => 'Pickup';

  @override
  String get bookingDuration => 'Duration';

  @override
  String bookingHoursAtDisposal(int hours) {
    return '$hours hours at your disposal';
  }

  @override
  String get bookingDestination => 'Destination';

  @override
  String get bookingBack => 'Back';

  @override
  String bookingStepOf(int step) {
    return 'STEP $step OF 3';
  }

  @override
  String get bookingVehicle => 'Vehicle';

  @override
  String get bookingStepDetails => 'Details';

  @override
  String get bookingConfirm => 'Confirm';

  @override
  String get bookingContinue => 'Continue';

  @override
  String get bookingContinueToPayment => 'Continue to payment';

  @override
  String get bookingTripDetails => 'TRIP DETAILS';

  @override
  String get bookingPassengers => 'Passengers';

  @override
  String get bookingLuggage => 'Luggage';

  @override
  String get bookingSpecialRequests => 'Special requests';

  @override
  String get bookingSpecialRequestsHint => 'Child seat, welcome sign…';

  @override
  String get bookingFlightNumberRequired => 'Flight number *';

  @override
  String get bookingFlightNumber => 'Flight number';

  @override
  String get bookingFlightNumberHint => 'e.g. OB 760';

  @override
  String get bookingFlightNumberHintOptional => 'e.g. OB 760 (optional)';

  @override
  String get bookingSummaryTitle => 'BOOKING SUMMARY';

  @override
  String get bookingSummaryService => 'Service';

  @override
  String get bookingSummaryFrom => 'From';

  @override
  String get bookingSummaryTo => 'To';

  @override
  String get bookingSummaryDistance => 'Distance';

  @override
  String bookingHours(int hours) {
    return '$hours hours';
  }

  @override
  String get bookingSummaryEstDuration => 'Est. duration';

  @override
  String bookingLuggageItems(int count) {
    return '$count items';
  }

  @override
  String get bookingSummaryFlight => 'Flight';

  @override
  String get bookingSummaryNotes => 'Notes';

  @override
  String get bookingTotalFixedPrice => 'TOTAL · FIXED PRICE';

  @override
  String get bookingTotalEstimatedUpper => 'ESTIMATED TOTAL';

  @override
  String get bookingPayNextNote =>
      'You pay in the next step. We look for a chauffeur once the payment is confirmed.';

  @override
  String get bookingFlightNote =>
      'Airport pickup: enter your flight number so your chauffeur has it.';

  @override
  String get bookingFlightType => 'Flight type *';

  @override
  String get bookingConfirmBooking => 'Confirm booking';

  @override
  String get bookingPriceEstimatedUpper => 'ESTIMATED PRICE';

  @override
  String get bookingPriceFinalUpper => 'FINAL PRICE';

  @override
  String get bookingRetry => 'Retry';

  @override
  String get bookingAuthRegisterTitle => 'Create an account';

  @override
  String get bookingAuthLoginTitle => 'Sign in to continue';

  @override
  String get bookingAuthRegisterBody =>
      'Create your Luxelane account to complete the booking.';

  @override
  String get bookingAuthLoginBody => 'Sign in to confirm your booking.';

  @override
  String get bookingAuthFullName => 'Full name';

  @override
  String get bookingAuthFullNameHint => 'Your name';

  @override
  String get bookingAuthEmail => 'Email';

  @override
  String get bookingAuthEmailHint => 'you@example.com';

  @override
  String get bookingAuthPassword => 'Password';

  @override
  String get bookingAuthRegister => 'Create account';

  @override
  String get bookingAuthLogin => 'Sign in';

  @override
  String get bookingAuthHaveAccount => 'Already have an account? Sign in';

  @override
  String get bookingAuthNoAccount => 'Don\'t have an account? Create one';

  @override
  String get bookingGuestTitleMr => 'Mr.';

  @override
  String get bookingGuestTitleMrs => 'Mrs.';

  @override
  String get bookingGuestTitleMiss => 'Ms.';

  @override
  String get bookingGuestTitleDr => 'Dr.';

  @override
  String get bookingGuestTitleProf => 'Prof.';

  @override
  String get bookingGuestAddTitle => 'Add a new guest';

  @override
  String get bookingGuestIntro =>
      'Enter the details of the person who will travel. We will share these details with the assigned chauffeur to coordinate the pickup.';

  @override
  String get bookingGuestSalutation => 'Title';

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
  String get bookingGuestPhoneNote =>
      'The assigned chauffeur will use this number to coordinate the pickup.';

  @override
  String get bookingGuestLanguage => 'Guest\'s language (optional)';

  @override
  String get bookingGuestLanguageHint => 'E.g. Spanish, English';

  @override
  String bookingVehiclePassengers(int count) {
    return '$count passengers';
  }

  @override
  String bookingVehicleBags(int count) {
    return '$count bags';
  }

  @override
  String get bookingVehicleDetailsEyebrow => 'DETAILS';

  @override
  String get bookingLuggageNote =>
      'Standard reference sizes. If you carry special luggage (golf clubs, stroller, instruments), mention it in the pickup notes.';

  @override
  String get bookingChildSeatNote =>
      'A child seat must be requested in advance and is subject to availability. Mention the child\'s age in the pickup notes.';

  @override
  String get bookingCapacityEyebrow => 'CAPACITY';

  @override
  String get bookingCapacityTitle => 'How much fits?';

  @override
  String bookingCapacityDetail(int passengers, int bags) {
    return 'Up to $passengers passengers and $bags checked bags';
  }

  @override
  String get bookingSeating => 'Seating';

  @override
  String get bookingNext => 'Next';

  @override
  String get bookingRatingSaveError =>
      'Your rating could not be saved. Please try again.';

  @override
  String get bookingAcceptTaken =>
      'Another chauffeur has already accepted this trip.';

  @override
  String get bookingAcceptNotVerified =>
      'Your documents have not yet been verified by Luxelane.';

  @override
  String get bookingAcceptBusy =>
      'Go online and finish your current trip before accepting another.';

  @override
  String get bookingAcceptUnavailable => 'This trip is no longer available.';

  @override
  String get bookingAcceptConnection =>
      'The trip could not be accepted. Check your connection.';

  @override
  String get bookingAcceptFailed =>
      'The trip could not be accepted. Please try again.';

  @override
  String get bookingConnectionError =>
      'We could not connect. Check your connection and try again.';

  @override
  String get bookingErrorPricingUnavailable =>
      'We could not calculate the price of this trip right now. Please try again in a few minutes.';

  @override
  String get bookingErrorOutOfArea =>
      'For now we only offer trips within the pickup city.';

  @override
  String get bookingErrorClassUnavailable =>
      'This vehicle class is not available at the moment. Choose another.';

  @override
  String get bookingErrorServiceUnavailable =>
      'Bookings are paused for maintenance. Please try again in a few minutes.';

  @override
  String get bookingErrorInvalidHours => 'Choose a whole number of hours.';

  @override
  String get bookingErrorInactiveUser =>
      'Your account cannot make bookings at the moment.';

  @override
  String get bookingErrorSignIn => 'Sign in to book.';

  @override
  String get bookingErrorPaymentsUnavailable =>
      'We cannot take bookings right now. Please try again later or contact our operations team.';

  @override
  String get bookingErrorInvalidRequest =>
      'We could not process your booking. Check the trip details and try again.';

  @override
  String get bookingErrorServer =>
      'We could not complete the booking due to an issue on our side. Please try again in a few minutes.';

  @override
  String get bookingCancelConnectionError =>
      'The booking could not be cancelled. Check your connection and try again.';

  @override
  String get bookingCancelServerError =>
      'The booking could not be cancelled right now. Please try again in a few minutes; if it persists, contact our operations team.';

  @override
  String get bookingCancelNotCancellable =>
      'This booking can no longer be cancelled: the trip is in progress or has ended.';

  @override
  String get bookingNotFound =>
      'We could not find this booking in your account.';

  @override
  String get bookingVehicleSaveError =>
      'We could not save the change. Please try again.';

  @override
  String get bookingTripsLoadError =>
      'We could not load your trips. Please retry.';

  @override
  String get businessEyebrow => 'For Business';

  @override
  String get businessTitle => 'Corporate travel, redefined.';

  @override
  String get businessLead =>
      'Private chauffeurs for your team and your guests, with centralized billing. Tell us what you need and we will get back to you within one business day.';

  @override
  String get businessSendError =>
      'We could not send your request. Please try again.';

  @override
  String get businessRequired => 'Required field';

  @override
  String businessThanks(String name, String email) {
    return 'Thank you, $name. We received your request and will write to you at $email.';
  }

  @override
  String get businessPerkBilling =>
      'Centralized monthly billing for your company';

  @override
  String get businessPerkPriority =>
      'Priority bookings for executives and guests';

  @override
  String get businessCompany => 'Company';

  @override
  String get businessName => 'Your name';

  @override
  String get businessEmail => 'Work email';

  @override
  String get businessEmailInvalid => 'Enter a valid email';

  @override
  String get businessPhone => 'Phone';

  @override
  String get businessTravellers => 'How many people would travel?';

  @override
  String get businessTravellersOver200 => 'More than 200';

  @override
  String get businessMessage => 'Tell us what you need (optional)';

  @override
  String get businessSubmit => 'Send request';

  @override
  String get commonLockedDocuments =>
      'To change these details, contact our operations team.';

  @override
  String get commonStartupErrorTitle => 'We could not start the app';

  @override
  String get commonStartupErrorBody =>
      'Close the app and open it again in a few minutes.';

  @override
  String commonSeatingPassengers(int count) {
    return '$count passengers';
  }

  @override
  String get commonSeatingMaxDetail => 'Maximum capacity';

  @override
  String get commonSeatingRoomierDetail => 'More room for everyone';

  @override
  String get commonSeatingChildSeat => 'With a child seat';

  @override
  String get commonSeatingChildSeatDetail => 'On prior request';

  @override
  String get commonHighlightBusiness1 => 'Executive sedan, discreet and quiet';

  @override
  String get commonHighlightBusiness2 => 'Leather rear seats for three';

  @override
  String get commonHighlightBusiness3 => 'Boot space for three checked bags';

  @override
  String get commonHighlightSuv1 =>
      'Executive SUV with a raised driving position';

  @override
  String get commonHighlightSuv2 => 'Spacious cabin for four passengers';

  @override
  String get commonHighlightSuv3 => 'Boot space for four checked bags';

  @override
  String get commonHighlightVan1 => 'Executive van for groups and families';

  @override
  String get commonHighlightVan2 => 'Up to seven passengers in three rows';

  @override
  String get commonHighlightVan3 => 'Room for two checked bags';

  @override
  String get commonHighlightFirst1 => 'Flagship sedan, our highest level';

  @override
  String get commonHighlightFirst2 => 'Rear seats with a central armrest';

  @override
  String get commonHighlightTwoCheckedBags => 'Boot space for two checked bags';

  @override
  String get commonHighlightElectric1 => 'Fully electric executive sedan';

  @override
  String get commonHighlightElectric2 => 'Quiet and emission-free';

  @override
  String get commonLuggageCabinOne => 'carry-on bag';

  @override
  String get commonLuggageCheckedOne => 'checked bag';

  @override
  String get commonLuggageOversizeOne => 'oversized bag';

  @override
  String get commonLuggageCabinMany => 'carry-on bags';

  @override
  String get commonLuggageCheckedMany => 'checked bags';

  @override
  String get commonLuggageOversizeMany => 'oversized bags';

  @override
  String get commonLuggageCabinSize => 'Up to 55 × 40 × 20 cm';

  @override
  String get commonLuggageCheckedSize => 'Up to 75 × 50 × 30 cm';

  @override
  String get commonLuggageOversizeSize => 'Over 80 cm';

  @override
  String get commonPromiseFixedPrice => 'Fixed price when you book';

  @override
  String get commonPromiseFixedPriceLong =>
      'The price you see when you confirm is calculated by Luxelane for your journey.';

  @override
  String get commonPromiseChauffeurs => 'Chauffeurs with verified documents';

  @override
  String get commonPromiseChauffeursLong =>
      'Luxelane reviews each chauffeur\'s documents before they receive trips.';

  @override
  String get commonVehicleElectric => 'Electric';

  @override
  String get commonVehicleBusinessDescription => 'Executive sedan';

  @override
  String get commonVehicleSuvDescription => 'Executive SUV, more room';

  @override
  String get commonVehicleFirstDescription => 'Flagship sedan';

  @override
  String get commonVehicleVanDescription => 'Executive van for groups';

  @override
  String get commonVehicleElectricDescription => 'Electric executive sedan';

  @override
  String get commonServiceOneWay => 'One way';

  @override
  String get commonServiceByTheHour => 'By the hour';

  @override
  String get commonServiceOneWayDescription =>
      'Fixed-price transfer to your destination';

  @override
  String get commonServiceByTheHourDescription =>
      'A chauffeur at your disposal for a set time';

  @override
  String get commonStatusPending => 'Pending';

  @override
  String get commonStatusConfirmed => 'Confirmed';

  @override
  String get commonStatusDriverArriving => 'On the way';

  @override
  String get commonStatusDriverArrived => 'Chauffeur arrived';

  @override
  String get commonStatusVerified => 'Verified';

  @override
  String get commonStatusInProgress => 'In progress';

  @override
  String get commonStatusCompleted => 'Completed';

  @override
  String get commonStatusCancelled => 'Cancelled';

  @override
  String get commonStatusNoShow => 'No-show';

  @override
  String get commonCancelReasonChangedPlans => 'My plans changed';

  @override
  String get commonCancelReasonOtherTransport => 'I found other transport';

  @override
  String get commonCancelReasonDriverLate => 'The chauffeur is taking too long';

  @override
  String get commonReasonOther => 'Other reason';

  @override
  String get commonReleaseReasonVehicle => 'Vehicle issue';

  @override
  String get commonReleaseReasonEmergency => 'Personal emergency';

  @override
  String get commonReleaseReasonUnsafe => 'Unsafe conditions';

  @override
  String get commonReleaseReasonSchedule => 'Schedule conflict';

  @override
  String get commonFeeBasisNoPolicy => 'No cancellation policy';

  @override
  String get commonFeeBasisPolicyInvalid => 'Invalid policy (no fee)';

  @override
  String get commonFeeBasisPaymentFailed => 'Payment failed';

  @override
  String get commonFeeBasisNoDriver => 'No chauffeur assigned';

  @override
  String get commonFeeBasisGrace => 'Within the window after booking';

  @override
  String get commonFeeBasisEarly => 'With enough notice';

  @override
  String get commonFeeBasisLate => 'Late (fee applies)';

  @override
  String get commonFeeBasisNoShowAdmin => 'No-show (operations team decision)';

  @override
  String get commonPickupArea => 'Pickup area';

  @override
  String get commonDropoffArea => 'Destination area';

  @override
  String get commonTariffNegative => 'Amounts cannot be negative';

  @override
  String get commonTariffZeroTransfer => 'A transfer cannot cost Bs0';

  @override
  String get commonTariffHourlyPrice =>
      'The hourly service needs an hourly price';

  @override
  String get commonLocationNotificationTitle => 'Luxelane · you are online';

  @override
  String get commonLocationNotificationText =>
      'We share your location to assign you trips and guide the passenger.';

  @override
  String get commonLocationChannelName => 'Chauffeur location';

  @override
  String get commonPricingLoading =>
      'Loading the current rates… try again in a few seconds.';

  @override
  String get commonPricingMaintenance =>
      'Bookings are paused for maintenance. Try again in a few minutes.';

  @override
  String commonPricingUnavailable(String vehicleClass, String serviceType) {
    return '$vehicleClass is not available for \"$serviceType\" at the moment.';
  }

  @override
  String get commonPromptEnjoyJourney => 'Enjoy the journey.';

  @override
  String get commonPromptChauffeurWaiting =>
      'Your chauffeur is waiting for you.';

  @override
  String get commonPromptChauffeurOnTheWay => 'Your chauffeur is on the way.';

  @override
  String get commonPromptNextTripSoon => 'Your next journey is coming up.';

  @override
  String get commonPromptMorning => 'Where does your day begin?';

  @override
  String get commonPromptMidday => 'Where can we take you?';

  @override
  String get commonPromptAfternoon => 'Shall we end the day calmly?';

  @override
  String get commonPromptEvening => 'Shall we head back calmly?';

  @override
  String get commonPromptLateNight => 'We are here at any hour.';

  @override
  String get commonFlightDomestic => 'Domestic';

  @override
  String get commonFlightInternational => 'International';

  @override
  String get commonOriginNoCoords =>
      'We could not find the pickup on the map. Choose another address.';

  @override
  String commonOriginOutsideArea(String cities) {
    return 'For now we operate in $cities. Choose a pickup in one of those cities.';
  }

  @override
  String commonDestinationOtherCity(String city) {
    return 'The destination must be in $city, the same city as the pickup.';
  }

  @override
  String get commonDestinationSameCity =>
      'The destination must be in the same city as the pickup.';

  @override
  String get commonFlightNumberMissing =>
      'Enter your flight number: we use it to work out your pickup time.';

  @override
  String get commonFlightNumberInvalid =>
      'Invalid flight number. Example: OB 760 or Z8 315.';

  @override
  String get commonAppTitle => 'Luxelane — Executive chauffeur service';

  @override
  String get commonTabBook => 'Book';

  @override
  String get commonTabMyTrips => 'My trips';

  @override
  String get commonTabProfile => 'Profile';

  @override
  String get commonSignIn => 'Sign in';

  @override
  String get commonMyProfile => 'My profile';

  @override
  String get commonNotFoundTitle => 'This page does not exist.';

  @override
  String get commonNotFoundBody => 'We will take you back to the home page.';

  @override
  String get commonNotFoundBack => 'BACK TO HOME';

  @override
  String get commonUpdateTitleDriver => 'Update the app to continue';

  @override
  String get commonUpdateTitleRider => 'Update the app to book';

  @override
  String get commonUpdateBodyWeb =>
      'There is a new version of the website. Reload the page to continue booking.';

  @override
  String get commonUpdateBodyApp =>
      'There is a new version of the app. Update it to continue booking.';

  @override
  String get commonUpdateGoToStore => 'Go to the store';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonEmailNotVerifiedTitle => 'Verify your email to book';

  @override
  String get commonEmailNotVerifiedBody =>
      'For your security, bookings require a verified email. Open the link we sent you or request a new one.';

  @override
  String get commonNotNow => 'Not now';

  @override
  String get commonVerifyMyEmail => 'Verify my email';

  @override
  String get commonErrorTitle => 'Something went wrong';

  @override
  String get commonErrorBody =>
      'We have been notified and are working on a solution.';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonOfflineBanner =>
      'No connection. What you see may not be up to date.';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonDone => 'Done';

  @override
  String commonStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get commonSlideToConfirm => 'Slide to confirm';

  @override
  String commonUpTo(int count) {
    return 'Up to $count';
  }

  @override
  String commonHoursTotal(int hours) {
    return '${hours}h in total';
  }

  @override
  String get commonFixedPriceLower => 'fixed price';

  @override
  String get commonRiderStyle => 'PASSENGER PREFERENCES';

  @override
  String get commonConfirmBooking => 'Confirm booking';

  @override
  String get commonFixedPriceUpper => 'FIXED PRICE';

  @override
  String get commonMapUnavailable => 'Map unavailable';

  @override
  String get commonMapUnavailableDetail =>
      'The map cannot be shown right now. Your trip details are still here.';

  @override
  String get commonPointOnMap => 'Point chosen on the map';

  @override
  String get commonSelectLocation => 'Select location';

  @override
  String get commonMoveMapToChoose => 'Move the map to choose the place';

  @override
  String get commonSelectedLocation => 'SELECTED LOCATION';

  @override
  String get commonConfirmUpper => 'CONFIRM';

  @override
  String get commonAddressNotFound =>
      'We could not locate that address. Try another one or choose it on the map.';

  @override
  String get commonSelectPickupPlace => 'Select pickup point';

  @override
  String get commonSelectDestination => 'Select destination';

  @override
  String get commonDestinationWasOtherCity =>
      'The destination was in another city. Choose one in the pickup city.';

  @override
  String get commonPickupDateUpper => 'PICKUP DATE';

  @override
  String get commonPickupTimeUpper => 'PICKUP TIME';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonNext => 'Next';

  @override
  String get commonPickupMissing => 'Tell us where to pick you up.';

  @override
  String commonPickupMovedLater(String when) {
    return 'There is no longer enough time for that pickup: we moved it to $when. Check it and continue.';
  }

  @override
  String get commonDestinationMissing =>
      'Enter your destination to calculate the fixed price.';

  @override
  String get commonPickupHintAirport => 'Pickup — airport, hotel or address';

  @override
  String get commonPickupHint => 'Pickup — address, hotel or place';

  @override
  String get commonDestinationHintAirport =>
      'Destination — airport, hotel or address';

  @override
  String get commonDestinationOptional => 'Destination (optional)';

  @override
  String get commonDestinationHint => 'Destination — address, hotel or place';

  @override
  String get commonBookYourChauffeur => 'BOOK YOUR CHAUFFEUR';

  @override
  String get commonPickup => 'Pickup';

  @override
  String get commonDestination => 'Destination';

  @override
  String get commonNow => 'Now';

  @override
  String get commonSchedule => 'Schedule';

  @override
  String get commonChange => 'Change';

  @override
  String get commonSeeVehiclesAndPrices => 'SEE VEHICLES AND PRICES';

  @override
  String get commonNoCommitment =>
      'No commitment: you will see the final price before you confirm.';

  @override
  String get commonChooseOnMap => 'Choose on the map';

  @override
  String get commonDuration => 'Duration';

  @override
  String get commonFewerHours => 'Fewer hours';

  @override
  String get commonMoreHours => 'More hours';

  @override
  String get commonServiceAirportTransfer => 'Airport transfer';

  @override
  String get commonServiceHourly => 'Hourly chauffeur';

  @override
  String get commonServiceImmediate => 'Immediate pickup';

  @override
  String get commonHomeLinkLabel => 'Luxelane, home';

  @override
  String get commonFleet => 'Fleet';

  @override
  String get commonForBusiness => 'For business';

  @override
  String get commonServicesUpper => 'SERVICES';

  @override
  String get commonBookUpper => 'BOOK';

  @override
  String get commonBookATripUpper => 'BOOK A TRIP';

  @override
  String get commonMenu => 'Menu';

  @override
  String get commonCloseMenu => 'Close menu';

  @override
  String get commonClose => 'Close';

  @override
  String get commonServices => 'Services';

  @override
  String get commonFooterTagline =>
      'A private chauffeur service for those who value their time, their privacy and every detail of the journey.';

  @override
  String get commonDriveWithUs => 'Drive with us';

  @override
  String get commonTerms => 'Terms and conditions';

  @override
  String get commonPrivacy => 'Privacy policy';

  @override
  String get commonOurPromise => 'Our promise';

  @override
  String commonCopyright(String year) {
    return '© $year Luxelane. All rights reserved.';
  }

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
  String get driverSignOut => 'Sign out';

  @override
  String get driverContinue => 'Continue';

  @override
  String get driverFieldRequired => 'Required';

  @override
  String get driverFieldInvalid => 'Invalid';

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
  String get regIntroTitle => 'Drive with Luxelane';

  @override
  String get regIntroBody =>
      'To sign up as a chauffeur, this account becomes a chauffeur account.';

  @override
  String get regIntroPointOneWay =>
      'The account stops being a passenger account and cannot be used to book rides again.';

  @override
  String get regIntroPointBookings =>
      'If you have already booked rides as a passenger with this email, create another account with a different email to sign up as a chauffeur.';

  @override
  String get regIntroPointReview =>
      'Then you will complete your details, your vehicle details and your documents. Luxelane reviews them before enabling you.';

  @override
  String get regIntroStart => 'Convert to a chauffeur account';

  @override
  String get regIntroConfirmTitle => 'Convert this account?';

  @override
  String get regIntroConfirmBody =>
      'This account can no longer be used as a passenger. This cannot be undone.';

  @override
  String get regIntroConfirmYes => 'Yes, convert';

  @override
  String get regCancel => 'Cancel';

  @override
  String get regSignOut => 'Sign out';

  @override
  String get regTitle => 'Your chauffeur application';

  @override
  String regStepOf(int current, int total, String title) {
    return 'Step $current of $total: $title';
  }

  @override
  String regProgressLabel(int current, int total) {
    return 'Application progress: step $current of $total';
  }

  @override
  String get regStepPersonal => 'Your details';

  @override
  String get regStepVehicle => 'Your vehicle';

  @override
  String get regStepDocuments => 'Documents';

  @override
  String get regStepSecurity => 'Two-step verification';

  @override
  String get regStepSummary => 'Summary and submission';

  @override
  String get regBack => 'Back';

  @override
  String get regContinue => 'Continue';

  @override
  String get regSaveContinue => 'Save and continue';

  @override
  String get regRetry => 'Try again';

  @override
  String get regSaving => 'Saving…';

  @override
  String get regFullName => 'Full name';

  @override
  String get regNationalId => 'ID document number';

  @override
  String get regLicenseNumber => 'Driver\'s license number';

  @override
  String get regLicenseExpiry => 'License expiry date';

  @override
  String get regPickDate => 'Choose date';

  @override
  String get regFieldRequired => 'Fill in this field';

  @override
  String get regFullNameInvalid => 'Enter your full name (2 to 120 characters)';

  @override
  String get regIdInvalid => 'Use only letters, numbers and hyphens (4 to 20)';

  @override
  String get regDateInFuture => 'Choose a date after today';

  @override
  String get regPrivacyNote =>
      'Your document numbers are only seen by the Luxelane team that reviews the application.';

  @override
  String get regMake => 'Make';

  @override
  String get regModel => 'Model';

  @override
  String get regYear => 'Year';

  @override
  String regYearInvalid(int min, int max) {
    return 'Year between $min and $max';
  }

  @override
  String get regTextInvalid => 'Between 1 and 40 characters';

  @override
  String get regColor => 'Color';

  @override
  String get regColorOtherText => 'Enter the color';

  @override
  String get regColorOtherInvalid => 'Between 1 and 20 characters';

  @override
  String get regPlate => 'License plate';

  @override
  String get regPlateInvalid => 'Letters and numbers only (4 to 10)';

  @override
  String get regBodyType => 'Vehicle type';

  @override
  String get regPassengers => 'Passengers';

  @override
  String get regVehicleClass => 'Service class';

  @override
  String get regVehicleChangeNote =>
      'If you change vehicles after approval, the new one stays in review until Luxelane approves it.';

  @override
  String get regDocsIntro =>
      'Upload each document with a sharp photo, in good light and without glare.';

  @override
  String get regDocsNotConfigured =>
      'Luxelane has not yet defined which documents are required. You can complete your details; submission is enabled once they are defined.';

  @override
  String get regDocRequired => 'Required';

  @override
  String get regDocOptional => 'Optional';

  @override
  String regDocExpires(String date) {
    return 'Expires: $date';
  }

  @override
  String regDocRejectedReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get regDocUpload => 'Upload';

  @override
  String get regDocReupload => 'Upload again';

  @override
  String get regDocUploading => 'Uploading…';

  @override
  String get regWebUploadBlocked =>
      'Documents and photos are uploaded from the Luxelane app on your phone. Here you can complete your details and your vehicle details.';

  @override
  String get regUploadFailed =>
      'The photo couldn\'t be uploaded. Check your connection and try again.';

  @override
  String get regPhotoTooSmall =>
      'The photo resolution is too low. Take it closer and in good light.';

  @override
  String get regPhotoUnreadable =>
      'We couldn\'t read the photo. Take it again.';

  @override
  String get regHelpIdDocument =>
      'Place the document on a flat surface, in good light and without glare. All four corners should be visible and the text readable.';

  @override
  String get regHelpPaper =>
      'Photograph the whole page, straight on and without shadows.';

  @override
  String get regHelpProfile =>
      'Your face straight on, without sunglasses or a cap, against a light background.';

  @override
  String get regHelpLive =>
      'It is taken on the spot with the front camera. Look at the camera in good light.';

  @override
  String get regHelpVehicle =>
      'The whole vehicle from this side, in good light.';

  @override
  String get regHelpInterior =>
      'The whole interior from this point, in good light.';

  @override
  String get regHelpPlate =>
      'The license plate straight on, complete and readable.';

  @override
  String get regFrameHint =>
      'The camera opens full screen: frame it like this guide.';

  @override
  String get regFrameLabel => 'Framing guide';

  @override
  String get regTakePhoto => 'Take photo';

  @override
  String get regFromGallery => 'Choose from gallery';

  @override
  String get regLiveCameraOnly =>
      'This photo can only be taken with the camera, not from the gallery.';

  @override
  String get regReviewTitle => 'Check the photo';

  @override
  String get regReviewHint => 'Make sure it is readable and not cropped.';

  @override
  String get regPhotoPreviewLabel => 'Photo preview';

  @override
  String get regRetake => 'Retake';

  @override
  String get regUsePhoto => 'Use this photo';

  @override
  String get regExpiryNeeded => 'Document expiry date';

  @override
  String get regExpiryRequired => 'Enter the expiry date';

  @override
  String get regPhotoCancelled => 'No photo was taken.';

  @override
  String get regCameraUnavailable =>
      'The camera couldn\'t be opened. Check the app permissions.';

  @override
  String get regSecurityBody =>
      'To submit the application and later go online, your account needs two-step verification with an authenticator app.';

  @override
  String get regSecurityEnroll => 'Turn on two-step verification';

  @override
  String get regSecurityReady =>
      'Two-step verification is active in this session.';

  @override
  String get regSecuritySignInAgain =>
      'You already have it turned on. Sign out and sign in again with the code from your authenticator app to continue.';

  @override
  String get regSecurityCheck => 'Check again';

  @override
  String get regSecurityNeededToSubmit =>
      'Before submitting, turn on two-step verification.';

  @override
  String get regSummaryIntro => 'Review your application before submitting it.';

  @override
  String get regSummaryPersonal => 'Personal details';

  @override
  String get regSummaryVehicle => 'Vehicle';

  @override
  String regSummaryDocs(int done, int total) {
    return 'Required documents ready: $done of $total';
  }

  @override
  String regSummaryMissing(String list) {
    return 'Missing: $list';
  }

  @override
  String get regSummaryIncomplete =>
      'Complete your details and your vehicle details to submit.';

  @override
  String get regEdit => 'Edit';

  @override
  String get regSubmit => 'Submit application';

  @override
  String get regSubmitted => 'Application submitted.';

  @override
  String get regStatusReviewTitle => 'Application in review';

  @override
  String get regStatusReviewBody =>
      'Luxelane is reviewing your application. You will get a notice in the app when there is an answer.';

  @override
  String get regStatusNeedsChanges =>
      'Luxelane asked for changes to your application. Check the highlighted documents and submit it again.';

  @override
  String get regStatusRejectedTitle => 'Application not approved';

  @override
  String get regStatusRejectedBody =>
      'This application was not approved and is closed.';

  @override
  String get regRefresh => 'Refresh';

  @override
  String get regOnlineNeedsMfa =>
      'To go online, turn on two-step verification.';

  @override
  String get regOnlineNeedsMfaSignIn =>
      'To go online, sign out and sign in again with the code from your authenticator app.';

  @override
  String get regOnlineMfaAction => 'Turn on';

  @override
  String get regDocTypeProfilePhoto => 'Profile photo';

  @override
  String get regDocTypeLivePhoto => 'Live photo';

  @override
  String get regDocTypeNationalIdFront => 'ID document (front)';

  @override
  String get regDocTypeNationalIdBack => 'ID document (back)';

  @override
  String get regDocTypeLicenseFront => 'Driver\'s license (front)';

  @override
  String get regDocTypeLicenseBack => 'Driver\'s license (back)';

  @override
  String get regDocTypeCriminalRecord => 'Criminal record certificate';

  @override
  String get regDocTypeVehicleOwnership => 'Vehicle ownership document';

  @override
  String get regDocTypeVehicleSoat => 'Mandatory accident insurance (SOAT)';

  @override
  String get regDocTypeVehicleInspection => 'Vehicle technical inspection';

  @override
  String get regDocTypeVehicleInsurance => 'Vehicle insurance';

  @override
  String get regDocTypeVehiclePermit => 'Vehicle operating permit';

  @override
  String get regDocTypeOwnerAuthorization => 'Owner authorization';

  @override
  String get regDocTypeVehiclePhotoFront => 'Vehicle: front';

  @override
  String get regDocTypeVehiclePhotoBack => 'Vehicle: rear';

  @override
  String get regDocTypeVehiclePhotoLeft => 'Vehicle: left side';

  @override
  String get regDocTypeVehiclePhotoRight => 'Vehicle: right side';

  @override
  String get regDocTypeVehiclePhotoInteriorFront => 'Vehicle: front interior';

  @override
  String get regDocTypeVehiclePhotoInteriorBack => 'Vehicle: rear interior';

  @override
  String get regDocTypeVehiclePhotoPlate => 'Vehicle: license plate';

  @override
  String get regAppStatusDraft => 'Draft';

  @override
  String get regAppStatusSubmitted => 'Submitted';

  @override
  String get regAppStatusInReview => 'In review';

  @override
  String get regAppStatusNeedsChanges => 'Needs changes';

  @override
  String get regAppStatusApproved => 'Approved';

  @override
  String get regAppStatusRejected => 'Rejected';

  @override
  String get regDocStatusPendingUpload => 'To upload';

  @override
  String get regDocStatusUploaded => 'Uploaded, in review';

  @override
  String get regDocStatusApproved => 'Approved';

  @override
  String get regDocStatusRejected => 'Rejected';

  @override
  String get regDocStatusExpired => 'Expired';

  @override
  String get regRejectIllegible => 'Not legible';

  @override
  String get regRejectExpired => 'It has expired';

  @override
  String get regRejectWrongDocument => 'Not the requested document';

  @override
  String get regRejectIncomplete => 'Incomplete or cropped';

  @override
  String get regRejectDataMismatch =>
      'The details do not match the application';

  @override
  String get regRejectLowQuality => 'Low image quality';

  @override
  String get regRejectOther => 'Other reason';

  @override
  String get regColorBlack => 'Black';

  @override
  String get regColorWhite => 'White';

  @override
  String get regColorSilver => 'Silver';

  @override
  String get regColorGray => 'Gray';

  @override
  String get regColorBlue => 'Blue';

  @override
  String get regColorRed => 'Red';

  @override
  String get regColorGreen => 'Green';

  @override
  String get regColorBeige => 'Beige';

  @override
  String get regColorBrown => 'Brown';

  @override
  String get regColorOther => 'Other';

  @override
  String get regBodySedan => 'Sedan';

  @override
  String get regBodySuv => 'SUV';

  @override
  String get regBodyVan => 'Van';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorMfaRequired =>
      'Turn on two-step verification (Profile) and sign in again to continue.';

  @override
  String get errorReauthRequired =>
      'For your security, sign in again to continue.';

  @override
  String get errorNoConnection =>
      'No connection to the server. Check your network and try again.';

  @override
  String get errorReauthWrongPassword => 'The password does not match.';

  @override
  String get errorReauthUserMismatch =>
      'Use the same account you signed in with.';

  @override
  String get errorReauthFailed =>
      'We could not confirm your identity. Please try again.';

  @override
  String get errorInvalidArgument => 'Check the details and try again.';

  @override
  String get errorPermissionDenied => 'You do not have permission to do this.';

  @override
  String get errorFailedPrecondition => 'This cannot be done at the moment.';

  @override
  String get errorNotFound => 'We could not find the record.';

  @override
  String get errorGeneric => 'This could not be completed. Please try again.';

  @override
  String get errorDeleteActiveBookings =>
      'You have active or booked trips. Cancel them or wait until they finish before deleting your account.';

  @override
  String get errorDeleteAdminAccount =>
      'Administrator accounts are deleted from the console.';

  @override
  String get errorDeleteAccountFailed =>
      'We could not delete your account. Please try again.';

  @override
  String get errorTermsOutdated =>
      'The terms have just been updated. Open them again and accept them once more.';

  @override
  String get errorAcceptTermsFailed =>
      'We could not record your acceptance. Please try again.';

  @override
  String get errorBusinessLeadTooMany =>
      'We have already received several requests from here. Try again later or write to us.';

  @override
  String get errorBusinessLeadInvalid => 'Check the form details.';

  @override
  String get errorBusinessLeadFailed =>
      'We could not send your request. Please try again.';

  @override
  String get errorBadCredentials => 'Incorrect email or password.';

  @override
  String errorPasswordResetSent(String email) {
    return 'If there is an account with $email, we sent you a link to reset your password. Check your spam folder as well.';
  }

  @override
  String get errorLoginFailed => 'We could not sign you in. Please try again.';

  @override
  String get errorRegisterEmailInUse =>
      'We could not create an account with that email. If you have already signed up, sign in or reset your password.';

  @override
  String get errorInvalidEmail => 'That email is not valid. Please check it.';

  @override
  String get errorWeakPassword =>
      'The password is too weak: use at least 6 characters.';

  @override
  String get errorRegisterFailed =>
      'We could not create the account. Please try again.';

  @override
  String get errorPasswordResetFailed =>
      'We could not send the link. Please try again.';

  @override
  String get errorServerDefault =>
      'The operation could not be completed. Please try again.';

  @override
  String get errorEmailNotVerified => 'Verify your email to make a booking.';

  @override
  String get errorTermsRequired =>
      'Accept the current terms to make a booking.';

  @override
  String get errorAuthDefault => 'We could not sign you in. Please try again.';

  @override
  String get errorAuthCancelledDefault => 'Sign-in cancelled.';

  @override
  String get errorNetworkDefault => 'No internet connection';

  @override
  String get errorNotFoundDefault =>
      'We could not find what you were looking for.';

  @override
  String get errorPaymentDefault =>
      'The payment could not be processed. Please try again.';

  @override
  String get errorPermissionDefault => 'You do not have permission to do this.';

  @override
  String get errorPriceChanged => 'The price of this trip has changed.';

  @override
  String get errorCancellationFeeChanged => 'The cancellation fee has changed.';

  @override
  String get errorAppUpdateDriver =>
      'Update the app to continue with your trips.';

  @override
  String get errorAppUpdateRider => 'Update the app to make a booking.';

  @override
  String get errorValidationDefault =>
      'Please check the details and try again.';

  @override
  String get errorMfaEnterCode => 'Enter the code from your authenticator app.';

  @override
  String get errorMfaWrongCode =>
      'Incorrect code. Use the current code from your authenticator app (and check that your phone\'s time is set automatically).';

  @override
  String get errorMfaRecentLogin =>
      'For your security, sign out, sign in again and repeat the setup.';

  @override
  String get errorMfaUnverifiedEmail =>
      'Verify your email before turning on two-step verification.';

  @override
  String get errorMfaNoConnection =>
      'No connection. Check your network and try again.';

  @override
  String get errorMfaQrExpired =>
      'The QR code has expired. Start the setup again.';

  @override
  String get errorMfaNotEnabled =>
      'Two-step verification is not enabled yet. Let our operations team know.';

  @override
  String get errorMfaNoTotp =>
      'Your account has no authenticator app registered. Contact our operations team.';

  @override
  String get errorMfaFailed =>
      'The verification could not be completed. Please try again.';

  @override
  String get errorAccountBlocked =>
      'Your account is blocked. Write to our support team if you think this is a mistake.';

  @override
  String get errorDriverSuspended =>
      'Account suspended. Contact our operations team.';

  @override
  String get errorAppCheckFailed =>
      'The app could not be verified. Update it or try again later.';

  @override
  String get errorProfileNotFound =>
      'We could not find your profile. Please sign in again.';

  @override
  String get regErrorHasBookings =>
      'This account already has bookings as a passenger. To sign up as a chauffeur, create an account with a different email.';

  @override
  String get regErrorDriverAccount =>
      'A chauffeur account cannot use passenger payments.';

  @override
  String get regErrorNotARider =>
      'This account cannot start a chauffeur application.';

  @override
  String get regErrorAdminAccount =>
      'An administrator account cannot sign up as a chauffeur.';

  @override
  String get regErrorInactiveUser => 'Your account is blocked.';

  @override
  String get regErrorNotADriver =>
      'This account does not have a chauffeur application yet.';

  @override
  String get regErrorLockedAfterApproval =>
      'Your details have already been approved; only Luxelane can change them.';

  @override
  String get regErrorApplicationClosed =>
      'This application is closed and can no longer be changed.';

  @override
  String get regErrorPlateInUse =>
      'That license plate is already registered to another active vehicle.';

  @override
  String get regErrorInvalidFile =>
      'The file is not a valid image or is too large. Take the photo again.';

  @override
  String get regErrorFileMissing =>
      'We couldn\'t find the uploaded file. Try again.';

  @override
  String get regErrorUnexpectedVersion =>
      'The document changed while you were uploading it. Refresh the screen and try again.';

  @override
  String get regErrorDocumentExpired =>
      'The expiry date has already passed. Upload a valid document.';

  @override
  String get regErrorRequirementsNotConfigured =>
      'We can\'t receive applications yet: the required documents haven\'t been defined. You can save your details and submit later.';

  @override
  String get regErrorStepsIncomplete =>
      'Complete your personal and vehicle details before submitting.';

  @override
  String get regErrorDocumentsMissing =>
      'Some required documents are missing, expired or rejected.';

  @override
  String get regErrorInvalidRequest =>
      'Check the highlighted details and try again.';

  @override
  String get regErrorDriverDocsBlocked =>
      'You have expired required documents. Upload them again to go back online.';

  @override
  String get regErrorProfileNotFound =>
      'We couldn\'t find your profile. Sign out and sign in again.';

  @override
  String get regErrorDocumentsNotApproved =>
      'Cannot approve: some required documents are not approved or have expired.';

  @override
  String get regErrorNotDecidable =>
      'The application is not in a state that allows this decision.';

  @override
  String get regErrorNotReviewable =>
      'This document cannot be reviewed in its current state.';

  @override
  String get regErrorStaleVersion =>
      'The chauffeur uploaded a newer version. Refresh and review the latest one.';

  @override
  String get regErrorDocumentNotFound =>
      'That document does not exist or has not been uploaded yet.';

  @override
  String get regErrorDriverNotFound => 'We couldn\'t find that chauffeur.';

  @override
  String get regErrorApplicationNotFound =>
      'We couldn\'t find that application.';

  @override
  String get regErrorPurgeDisabled => 'Document deletion is turned off.';

  @override
  String get regErrorGeneric => 'We couldn\'t complete this step. Try again.';

  @override
  String get bookingErrorFlightConfigMissing =>
      'Pickups with a flight cannot be booked yet. Try again later.';

  @override
  String get bookingErrorAirportUnknown =>
      'This airport is not available for pickups yet.';

  @override
  String get bookingErrorFlightNotAirportPickup =>
      'The flight is only entered when the pickup is at the arrival airport.';

  @override
  String get bookingFlightSectionTitle => 'Your flight';

  @override
  String get bookingFlightAirline => 'Airline (optional)';

  @override
  String get bookingFlightDate => 'Flight date';

  @override
  String get bookingFlightTime => 'Arrival time on your ticket';

  @override
  String get bookingFlightPickDate => 'Choose date';

  @override
  String get bookingFlightPickTime => 'Choose time';

  @override
  String get bookingFlightDateMissing => 'Enter the flight date';

  @override
  String get bookingFlightTimeMissing =>
      'Enter the arrival time on your ticket';

  @override
  String get bookingFlightCheckedBagQuestion => 'Do you have checked luggage?';

  @override
  String get bookingFlightCheckedBagYes => 'Yes, checked luggage';

  @override
  String get bookingFlightCheckedBagNo => 'No, carry-on only';

  @override
  String get bookingFlightCheckedBagHelp =>
      'If you say you have no checked luggage but you do, your chauffeur may leave before you come out.';

  @override
  String rideFlightDelayed(String time) {
    return 'Your flight shows a delay. New pickup time: $time.';
  }

  @override
  String get rideFlightDisrupted =>
      'Your flight shows as cancelled or diverted. Our team will review your booking.';

  @override
  String get driverFlightCardTitle => 'Flight';

  @override
  String driverFlightStatus(String status) {
    return 'Status: $status';
  }

  @override
  String driverRequestAirportFlight(String airport, String type) {
    return 'Airport $airport · $type';
  }

  @override
  String get flightStatusScheduled => 'Scheduled';

  @override
  String get flightStatusDelayed => 'Delayed';

  @override
  String get flightStatusLanded => 'Landed';

  @override
  String get flightStatusCancelled => 'Cancelled';

  @override
  String get flightStatusDiverted => 'Diverted';

  @override
  String get flightStatusUnknown => 'No data';

  @override
  String get flightPickupPointPending =>
      'Pickup point to be confirmed by our team';

  @override
  String flightNoLiveData(String time) {
    return 'No live flight data: scheduled time $time';
  }

  @override
  String flightBeAtPointAt(String time) {
    return 'Be at the pickup point at $time';
  }

  @override
  String flightDriverWillBeAt(String time) {
    return 'Pickup time at the point: $time';
  }

  @override
  String flightEstimatedArrival(String time) {
    return 'Estimated arrival: $time';
  }

  @override
  String flightScheduledArrival(String time) {
    return 'Scheduled arrival: $time';
  }

  @override
  String flightActualArrival(String time) {
    return 'Landed: $time';
  }

  @override
  String get homePickOriginTitle => 'Select pickup point';

  @override
  String get homePickDestinationTitle => 'Select destination';

  @override
  String get homeDestinationOtherCity =>
      'The destination was in another city. Choose one in the pickup city.';

  @override
  String get homeEnterPickup => 'Enter a pickup point';

  @override
  String homePickupMoved(String when) {
    return 'That time is no longer possible: we moved it to $when. Check it and continue.';
  }

  @override
  String get homeEnterDestination => 'Enter a destination';

  @override
  String get homeLocationUnavailable =>
      'We could not use your location. Allow location access in your browser or phone settings, or choose the point on the map.';

  @override
  String get homeMyProfile => 'My profile';

  @override
  String get homeSeeVehicles => 'See vehicles and prices';

  @override
  String homeHourlyFrom(int hours, String place) {
    return '$hours h from $place';
  }

  @override
  String get homeNextTripSemantics => 'View your next trip';

  @override
  String get homeNextTripEyebrow => 'YOUR NEXT TRIP';

  @override
  String get homePickupLabel => 'Pickup point';

  @override
  String get homePickupHint => 'Pickup';

  @override
  String get homeUseMyLocation => 'Use my location';

  @override
  String get homeDestinationLabel => 'Destination';

  @override
  String get homeDestinationHint => 'Where are you going?';

  @override
  String get homeChooseOnMap => 'Choose on the map';

  @override
  String get homeRepeatLast => 'Repeat last trip';

  @override
  String homeRouteSummary(String km, int minutes) {
    return '$km km · $minutes min';
  }

  @override
  String homePreferredClass(String vehicleClass) {
    return 'Your $vehicleClass';
  }

  @override
  String get homePickupDateHelp => 'PICKUP DATE';

  @override
  String get homePickupTimeHelp => 'PICKUP TIME';

  @override
  String get homePickerCancel => 'Cancel';

  @override
  String get homePickerNext => 'Next';

  @override
  String get homePickerDone => 'Done';

  @override
  String get homeChangePickupTime => 'Change pickup date and time';

  @override
  String homeAsap(String time) {
    return 'As soon as possible · $time';
  }

  @override
  String get homeSchedule => 'Schedule';

  @override
  String get homeDuration => 'Duration';

  @override
  String get homeWebHeadlineStart => 'Your chauffeur ';

  @override
  String get homeWebHeadlineEnd => 'awaits you.';

  @override
  String get homeWebPickup => 'PICKUP';

  @override
  String get homeWebWhereAreYou => 'Where are you?';

  @override
  String get homeWebDestination => 'DESTINATION';

  @override
  String get homeWebDuration => 'DURATION';

  @override
  String get homeWebDateTime => 'DATE AND TIME';

  @override
  String get homeWebChangeLocation => 'CHANGE LOCATION';

  @override
  String get homeWebOneWay => 'One way';

  @override
  String get homeWebHourly => 'By the hour';

  @override
  String get homeWebSeePrices => 'SEE PRICES';

  @override
  String get homeWebConfirm => 'CONFIRM';

  @override
  String homeWebHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get homeWebMarqueeFixedPrices => 'Fixed Prices';

  @override
  String get homeWebMarqueeChauffeurs => 'Professional Chauffeurs';

  @override
  String get homeWebMarqueeFleet => 'Premium Fleet';

  @override
  String get homeWebMarqueeAirport => 'Airport Transfers';

  @override
  String get homeWebMarqueeCorporate => 'Corporate Travel';

  @override
  String get homeWebFleetEyebrow => 'Our Fleet';

  @override
  String get homeWebFleetTitle => 'Premium vehicles,\nwithout exception.';

  @override
  String get homeWebFleetSwipe => 'SWIPE TO EXPLORE →';

  @override
  String get homeWebReview1Quote =>
      'Absolutely impeccable from start to finish. The chauffeur arrived early and the car was spotless. I will not use anyone else.';

  @override
  String get homeWebReview1Location => 'London, United Kingdom';

  @override
  String get homeWebReview2Quote =>
      'Fixed prices and reliable chauffeurs make Luxelane the only service I trust for all my business trips.';

  @override
  String get homeWebReview2Location => 'New York, USA';

  @override
  String get homeWebReview3Quote =>
      'From the airport to the hotel, every detail was handled perfectly. This is how luxury travel should feel.';

  @override
  String get homeWebReview3Location => 'Paris, France';

  @override
  String get homeWebBusinessPerkBilling => 'Centralized billing and payments';

  @override
  String get homeWebBusinessPerkPriority => 'Priority bookings for executives';

  @override
  String get homeWebBusinessEyebrow => 'For Business';

  @override
  String get homeWebBusinessTitle => 'Corporate travel,\nredefined.';

  @override
  String get homeWebBusinessBody =>
      'Luxelane for Business gives your team access to a premium chauffeur service with the controls and reports your finance team requires.';

  @override
  String get homeWebLearnMore => 'Learn more';

  @override
  String get homeWebCtaEyebrow => 'WHENEVER YOU WANT. WHEREVER YOU WANT.';

  @override
  String get homeWebCtaTitleStart => 'Your next journey,';

  @override
  String get homeWebCtaTitleEnd => 'on your terms.';

  @override
  String get homeWebCtaPromise => 'Fixed price  ·  Professional chauffeurs';

  @override
  String get homeWebCtaBook => 'Book a trip';

  @override
  String get homeWebCtaFleet => 'View fleet';

  @override
  String get homeWebBookTagline => 'Premium Chauffeur Service';

  @override
  String get homeWebBookStandardLabel => 'The Standard';

  @override
  String get homeWebBookStandardSub => 'The Promise We Keep';

  @override
  String get homeWebBookStandardTag => 'The Luxelane Standard';

  @override
  String get homeWebBookStandardHeadline => 'The standard\nothers follow.';

  @override
  String get homeWebBookStandardBullet1 => 'Chauffeurs with verified documents';

  @override
  String get homeWebBookStandardBullet2 => 'Fixed price when you book';

  @override
  String get homeWebBookExperienceLabel => 'The Experience';

  @override
  String get homeWebBookExperienceSub => 'Every Detail Considered';

  @override
  String get homeWebBookExperienceHeadline => 'Every detail,\ncared for.';

  @override
  String get homeWebBookExperienceBody =>
      'From curated playlists to noise-cancelling privacy — your preferences, remembered.';

  @override
  String get homeWebBookExperienceBullet1 => 'Premium leather interiors';

  @override
  String get homeWebBookExperienceBullet2 => 'Wi-Fi and wireless charging';

  @override
  String get homeWebBookExperienceBullet3 => 'Champagne service available';

  @override
  String get homeWebBookExperienceBullet4 => 'Climate control';

  @override
  String get homeWebBookBusinessSub => 'Corporate Travel Redefined';

  @override
  String get homeWebBookBusinessBullet1 => 'Centralized billing';

  @override
  String get homeWebBookEyebrow => 'OUR SIGNATURE EXPERIENCE';

  @override
  String get homeWebBookScroll => 'SCROLL';

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
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationsNow => 'Now';

  @override
  String notificationsMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String notificationsHoursAgo(int hours) {
    return '${hours}h ago';
  }

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
  String get prefsNoPreference => 'No preference';

  @override
  String get prefsLanguagesTitle => 'Chauffeur\'s languages';

  @override
  String get prefsLanguageEs => 'Spanish';

  @override
  String get prefsLanguageEn => 'English';

  @override
  String get prefsLanguagePt => 'Portuguese';

  @override
  String get prefsTemperatureTitle => 'Temperature';

  @override
  String get prefsTemperatureCool => 'Cool';

  @override
  String get prefsTemperatureMild => 'Mild';

  @override
  String get prefsConversationTitle => 'Conversation';

  @override
  String get prefsConversationChatty => 'Happy to chat';

  @override
  String get prefsConversationQuiet => 'I prefer quiet';

  @override
  String get prefsMusicTitle => 'Music';

  @override
  String get prefsMusicClassical => 'Classical';

  @override
  String get prefsMusicJazz => 'Jazz';

  @override
  String get prefsMusicInstrumental => 'Instrumental';

  @override
  String get prefsMusicPop => 'Pop';

  @override
  String get prefsMusicRock => 'Rock';

  @override
  String get prefsMusicLatin => 'Latin';

  @override
  String get prefsMusicElectronic => 'Electronic';

  @override
  String get prefsMusicFolk => 'Folk';

  @override
  String get prefsMusicNone => 'No music';

  @override
  String get prefsPlaylistTitle => 'Playlist';

  @override
  String get prefsNeedsTitle => 'Practical needs';

  @override
  String get prefsNeedExtraLuggage => 'Extra luggage';

  @override
  String get prefsNeedLuggageAssistance => 'Help with luggage';

  @override
  String get prefsNeedChildSeat => 'Child seat';

  @override
  String get prefsNeedBoosterSeat => 'Booster seat';

  @override
  String get prefsNeedBoardingAssistance => 'Help getting in';

  @override
  String get prefsNeedFoldingWheelchair => 'Folding wheelchair';

  @override
  String get prefsNeedPetInCarrier => 'Pet in a carrier';

  @override
  String get prefsNeedPrivateHint =>
      'Only your assigned chauffeur will see this.';

  @override
  String get prefsNoteTitle => 'Note for your chauffeur';

  @override
  String get prefsNoteWarning =>
      'Do not write sensitive information: passwords, cards or health details.';

  @override
  String get prefsDriverWillSee => 'Your chauffeur will see these preferences.';

  @override
  String get prefsCardTitle => 'Passenger preferences';

  @override
  String get prefsOpenPlaylist => 'Open playlist';

  @override
  String get prefsOpenPlaylistTitle => 'Open outside the app';

  @override
  String get prefsOpenPlaylistBody =>
      'The playlist will open outside Luxelane, in your browser or another app.';

  @override
  String get prefsOpenPlaylistConfirm => 'Open';

  @override
  String get prefsCancel => 'Cancel';

  @override
  String get prefsOpenPlaylistError => 'The playlist could not be opened.';

  @override
  String prefsLanguagesSummary(String languages) {
    return 'Languages: $languages';
  }

  @override
  String get prefsErrorPlaylist =>
      'That playlist link cannot be used. Check that it starts with https and is from a supported service.';

  @override
  String get prefsErrorNote =>
      'Check the note: up to 200 characters and no links.';

  @override
  String get prefsSaved => 'Preferences saved.';

  @override
  String get prefsScreenTitle => 'Preferences';

  @override
  String get prefsEmpty =>
      'You have no preferences yet. Add any you would like your chauffeur to know.';

  @override
  String get prefsEmptyShort => 'No preferences yet';

  @override
  String get prefsSave => 'Save';

  @override
  String get prefsPlaylistHelp =>
      'Paste an https link. It always opens outside the app.';

  @override
  String get prefsPlaylistInvalid => 'The link must start with https://';

  @override
  String get prefsNoteHint => 'For example, where to wait for you';

  @override
  String get prefsTripTitle => 'Preferences for this trip';

  @override
  String get prefsTripFromProfile => 'From your profile.';

  @override
  String get prefsTripChanged => 'Changed for this trip only.';

  @override
  String get prefsTripEdit => 'Change for this trip';

  @override
  String get prefsTripSkip => 'Skip';

  @override
  String get prefsTripReset => 'Use my profile\'s';

  @override
  String get prefsTripApply => 'Use for this trip';

  @override
  String get prefsTripEmpty => 'No preferences for this trip.';

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
  String get profilePreferencesEntry => 'Preferences for your chauffeur';

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
  String get servicesPromiseEyebrow => 'Our promise';

  @override
  String get servicesPromiseTitle => 'Peace of mind, in writing.';

  @override
  String get servicesStepsEyebrow => 'How it works';

  @override
  String get servicesStepsTitle => 'Three steps.\nNothing more.';

  @override
  String get servicesFleetEyebrow => 'The fleet';

  @override
  String get servicesFleetTitle => 'Choose how you arrive.';

  @override
  String get servicesFleetBody =>
      'High-end vehicles, spotless and prepared before every service.';

  @override
  String get servicesMostChosen => 'MOST CHOSEN';

  @override
  String servicesCapacity(int count) {
    return 'Up to $count passengers';
  }

  @override
  String get servicesPriceFrom => 'FROM';

  @override
  String get servicesQuoteOnBooking => 'Quoted when you book';

  @override
  String get servicesFaqEyebrow => 'Frequently asked questions';

  @override
  String get servicesFaqTitle => 'Everything\nyou want to know.';

  @override
  String get servicesBookNow => 'BOOK NOW';

  @override
  String get servicesAirportEyebrow => 'Airport transfer';

  @override
  String get servicesAirportTitle => 'Land.\nWe take care\nof the rest.';

  @override
  String get servicesAirportLead =>
      'Your chauffeur waits for you in arrivals with your name and takes care of your luggage. You just walk out the door.';

  @override
  String get servicesAirportStep1Title => 'Book in 2 minutes';

  @override
  String get servicesAirportStep1Body =>
      'Enter the airport, destination and time. Add your flight number and you will see the final price.';

  @override
  String get servicesAirportStep2Title => 'Meet your chauffeur';

  @override
  String get servicesAirportStep2Body =>
      'Before pickup, you will have their name, vehicle and contact details in the app.';

  @override
  String get servicesAirportStep3Title => 'Walk out and relax';

  @override
  String get servicesAirportStep3Body =>
      'They wait for you in arrivals, take care of your luggage and drive you straight to your destination.';

  @override
  String get servicesAirportStoryEyebrow => 'The arrival';

  @override
  String get servicesAirportStoryTitle =>
      'The first moment\nof your journey, taken care of.';

  @override
  String get servicesAirportStoryBody =>
      'After a long flight, the last thing you want is queues, negotiations or uncertainty. A Luxelane chauffeur turns your arrival into a calm transition to your hotel, your meeting or your home.';

  @override
  String get servicesAirportStoryPoint1 =>
      'Help with your luggage, from the carousel to the trunk';

  @override
  String get servicesAirportStoryPoint2 =>
      'Smooth connections between airports and hotels';

  @override
  String get servicesAirportFaq1Question =>
      'Where will my chauffeur wait for me?';

  @override
  String get servicesAirportFaq1Answer =>
      'In the arrivals area. You will receive their contact details in the app before pickup.';

  @override
  String get servicesAirportFaq2Question => 'Can I cancel my booking?';

  @override
  String get servicesAirportFaq2Answer =>
      'Yes, from the app before the trip starts. If the cancellation policy applies a fee, you will see it before you confirm.';

  @override
  String get servicesAirportFaq3Question => 'How much luggage can I bring?';

  @override
  String get servicesAirportFaq3Answer =>
      'It depends on the vehicle class. If you travel with a lot of luggage or in a group, the Business Van has room for up to 7 passengers.';

  @override
  String get servicesAirportClosingTitle =>
      'Your next flight\nalready has a chauffeur.';

  @override
  String get servicesAirportClosingBody =>
      'Book now. Fixed price when you book and chauffeurs with verified documents.';

  @override
  String get servicesHourlyEyebrow => 'Hourly chauffeur';

  @override
  String get servicesHourlyTitle =>
      'Your schedule.\nYour pace.\nYour chauffeur.';

  @override
  String get servicesHourlyLead =>
      'A chauffeur and a vehicle just for you, from 2 to 24 hours. Change your plans as often as you like: your chauffeur adapts.';

  @override
  String get servicesHourlyStopsTitle => 'Unlimited stops';

  @override
  String get servicesHourlyStopsDetail =>
      'Meetings, shopping or visits: your chauffeur waits for you at every stop.';

  @override
  String get servicesHourlyStep1Title => 'Choose the duration';

  @override
  String get servicesHourlyStep1Body =>
      'Enter the pickup point, the day and how many hours you need. Minimum 2, maximum 24.';

  @override
  String get servicesHourlyStep2Title => 'Plan your day';

  @override
  String get servicesHourlyStep2Body =>
      'Share your itinerary in the notes or decide as you go. No final destination is needed.';

  @override
  String get servicesHourlyStep3Title => 'Enjoy without watching the clock';

  @override
  String get servicesHourlyStep3Body =>
      'Your chauffeur and your vehicle are at your disposal for the entire time booked.';

  @override
  String get servicesHourlyStoryEyebrow => 'For every occasion';

  @override
  String get servicesHourlyStoryTitle =>
      'A whole day,\nwithout thinking about getting around.';

  @override
  String get servicesHourlyStoryBody =>
      'From a day of meetings to an afternoon discovering the city, the hourly service gives you the freedom of a private vehicle without any of the worries.';

  @override
  String get servicesHourlyStoryPoint1 =>
      'Business trips: from meeting to meeting, without waiting';

  @override
  String get servicesHourlyStoryPoint2 =>
      'Events and dinners: an impeccable arrival, an unhurried departure';

  @override
  String get servicesHourlyStoryPoint3 =>
      'Private sightseeing: the city at your pace, with a local chauffeur';

  @override
  String get servicesHourlyStoryPoint4 =>
      'Shopping and leisure: your chauffeur keeps your bags and waits for you';

  @override
  String get servicesHourlyFaq1Question => 'How do I book an hourly chauffeur?';

  @override
  String get servicesHourlyFaq1Answer =>
      'Select the pickup point, the duration, the day and the time. Then choose the vehicle class and confirm. You will see the final price before you pay.';

  @override
  String get servicesHourlyFaq2Question =>
      'Can I change the itinerary during the service?';

  @override
  String get servicesHourlyFaq2Answer =>
      'Yes. The chauffeur and the vehicle are at your disposal for all the hours booked, with as many stops as you need.';

  @override
  String get servicesHourlyFaq3Question => 'Can I add more hours?';

  @override
  String get servicesHourlyFaq3Answer =>
      'Yes, you can change the booking before the start time. The minimum duration is 2 hours and the maximum is 24.';

  @override
  String get servicesHourlyFaq4Question => 'Can it start or end at an airport?';

  @override
  String get servicesHourlyFaq4Answer =>
      'Yes. The service can start or end at an airport, as long as the start and the end are in the same city.';

  @override
  String get servicesHourlyFaq5Question =>
      'When will I receive my chauffeur\'s details?';

  @override
  String get servicesHourlyFaq5Answer =>
      'Before pickup, you will have the chauffeur\'s name, the vehicle and their contact details in the app.';

  @override
  String get servicesHourlyClosingTitle =>
      'Book the time.\nWe take care of the road.';

  @override
  String get servicesHourlyClosingBody =>
      'From 2 hours, with a fixed price and a professional chauffeur entirely at your disposal.';

  @override
  String get servicesImmediateEyebrow => 'On-demand pickup';

  @override
  String get servicesImmediateTitle => 'When you\nneed it.';

  @override
  String get servicesImmediateLead =>
      'The same excellence as an advance booking, without planning ahead.';

  @override
  String get servicesImmediateTrackingTitle => 'Real-time tracking';

  @override
  String get servicesImmediateTrackingDetail =>
      'See on the map where your chauffeur is and when they arrive.';

  @override
  String get servicesImmediateStep1Title => 'Enter pickup and destination';

  @override
  String get servicesImmediateStep1Body =>
      'Type the address or choose it on the map. You will see the final price before you confirm.';

  @override
  String get servicesImmediateStep2Title => 'Confirm with one tap';

  @override
  String get servicesImmediateStep2Body =>
      'You pay for the booking. Once the payment is confirmed, we look for a chauffeur and show you their name and vehicle.';

  @override
  String get servicesImmediateStep3Title => 'Follow them on the map';

  @override
  String get servicesImmediateStep3Body =>
      'Get a notification when your chauffeur is on the way and another when they have arrived.';

  @override
  String get servicesImmediateStoryEyebrow => 'Unplanned';

  @override
  String get servicesImmediateStoryTitle =>
      'The unexpected,\nwith the same elegance.';

  @override
  String get servicesImmediateStoryBody =>
      'A meeting that runs late, a change of plans, a dinner that deserves a fitting end. On-demand pickup puts a premium vehicle and a professional chauffeur within your reach.';

  @override
  String get servicesImmediateStoryPoint1 =>
      'Premium vehicles, spotless on every service';

  @override
  String get servicesImmediateStoryPoint2 =>
      'Chauffeurs with verified documents';

  @override
  String get servicesImmediateStoryPoint3 =>
      'Fixed price calculated before you confirm, with no surge pricing';

  @override
  String get servicesImmediateFaq1Question =>
      'How long does the chauffeur take to arrive?';

  @override
  String get servicesImmediateFaq1Answer =>
      'It depends on your location and availability. You will see the estimated arrival time before you confirm and can follow the chauffeur on the map.';

  @override
  String get servicesImmediateFaq2Question =>
      'Does the price change with demand?';

  @override
  String get servicesImmediateFaq2Answer =>
      'No. The price is set before you confirm and does not change: no surge pricing and no hidden charges.';

  @override
  String get servicesImmediateFaq3Question =>
      'Can I schedule the trip for later?';

  @override
  String get servicesImmediateFaq3Answer =>
      'Yes. Choose \"Schedule\" in the form and select the day and time you prefer.';

  @override
  String get servicesImmediateFaq4Question =>
      'What happens if I need to cancel?';

  @override
  String get servicesImmediateFaq4Answer =>
      'You can cancel from the app before the trip starts. If the cancellation policy applies a fee, you will see it before you confirm.';

  @override
  String get servicesImmediateClosingTitle => 'Your chauffeur,\none tap away.';

  @override
  String get servicesImmediateClosingBody =>
      'Confirm now and follow your chauffeur in real time to your door.';

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
