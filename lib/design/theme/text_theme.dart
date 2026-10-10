import 'package:flutter/material.dart';

import '../tokens/typography.dart';

/// Material's text roles filled from the design's styles, so Flutter's own widgets
/// (dialogs, snackbars, text fields, list tiles) use the same type scale.
TextTheme textThemeFrom(AppTypography t) {
  return TextTheme(
    displayMedium: t.display,
    headlineSmall: t.h1,
    titleLarge: t.h2,
    titleMedium: t.h3,
    titleSmall: t.bodyStrong,
    bodyLarge: t.body,
    bodyMedium: t.body,
    bodySmall: t.caption,
    labelLarge: t.button,
    labelMedium: t.caption.copyWith(fontWeight: FontWeight.w500),
    labelSmall: t.micro,
  );
}
