import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/booking_payment.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/trips/presentation/pages/trips_screen.dart';

/// E41: Mis viajes distingue «Esperando pago», «Pendiente» y «Pagada».
/// Referencias e importes de PRUEBA, ficticios.
class _Repo implements BookingPaymentRepository {
  final ctrl = StreamController<BookingPayment?>.broadcast();
  final watched = <String>[];

  Future<void> dispose() => ctrl.close();

  @override
  Stream<BookingPayment?> watch(String bookingId) {
    watched.add(bookingId);
    return ctrl.stream;
  }

  @override
  Future<Either<Failure, PaymentStart>> start(String b, String m) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> markSent(String b, {String? operationNumber}) =>
      throw UnimplementedError();
}

BookingPayment _p(String status) => BookingPayment.fromJson('b1', {
      'paymentStatus': status,
      'amountDue': 12000,
      'amountPaid': status == 'paid' ? 12000 : 0,
    });

Booking _b(String status) => Booking.fromJson({
      'id': 'b1',
      'riderId': 'ana',
      'origin': {'address': 'A', 'coordinates': const GeoPoint(-17.78, -63.18)},
      'destination': {
        'address': 'B',
        'coordinates': const GeoPoint(-17.7, -63.1)
      },
      'status': status,
      'estimatedPrice': 120,
    });

void main() {
  group('tripPaymentBadge', () {
    test('pendiente sin pagar, rechazada o pagada', () {
      expect(
          tripPaymentBadge(BookingStatus.pending, _p('awaiting_payment'))
              ?.label,
          'Esperando pago');
      expect(tripPaymentBadge(BookingStatus.pending, _p('failed'))?.label,
          'Esperando pago');
      expect(
          tripPaymentBadge(BookingStatus.pending, _p('paid'))?.label, 'Pagada');
    });

    test('sin estado de pago u otro estado: la etiqueta de siempre', () {
      expect(tripPaymentBadge(BookingStatus.pending, null), isNull);
      expect(tripPaymentBadge(BookingStatus.confirmed, _p('paid')), isNull);
      expect(tripPaymentBadge(BookingStatus.cancelled, _p('expired')), isNull);
    });
  });

  testWidgets('la tarjeta cambia con el pago; el historial no escucha pagos',
      (t) async {
    final repo = _Repo();
    addTearDown(repo.dispose);
    Future<void> pump(Booking b) => t.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TripStatusChip(booking: b, repository: repo)),
          ),
        );
    await pump(_b('pending'));
    // Mientras llega el estado del pago: la de siempre.
    expect(find.text('Pendiente'), findsOneWidget);
    repo.ctrl.add(_p('awaiting_payment'));
    await t.pump();
    expect(find.text('Esperando pago'), findsOneWidget);
    repo.ctrl.add(_p('paid'));
    await t.pump();
    await t.pump();
    expect(find.text('Pagada'), findsOneWidget);
    expect(repo.watched, ['b1']);

    await pump(_b('completed'));
    expect(find.text('Completado'), findsOneWidget);
    expect(repo.watched, ['b1']);
  });
}
