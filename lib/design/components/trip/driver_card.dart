import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../design_context.dart';
import '../../tokens/metrics.dart';
import '../buttons/app_icon_button.dart';
import 'app_avatar.dart';
import 'plate_badge.dart';

/// The captain on a trip: photo, name, rating, car and plate, with call and chat.
class DriverCard extends StatelessWidget {
  const DriverCard({
    super.key,
    required this.name,
    required this.car,
    required this.plate,
    this.rating,
    this.photoUrl,
    this.plateRegion,
    this.onCall,
    this.onChat,
    this.hasUnreadMessage = false,
  });

  final String name;

  /// Model and colour, already translated or as the backend wrote them.
  final String car;
  final String plate;
  final String? plateRegion;
  final double? rating;
  final String? photoUrl;
  final VoidCallback? onCall;

  /// Null hides the chat button (the chat backend is not built yet).
  final VoidCallback? onChat;
  final bool hasUnreadMessage;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.typo;

    return Container(
      padding: const EdgeInsetsDirectional.all(Space.x4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          AppAvatar(name: name, imageUrl: photoUrl),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: t.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (rating != null) _Rating(value: rating!),
                Text(car, style: t.caption.copyWith(color: p.textSecondary)),
                const SizedBox(height: Space.x2),
                PlateBadge(number: plate, region: plateRegion),
              ],
            ),
          ),
          if (onChat != null) ...[
            AppIconButton(
              icon: Icons.chat_bubble_outline,
              semanticLabel: context.l10n.actionChat,
              onPressed: onChat,
              showBadge: hasUnreadMessage,
            ),
            const SizedBox(width: Space.x2),
          ],
          if (onCall != null)
            AppIconButton(
              icon: Icons.call_outlined,
              semanticLabel: context.l10n.actionCall,
              onPressed: onCall,
              filled: true,
            ),
        ],
      ),
    );
  }
}

class _Rating extends StatelessWidget {
  const _Rating({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 16, color: context.palette.brandStrong),
        const SizedBox(width: Space.x1),
        Text(value.toStringAsFixed(1), style: context.typo.caption),
      ],
    );
  }
}
