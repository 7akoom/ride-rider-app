import '../../../../core/location/location_access.dart';
import '../entities/next_step.dart';
import '../repositories/onboarding_preferences.dart';

/// The location screen's two buttons. Whatever the rider answers, the screen is not
/// shown again and the app opens: location is asked for again where it is needed.
final class FinishLocationStep {
  const FinishLocationStep({required this.preferences, required this.location});

  final OnboardingPreferences preferences;
  final LocationAccess location;

  /// [allow] true asks the system; when the system no longer asks (refused for good)
  /// the app's settings page opens instead.
  Future<NextStep> call({required bool allow}) async {
    if (allow && await location.request() == LocationAccessStatus.deniedForever) {
      await location.openSettings();
    }

    await preferences.markLocationAsked();

    return NextStep.home;
  }
}
