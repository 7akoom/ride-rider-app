import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';

/// A tappable row: icon in a rounded square at the start, title and optional subtitle,
/// and a chevron (or [trailing]) at the end. The chevron points the reading direction.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  /// Draws title and icon in the danger colour (delete account, sign out).
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.typo;
    final accent = destructive ? p.danger : p.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(Radii.input)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.listRow),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x2),
          child: Row(
            children: [
              if (icon != null) ...[
                _IconTile(icon: icon!, color: accent),
                const SizedBox(width: Space.x3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: t.bodyStrong.copyWith(color: accent)),
                    if (subtitle != null)
                      Text(subtitle!, style: t.caption.copyWith(color: p.textSecondary)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null && showChevron && onTap != null)
                Icon(Icons.chevron_right, color: p.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.palette.surface2,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.iconButton)),
      ),
      child: Icon(icon, size: Sizes.iconSmall, color: color),
    );
  }
}
