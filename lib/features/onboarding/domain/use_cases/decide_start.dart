import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/next_step.dart';
import '../repositories/onboarding_preferences.dart';
import '../repositories/rider_account_repository.dart';
import '../repositories/sign_in_repository.dart';

/// Where the app opens: the language screen on the first run, sign-in without a
/// session, the name screen without a profile, otherwise the app.
///
/// A stored session is only trusted once the backend has accepted it. When the backend
/// cannot be reached the failure is returned and the session is kept: losing the
/// connection is no reason to sign anyone out.
final class DecideStart {
  const DecideStart({
    required this.preferences,
    required this.signIn,
    required this.accounts,
  });

  final OnboardingPreferences preferences;
  final SignInRepository signIn;
  final RiderAccountRepository accounts;

  Future<Result<NextStep>> call() async {
    if (!await preferences.languageChosen()) {
      return const Ok(NextStep.chooseLanguage);
    }

    if (!await signIn.hasSession()) {
      return const Ok(NextStep.enterPhone);
    }

    switch (await accounts.findMine()) {
      case Ok(:final value):
        return Ok(value == null ? NextStep.enterName : NextStep.home);
      case Err(failure: SessionExpiredFailure()):
        await signIn.forgetSession();

        return const Ok(NextStep.enterPhone);
      case Err(:final failure):
        return Err(failure);
    }
  }
}
