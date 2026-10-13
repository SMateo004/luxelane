import 'package:cloud_firestore/cloud_firestore.dart';

/// Which of the two store apps is running.
enum LuxApp { rider, driver }

/// Build number of this binary (pubspec `+N`), passed at build time by
/// scripts/build_mobile.sh, scripts/build_ios.sh and the CI. 0 means unknown
/// (debug runs, web), and then the minimum-version check never blocks.
const kAppBuild = int.fromEnvironment('LUX_BUILD');

/// Store package names (android/app/build.gradle.kts), also the bundle ids.
const _androidIds = {LuxApp.rider: 'com.luxelane.rider', LuxApp.driver: 'com.luxelane.driver'};

/// App-wide switches in config/global, set from Admin → Settings. Public:
/// the apps read it before anyone signs in.
class GlobalConfig {
  const GlobalConfig({
    this.maintenance = false,
    this.riderMinBuild = 0,
    this.driverMinBuild = 0,
    this.riderIosUrl,
    this.driverIosUrl,
  });

  /// New bookings are paused (the server refuses quotes and bookings);
  /// rides already booked carry on.
  final bool maintenance;
  final int riderMinBuild;
  final int driverMinBuild;

  /// App Store pages (known only once each app is listed there).
  final String? riderIosUrl;
  final String? driverIosUrl;

  factory GlobalConfig.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const GlobalConfig();
    int build(Object? v) => v is int && v > 0 ? v : 0;
    String? url(Object? v) => v is String && v.startsWith('https://') ? v : null;
    return GlobalConfig(
      maintenance: j['isMaintenanceMode'] == true,
      riderMinBuild: build(j['riderMinBuild']),
      driverMinBuild: build(j['driverMinBuild']),
      riderIosUrl: url(j['riderIosUrl']),
      driverIosUrl: url(j['driverIosUrl']),
    );
  }

  int minBuildFor(LuxApp app) => app == LuxApp.rider ? riderMinBuild : driverMinBuild;

  /// This binary is older than the oldest build an admin still allows.
  /// Never true when the build number is unknown.
  bool updateRequired(LuxApp app, int build) => build > 0 && minBuildFor(app) > build;

  /// Where to update: Google Play, or the App Store page if an admin set it.
  String? storeUrl(LuxApp app, {required bool ios}) => ios
      ? (app == LuxApp.rider ? riderIosUrl : driverIosUrl)
      : 'https://play.google.com/store/apps/details?id=${_androidIds[app]}';
}

/// Admins write config/global through AdminRepository.updateGlobalSettings
/// (audited); the apps only watch it.
abstract class GlobalConfigRepository {
  Stream<GlobalConfig> watch();
}

class GlobalConfigRepositoryImpl implements GlobalConfigRepository {
  GlobalConfigRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<GlobalConfig> watch() =>
      _db.collection('config').doc('global').snapshots().map((d) => GlobalConfig.fromJson(d.data()));
}
