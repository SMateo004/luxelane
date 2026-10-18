import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../refunds/domain/refund.dart';
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

  FirebaseFunctions get _fn => _functions;

  @override
  Future<Either<Failure, bool>> assignNearestDriver(Booking booking) async {
    try {
      final result = await _fn.httpsCallable('assignNearestDriver').call({
        'bookingId': booking.id,
        'vehicleClass': booking.vehicleClass.name,
      });
      return Right((result.data as Map)['assigned'] == true);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking(String bookingId, {String? reason}) async {
    try {
      await _fn.httpsCallable('cancelBooking').call({
        'bookingId': bookingId,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> adjustPrice({
    required String bookingId,
    required AdjustmentType type,
    required double amount,
    String? note,
  }) async {
    try {
      final r = await _fn.httpsCallable('adjustPrice').call({
        'bookingId': bookingId,
        'type': type.name,
        'amount': amount,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });
      return Right(((r.data as Map)['finalPrice'] as num).toDouble());
    } on FirebaseFunctionsException catch (e) {
      final code = RegExp(r'adjust/[a-z-]+').firstMatch(e.message ?? '')?.group(0);
      return Left(ServerFailure(code ?? 'adjust/failed'));
    } catch (_) {
      return const Left(ServerFailure('adjust/failed'));
    }
  }

  @override
  Future<Either<Failure, void>> recordRefund({
    required String bookingId,
    required double amount,
    required RefundMethod method,
    required String reason,
  }) async {
    try {
      await _fn.httpsCallable('recordRefund').call({
        'bookingId': bookingId,
        'amount': amount,
        'method': method.name,
        'reason': reason.trim(),
      });
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      final code = RegExp(r'refund/[a-z-]+').firstMatch(e.message ?? '')?.group(0);
      return Left(ServerFailure(code ?? 'refund/failed'));
    } catch (_) {
      return const Left(ServerFailure('refund/failed'));
    }
  }

  @override
  Future<Either<Failure, void>> releaseChauffeur(String bookingId, {String? reason}) async {
    try {
      await _fn.httpsCallable('releaseChauffeur').call({
        'bookingId': bookingId,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

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
      query.snapshots().map((snap) => snap.docs
          .map((doc) {
            try {
              return parse({...doc.data(), idField: doc.id});
            } catch (_) {
              // Un documento mal formado no debe tumbar todo el panel.
              return null;
            }
          })
          .whereType<T>()
          .toList());

  @override
  Stream<List<Booking>> watchAllBookings() => _watch(
      _db
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .limit(bookingsLimit),
      Booking.fromJson);

  @override
  Stream<List<Payment>> watchAllPayments() => _watch(
      _db
          .collection('payments')
          .orderBy('createdAt', descending: true)
          .limit(bookingsLimit * 2),
      Payment.fromJson);

  @override
  Stream<List<User>> watchAllUsers() =>
      _watch(_db.collection('users'), User.fromJson);

  @override
  Stream<List<DriverProfile>> watchAllDrivers() =>
      _watch(_db.collection('driverProfiles'), DriverProfile.fromJson,
          idField: 'userId');

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
      AuditLog.fromJson);

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

  // ---------------------------------------------------------------------------
  // Auditoría: cada cambio se escribe en el mismo batch que su registro, así
  // no puede existir una acción sin rastro ni un rastro sin acción.
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _logEntry(
      String action, String targetId, String targetType, String details) {
    final user = _auth.currentUser;
    return {
      'adminId': user?.uid ?? 'unknown',
      'adminEmail': user?.email,
      'action': action,
      'targetId': targetId,
      'targetType': targetType,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  void _log(WriteBatch batch, String action, String targetId, String targetType,
      {String details = ''}) {
    batch.set(_db.collection('admin_logs').doc(),
        _logEntry(action, targetId, targetType, details));
  }

  /// Como [_run], pero en una transacción: para cambios que dependen del
  /// estado actual y pueden chocar con otro escritor (un chófer aceptando,
  /// un cobro de Stripe…).
  Future<Either<Failure, void>> _runTx(
      Future<void> Function(Transaction tx) build) async {
    try {
      await _db.runTransaction(build);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(_friendly(e)));
    } on _AdminRuleViolation catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  void _logTx(Transaction tx, String action, String targetId, String targetType,
      {String details = ''}) {
    tx.set(_db.collection('admin_logs').doc(),
        _logEntry(action, targetId, targetType, details));
  }

  Future<Either<Failure, void>> _run(
      Future<void> Function(WriteBatch batch) build) async {
    try {
      final batch = _db.batch();
      await build(batch);
      await batch.commit();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(_friendly(e)));
    } on _AdminRuleViolation catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  static String _friendly(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return 'Permiso denegado: tu cuenta no tiene rol de administrador '
          'o las reglas de Firestore no están desplegadas.';
    }
    return e.message ?? e.code;
  }

  /// Los errores de las Cloud Functions llegan en inglés: se traducen por
  /// código.
  static String _fnError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Permiso denegado: se necesita rol de administrador';
      case 'unauthenticated':
        return 'Tu sesión expiró; vuelve a iniciar sesión';
      case 'not-found':
        return 'No se encontró el registro';
      case 'failed-precondition':
        return 'Solo se pueden reembolsar pagos cobrados';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Sin conexión con el servidor; inténtalo de nuevo';
      default:
        return 'No se pudo completar la operación (${e.code})';
    }
  }

  static String _money(double v) => 'Bs${v.toStringAsFixed(2)}';

  DocumentReference<Map<String, dynamic>> _booking(String id) =>
      _db.collection('bookings').doc(id);

  DocumentReference<Map<String, dynamic>> _driver(String id) =>
      _db.collection('driverProfiles').doc(id);

  // ---------------------------------------------------------------------------
  // Tarifas
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> updatePricingRule(PricingRule rule) {
    final errors = rule.validate();
    if (errors.isNotEmpty) {
      return Future.value(Left(ValidationFailure(errors.join('. '))));
    }
    final id = PricingRule.idFor(rule.vehicleClass, rule.serviceType);
    return _run((batch) async {
      batch.set(_db.collection('pricingRules').doc(id), {
        ...rule.toJson(),
        'id': id,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
      _log(batch, 'update_pricing', id, 'pricing',
          details: '${rule.vehicleClass.label} · ${rule.serviceType.label}: '
              'base ${_money(rule.basePriceUsd)}, '
              '${_money(rule.pricePerKmUsd)}/km, '
              '${_money(rule.pricePerHourUsd)}/h, '
              'mín. ${_money(rule.minimumPriceUsd)}'
              '${rule.isActive ? '' : ' · DESACTIVADA'}');
    });
  }

  @override
  Future<Either<Failure, void>> resetPricingRule(PricingRule rule) {
    final id = PricingRule.idFor(rule.vehicleClass, rule.serviceType);
    return _run((batch) async {
      batch.delete(_db.collection('pricingRules').doc(id));
      _log(batch, 'reset_pricing', id, 'pricing',
          details: '${rule.vehicleClass.label} · ${rule.serviceType.label} '
              'vuelve a la tarifa de fábrica');
    });
  }

  // ---------------------------------------------------------------------------
  // Operaciones sobre reservas
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> changeBookingStatus(
      Booking booking, BookingStatus status,
      {String reason = ''}) {
    return _run((batch) async {
      // Se valida contra el estado actual en servidor, no el de la pantalla.
      final snap = await _booking(booking.id).get();
      final current =
          BookingStatusX.fromString(snap.data()?['status'] as String? ?? '');
      if (!AdminOperations.canTransition(current, status)) {
        throw _AdminRuleViolation(
            'No se puede pasar de "${current.displayLabel}" a '
            '"${status.displayLabel}"');
      }
      final update = <String, dynamic>{
        'status': status.label,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (status == BookingStatus.cancelled) {
        update['cancelledBy'] = 'admin';
        update['cancellationReason'] = reason;
      }
      if (status == BookingStatus.completed &&
          snap.data()?['finalPrice'] == null) {
        update['finalPrice'] = booking.estimatedPrice;
      }
      batch.update(_booking(booking.id), update);

      // Liberar al chófer y contar el viaje lo hace el servidor
      // (releaseDriver) para cualquier cierre, también este.
      _log(
        batch,
        status == BookingStatus.cancelled ? 'cancel_booking' : 'update_status',
        booking.id,
        'booking',
        details: '${current.displayLabel} → ${status.displayLabel}'
            '${reason.isNotEmpty ? ' · $reason' : ''}',
      );
    });
  }

  @override
  Future<Either<Failure, void>> assignDriver(Booking booking, String driverId) {
    // En transacción: si un chófer acepta la reserva a la vez, una de las dos
    // escrituras se repite con el estado nuevo en vez de pisar a la otra.
    return _runTx((tx) async {
      final snap = await tx.get(_booking(booking.id));
      final fresh = Booking.fromJson({...?snap.data(), 'id': booking.id});
      if (!AdminOperations.canAssignDriver(fresh)) {
        throw _AdminRuleViolation('No se puede asignar chófer a una reserva '
            '"${fresh.status.displayLabel}"');
      }
      final previous = fresh.driverId;
      if (previous != driverId) {
        final driver = await tx.get(_driver(driverId));
        if (driver.data()?['isAvailable'] != true) {
          throw _AdminRuleViolation(
              'Ese chófer está ocupado o desconectado; elige otro');
        }
      }
      tx.update(_booking(booking.id), {
        'driverId': driverId,
        if (fresh.status == BookingStatus.pending)
          'status': BookingStatus.confirmed.label,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (fresh.status != BookingStatus.confirmed &&
              fresh.status != BookingStatus.pending ||
          fresh.scheduledAt.isBefore(DateTime.now().add(kBusyLead))) {
        tx.update(_driver(driverId), {'isAvailable': false});
      }
      if (previous != null && previous != driverId) {
        tx.update(_driver(previous), {'isAvailable': true});
      }
      _logTx(tx, previous == null ? 'assign_driver' : 'reassign_driver',
          booking.id, 'booking',
          details: previous == null
              ? 'Chófer $driverId'
              : 'Chófer $previous → $driverId');
    });
  }

  @override
  Future<Either<Failure, void>> adjustFinalPrice(
      Booking booking, double finalPrice, String reason) {
    if (finalPrice.isNaN || finalPrice < 0) {
      return Future.value(
          const Left(ValidationFailure('El precio final no es válido')));
    }
    return _run((batch) async {
      // Sin tocar updatedAt: las finanzas fechan el viaje por él y un ajuste
      // no debe moverlo al periodo actual.
      batch.update(_booking(booking.id), {
        'finalPrice': finalPrice,
        'priceAdjustmentReason': reason,
      });
      _log(batch, 'adjust_price', booking.id, 'booking',
          details: '${_money(booking.finalPrice ?? booking.estimatedPrice)} → '
              '${_money(finalPrice)}${reason.isNotEmpty ? ' · $reason' : ''}');
    });
  }

  // ---------------------------------------------------------------------------
  // Finanzas
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> refundPayment(
      Payment payment, String reason) async {
    // El reembolso lo ejecuta la Cloud Function (Stripe + auditoría en
    // servidor); el cliente no puede marcar un pago como reembolsado.
    try {
      await _functions
          .httpsCallable('refundPayment')
          .call({'paymentId': payment.id, 'reason': reason});
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
      Booking booking, String method, String reference) {
    final amount = booking.finalPrice ?? booking.estimatedPrice;
    // En transacción: un doble clic o un cobro de Stripe simultáneo no deben
    // dejar dos pagos cobrados para el mismo viaje.
    return _runTx((tx) async {
      final snap = await tx.get(_booking(booking.id));
      final data = snap.data() ?? const <String, dynamic>{};
      if (data['status'] != BookingStatus.completed.label) {
        throw _AdminRuleViolation('Solo se cobran viajes completados');
      }
      final card = data['stripePaymentIntentId'] != null ||
          data['stripePaymentMethodId'] != null;
      if (card && data['cardPaymentFailed'] != true) {
        throw _AdminRuleViolation('Este viaje se paga con tarjeta y el cobro '
            'es automático; solo se registra a mano si ese cobro falla.');
      }
      final existingId = data['paymentId'] as String?;
      if (existingId != null && existingId.isNotEmpty) {
        final existing =
            await tx.get(_db.collection('payments').doc(existingId));
        final st = existing.data()?['status'];
        if (st == PaymentStatus.captured.label ||
            st == PaymentStatus.refunded.label) {
          throw _AdminRuleViolation('Este viaje ya tiene un cobro registrado');
        }
      }
      final ref = _db.collection('payments').doc();
      tx.set(ref, {
        'bookingId': booking.id,
        'riderId': booking.riderId,
        'stripePaymentIntentId': '',
        // Pagos en centavos, como Stripe y capturePayment.
        'amount': Payment.toCents(amount),
        'currency': 'bob',
        'status': PaymentStatus.captured.label,
        'method': method,
        'reference': reference,
        'recordedBy': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(_booking(booking.id), {
        'paymentId': ref.id,
        'finalPrice': amount,
      });
      _logTx(tx, 'record_payment', booking.id, 'payment',
          details: '${_money(amount)} · $method'
              '${reference.isNotEmpty ? ' · ref. $reference' : ''}');
    });
  }

  @override
  Future<Either<Failure, void>> updateFinanceSettings(
      Map<String, dynamic> fields) {
    final pct = fields['platformCommissionPct'];
    if (pct is num && (pct < 0 || pct > 100)) {
      return Future.value(const Left(
          ValidationFailure('La comisión debe estar entre 0 y 100 %')));
    }
    return _run((batch) async {
      batch.set(
          _db.collection('config').doc('finance'),
          {...fields, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
      _log(batch, 'update_finance_settings', 'finance', 'global_config',
          details:
              fields.entries.map((e) => '${e.key}: ${e.value}').join(', '));
    });
  }

  // ---------------------------------------------------------------------------
  // Personas, flota y sistema
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> verifyDriver(String driverId) =>
      _run((batch) async {
        batch.update(_driver(driverId), {'documentsVerified': true});
        _log(batch, 'verify_driver', driverId, 'driver');
      });

  @override
  Future<Either<Failure, void>> toggleUserStatus(String userId, bool active) {
    if (!active && userId == _auth.currentUser?.uid) {
      return Future.value(
          const Left(ValidationFailure('No puedes bloquear tu propia cuenta')));
    }
    return _run((batch) async {
      batch.update(_db.collection('users').doc(userId), {'isActive': active});
      _log(batch, active ? 'unblock_user' : 'block_user', userId, 'user');
    });
  }

  @override
  Future<Either<Failure, void>> toggleVehicleStatus(
          String vehicleId, bool active) =>
      _run((batch) async {
        batch.update(
            _db.collection('vehicles').doc(vehicleId), {'isActive': active});
        _log(batch, active ? 'enable_vehicle' : 'disable_vehicle', vehicleId,
            'vehicle');
      });

  @override
  Future<Either<Failure, void>> toggleMaintenanceMode(bool active) =>
      _run((batch) async {
        batch.set(
            _db.collection('config').doc('global'),
            {
              'isMaintenanceMode': active,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
        _log(batch, active ? 'enable_maintenance' : 'disable_maintenance',
            'app', 'global_config');
      });

  @override
  Future<Either<Failure, void>> updateGlobalSettings(
          Map<String, dynamic> fields) =>
      _run((batch) async {
        batch.set(
            _db.collection('config').doc('global'),
            {...fields, 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
        _log(batch, 'update_settings', 'global', 'global_config',
            details:
                fields.entries.map((e) => '${e.key}: ${e.value}').join(', '));
      });

  @override
  Future<Either<Failure, void>> updateUserRole(String userId, UserRole role) {
    if (userId == _auth.currentUser?.uid && role != UserRole.admin) {
      return Future.value(const Left(ValidationFailure(
          'No puedes quitarte el rol de administrador a ti mismo')));
    }
    return _run((batch) async {
      batch.update(_db.collection('users').doc(userId), {'role': role.name});
      _log(batch, 'update_role', userId, 'user',
          details: 'Rol → ${role.displayLabel}');
    });
  }
}

class _AdminRuleViolation implements Exception {
  _AdminRuleViolation(this.message);
  final String message;
}
