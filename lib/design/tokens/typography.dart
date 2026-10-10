import 'package:flutter/material.dart';

/// The text styles of the design brief. Screens use these (`context.typo.h2`), never
/// font sizes or weights of their own.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.display,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.body,
    required this.bodyStrong,
    required this.caption,
    required this.micro,
    required this.button,
    required this.price,
    required this.amount,
  });

  /// Builds every style in [color] with the given font family and fallback.
  factory AppTypography.build({
    required Color color,
    required String family,
    required List<String> fallback,
  }) {
    TextStyle style(double size, double lineHeight, FontWeight weight,
        {bool tabular = false}) {
      return TextStyle(
        fontFamily: family,
        fontFamilyFallback: fallback,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        color: color,
        fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
      );
    }

    return AppTypography(
      display: style(32, 40, FontWeight.w700),
      h1: style(24, 32, FontWeight.w700),
      h2: style(20, 28, FontWeight.w600),
      h3: style(17, 24, FontWeight.w600),
      body: style(15, 22, FontWeight.w400),
      bodyStrong: style(15, 22, FontWeight.w600),
      caption: style(13, 18, FontWeight.w400),
      micro: style(11, 14, FontWeight.w500),
      button: style(16, 22, FontWeight.w600),
      price: style(18, 24, FontWeight.w700, tabular: true),
      amount: style(48, 56, FontWeight.w700, tabular: true),
    );
  }

  final TextStyle display;
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle caption;
  final TextStyle micro;
  final TextStyle button;

  /// Prices in lists and cards (digits of equal width, so columns line up).
  final TextStyle price;

  /// The big number on amount-entry and balance screens.
  final TextStyle amount;

  List<TextStyle> get _all =>
      [display, h1, h2, h3, body, bodyStrong, caption, micro, button, price, amount];

  @override
  AppTypography copyWith() => this;

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) {
      return this;
    }

    final a = _all;
    final b = other._all;
    TextStyle at(int i) => TextStyle.lerp(a[i], b[i], t)!;

    return AppTypography(
      display: at(0), h1: at(1), h2: at(2), h3: at(3), body: at(4),
      bodyStrong: at(5), caption: at(6), micro: at(7), button: at(8),
      price: at(9), amount: at(10),
    );
  }
}
