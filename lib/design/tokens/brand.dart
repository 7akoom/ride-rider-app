import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../core/config/app_env.dart';
import '../../core/config/hex_color.dart';
import 'base_colors.dart';
import 'contrast.dart';

/// The investor's brand colour and the shades derived from it. This is the only part of
/// the palette that changes between copies of the app.
@immutable
class Brand {
  const Brand({
    required this.fill,
    required this.onFill,
    required this.strongOnLight,
    required this.strongOnDark,
  });

  /// Primary buttons, selected chips, active indicators.
  final Color fill;

  /// Text and icons on [fill] (ink or white, whichever reads better).
  final Color onFill;

  /// Brand-coloured text and icons on light surfaces (at least 4.5:1).
  final Color strongOnLight;

  /// Brand-coloured text and icons on dark surfaces (at least 4.5:1).
  final Color strongOnDark;

  /// The demo copy's gold (Lenda Agency), with the shades chosen in the design brief.
  static const Brand lenda = Brand(
    fill: Color(0xFFF3D59A),
    onFill: BaseColors.ink,
    strongOnLight: Color(0xFF8A6A2B),
    strongOnDark: Color(0xFFF3D59A),
  );

  /// Derives every shade from [fill], keeping each one readable.
  factory Brand.from(Color fill, {Color? strong}) {
    return Brand(
      fill: fill,
      onFill: bestTextOn(fill, dark: BaseColors.ink),
      strongOnLight: withContrast(strong ?? fill, BaseColors.lightSurface),
      strongOnDark: withContrast(fill, BaseColors.darkSurface),
    );
  }

  /// The brand this build was made with (BRAND_COLOR / BRAND_STRONG_COLOR).
  static Brand fromEnv() => resolve(
        brandColor: AppEnv.brandColor,
        brandStrongColor: AppEnv.brandStrongColor,
      );

  @visibleForTesting
  static Brand resolve({required String brandColor, String brandStrongColor = ''}) {
    final fill = parseHexColor(brandColor);
    final strong = parseHexColor(brandStrongColor);

    if (fill == null || (fill == lenda.fill.toARGB32() && strong == null)) {
      return lenda;
    }

    return Brand.from(Color(fill), strong: strong == null ? null : Color(strong));
  }
}
