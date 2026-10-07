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
  static const cancelFailed = 'booking/cancel-failed';
  static const notCancellable = 'booking/not-cancellable';
  static const costCenterRequired = 'booking/cost-center-required';
  static const companyInactive = 'booking/company-inactive';
  static const corporateNotAllowed = 'booking/corporate-not-allowed';
  static const promoNoLongerValid = 'booking/promo-no-longer-valid';
}

/// Promo error codes from checkPromoCode / quoteBooking (functions/src/promo.ts).
abstract final class PromoErrorCodes {
  static const invalid = 'promo/invalid';
  static const notStarted = 'promo/not-started';
  static const expired = 'promo/expired';
  static const exhausted = 'promo/exhausted';
  static const alreadyUsed = 'promo/already-used';
  static const firstRideOnly = 'promo/first-ride-only';
  static const vehicleClass = 'promo/vehicle-class';
  static const minFare = 'promo/min-fare';
  static const failed = 'promo/failed';
}
