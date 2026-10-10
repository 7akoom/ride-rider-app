import 'package:flutter/widgets.dart';

import '../../core/l10n/app_locales.dart';

/// The bundled fonts (assets/fonts, SIL Open Font License). Nothing is downloaded at
/// runtime, so text looks right on the first launch and offline.
abstract final class AppFonts {
  static const String arabic = 'IBMPlexSansArabic';
  static const String latin = 'IBMPlexSans';

  /// The main family and its fallback for [locale]: Arabic script first for Arabic and
  /// Kurdish, Latin first for English. The other covers mixed text (names, plates).
  static ({String family, List<String> fallback}) forLocale(Locale locale) {
    return AppLocales.isRightToLeft(locale)
        ? (family: arabic, fallback: const [latin])
        : (family: latin, fallback: const [arabic]);
  }
}
