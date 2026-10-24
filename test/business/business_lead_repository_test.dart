import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/error/function_errors.dart';
import 'package:luxelane/features/business/data/business_lead_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockResult extends Mock implements HttpsCallableResult<void> {}

class _MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late _MockFunctions functions;
  late _MockCallable callable;
  late _MockFirestore firestore;
  late BusinessLeadRepository repo;

  setUp(() {
    functions = _MockFunctions();
    callable = _MockCallable();
    firestore = _MockFirestore();
    repo = BusinessLeadRepository(firestore, functions);
    when(() => functions.httpsCallable('submitBusinessLead'))
        .thenReturn(callable);
    when(() => callable.call<void>(any()))
        .thenAnswer((_) async => _MockResult());
  });

  Future<Map<String, dynamic>> submit({String website = ''}) async {
    await repo.submit(
      company: ' Empresa SA ',
      contactName: 'Laura',
      email: 'laura@example.com ',
      phone: '+59170000000',
      travellers: '11–50',
      message: 'Hola',
      website: website,
    );
    return verify(() => callable.call<void>(captureAny())).captured.single
        as Map<String, dynamic>;
  }

  test('envía por submitBusinessLead, sin escribir en Firestore', () async {
    final sent = await submit();
    expect(sent, {
      'company': 'Empresa SA',
      'contactName': 'Laura',
      'email': 'laura@example.com',
      'phone': '+59170000000',
      'travellers': '11–50',
      'message': 'Hola',
    });
    verifyZeroInteractions(firestore);
  });

  test('el campo trampa solo viaja si alguien lo rellenó', () async {
    expect(
        (await submit(website: 'https://spam')).containsKey('website'), isTrue);
  });

  test('mensajes del formulario', () {
    expect(businessLeadErrorMessage('resource-exhausted', null),
        startsWith('Ya recibimos varias solicitudes'));
    expect(businessLeadErrorMessage('invalid-argument', null),
        'Revisa los datos del formulario.');
  });
}
