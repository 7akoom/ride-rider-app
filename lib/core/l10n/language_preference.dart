import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../error/error_reporter.dart';
import 'app_locales.dart';

/// The language the rider picked, kept on the phone. Nothing here is secret.
abstract final class LanguagePreference {
  static const String _key = 'locale';

  /// The saved language, or Arabic when none was saved or it cannot be read.
  static Future<Locale> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return AppLocales.fromCode(prefs.getString(_key));
    } catch (error, stack) {
      ErrorReporter.report(error, stack);

      return AppLocales.fallback;
    }
  }

  static Future<void> save(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, locale.languageCode);
    } catch (error, stack) {
      // The app keeps the language for this run; it is asked again next time.
      ErrorReporter.report(error, stack);
    }
  }
}
