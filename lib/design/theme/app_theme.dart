import 'package:flutter/material.dart';

import '../fonts/app_fonts.dart';
import '../tokens/brand.dart';
import '../tokens/palette.dart';
import '../tokens/palettes.dart';
import '../tokens/typography.dart';
import 'button_themes.dart';
import 'input_theme.dart';
import 'surface_themes.dart';
import 'text_theme.dart';

/// Builds the app's ThemeData from the design tokens for a mode, brand and language
/// (the language picks the font: Arabic script for Arabic and Kurdish).
abstract final class AppTheme {
  static ThemeData light(
    Brand brand,
    Locale locale, {
    List<ThemeExtension<dynamic>> extra = const [],
  }) =>
      build(Palettes.light(brand), Brightness.light, locale, extra: extra);

  static ThemeData dark(
    Brand brand,
    Locale locale, {
    List<ThemeExtension<dynamic>> extra = const [],
  }) =>
      build(Palettes.dark(brand), Brightness.dark, locale, extra: extra);

  static ThemeData build(
    Palette p,
    Brightness brightness,
    Locale locale, {
    List<ThemeExtension<dynamic>> extra = const [],
  }) {
    final fonts = AppFonts.forLocale(locale);
    final t = AppTypography.build(
      color: p.textPrimary,
      family: fonts.family,
      fallback: fonts.fallback,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: _colorScheme(p, brightness),
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      fontFamily: fonts.family,
      fontFamilyFallback: fonts.fallback,
      textTheme: textThemeFrom(t),
      iconTheme: IconThemeData(color: p.textPrimary, size: 24),
      extensions: [p, t, ...extra],
      filledButtonTheme: filledButtonTheme(p, t),
      elevatedButtonTheme: elevatedButtonTheme(p, t),
      outlinedButtonTheme: outlinedButtonTheme(p, t),
      textButtonTheme: textButtonTheme(p, t),
      inputDecorationTheme: inputTheme(p, t),
      bottomSheetTheme: bottomSheetTheme(p),
      dialogTheme: dialogTheme(p, t),
      cardTheme: cardTheme(p),
      chipTheme: chipTheme(p, t),
      navigationBarTheme: navigationBarTheme(p, t),
      snackBarTheme: snackBarTheme(p, t),
      dividerTheme: dividerTheme(p),
      progressIndicatorTheme: progressTheme(p),
    );
  }

  static ColorScheme _colorScheme(Palette p, Brightness brightness) => ColorScheme(
        brightness: brightness,
        primary: p.brand,
        onPrimary: p.onBrand,
        primaryContainer: p.brandSoft,
        onPrimaryContainer: p.textPrimary,
        secondary: p.ink,
        onSecondary: p.onInk,
        error: p.danger,
        onError: p.onInk,
        surface: p.surface,
        onSurface: p.textPrimary,
        onSurfaceVariant: p.textSecondary,
        surfaceContainerHighest: p.surface2,
        outline: p.border,
        outlineVariant: p.border,
        scrim: p.scrim,
      );
}
