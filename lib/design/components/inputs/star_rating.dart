import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../design_context.dart';
import '../../tokens/metrics.dart';

/// Five stars to tap; the chosen ones are filled in the brand's colour. 0 is none yet.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const double _star = Sizes.touchTarget;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var star = 1; star <= 5; star++)
          Semantics(
            button: true,
            selected: star <= value,
            label: l10n.rateStars(star),
            child: InkResponse(
              onTap: () => onChanged(star),
              radius: _star / 2 + Space.x1,
              child: Padding(
                padding: const EdgeInsetsDirectional.all(Space.x1),
                child: Icon(
                  star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: _star,
                  color: star <= value ? p.brand : p.textTertiary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
