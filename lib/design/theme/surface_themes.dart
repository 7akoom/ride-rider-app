import 'package:flutter/material.dart';

import '../tokens/metrics.dart';
import '../tokens/palette.dart';
import '../tokens/typography.dart';

BottomSheetThemeData bottomSheetTheme(Palette p) => BottomSheetThemeData(
      backgroundColor: p.surface,
      modalBackgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: p.scrim,
      showDragHandle: true,
      dragHandleColor: p.border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
      ),
    );

DialogThemeData dialogTheme(Palette p, AppTypography t) => DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      barrierColor: p.scrim,
      titleTextStyle: t.h2,
      contentTextStyle: t.body.copyWith(color: p.textSecondary),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Radii.dialog)),
      ),
    );

/// Cards are flat with a 1px border.
CardThemeData cardTheme(Palette p) => CardThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
        side: BorderSide(color: p.border),
      ),
    );

/// Pills: surface-2; selected ones are ink with light text.
ChipThemeData chipTheme(Palette p, AppTypography t) => ChipThemeData(
      backgroundColor: p.surface2,
      selectedColor: p.ink,
      disabledColor: p.surface2,
      labelStyle: t.caption.copyWith(color: p.textPrimary, fontWeight: FontWeight.w500),
      secondaryLabelStyle: t.caption.copyWith(color: p.onInk, fontWeight: FontWeight.w500),
      checkmarkColor: p.onInk,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.x3),
    );

/// The bottom navigation: ink background, the active tab in the brand colour.
NavigationBarThemeData navigationBarTheme(Palette p, AppTypography t) {
  Color tint(Set<WidgetState> states) => states.contains(WidgetState.selected)
      ? p.brand
      : p.onInk.withValues(alpha: 0.7);

  return NavigationBarThemeData(
    backgroundColor: p.ink,
    surfaceTintColor: Colors.transparent,
    indicatorColor: Colors.transparent,
    elevation: 0,
    height: 64,
    iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: tint(s))),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (s) => t.micro.copyWith(color: tint(s)),
    ),
  );
}

SnackBarThemeData snackBarTheme(Palette p, AppTypography t) => SnackBarThemeData(
      backgroundColor: p.ink,
      contentTextStyle: t.body.copyWith(color: p.onInk),
      actionTextColor: p.brand,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Radii.input)),
      ),
    );

DividerThemeData dividerTheme(Palette p) =>
    DividerThemeData(color: p.border, thickness: 1, space: 1);

ProgressIndicatorThemeData progressTheme(Palette p) => ProgressIndicatorThemeData(
      color: p.brand,
      linearTrackColor: p.surface2,
      circularTrackColor: p.surface2,
    );
