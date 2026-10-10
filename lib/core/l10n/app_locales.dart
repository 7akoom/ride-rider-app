import 'package:flutter/widgets.dart';

/// The languages the app speaks. Arabic is the default.
///
/// Kurdish is Sorani (Arabic script, right to left). It uses the code 'ku', the same
/// code the backend uses for its own Kurdish texts (notifications, help articles).
abstract final class AppLocales {
  static const Locale arabic = Locale('ar');
  static const Locale kurdish = Locale('ku');
  static const Locale english = Locale('en');

  static const Locale fallback = arabic;

  static const List<Locale> all = [arabic, kurdish, english];

  static const Set<String> _rightToLeft = {'ar', 'ku'};

  static bool isRightToLeft(Locale locale) =>
      _rightToLeft.contains(locale.languageCode);

  static TextDirection directionOf(Locale locale) =>
      isRightToLeft(locale) ? TextDirection.rtl : TextDirection.ltr;

  /// A saved language code turned back into a supported locale.
  static Locale fromCode(String? code) {
    for (final locale in all) {
      if (locale.languageCode == code) {
        return locale;
      }
    }

    return fallback;
  }
}
