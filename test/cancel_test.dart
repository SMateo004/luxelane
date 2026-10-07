import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/features/booking/domain/booking_error_codes.dart';
import 'package:luxelane/features/booking/presentation/booking_error_l10n.dart';
import 'package:luxelane/l10n/l10n.dart';

void main() {
  test('cancellation errors are translated in every language', () {
    for (final code in ['es', 'en', 'pt']) {
      final l = lookupAppLocalizations(Locale(code));
      expect(localizedBookingError(l, BookingErrorCodes.notCancellable), l.rideCancelNotAllowed);
      expect(localizedBookingError(l, BookingErrorCodes.cancelFailed), l.rideCancelFailed);
    }
    expect(
      localizedBookingError(lookupAppLocalizations(const Locale('en')), BookingErrorCodes.notCancellable),
      'This booking can no longer be cancelled in the app.',
    );
  });
}
