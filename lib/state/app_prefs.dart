import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n/language_preference.dart';

class AppPrefs {
  static const _themeModeKey = 'theme_mode';

  static Future<ThemeMode> readThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeModeKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  // Moved to LanguagePreference (lib/core/l10n). Kept for the legacy settings screen.
  static Future<Locale> readLocale() => LanguagePreference.read();

  static Future<void> saveLocale(Locale locale) => LanguagePreference.save(locale);
}
