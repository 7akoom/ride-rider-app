import 'package:flutter/painting.dart';

import 'base_colors.dart';
import 'brand.dart';
import 'palette.dart';

/// The light and dark palettes for a given [Brand].
abstract final class Palettes {
  static Palette light(Brand brand) => Palette(
        background: BaseColors.lightBackground,
        surface: BaseColors.lightSurface,
        surface2: BaseColors.lightSurface2,
        border: BaseColors.lightBorder,
        textPrimary: BaseColors.lightText,
        textSecondary: BaseColors.lightTextSecondary,
        textTertiary: BaseColors.lightTextTertiary,
        brand: brand.fill,
        onBrand: brand.onFill,
        brandStrong: brand.strongOnLight,
        brandSoft: _tint(brand.fill, BaseColors.lightSurface, 0.16),
        ink: BaseColors.ink,
        onInk: BaseColors.white,
        info: BaseColors.lightInfo,
        infoSoft: BaseColors.lightInfoSoft,
        success: BaseColors.lightSuccess,
        successSoft: BaseColors.lightSuccessSoft,
        warning: BaseColors.lightWarning,
        warningSoft: BaseColors.lightWarningSoft,
        danger: BaseColors.lightDanger,
        dangerSoft: BaseColors.lightDangerSoft,
        scrim: BaseColors.scrim,
      );

  static Palette dark(Brand brand) => Palette(
        background: BaseColors.darkBackground,
        surface: BaseColors.darkSurface,
        surface2: BaseColors.darkSurface2,
        border: BaseColors.darkBorder,
        textPrimary: BaseColors.darkText,
        textSecondary: BaseColors.darkTextSecondary,
        textTertiary: BaseColors.darkTextTertiary,
        brand: brand.fill,
        onBrand: brand.onFill,
        brandStrong: brand.strongOnDark,
        brandSoft: _tint(brand.fill, BaseColors.darkSurface, 0.14),
        ink: BaseColors.darkSurface2,
        onInk: BaseColors.white,
        info: BaseColors.darkInfo,
        infoSoft: BaseColors.darkInfoSoft,
        success: BaseColors.darkSuccess,
        successSoft: BaseColors.darkSuccessSoft,
        warning: BaseColors.darkWarning,
        warningSoft: BaseColors.darkWarningSoft,
        danger: BaseColors.darkDanger,
        dangerSoft: BaseColors.darkDangerSoft,
        scrim: BaseColors.scrim,
      );

  static Color _tint(Color color, Color over, double amount) =>
      Color.alphaBlend(color.withValues(alpha: amount), over);
}
