import '../../../../core/location/location_access.dart';
import '../entities/next_step.dart';
import '../entities/rider_account.dart';
import '../repositories/onboarding_preferences.dart';

/// Where a signed-in rider goes: the name screen without a profile, then the location
/// screen once (skipped when location is already allowed), then the app.
final class AccountStep {
  const AccountStep({required this.preferences, required this.location});

  final OnboardingPreferences preferences;
  final LocationAccess location;

  Future<NextStep> after(RiderAccount? account) async {
    if (account == null) {
      return NextStep.enterName;
    }

    if (await preferences.locationAsked()) {
      return NextStep.home;
    }

    if (await location.status() == LocationAccessStatus.granted) {
      await preferences.markLocationAsked();

      return NextStep.home;
    }

    return NextStep.askLocation;
  }
}
