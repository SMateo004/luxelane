/// Stable failure codes returned by `BookingRepository` as `Failure.message`.
///
/// The data layer has no BuildContext, so it reports these codes and the UI
/// translates them with `localizedBookingError`
/// (presentation/booking_error_l10n.dart).
abstract final class BookingErrorCodes {
  static const quoteFailed = 'booking/quote-failed';
  static const quoteMissing = 'booking/quote-missing';
  static const quoteExpired = 'booking/quote-expired';
  static const createFailed = 'booking/create-failed';
  static const paymentNotAuthorised = 'booking/payment-not-authorised';
  static const invalidFlight = 'booking/invalid-flight';
  static const tooManyPassengers = 'booking/too-many-passengers';
  static const rateFailed = 'booking/rate-failed';
}
