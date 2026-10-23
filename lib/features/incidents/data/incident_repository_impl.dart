import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repositories.dart';

/// Sin respuesta en este tiempo, la pantalla ofrece llamar o enviar SMS.
const kIncidentTimeout = Duration(seconds: 5);

class IncidentRepositoryImpl implements IncidentRepository {
  IncidentRepositoryImpl({
    required FirebaseFirestore firestore,
    FirebaseFunctions? functions,
    this.timeout = kIncidentTimeout,
  })  : _db = firestore,
        _functionsOverride = functions;

  final FirebaseFirestore _db;
  final FirebaseFunctions? _functionsOverride;
  final Duration timeout;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  @override
  Future<Either<Failure, IncidentRaise>> raise(
    String bookingId, {
    ({double lat, double lng})? location,
  }) async {
    try {
      final res = await _functions
          .httpsCallable('raiseIncident')
          .call<Map<String, dynamic>>({
        'bookingId': bookingId,
        if (location != null)
          'location': {'lat': location.lat, 'lng': location.lng},
      }).timeout(timeout);
      return Right(IncidentRaise(
        incidentId: res.data['incidentId'] as String,
        alreadyOpen: res.data['alreadyOpen'] == true,
        count: (res.data['count'] as num?)?.toInt() ?? 1,
      ));
    } on FirebaseFunctionsException catch (e) {
      return Left(incidentFailureFor(e.code, e.details));
    } catch (_) {
      // Sin red o sin respuesta a tiempo.
      return const Left(IncidentFailure(IncidentIssue.offline, _kOffline));
    }
  }

  @override
  Future<Either<Failure, void>> cancel(String incidentId) async {
    try {
      await _functions
          .httpsCallable('cancelIncident')
          .call<Map<String, dynamic>>({'incidentId': incidentId}).timeout(
              timeout);
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      return Left(incidentFailureFor(e.code, e.details));
    } catch (_) {
      return const Left(IncidentFailure(IncidentIssue.offline, _kOffline));
    }
  }

  @override
  Stream<Incident?> watchMine(String bookingId, String uid) => _db
      .collection('incidents')
      .where('bookingId', isEqualTo: bookingId)
      .where('reporterId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty
          ? null
          : Incident.fromJson(s.docs.first.id, s.docs.first.data()));

  @override
  Future<void> publishLocation(String incidentId, double lat, double lng) => _db
          .collection('incidents')
          .doc(incidentId)
          .collection('locations')
          .doc(incidentLocationSlot(DateTime.now()))
          .set({
        'lat': lat,
        'lng': lng,
        'at': FieldValue.serverTimestamp(),
      });
}

/// Tramo de 10 s: el ID que las reglas exigen a cada ubicación.
String incidentLocationSlot(DateTime t) =>
    (t.millisecondsSinceEpoch ~/ 10000).toString();

const _kOffline = 'No pudimos avisar a central: sin conexión.';

Failure incidentFailureFor(String code, Object? details) {
  final reason = (details is Map ? details : const {})['reason'];
  return switch (reason) {
    'outside_window' => const IncidentFailure(IncidentIssue.outsideWindow,
        'El botón de ayuda funciona durante el viaje.'),
    'rate_limited' => const IncidentFailure(IncidentIssue.rateLimited,
        'Ya enviaste varios avisos. Llama a central si lo necesitas.'),
    'not_in_booking' || 'not_reporter' => const IncidentFailure(
        IncidentIssue.notAllowed, 'Este viaje ya no está a tu nombre.'),
    _ => code == 'unavailable' || code == 'deadline-exceeded'
        ? const IncidentFailure(IncidentIssue.offline, _kOffline)
        : const IncidentFailure(
            IncidentIssue.other, 'No pudimos avisar a central.'),
  };
}
