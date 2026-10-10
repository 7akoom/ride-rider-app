import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';

/// A soft rounded button with an icon and a short label, for options under a list
/// (payment, coupon). [marked] adds a small success dot (a coupon is on).
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.marked = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool marked;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const shape = StadiumBorder();

    return Material(
      color: p.surface2,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.x3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: Sizes.iconSmall, color: p.textPrimary),
                const SizedBox(width: Space.x2),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typo.bodyStrong,
                  ),
                ),
                if (marked) ...[
                  const SizedBox(width: Space.x2),
                  Container(
                    width: Space.x2,
                    height: Space.x2,
                    decoration: BoxDecoration(color: p.success, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
