import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';

/// A car's licence plate, drawn like a plate: bordered, bold, always left to right.
class PlateBadge extends StatelessWidget {
  const PlateBadge({super.key, required this.number, this.region});

  final String number;

  /// The plate's city or region, shown small before the number.
  final String? region;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.typo;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: Space.x2,
        vertical: Space.x1,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        border: Border.all(color: p.textPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (region != null) ...[
            Text(region!, style: t.micro.copyWith(color: p.textSecondary)),
            const SizedBox(width: Space.x2),
          ],
          // Shrinks rather than wraps or cuts when space is tight: a plate is read whole.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  number,
                  style: t.bodyStrong.copyWith(letterSpacing: 1),
                  semanticsLabel: number.split('').join(' '),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
