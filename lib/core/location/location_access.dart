/// Whether the app may read the phone's location.
enum LocationAccessStatus {
  /// Allowed while the app is in use (or always).
  granted,

  /// Not allowed yet; asking again is possible.
  denied,

  /// Refused for good: only the phone's settings can change it.
  deniedForever,

  /// Allowed or not, location is switched off on the phone.
  serviceOff,
}

/// Asking for the location permission. Pure Dart: the onboarding and the home screen
/// use it through this interface; the plugin lives in the implementation.
abstract interface class LocationAccess {
  Future<LocationAccessStatus> status();

  /// Shows the system prompt (when the system still allows it) and returns the answer.
  Future<LocationAccessStatus> request();

  /// Opens this app's page in the phone's settings.
  Future<void> openSettings();
}
