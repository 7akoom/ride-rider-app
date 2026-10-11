import 'package:flutter/material.dart';

import '../../../../core/format/distance_format.dart';
import '../../../../core/format/duration_format.dart';
import '../../../../core/format/time_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/ride.dart';
import 'trip_state.dart';

/// The top of the trip panel, for where the trip stands: the captain coming (18),
/// at the pickup (19), on the way to the destination (20).
class TripHeader extends StatelessWidget {
  const TripHeader({super.key, required this.state});

  final TripState state;

  @override
  Widget build(BuildContext context) {
    final arrivedAt = state.ride.arrivedAt;

    return switch (state.stage) {
      TripStage.arrived when arrivedAt != null => _Arrived(since: arrivedAt),
      TripStage.onTrip => _OnTrip(state: state),
      _ => _Coming(minutes: state.minutesAhead),
    };
  }
}

class _Coming extends StatelessWidget {
  const _Coming({required this.minutes});

  final int? minutes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.typo;
    final minutes = this.minutes;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.tripComingLabel, style: t.caption.copyWith(color: p.textSecondary)),
              const SizedBox(height: Space.x1),
              minutes == null
                  ? Text(l10n.tripComingSoon, style: t.h3)
                  : Text(l10n.etaMinutes(minutes), style: t.h1),
            ],
          ),
        ),
        const SizedBox(width: Space.x3),
        Container(
          width: Sizes.hero / 2,
          height: Sizes.hero / 2,
          decoration: BoxDecoration(
            color: p.brandSoft,
            borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
          ),
          child: Icon(Icons.local_taxi_outlined, color: p.brandStrong, size: Sizes.icon),
        ),
      ],
    );
  }
}

class _Arrived extends StatelessWidget {
  const _Arrived({required this.since});

  final DateTime since;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.typo;

    return Container(
      padding: const EdgeInsetsDirectional.all(Space.x4),
      decoration: BoxDecoration(
        color: p.ink,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
      ),
      child: Row(
        children: [
          Icon(Icons.hail, color: p.brand, size: Sizes.icon),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tripArrivedTitle, style: t.h3.copyWith(color: p.onInk)),
                const SizedBox(height: Space.x1),
                ElapsedBuilder(
                  since: since,
                  builder: (context, elapsed) => Text(
                    l10n.tripArrivedWaiting(formatCountdown(elapsed)),
                    style: t.caption.copyWith(color: p.brand),
                  ),
                ),
                Text(l10n.tripArrivedHint, style: t.caption.copyWith(color: p.onInk)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnTrip extends StatelessWidget {
  const _OnTrip({required this.state});

  final TripState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.typo;
    final ahead = state.ahead;
    final minutes = state.minutesAhead;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.tripArrivalLabel, style: t.caption.copyWith(color: p.textSecondary)),
              const SizedBox(height: Space.x1),
              if (ahead == null || minutes == null)
                Text(l10n.tripOnTheWay, style: t.h3)
              else ...[
                Text(formatClock(l10n, DateTime.now().add(ahead.duration)), style: t.h1),
                Text(
                  l10n.tripRemaining(l10n.etaMinutes(minutes)),
                  style: t.caption.copyWith(color: p.success),
                ),
              ],
            ],
          ),
        ),
        if (ahead != null) ...[
          const SizedBox(width: Space.x3),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.x3, vertical: Space.x2),
            decoration: BoxDecoration(
              color: p.surface2,
              borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
            ),
            child: Text(formatDistance(l10n, ahead.distanceMeters), style: t.bodyStrong),
          ),
        ],
      ],
    );
  }
}
