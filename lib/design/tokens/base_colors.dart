import 'dart:ui';

/// The fixed colours of the design brief: the same in every investor's copy.
abstract final class BaseColors {
  static const Color ink = Color(0xFF05070F);
  static const Color white = Color(0xFFFFFFFF);

  // Light mode.
  static const Color lightBackground = Color(0xFFF7F6F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF1EFE9);
  static const Color lightBorder = Color(0xFFE6E2D8);
  static const Color lightText = ink;
  static const Color lightTextSecondary = Color(0xFF4A5060);
  static const Color lightTextTertiary = Color(0xFF8A90A0);
  static const Color lightInfo = Color(0xFF2563EB);
  static const Color lightInfoSoft = Color(0xFFEAF1FD);
  static const Color lightSuccess = Color(0xFF15803D);
  static const Color lightSuccessSoft = Color(0xFFE8F3EC);
  static const Color lightWarning = Color(0xFFB45309);
  static const Color lightWarningSoft = Color(0xFFFFF4E5);
  static const Color lightDanger = Color(0xFFDC2626);
  static const Color lightDangerSoft = Color(0xFFFDECEC);

  // Dark mode.
  static const Color darkBackground = ink;
  static const Color darkSurface = Color(0xFF0D1220);
  static const Color darkSurface2 = Color(0xFF151B2C);
  static const Color darkBorder = Color(0xFF1F2536);
  static const Color darkText = white;
  static const Color darkTextSecondary = Color(0xFF9BA1B0);
  static const Color darkTextTertiary = Color(0xFF6B7280);
  static const Color darkInfo = Color(0xFF60A5FA);
  static const Color darkInfoSoft = Color(0xFF12233F);
  static const Color darkSuccess = Color(0xFF4ADE80);
  static const Color darkSuccessSoft = Color(0xFF0F2A1C);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkWarningSoft = Color(0xFF2E2410);
  static const Color darkDanger = Color(0xFFF87171);
  static const Color darkDangerSoft = Color(0xFF3A1618);

  /// Behind modal sheets and dialogs.
  static const Color scrim = Color(0x7305070F);
}
