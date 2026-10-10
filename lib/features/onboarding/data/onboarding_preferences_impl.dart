import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/error_reporter.dart';
import '../domain/repositories/onboarding_preferences.dart';

/// Kept in shared preferences: nothing here is secret.
final class OnboardingPreferencesImpl implements OnboardingPreferences {
  const OnboardingPreferencesImpl();

  /// The key the earlier version of the app used, so phones that already picked a
  /// language do not see the language screen again after the update.
  static const String _languageChosenKey = 'onboarded';

  @override
  Future<bool> languageChosen() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return prefs.getBool(_languageChosenKey) ?? false;
    } catch (error, stack) {
      // Unreadable: showing the language screen once more is harmless.
      ErrorReporter.report(error, stack);

      return false;
    }
  }

  @override
  Future<void> markLanguageChosen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_languageChosenKey, true);
    } catch (error, stack) {
      ErrorReporter.report(error, stack);
    }
  }
}
