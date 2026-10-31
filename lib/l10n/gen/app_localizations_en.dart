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
}
