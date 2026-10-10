import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';

/// One choice in a list of cards where exactly one is picked: languages, payment
/// methods, cancel reasons. The picked card gets a brand border and a filled dot.
class AppRadioTile extends StatelessWidget {
  const AppRadioTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;

  /// A short badge at the start (a letter, an icon).
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.typo;
    const radius = BorderRadius.all(Radius.circular(Radii.card));

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? p.brandSoft : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? p.brand : p.border, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.listRow),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(Space.x4),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: Space.x3),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: t.bodyStrong),
                        if (subtitle != null)
                          Text(subtitle!, style: t.caption.copyWith(color: p.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.x3),
                  _Dot(selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: Sizes.iconSmall,
      height: Sizes.iconSmall,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? p.brand : p.surface2,
        border: Border.all(color: selected ? p.brand : p.border, width: 2),
      ),
      child: selected
          ? Center(
              child: Container(
                width: Sizes.iconSmall / 3,
                height: Sizes.iconSmall / 3,
                decoration: BoxDecoration(shape: BoxShape.circle, color: p.onBrand),
              ),
            )
          : null,
    );
  }
}
