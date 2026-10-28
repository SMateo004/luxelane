import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pagos B2: la app del chófer no lee el pago del pasajero. Ni su estado
/// (bookings/{id}/payment), ni la referencia, ni lo pagado, retenido o
/// devuelto. Las reglas tampoco se lo dejan leer (MATRIZ_ACCESO, pagos A1);
/// esto evita que una pantalla lo intente.
void main() {
  test('el código del chófer no toca el pago del pasajero', () {
    final files = [
      ...Directory('lib/features/driver').listSync(recursive: true),
      ...Directory('lib/app/driver_router').listSync(recursive: true),
      ...Directory('lib/app/driver_shell').listSync(recursive: true),
      File('lib/app/driver_app.dart'),
    ].whereType<File>().where((f) => f.path.endsWith('.dart'));
    final forbidden = RegExp(
      r"BookingPayment|booking_payment|collection\('payment'\)|"
      r'amountDue|amountPaid|amountRetained|amountRefunded|refundDue|'
      r'balanceDue|paymentRef|paymentStatus|cancellationFee|'
      r'payment_receipt|PaymentReceipt|PaymentPending',
    );
    final hits = <String>[];
    for (final f in files) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (forbidden.hasMatch(lines[i])) hits.add('${f.path}:${i + 1}');
      }
    }
    expect(hits, isEmpty);
  });
}
