import 'package:flutter/material.dart';

import '../design/theme/app_theme.dart';
import '../design/tokens/brand.dart';
import '../design/tokens/palettes.dart';
import '../theme/app_theme.dart' show AppColors;

/// The app's light and dark themes for a language, built once per language.
///
/// They also carry the legacy colour names (AppColors), mapped onto the new palette, for
/// the screens not migrated yet.
class AppThemes {
  AppThemes._();

  static final Brand _brand = Brand.fromEnv();
  static final Map<String, ThemeData> _cache = {};

  static ThemeData light(Locale locale) => _cache.putIfAbsent(
        'light-${locale.languageCode}',
        () => AppTheme.light(
          _brand,
          locale,
          extra: [AppColors.fromPalette(Palettes.light(_brand))],
        ),
      );

  static ThemeData dark(Locale locale) => _cache.putIfAbsent(
        'dark-${locale.languageCode}',
        () => AppTheme.dark(
          _brand,
          locale,
          extra: [AppColors.fromPalette(Palettes.dark(_brand))],
        ),
      );
}
