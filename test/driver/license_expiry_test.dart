import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_onboarding_screen.dart';

void main() {
  final now = DateTime(2026, 10, 15);

  test('vigente hasta el último día del mes', () {
    expect(validateLicenseExpiry('10/2026', now: now), isNull);
    expect(parseLicenseExpiry('02/2028')!.day, 29);
  });

  test('rechaza licencias vencidas y formatos raros', () {
    expect(validateLicenseExpiry('09/2026', now: now), 'Licencia vencida');
    expect(validateLicenseExpiry('13/2027', now: now), contains('MM/AAAA'));
    expect(validateLicenseExpiry('2027', now: now), contains('MM/AAAA'));
    expect(validateLicenseExpiry('', now: now), 'Requerido');
  });
}
