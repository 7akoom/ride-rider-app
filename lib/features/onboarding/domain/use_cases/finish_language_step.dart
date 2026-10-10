import '../entities/next_step.dart';
import '../repositories/onboarding_preferences.dart';

/// Remembers that the language was picked, so the language screen shows only once, and
/// says where to go next.
final class FinishLanguageStep {
  const FinishLanguageStep(this.preferences);

  final OnboardingPreferences preferences;

  Future<NextStep> call() async {
    await preferences.markLanguageChosen();

    return NextStep.enterPhone;
  }
}
