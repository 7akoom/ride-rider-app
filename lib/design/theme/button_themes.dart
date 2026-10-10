import 'package:flutter/material.dart';

import '../tokens/metrics.dart';
import '../tokens/palette.dart';
import '../tokens/typography.dart';

const _shape = WidgetStatePropertyAll<OutlinedBorder>(
  RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Radii.button))),
);

WidgetStateProperty<Color> _byState(Color enabled, Color disabled) =>
    WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? disabled : enabled,
    );

ButtonStyle _fullWidth(AppTypography t) => ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(Sizes.buttonHeight)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: Space.x6)),
      shape: _shape,
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(t.button),
    );

/// Primary action: brand fill, full width. One per screen.
ButtonStyle primaryButtonStyle(Palette p, AppTypography t) => _fullWidth(t).copyWith(
      backgroundColor: _byState(p.brand, p.surface2),
      foregroundColor: _byState(p.onBrand, p.textTertiary),
      overlayColor: WidgetStatePropertyAll(p.onBrand.withValues(alpha: 0.08)),
    );

/// Secondary action: surface with a 1px border, full width.
ButtonStyle secondaryButtonStyle(Palette p, AppTypography t) =>
    _fullWidth(t).copyWith(
      backgroundColor: WidgetStatePropertyAll(p.surface),
      foregroundColor: _byState(p.textPrimary, p.textTertiary),
      side: WidgetStatePropertyAll(BorderSide(color: p.border)),
      overlayColor: WidgetStatePropertyAll(p.textPrimary.withValues(alpha: 0.06)),
    );

/// Dark filled action (secondary emphasis on light screens).
ButtonStyle inkButtonStyle(Palette p, AppTypography t) => _fullWidth(t).copyWith(
      backgroundColor: _byState(p.ink, p.surface2),
      foregroundColor: _byState(p.onInk, p.textTertiary),
      overlayColor: WidgetStatePropertyAll(p.onInk.withValues(alpha: 0.08)),
    );

/// Destructive action (cancel a trip, delete the account): danger outline.
ButtonStyle dangerButtonStyle(Palette p, AppTypography t) => _fullWidth(t).copyWith(
      backgroundColor: WidgetStatePropertyAll(p.surface),
      foregroundColor: _byState(p.danger, p.textTertiary),
      side: WidgetStatePropertyAll(BorderSide(color: p.danger)),
      overlayColor: WidgetStatePropertyAll(p.danger.withValues(alpha: 0.06)),
    );

/// Text-only action (links, "Not now").
ButtonStyle textButtonStyle(Palette p, AppTypography t) => ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size(Sizes.touchTarget, Sizes.touchTarget),
      ),
      shape: _shape,
      foregroundColor: _byState(p.brandStrong, p.textTertiary),
      textStyle: WidgetStatePropertyAll(t.bodyStrong),
    );

FilledButtonThemeData filledButtonTheme(Palette p, AppTypography t) =>
    FilledButtonThemeData(style: primaryButtonStyle(p, t));

ElevatedButtonThemeData elevatedButtonTheme(Palette p, AppTypography t) =>
    ElevatedButtonThemeData(style: primaryButtonStyle(p, t));

OutlinedButtonThemeData outlinedButtonTheme(Palette p, AppTypography t) =>
    OutlinedButtonThemeData(style: secondaryButtonStyle(p, t));

TextButtonThemeData textButtonTheme(Palette p, AppTypography t) =>
    TextButtonThemeData(style: textButtonStyle(p, t));
