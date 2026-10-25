import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _Functions extends Mock implements FirebaseFunctions {}

class _Callable extends Mock implements HttpsCallable {}

class _Result extends Mock implements HttpsCallableResult<void> {}

class _Firestore extends Mock implements FirebaseFirestore {}

class _Auth extends Mock implements fb.FirebaseAuth {}

class _User extends Mock implements fb.User {}

/// El panel cambia rol y bloqueo por callables: el servidor fija el claim,
/// revoca sesiones y audita. Desde el cliente no se escribe Firestore.
void main() {
  late _Functions functions;
  late _Callable callable;
  late _Firestore db;
  late AdminRepositoryImpl repo;

  setUp(() {
    functions = _Functions();
    callable = _Callable();
    db = _Firestore();
    final auth = _Auth();
    final me = _User();
    when(() => me.uid).thenReturn('jefa');
    when(() => auth.currentUser).thenReturn(me);
    repo = AdminRepositoryImpl(db, auth: auth, functions: functions);
    when(() => functions.httpsCallable(any())).thenReturn(callable);
    when(() => callable.call<void>(any())).thenAnswer((_) async => _Result());
  });

  test('cambiar el rol llama a setUserRole y no escribe Firestore', () async {
    final r = await repo.updateUserRole('ana', UserRole.driver);
    expect(r.isRight(), isTrue);
    verify(() => functions.httpsCallable('setUserRole')).called(1);
    verify(() => callable.call<void>({'uid': 'ana', 'role': 'driver'}))
        .called(1);
    verifyZeroInteractions(db);
  });

  test('error del servidor: mensaje en español', () async {
    when(() => callable.call<void>(any())).thenThrow(
      FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'failed_precondition',
        details: const {'reason': 'cannot_change_own_role'},
      ),
    );
    final r = await repo.updateUserRole('otra', UserRole.rider);
    expect(
        r.fold((f) => f.message, (_) => ''), 'No puedes cambiar tu propio rol');
  });

  test('bloquear y desbloquear llaman a setUserBlocked', () async {
    expect((await repo.toggleUserStatus('luis', false)).isRight(), isTrue);
    verify(() => callable.call<void>({'uid': 'luis', 'blocked': true}))
        .called(1);
    expect((await repo.toggleUserStatus('luis', true)).isRight(), isTrue);
    verify(() => callable.call<void>({'uid': 'luis', 'blocked': false}))
        .called(1);
    verify(() => functions.httpsCallable('setUserBlocked')).called(2);
    verifyZeroInteractions(db);
  });
}
