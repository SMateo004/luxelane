import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_booking_events.dart';

void main() {
  String name(String uid) => uid == 'jefa' ? 'Jefa' : 'Luis';

  test('lee el evento del servidor y su ubicación (solo admin)', () {
    final e = BookingEvent.fromJson('e1', {
      'type': 'transition',
      'from': 'driver_arrived',
      'to': 'verified',
      'actor': {'uid': 'chofer', 'role': 'driver'},
      'source': 'driver_app',
      'at': Timestamp.fromDate(DateTime(2026, 10, 20, 15)),
      'appVersion': '2.0.0',
      'method': 'pickup_code',
    }, {
      'lat': -17.6,
      'lng': -63.1,
    });
    expect(e.from, BookingStatus.driverArrived);
    expect(e.to, BookingStatus.verified);
    expect(e.hasLocation, isTrue);
    expect(bookingEventTitle(e), 'Chófer llegó → Verificada');
    expect(bookingEventDetails(e, name).first,
        'Chófer Luis · app 2.0.0 · con el código del pasajero');
  });

  test('override del admin: muestra quién y el motivo', () {
    final e = BookingEvent.fromJson('e2', {
      'from': 'driver_arrived',
      'to': 'verified',
      'actor': {'uid': 'jefa', 'role': 'admin'},
      'source': 'admin',
      'method': 'admin_override',
      'reason': 'Pasajero sin batería',
    });
    expect(e.hasLocation, isFalse);
    final d = bookingEventDetails(e, name);
    expect(d.first, 'Admin Jefa · forzada por el admin');
    expect(d, contains('Motivo: Pasajero sin batería'));
  });

  test('llegada sin radio o sin ubicación queda anotada', () {
    BookingEvent arrival(String check) => BookingEvent.fromJson('e', {
          'from': 'driver_arriving',
          'to': 'driver_arrived',
          'actor': {'uid': 'chofer', 'role': 'driver'},
          'arrivalCheck': check,
        });
    expect(bookingEventDetails(arrival('no_radius'), name),
        contains(startsWith('Sin radio de llegada')));
    expect(bookingEventDetails(arrival('no_location'), name),
        contains('El chófer no envió su ubicación al llegar'));
  });
}
