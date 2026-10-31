import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/function_errors.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../l10n/l10n.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  PreferencesRepositoryImpl({
    required FirebaseFunctions functions,
    required FirebaseFirestore firestore,
  })  : _functions = functions,
        _db = firestore;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _db;

  @override
  Future<Either<Failure, TripPreferences>> save(
    TripPreferences preferences,
  ) async {
    try {
      final res = await _functions
          .httpsCallable('updatePreferences')
          .call(preferences.toJson());
      final data = res.data;
      final saved = data is Map ? data['preferences'] : null;
      return Right(
        saved is Map ? TripPreferences.fromJson(saved) : preferences,
      );
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(preferencesErrorMessage(e.code, e.details)));
    } catch (e) {
      return Left(ServerFailure(unexpectedErrorMessage(e)));
    }
  }

  @override
  Future<PreferenceOptions> options() async {
    try {
      final res = await _functions.httpsCallable('getPreferenceOptions').call();
      final data = res.data;
      if (data is! Map) return PreferenceOptions.none;
      return PreferenceOptions(
        playlistEnabled: data['playlistEnabled'] == true,
        noteMax: data['noteMax'] is int
            ? data['noteMax'] as int
            : TripPreferences.noteMax,
      );
    } catch (_) {
      // Sin respuesta: el campo de la lista no se ofrece.
      return PreferenceOptions.none;
    }
  }

  @override
  Stream<TripPreferences?> watchBookingPreferences(String bookingId) => _db
      .collection('bookings')
      .doc(bookingId)
      .collection('driverView')
      .doc('preferences')
      .snapshots()
      .map((s) => s.exists ? TripPreferences.fromJson(s.data()) : null)
      // Fuera de la ventana las reglas deniegan: no se muestra nada.
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (_, __, sink) => sink.add(null),
        ),
      );
}

/// Motivo del servidor → texto en el idioma activo.
String preferencesErrorMessage(String code, Object? details) {
  final d = details is Map ? details : const {};
  final fields = d['fields'] is List ? d['fields'] as List : const [];
  if (d['reason'] == 'playlist_not_allowed') {
    return L10n.current.prefsErrorPlaylist;
  }
  if (d['reason'] == 'invalid_request' && fields.contains('note')) {
    return L10n.current.prefsErrorNote;
  }
  return functionErrorMessage(code, details);
}
