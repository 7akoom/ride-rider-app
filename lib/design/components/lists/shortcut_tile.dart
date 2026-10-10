import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';

/// A round icon with a short label under it: saved places on the home screen.
class ShortcutTile extends StatelessWidget {
  const ShortcutTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.input)),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Space.x1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: Sizes.iconButton + Space.x2,
                height: Sizes.iconButton + Space.x2,
                decoration: BoxDecoration(shape: BoxShape.circle, color: p.surface2),
                child: Icon(icon, color: p.textPrimary),
              ),
              const SizedBox(height: Space.x1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.typo.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
