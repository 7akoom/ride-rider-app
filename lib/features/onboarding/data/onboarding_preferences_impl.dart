import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/error_reporter.dart';
import '../domain/repositories/onboarding_preferences.dart';

/// Kept in shared preferences: nothing here is secret. A storage error is reported and
/// read as "not yet", which only shows a screen once more.
final class OnboardingPreferencesImpl implements OnboardingPreferences {
  const OnboardingPreferencesImpl();

  /// The key the earlier version of the app used, so phones that already picked a
  /// language do not see the language screen again after the update.
  static const String _languageChosenKey = 'onboarded';
  static const String _locationAskedKey = 'location_asked';

  @override
  Future<bool> languageChosen() => _read(_languageChosenKey);

  @override
  Future<void> markLanguageChosen() => _mark(_languageChosenKey);

  @override
  Future<bool> locationAsked() => _read(_locationAskedKey);

  @override
  Future<void> markLocationAsked() => _mark(_locationAskedKey);

  static Future<bool> _read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return prefs.getBool(key) ?? false;
    } catch (error, stack) {
      ErrorReporter.report(error, stack);

      return false;
    }
  }

  static Future<void> _mark(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
    } catch (error, stack) {
      ErrorReporter.report(error, stack);
    }
  }
}
