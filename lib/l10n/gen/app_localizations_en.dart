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
