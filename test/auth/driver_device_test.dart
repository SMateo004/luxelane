import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/auth/driver_device.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_alerts_tab.dart';
import 'package:mocktail/mocktail.dart';

class _MemoryStore implements InstallationIdStore {
  String? value;
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String id) async {
    value = id;
    writes++;
  }
}

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockResult extends Mock implements HttpsCallableResult<dynamic> {}

void main() {
  late _MemoryStore store;
  late _MockFunctions functions;
  late _MockCallable callable;
  var ids = 0;

  DriverDeviceRegistrar registrar() => DriverDeviceRegistrar(
        store: store,
        functions: functions,
        appVersion: () async => '1.4.0',
        newId: () => 'aaaaaaaa-1111-4111-8111-00000000000${ids++}',
        platform: 'android',
      );

  setUp(() {
    store = _MemoryStore();
    functions = _MockFunctions();
    callable = _MockCallable();
    ids = 0;
    when(() => functions.httpsCallable('registerDriverDevice'))
        .thenReturn(callable);
    when(() => callable.call<dynamic>(any()))
        .thenAnswer((_) async => _MockResult());
  });

  test('el identificador se crea una vez y se reutiliza', () async {
    final first = await registrar().installationId();
    final again = await registrar().installationId();
    expect(again, first);
    expect(store.writes, 1);
  });

  test('register manda identificador, plataforma y versión', () async {
    await registrar().register();
    final sent = verify(() => callable.call<dynamic>(captureAny()))
        .captured
        .single as Map;
    expect(sent, {
      'installationId': store.value,
      'platform': 'android',
      'appVersion': '1.4.0',
    });
  });

  test('si el servidor falla, no rompe nada (no bloquea)', () async {
    when(() => callable.call<dynamic>(any())).thenThrow(
      FirebaseFunctionsException(code: 'unavailable', message: 'x'),
    );
    await expectLater(registrar().register(), completes);
  });

  test('la alerta de dispositivo nuevo tiene su etiqueta y el chófer', () {
    expect(alertLabel('new_driver_device'), 'Chófer en un dispositivo nuevo');
    expect(
      alertLabel('ops_config_in_global'),
      'Configuración por mover a config/ops',
    );
    final a = AdminAlert.fromJson({
      'id': 'al-1',
      'type': 'new_driver_device',
      'driverId': 'luis',
    });
    expect(a.driverId, 'luis');
  });
}
