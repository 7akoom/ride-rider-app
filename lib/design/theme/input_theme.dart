import 'package:flutter/material.dart';

import '../tokens/metrics.dart';
import '../tokens/palette.dart';
import '../tokens/typography.dart';

OutlineInputBorder _border(Color color, {double width = 1}) => OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(Radii.input)),
      borderSide: width == 0 ? BorderSide.none : BorderSide(color: color, width: width),
    );

/// Text fields: filled surface-2, no border until focused (brand) or invalid (danger).
InputDecorationThemeData inputTheme(Palette p, AppTypography t) {
  return InputDecorationThemeData(
    filled: true,
    fillColor: p.surface2,
    isDense: false,
    contentPadding: const EdgeInsetsDirectional.symmetric(
      horizontal: Space.x4,
      vertical: Space.x4,
    ),
    hintStyle: t.body.copyWith(color: p.textTertiary),
    labelStyle: t.caption.copyWith(color: p.textSecondary),
    floatingLabelStyle: t.caption.copyWith(color: p.textSecondary),
    helperStyle: t.caption.copyWith(color: p.textSecondary),
    errorStyle: t.caption.copyWith(color: p.danger),
    prefixIconColor: p.textSecondary,
    suffixIconColor: p.textSecondary,
    border: _border(p.surface2, width: 0),
    enabledBorder: _border(p.surface2, width: 0),
    disabledBorder: _border(p.surface2, width: 0),
    focusedBorder: _border(p.brandStrong, width: 1.5),
    errorBorder: _border(p.danger),
    focusedErrorBorder: _border(p.danger, width: 1.5),
  );
}
