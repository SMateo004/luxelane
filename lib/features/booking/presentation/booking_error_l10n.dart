import '../../../l10n/l10n.dart';
import '../domain/booking_error_codes.dart';

/// Translates a booking failure message for display. Known
/// [BookingErrorCodes] map to localized text; anything else is returned as is.
String localizedBookingError(AppLocalizations l, String message) => switch (message) {
      BookingErrorCodes.quoteFailed => l.bookingErrorQuoteFailed,
      BookingErrorCodes.quoteMissing => l.bookingErrorQuoteMissing,
      BookingErrorCodes.quoteExpired => l.bookingErrorQuoteExpired,
      BookingErrorCodes.createFailed => l.bookingErrorCreateFailed,
      BookingErrorCodes.paymentNotAuthorised => l.bookingErrorPaymentNotAuthorised,
      BookingErrorCodes.invalidFlight => l.bookingErrorInvalidFlight,
      BookingErrorCodes.tooManyPassengers => l.bookingErrorTooManyPassengers,
      BookingErrorCodes.rateFailed => l.bookingErrorRateFailed,
      BookingErrorCodes.cancelFailed => l.rideCancelFailed,
      BookingErrorCodes.notCancellable => l.rideCancelNotAllowed,
      BookingErrorCodes.costCenterRequired => l.corpErrorCostCenterRequired,
      BookingErrorCodes.companyInactive => l.corpErrorCompanyInactive,
      BookingErrorCodes.corporateNotAllowed => l.corpErrorNotAllowed,
      BookingErrorCodes.accountSuspended => l.accountSuspendedError,
      BookingErrorCodes.promoNoLongerValid => l.promoErrorNoLongerValid,
      PromoErrorCodes.invalid => l.promoErrorInvalid,
      PromoErrorCodes.notStarted => l.promoErrorNotStarted,
      PromoErrorCodes.expired => l.promoErrorExpired,
      PromoErrorCodes.exhausted => l.promoErrorExhausted,
      PromoErrorCodes.alreadyUsed => l.promoErrorAlreadyUsed,
      PromoErrorCodes.firstRideOnly => l.promoErrorFirstRideOnly,
      PromoErrorCodes.vehicleClass => l.promoErrorVehicleClass,
      PromoErrorCodes.minFare => l.promoErrorMinFare,
      PromoErrorCodes.failed => l.promoErrorFailed,
      PromoErrorCodes.loyaltyBetter => l.promoLoyaltyBetter,
      _ => message,
    };
