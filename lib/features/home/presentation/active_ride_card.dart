import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/bidi.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../../booking/domain/entities/ride.dart';
import '../home_providers.dart';

/// The ride under way, on top of the home: where it stands and the captain's car,
/// kept current while it shows (the home checks it every few seconds). Tapping it
/// opens the search or the trip. Nothing without one.
class ActiveRideCard extends ConsumerWidget {
  const ActiveRideCard({super.key, required this.onOpen, this.top = 0});

  final ValueChanged<Ride> onOpen;

  /// The space above the card, only there when it shows.
  final double top;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ride = ref.watch(homeRideProvider).valueOrNull;

    if (ride == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final captain = ride.hasCaptain ? ref.watch(homeCaptainProvider(ride.id)).valueOrNull : null;
    final title = switch (ride.stage) {
      TripStage.searching => l10n.searchingTitle,
      TripStage.arrived => l10n.tripArrivedTitle,
      TripStage.onTrip => l10n.tripOnTheWay,
      _ => l10n.tripComingLabel,
    };
    final car = [captain?.color, captain?.make, captain?.model]
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' ');
    final detail = [
      if (captain != null && captain.name.isNotEmpty) captain.name,
      if (car.isNotEmpty) car,
      if (captain != null && captain.plate.isNotEmpty) isolateLtr(captain.plate),
    ].join(' · ');
    const radius = BorderRadius.all(Radius.circular(Radii.card));

    return Padding(
      padding: EdgeInsetsDirectional.only(top: top),
      child: _card(context, ride, title, detail, radius),
    );
  }

  Widget _card(BuildContext context, Ride ride, String title, String detail, BorderRadius radius) {
    final p = context.palette;

    return Material(
      color: p.ink,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => onOpen(ride),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Space.x4),
          child: Row(
            children: [
              Icon(
                ride.stage == TripStage.searching ? Icons.radar : Icons.local_taxi,
                color: p.brand,
                size: Sizes.icon,
              ),
              const SizedBox(width: Space.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.typo.bodyStrong.copyWith(color: p.onInk)),
                    if (detail.isNotEmpty || ride.dropoffAddress.isNotEmpty)
                      Text(
                        detail.isNotEmpty ? detail : ride.dropoffAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.typo.caption.copyWith(color: p.onInk.withValues(alpha: 0.8)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Space.x2),
              Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: p.onInk),
            ],
          ),
        ),
      ),
    );
  }
}
