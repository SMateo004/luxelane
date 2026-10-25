import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/function_errors.dart';
import '../../../../core/models/models.dart';
import '../../domain/admin_operations.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(
    this._db, {
    fb.FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _authOverride = auth,
        _functionsOverride = functions;

  final FirebaseFirestore _db;
  final fb.FirebaseAuth? _authOverride;
  final FirebaseFunctions? _functionsOverride;

  fb.FirebaseAuth get _auth => _authOverride ?? fb.FirebaseAuth.instance;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  @override
  int get bookingsLimit => 1000;

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  Stream<List<T>> _watch<T>(
    Query<Map<String, dynamic>> query,
    T Function(Map<String, dynamic>) parse, {
    String idField = 'id',
  }) =>
      query.snapshots().map(
            (snap) => snap.docs
                .map((doc) {
                  try {
                    return parse({...doc.data(), idField: doc.id});
                  } catch (_) {
                    // Un documento mal formado no debe tumbar todo el panel.
                    return null;
                  }
                })
                .whereType<T>()
                .toList(),
          );

  @override
  Stream<List<Booking>> watchAllBookings() => _watch(
        _db
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .limit(bookingsLimit),
        Booking.fromJson,
      );

  @override
  Stream<List<Payment>> watchAllPayments() => _watch(
        _db
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .limit(bookingsLimit * 2),
        Payment.fromJson,
      );

  @override
  Stream<List<User>> watchAllUsers() =>
      _watch(_db.collection('users'), User.fromJson);

  @override
  Stream<List<DriverProfile>> watchAllDrivers() => _watch(
        _db.collection('driverProfiles'),
        DriverProfile.fromJson,
        idField: 'userId',
      );

  @override
  Stream<List<PricingRule>> watchPricingRules() =>
      _watch(_db.collection('pricingRules'), PricingRule.fromJson);

  @override
  Stream<List<Vehicle>> watchAllVehicles() =>
      _watch(_db.collection('vehicles'), Vehicle.fromJson);

  @override
  Stream<List<AuditLog>> watchAuditLogs() => _watch(
        _db
            .collection('admin_logs')
            .orderBy('createdAt', descending: true)
            .limit(250),
        AuditLog.fromJson,
      );

  @override
  Stream<List<AdminAlert>> watchAdminAlerts() => _watch(
        _db
            .collection('adminAlerts')
            .orderBy('createdAt', descending: true)
            .limit(200),
        AdminAlert.fromJson,
      );

  @override
  Future<Either<Failure, void>> resolveAlert(
    String alertId, {
    String note = '',
  }) async {
    try {
      await _functions.httpsCallable('resolveAlert').call({
        'alertId': alertId,
        if (note.trim().isNotEmpty) 'note': note.trim(),
      });
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(_fnError(e)));
    } catch (_) {
      return const Left(
        ServerFailure('No se pudo marcar la alerta. Revisa tu conexión.'),
      );
    }
  }

  @override
  Stream<List<BookingEvent>> watchBookingEvents(String bookingId) {
    final ref = _db.collection('bookings').doc(bookingId);
    return ref.collection('events').orderBy('at').snapshots().asyncMap((
      events,
    ) async {
      final locations = await ref.collection('eventLocations').get();
      final details = await ref.collection('eventDetails').get();
      final byId = {for (final d in locations.docs) d.id: d.data()};
      final detailById = {for (final d in details.docs) d.id: d.data()};
      return events.docs
          .map(
            (d) => BookingEvent.fromJson(
              d.id,
              d.data(),
              byId[d.id],
              detailById[d.id],
            ),
          )
          .toList();
    });
  }

  @override
  Future<Either<Failure, void>> forceVerify(
    String bookingId,
    String reason,
  ) async {
    try {
      await _functions.httpsCallable('adminOverrideVerify').call({
        'bookingId': bookingId,
        'reason': reason.trim(),
      });
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      final why = (e.details is Map ? e.details as Map : const {})['reason'];
      return Left(
        ServerFailure(
          why == 'not_at_pickup'
              ? 'Solo se fuerza con el chófer en la recogida.'
              : why == 'invalid_request'
                  ? 'Escribe un motivo de al menos 5 caracteres.'
                  : _fnError(e),
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure('No se pudo forzar la verificación. Revisa tu conexión.'),
      );
    }
  }

  @override
  Stream<List<Incident>> watchOpenIncidents() => _db
      .collection('incidents')
      .where(
        'status',
        whereIn: ['open', 'acknowledged', 'cancel_requested'],
      )
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => Incident.fromJson(d.id, d.data())).toList(),
      );

  @override
  Stream<List<IncidentLogEntry>> watchIncidentLog(String incidentId) => _db
      .collection('incidents')
      .doc(incidentId)
      .collection('events')
      .orderBy('at')
      .snapshots()
      .map(
        (s) => s.docs.map((d) => IncidentLogEntry.fromJson(d.data())).toList(),
      );

  ({double lat, double lng})? _latLng(Map<String, dynamic>? d) {
    final lat = (d?['lat'] as num?)?.toDouble();
    final lng = (d?['lng'] as num?)?.toDouble();
    return lat == null || lng == null ? null : (lat: lat, lng: lng);
  }

  @override
  Stream<({double lat, double lng})?> watchIncidentLocation(
    String incidentId,
  ) =>
      _db
          .collection('incidents')
          .doc(incidentId)
          .collection('locations')
          .orderBy('at', descending: true)
          .limit(1)
          .snapshots()
          .map((s) => s.docs.isEmpty ? null : _latLng(s.docs.first.data()));

  @override
  Stream<({double lat, double lng})?> watchDriverTracking(String bookingId) =>
      _db
          .collection('bookings')
          .doc(bookingId)
          .collection('tracking')
          .doc('driver')
          .snapshots()
          .map((s) => _latLng(s.data()));

  Future<Either<Failure, void>> _incidentCall(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      await _functions.httpsCallable(name).call(data);
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      final why = (e.details is Map ? e.details as Map : const {})['reason'];
      return Left(
        ServerFailure(switch (why) {
          'invalid_request' => 'Escribe una nota de al menos 10 caracteres.',
          'not_open' => 'Este incidente ya no está abierto.',
          _ => _fnError(e),
        }),
      );
    } catch (_) {
      return const Left(
        ServerFailure(
          'No se pudo actualizar el incidente. Revisa tu conexión.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> acknowledgeIncident(String incidentId) =>
      _incidentCall('acknowledgeIncident', {'incidentId': incidentId});

  @override
  Future<Either<Failure, void>> closeIncident(String incidentId, String note) =>
      _incidentCall('closeIncident', {
        'incidentId': incidentId,
        'note': note.trim(),
      });

  @override
  Stream<Map<String, dynamic>> watchGlobalSettings() => _db
      .collection('config')
      .doc('global')
      .snapshots()
      .map((doc) => doc.data() ?? {});

  @override
  Stream<Map<String, dynamic>> watchFinanceSettings() => _db
      .collection('config')
      .doc('finance')
      .snapshots()
      .map((doc) => doc.data() ?? {});

  static String _fnError(FirebaseFunctionsException e) =>
      adminErrorMessage(e.code, e.details);

  // ---------------------------------------------------------------------------
  // Tarifas. Todas las escrituras de admin pasan por callables que validan
  // contra el estado actual y escriben la auditoría en la misma transacción
  // (Parte A); las reglas ya no dejan al admin escribir directo.
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> updatePricingRule(
    PricingRule rule,
    String reason,
  ) {
    final errors = rule.validate();
    if (errors.isNotEmpty) {
      return Future.value(Left(ValidationFailure(errors.join('. '))));
    }
    return _call('adminUpdatePricingRule', {
      'action': 'upsert',
      'vehicleClass': rule.vehicleClass.name,
      'serviceType': rule.serviceType.name,
      'basePriceUsd': rule.basePriceUsd,
      'pricePerKmUsd': rule.pricePerKmUsd,
      'pricePerHourUsd': rule.pricePerHourUsd,
      'minimumPriceUsd': rule.minimumPriceUsd,
      'isActive': rule.isActive,
      'reason': reason.trim(),
    });
  }

  @override
  Future<Either<Failure, void>> deactivatePricingRule(
    PricingRule rule,
    String reason,
  ) =>
      _call('adminUpdatePricingRule', {
        'action': 'deactivate',
        'vehicleClass': rule.vehicleClass.name,
        'serviceType': rule.serviceType.name,
        'reason': reason.trim(),
      });

  // ---------------------------------------------------------------------------
  // Operaciones sobre reservas (adminUpdateBooking)
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> changeBookingStatus(
    Booking booking,
    BookingStatus status,
    String reason,
  ) =>
      _call('adminUpdateBooking', {
        'bookingId': booking.id,
        if (status == BookingStatus.cancelled)
          'action': 'cancel'
        else ...{
          'action': 'status',
          'to': status.label,
        },
        'reason': reason.trim(),
      });

  @override
  Future<Either<Failure, void>> assignDriver(
    Booking booking,
    String driverId,
    String reason,
  ) =>
      _call('adminUpdateBooking', {
        'action': 'assign',
        'bookingId': booking.id,
        'driverId': driverId,
        'reason': reason.trim(),
      });

  @override
  Future<Either<Failure, void>> adjustFinalPrice(
    Booking booking,
    double finalPrice,
    String reason,
  ) {
    if (finalPrice.isNaN || finalPrice < 0) {
      return Future.value(
        const Left(ValidationFailure('El precio final no es válido')),
      );
    }
    return _call('adminUpdateBooking', {
      'action': 'adjust_price',
      'bookingId': booking.id,
      'finalPrice': finalPrice,
      'reason': reason.trim(),
    });
  }

  // ---------------------------------------------------------------------------
  // Finanzas
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> refundPayment(
    Payment payment,
    String reason,
  ) async {
    // El reembolso lo ejecuta la Cloud Function (Stripe + auditoría en
    // servidor); el cliente no puede marcar un pago como reembolsado.
    try {
      await _functions.httpsCallable('refundPayment').call({
        'paymentId': payment.id,
        'reason': reason,
      });
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      return Left(PaymentFailure(_fnError(e)));
    } catch (e) {
      return Left(PaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> backfillSettlements() async {
    // Lo hace la Cloud Function: el reparto solo lo escribe el servidor.
    try {
      final result =
          await _functions.httpsCallable('backfillSettlements').call();
      return Right((result.data['settled'] as num?)?.toInt() ?? 0);
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(_fnError(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markPaymentCollected(
    Booking booking,
    String method,
    String reference,
    String reason,
  ) =>
      // El servidor comprueba en una transacción que el viaje esté
      // completado y sin otro cobro, y fija el importe.
      _call('adminRecordPayment', {
        'action': 'record',
        'bookingId': booking.id,
        'method': method,
        'reference': reference.trim(),
        'reason': reason.trim(),
      });

  @override
  Future<Either<Failure, void>> correctPayment(
    Payment payment, {
    double? amountBs,
    String? method,
    String? reference,
    required String reason,
  }) =>
      _call('adminRecordPayment', {
        'action': 'correct',
        'paymentId': payment.id,
        if (amountBs != null) 'amountBs': amountBs,
        if (method != null) 'method': method,
        if (reference != null) 'reference': reference.trim(),
        'reason': reason.trim(),
      });

  @override
  Future<Either<Failure, void>> updateFinanceSettings(
    Map<String, dynamic> fields,
    String reason,
  ) {
    final pct = fields['platformCommissionPct'];
    if (pct is num && (pct < 0 || pct > 100)) {
      return Future.value(
        const Left(ValidationFailure('La comisión debe estar entre 0 y 100 %')),
      );
    }
    return _call('adminUpdateConfig', {
      'doc': 'finance',
      'changes': fields,
      'reason': reason.trim(),
    });
  }

  // ---------------------------------------------------------------------------
  // Personas, flota y sistema
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> verifyDriver(
    String driverId, {
    required bool vehicleReviewed,
    String vehicleNote = '',
    required String reason,
  }) =>
      _call('adminVerifyDriver', {
        'driverId': driverId,
        'vehicleReviewed': vehicleReviewed,
        'vehicleNote': vehicleNote.trim(),
        'reason': reason.trim(),
      });

  @override
  Future<Either<Failure, void>> toggleUserStatus(String userId, bool active) {
    if (!active && userId == _auth.currentUser?.uid) {
      return Future.value(
        const Left(ValidationFailure('No puedes bloquear tu propia cuenta')),
      );
    }
    // El servidor deshabilita la cuenta en Auth, revoca sus sesiones, marca
    // isActive y audita (B3).
    return _call('setUserBlocked', {'uid': userId, 'blocked': !active});
  }

  @override
  Future<Either<Failure, void>> updateDriverDocuments(
    DriverProfile profile,
    Vehicle? vehicle,
    DriverDocumentsEdit edit,
    String reason,
  ) {
    final profileChanges = edit.profileChanges(profile);
    final vehicleChanges = edit.vehicleChanges(vehicle);
    if (profileChanges.isEmpty && vehicleChanges.isEmpty) {
      return Future.value(const Left(ValidationFailure('No hay cambios.')));
    }
    final expiry = profileChanges['licenseExpiry'];
    return _call('adminUpdateDriverSensitive', {
      'driverId': profile.userId,
      if (profileChanges.isNotEmpty)
        'profile': {
          if (profileChanges['licenseNumber'] != null)
            'licenseNumber': profileChanges['licenseNumber'],
          if (expiry is DateTime)
            'licenseExpiry': expiry.millisecondsSinceEpoch,
        },
      if (vehicleChanges.isNotEmpty)
        'vehicle': {
          'vehicleId': vehicle!.id,
          for (final k in ['plate', 'make', 'model', 'year'])
            if (vehicleChanges[k] != null) k: vehicleChanges[k],
          // La capacidad la pone el servidor según la clase.
          if (vehicleChanges['class'] != null)
            'vehicleClass': vehicleChanges['class'],
        },
      'reason': reason.trim(),
    });
  }

  @override
  Future<Either<Failure, void>> toggleVehicleStatus(
    String vehicleId,
    bool active,
    String reason,
  ) =>
      _call('adminSetVehicleActive', {
        'vehicleId': vehicleId,
        'active': active,
        'reason': reason.trim(),
      });

  @override
  Future<Either<Failure, void>> toggleMaintenanceMode(
    bool active,
    String reason,
  ) =>
      updateGlobalSettings({'isMaintenanceMode': active}, reason);

  @override
  Future<Either<Failure, void>> updateGlobalSettings(
    Map<String, dynamic> fields,
    String reason,
  ) =>
      _call('adminUpdateConfig', {
        'doc': 'global',
        'changes': fields,
        'reason': reason.trim(),
      });

  @override
  Future<Either<Failure, void>> setLeadHandled(String leadId, bool handled) =>
      _call('adminSetLeadHandled', {'leadId': leadId, 'handled': handled});

  @override
  Future<Either<Failure, void>> updateUserRole(String userId, UserRole role) {
    if (userId == _auth.currentUser?.uid && role != UserRole.admin) {
      return Future.value(
        const Left(
          ValidationFailure(
            'No puedes quitarte el rol de administrador a ti mismo',
          ),
        ),
      );
    }
    // El servidor fija el claim, el documento, revoca las sesiones del
    // afectado y deja la auditoría (B2).
    return _call('setUserRole', {'uid': userId, 'role': role.name});
  }

  /// Llama a una callable de administración y traduce su error.
  Future<Either<Failure, void>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      await _functions.httpsCallable(name).call<void>(data);
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(_fnError(e)));
    } catch (_) {
      return const Left(
        ServerFailure('Sin conexión con el servidor; inténtalo de nuevo'),
      );
    }
  }
}

/// Las Cloud Functions solo mandan código y motivo corto: se traducen aquí,
/// sin texto técnico.
String adminErrorMessage(String code, Object? details) {
  final common = commonFunctionError(code, details);
  if (common != null) return common;
  final d = details is Map ? details : const {};
  return switch (functionErrorReason(details)) {
    'invalid_request' => 'Revisa los datos. El motivo necesita al menos '
        '$kAdminReasonMinLength caracteres.',
    'no_change' => 'No hay nada que cambiar.',
    'not_captured' => 'Solo se pueden reembolsar o corregir pagos cobrados',
    'payment_failed' => 'El procesador de pagos rechazó la operación',
    'cannot_change_own_role' => 'No puedes cambiar tu propio rol',
    'cannot_block_self' => 'No puedes bloquear tu propia cuenta',
    'user_not_found' => 'No se encontró el usuario',
    'booking_not_found' => 'No se encontró la reserva',
    'driver_not_found' => 'No se encontró el chófer',
    'vehicle_not_found' => 'No se encontró el vehículo de este chófer',
    'payment_not_found' => 'No se encontró el pago',
    'lead_not_found' => 'No se encontró la solicitud',
    'fare_not_found' => 'Esa tarifa no está configurada',
    'driver_not_verified' => 'Ese chófer aún no está verificado',
    'driver_inactive' => 'Ese chófer está bloqueado',
    'driver_busy' => 'Ese chófer está ocupado o desconectado; elige otro',
    'not_assignable' => 'A esta reserva ya no se le puede asignar chófer',
    'not_cancellable' => 'Esta reserva ya no se puede cancelar',
    'invalid_transition' => 'La reserva ya no está en ese paso; recarga',
    'price_locked' => 'El importe solo se ajusta antes de completar el viaje',
    'price_adjustment_disabled' =>
      'El ajuste de importe no está habilitado: falta fijar el límite en '
          'la configuración de operación.',
    'price_adjustment_too_large' => d['maxPercent'] is num
        ? 'El ajuste supera el límite permitido '
            '(${(d['maxPercent'] as num).toStringAsFixed(0)} %).'
        : 'El ajuste supera el límite permitido.',
    'not_completed' => 'Solo se cobran viajes completados',
    'card_payment' => 'Este viaje se paga con tarjeta y el cobro es '
        'automático; solo se registra a mano si ese cobro falla.',
    'already_paid' => 'Este viaje ya tiene un cobro registrado',
    'not_manual' => 'Solo se corrigen cobros registrados a mano',
    'invalid_fare' => 'La tarifa no es válida: revisa los importes',
    _ => code == 'permission-denied'
        ? 'Permiso denegado: se necesita rol de administrador'
        : functionErrorMessage(code, details),
  };
}
