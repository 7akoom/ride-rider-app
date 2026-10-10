import 'package:flutter/material.dart';

import 'tokens/palette.dart';
import 'tokens/typography.dart';

/// `context.palette.surface`, `context.typo.h2`: the only way screens reach colours and
/// text styles.
extension DesignContext on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;

  AppTypography get typo => Theme.of(this).extension<AppTypography>()!;
}
