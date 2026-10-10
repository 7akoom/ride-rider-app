import 'package:flutter/material.dart';

/// Every colour a screen may use, for the current mode (light or dark).
///
/// Screens read colours only from here (`context.palette.surface`), never as literals,
/// so light/dark mode and the investor's brand apply everywhere at once.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.brand,
    required this.onBrand,
    required this.brandStrong,
    required this.brandSoft,
    required this.ink,
    required this.onInk,
    required this.info,
    required this.infoSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.scrim,
  });

  final Color background;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Brand fill (primary buttons, selection) and the text on it.
  final Color brand;
  final Color onBrand;

  /// Brand-coloured text, links and icons on this mode's surfaces.
  final Color brandStrong;

  /// A light brand tint for selected cards and highlights.
  final Color brandSoft;

  /// Dark headers (wallet card, "captain arrived"), bottom navigation, snackbars.
  final Color ink;
  final Color onInk;

  /// Route line, links and info banners.
  final Color info;
  final Color infoSoft;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color scrim;

  List<Color> get _all => [
        background, surface, surface2, border, textPrimary, textSecondary,
        textTertiary, brand, onBrand, brandStrong, brandSoft, ink, onInk, info,
        infoSoft, success, successSoft, warning, warningSoft, danger, dangerSoft,
        scrim,
      ];

  static Palette _fromList(List<Color> c) => Palette(
        background: c[0], surface: c[1], surface2: c[2], border: c[3],
        textPrimary: c[4], textSecondary: c[5], textTertiary: c[6], brand: c[7],
        onBrand: c[8], brandStrong: c[9], brandSoft: c[10], ink: c[11], onInk: c[12],
        info: c[13], infoSoft: c[14], success: c[15], successSoft: c[16],
        warning: c[17], warningSoft: c[18], danger: c[19], dangerSoft: c[20],
        scrim: c[21],
      );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) {
    if (other is! Palette) {
      return this;
    }

    final from = _all;
    final to = other._all;

    return _fromList([
      for (var i = 0; i < from.length; i++) Color.lerp(from[i], to[i], t)!,
    ]);
  }
}
