import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

/// Dispositivo del chófer (decisión 5). En el piloto no se bloquea nada: la
/// app guarda un identificador aleatorio de esta instalación en el
/// almacenamiento seguro y el servidor lo anota (registerDriverDevice). Un
/// dispositivo nuevo avisa al admin.

/// Dónde vive el identificador (sustituible en pruebas).
abstract class InstallationIdStore {
  Future<String?> read();
  Future<void> write(String id);
}

class SecureInstallationIdStore implements InstallationIdStore {
  SecureInstallationIdStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _key = 'luxelane.installation_id';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String id) => _storage.write(key: _key, value: id);
}

class DriverDeviceRegistrar {
  DriverDeviceRegistrar({
    required InstallationIdStore store,
    FirebaseFunctions? functions,
    Future<String?> Function()? appVersion,
    String Function()? newId,
    String? platform,
  })  : _store = store,
        _functionsOverride = functions,
        _appVersion = appVersion ?? _installedVersion,
        _newId = newId ?? const Uuid().v4,
        _platform = platform ?? _currentPlatform();

  final InstallationIdStore _store;
  final FirebaseFunctions? _functionsOverride;
  final Future<String?> Function() _appVersion;
  final String Function() _newId;
  final String _platform;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  static Future<String?> _installedVersion() async {
    try {
      return (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      return null;
    }
  }

  static String _currentPlatform() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  /// El de esta instalación; se crea la primera vez.
  Future<String> installationId() async {
    final existing = await _store.read();
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _newId();
    await _store.write(id);
    return id;
  }

  /// Lo anota en el servidor. Nunca impide trabajar: si falla, se reintenta
  /// la próxima vez que se abra la app.
  Future<void> register() async {
    try {
      final v = await _appVersion();
      await _functions.httpsCallable('registerDriverDevice').call({
        'installationId': await installationId(),
        'platform': _platform,
        'appVersion': v == null || v.isEmpty ? 'desconocida' : v,
      });
    } catch (_) {
      /* sin red o sin almacenamiento: no bloquea */
    }
  }
}
