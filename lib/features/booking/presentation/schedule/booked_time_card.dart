import 'package:flutter/material.dart';

import '../../../../core/format/time_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';

/// When a booked ride is, with its "confirmed" badge.
class BookedTimeCard extends StatelessWidget {
  const BookedTimeCard({super.key, required this.at});

  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.typo;
    final local = at.toLocal();

    return Container(
      padding: const EdgeInsetsDirectional.all(Space.x4),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: p.textSecondary),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Text(
              l10n.dayAndTime(formatDate(l10n, local), formatClock(l10n, local)),
              style: t.bodyStrong,
            ),
          ),
          const SizedBox(width: Space.x2),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.x2, vertical: Space.x1),
            decoration: BoxDecoration(
              color: p.successSoft,
              borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
            ),
            child: Text(l10n.bookedConfirmed, style: t.micro.copyWith(color: p.success)),
          ),
        ],
      ),
    );
  }
}
