import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/remote_flags.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/features/incidents/data/incident_repository_impl.dart';
import 'package:luxelane/features/incidents/presentation/help_contacts.dart';
import 'package:mocktail/mocktail.dart';

class _Functions extends Mock implements FirebaseFunctions {}

class _Callable extends Mock implements HttpsCallable {}

class _Firestore extends Mock implements FirebaseFirestore {}

void main() {
  group('números de config/global', () {
    test(
      'emergencyNumbers: solo nombre → número no vacíos; sin datos, vacío',
      () {
        expect(emergencyNumbersFrom({}), isEmpty);
        expect(emergencyNumbersFrom({'emergencyNumbers': 'x'}), isEmpty);
        expect(
          emergencyNumbersFrom({
            'emergencyNumbers': {
              'Policía': ' 000 ',
              '': '111',
              'Bomberos': '',
              'Ambulancia': 7,
            },
          }),
          {'Policía': '000'},
        );
      },
    );

    test('sin números no se inventa ninguno', () {
      expect(kNoNumbersHelp, 'Contacta con las autoridades locales.');
      expect(dispatchPhoneFrom({}), isNull);
    });
  });

  group('SMS prellenado a central', () {
    test('lleva el ID corto y el enlace de mapa a la última ubicación', () {
      final body = incidentSmsBody('ABC123', lat: -17.783327, lng: -63.182140);
      expect(
        body,
        'SOS. Reserva #ABC123. Ubicación: https://maps.google.com/?q=-17.783327,-63.182140',
      );
      expect(incidentSmsBody('ABC123'), contains('Ubicación no disponible'));
    });

    test('esquema sms: con el cuerpo codificado (Android ? / iOS &)', () {
      final android = incidentSmsUri(
        '+000 111',
        'ABC123',
        lat: -17.7,
        lng: -63.1,
        platform: TargetPlatform.android,
      );
      expect(android.scheme, 'sms');
      expect(android.toString(), startsWith('sms:+000111?body=SOS.'));
      expect(
        Uri.decodeComponent(android.toString()),
        contains('Reserva #ABC123'),
      );
      final ios = incidentSmsUri(
        '+000',
        'ABC123',
        platform: TargetPlatform.iOS,
      );
      expect(ios.toString(), startsWith('sms:+000&body='));
    });

    test('tel: sin espacios y el ID corto de la reserva', () {
      expect(telUri('+000 111').toString(), 'tel:+000111');
      expect(bookingShortId('abcdef1234'), 'ABCDEF');
    });
  });

  group('raise sin red', () {
    late _Functions functions;
    late _Callable callable;
    setUp(() {
      functions = _Functions();
      callable = _Callable();
      when(() => functions.httpsCallable('raiseIncident')).thenReturn(callable);
    });

    test(
      'sin respuesta en el plazo: offline (la pantalla ofrece llamar/SMS)',
      () async {
        when(() => callable.call<Map<String, dynamic>>(any())).thenAnswer(
          (_) => Completer<HttpsCallableResult<Map<String, dynamic>>>().future,
        );
        final repo = IncidentRepositoryImpl(
          firestore: _Firestore(),
          functions: functions,
          timeout: const Duration(milliseconds: 20),
        );
        final r = await repo.raise('b1');
        expect(
          (r.swap().getOrElse(() => throw 'x') as IncidentFailure).issue,
          IncidentIssue.offline,
        );
      },
    );

    test('error de red de la callable: offline', () async {
      when(() => callable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(code: 'unavailable', message: 'x'),
      );
      final repo = IncidentRepositoryImpl(
        firestore: _Firestore(),
        functions: functions,
      );
      final r = await repo.raise('b1');
      expect(
        (r.swap().getOrElse(() => throw 'x') as IncidentFailure).issue,
        IncidentIssue.offline,
      );
    });

    test('motivos del servidor', () {
      IncidentIssue issue(String r) =>
          (incidentFailureFor('failed-precondition', {'reason': r})
                  as IncidentFailure)
              .issue;
      expect(issue('outside_window'), IncidentIssue.outsideWindow);
      expect(issue('rate_limited'), IncidentIssue.rateLimited);
      expect(issue('not_in_booking'), IncidentIssue.notAllowed);
    });

    test('el plazo por defecto es de 5 s', () {
      expect(kIncidentTimeout, const Duration(seconds: 5));
    });
  });
}
