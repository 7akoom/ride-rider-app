import 'config/app_env.dart';

/// Legacy entry point kept for the screens that are not migrated yet.
/// New code reads [AppEnv] directly.
class AppConfig {
  static const String apiBaseUrl = AppEnv.apiBaseUrl;

  static const String clientId = AppEnv.clientId;
  static const String appVersion = AppEnv.appVersion;

  /// The number the legacy emergency button dials. The new safety center sends SOS to
  /// the operator's safety team instead (Trip SOS); this goes away with the old screen.
  static const String emergencyNumber = '104';
}
