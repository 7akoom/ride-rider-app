import 'config/app_env.dart';

/// Legacy entry point kept for the screens that are not migrated yet.
/// New code reads [AppEnv] directly.
class AppConfig {
  static const String apiBaseUrl = AppEnv.apiBaseUrl;

  /// Sent with the login so the backend can tell which app a session belongs to.
  static const String clientId = 'rider-app';

  /// Keep in step with `version:` in pubspec.yaml.
  static const String appVersion = '0.1.0';

  /// The number the legacy emergency button dials. The new safety center sends SOS to
  /// the operator's safety team instead (Trip SOS); this goes away with the old screen.
  static const String emergencyNumber = '104';
}
