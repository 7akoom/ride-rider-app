import 'package:flutter/material.dart';

import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';

/// A service on the home ("Ride", "Book ahead", "Wallet"): a large icon on a soft
/// square with its name under it, and a count when something waits there.
class ServiceTile extends StatelessWidget {
  const ServiceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
    this.badgeLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// 0 for none.
  final int badge;

  /// What the count means, for screen readers.
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const radius = BorderRadius.all(Radius.circular(Radii.card));

    return Semantics(
      button: true,
      label: badge > 0 && badgeLabel != null ? '$label, $badgeLabel' : null,
      excludeSemantics: badge > 0 && badgeLabel != null,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: p.border)),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.x2, vertical: Space.x3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: Sizes.heroIcon,
                      height: Sizes.heroIcon,
                      decoration: BoxDecoration(
                        color: p.brandSoft,
                        borderRadius: const BorderRadius.all(Radius.circular(Radii.button)),
                      ),
                      child: Icon(icon, size: Sizes.icon + Space.x2, color: p.brandStrong),
                    ),
                    if (badge > 0)
                      PositionedDirectional(
                        top: -Space.x1,
                        end: -Space.x1,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: Space.x5),
                          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.x1),
                          decoration: BoxDecoration(
                            color: p.danger,
                            borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
                            border: Border.all(color: p.surface, width: 2),
                          ),
                          child: Text(
                            badge > 9 ? '9+' : '$badge',
                            textAlign: TextAlign.center,
                            style: context.typo.micro.copyWith(color: p.onInk, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Space.x2),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: context.typo.bodyStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small card in the home's row of shortcuts: an icon, a title and one line
/// (the balance; home or work; where the last trip went).
class HomeShortcutCard extends StatelessWidget {
  const HomeShortcutCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.detail,
    this.value,
  });

  /// The card's width; long names wrap within it.
  static const double width = 156;

  final IconData icon;
  final String title;
  final String? detail;

  /// Shown instead of [detail] (the balance, in strong type).
  final Widget? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const radius = BorderRadius.all(Radius.circular(Radii.card));

    return SizedBox(
      width: width,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: p.border)),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(Space.x3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: Sizes.iconSmall, color: p.textSecondary),
                const SizedBox(height: Space.x2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typo.caption.copyWith(color: p.textSecondary),
                ),
                if (value != null)
                  value!
                else if (detail != null)
                  Text(detail!, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.typo.bodyStrong),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
