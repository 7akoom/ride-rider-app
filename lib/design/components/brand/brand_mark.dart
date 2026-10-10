import 'package:flutter/material.dart';

import '../../../core/config/app_env.dart';
import '../../design_context.dart';
import '../../tokens/shadows.dart';

/// The copy's mark: the first letter of its name on the brand colour. Every investor's
/// copy gets its own name and colour from the build, so there is no image to replace.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final name = AppEnv.appName.trim();
    final letter = name.isEmpty ? '' : String.fromCharCode(name.runes.first);

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.brand,
          borderRadius: BorderRadius.all(Radius.circular(size * 0.28)),
          boxShadow: Shadows.floating,
        ),
        child: Text(
          letter.toUpperCase(),
          style: context.typo.display.copyWith(color: p.onBrand, height: 1),
        ),
      ),
    );
  }
}
