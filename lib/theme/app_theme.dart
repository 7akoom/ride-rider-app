import 'package:flutter/material.dart';
import '../design/tokens/palette.dart';

/// Spacing scale — mirrors the Design System's space-1..space-6.
class AppSpacing {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;
}

/// Radius scale — mirrors radius-sm / radius-md / radius-full.
class AppRadius {
  static const double sm = 8;
  static const double md = 16;
  static const double full = 9999;
}

/// Color tokens as a ThemeExtension, so both light and dark values live in
/// one place and are looked up automatically with the platform brightness —
/// exactly the split the Design System defines. brand-500/600/100 are the
/// ONLY colors a re-branded deployment changes; everything else here stays
/// fixed across every licensed copy.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color brand500;
  final Color brand600;
  final Color brand100;
  final Color success;
  final Color warning;
  final Color danger;
  final Color ink;
  final Color inkMuted;
  final Color surface100;
  final Color surface200;
  final Color border;

  const AppColors({
    required this.brand500,
    required this.brand600,
    required this.brand100,
    required this.success,
    required this.warning,
    required this.danger,
    required this.ink,
    required this.inkMuted,
    required this.surface100,
    required this.surface200,
    required this.border,
  });

  /// The legacy colour names mapped onto the new design tokens, so the screens that
  /// are not migrated yet already show the new palette. Removed with the last of them.
  factory AppColors.fromPalette(Palette p) => AppColors(
        brand500: p.brandStrong,
        brand600: Color.lerp(p.brandStrong, const Color(0xFF000000), 0.2)!,
        brand100: p.brandSoft,
        success: p.success,
        warning: p.warning,
        danger: p.danger,
        ink: p.textPrimary,
        inkMuted: p.textSecondary,
        surface100: p.background,
        surface200: p.surface,
        border: p.border,
      );

  static const light = AppColors(
    brand500: Color(0xFF0E7C7B),
    brand600: Color(0xFF0A5F5E),
    brand100: Color(0xFFC9E8E6),
    success: Color(0xFF2F8F4E),
    warning: Color(0xFFB4720B),
    danger: Color(0xFFC4433D),
    ink: Color(0xFF1B2430),
    inkMuted: Color(0xFF5B6672),
    surface100: Color(0xFFF1F3F4),
    surface200: Color(0xFFFFFFFF),
    border: Color(0xFFDBE0E4),
  );

  static const dark = AppColors(
    brand500: Color(0xFF17A3A1),
    brand600: Color(0xFF0E7C7B),
    brand100: Color(0xFF1B4A48),
    success: Color(0xFF4CAE6C),
    warning: Color(0xFFD99A2B),
    danger: Color(0xFFE2635C),
    ink: Color(0xFFE7EBEF),
    inkMuted: Color(0xFF9AA5B1),
    surface100: Color(0xFF14181D),
    surface200: Color(0xFF1D2229),
    border: Color(0xFF2A3038),
  );

  @override
  AppColors copyWith({
    Color? brand500,
    Color? brand600,
    Color? brand100,
    Color? success,
    Color? warning,
    Color? danger,
    Color? ink,
    Color? inkMuted,
    Color? surface100,
    Color? surface200,
    Color? border,
  }) {
    return AppColors(
      brand500: brand500 ?? this.brand500,
      brand600: brand600 ?? this.brand600,
      brand100: brand100 ?? this.brand100,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      surface100: surface100 ?? this.surface100,
      surface200: surface200 ?? this.surface200,
      border: border ?? this.border,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      brand500: Color.lerp(brand500, other.brand500, t)!,
      brand600: Color.lerp(brand600, other.brand600, t)!,
      brand100: Color.lerp(brand100, other.brand100, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      surface100: Color.lerp(surface100, other.surface100, t)!,
      surface200: Color.lerp(surface200, other.surface200, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

/// Convenience getter: `context.colors.brand500` instead of
/// `Theme.of(context).extension<AppColors>()!.brand500`.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
