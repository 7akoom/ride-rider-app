import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/error/result.dart';
import '../../../../core/format/distance_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../booking_providers.dart';
import '../../domain/entities/route_estimate.dart';
import '../../domain/entities/trip_draft.dart';
import '../../domain/use_cases/estimate_route.dart';
import '../legacy_routes.dart';
import '../spot_view.dart';

final _estimateProvider = FutureProvider.autoDispose.family<Result<RouteEstimate>, TripDraft>(
  (ref, draft) => ref.watch(estimateRouteProvider).call(draft),
);

/// The trip as planned, with the road's distance and time. Stage 3c turns this into
/// choosing the ride; until then "Choose a ride" opens the old booking screen.
class TripReviewScreen extends ConsumerWidget {
  const TripReviewScreen({super.key, required this.draft});

  final TripDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final estimate = ref.watch(_estimateProvider(draft));
    final ready = estimate.valueOrNull is Ok<RouteEstimate>;

    return AppScaffold(
      topBar: AppTopBar(title: l10n.reviewTitle),
      bottomAction: AppButton(
        label: l10n.reviewContinue,
        onPressed: ready ? () => openLegacyBooking(context) : null,
      ),
      body: ListView(
        children: [
          RouteSummary(points: [
            RoutePoint(
              kind: RoutePointKind.pickup,
              label: l10n.routePickup,
              title: SpotView.title(l10n, draft.pickup!),
              subtitle: draft.pickup!.detail,
            ),
            for (var i = 0; i < draft.stops.length; i++)
              RoutePoint(
                kind: RoutePointKind.stop,
                label: l10n.routeStop(i + 1),
                title: SpotView.title(l10n, draft.stops[i]),
                subtitle: draft.stops[i].detail,
              ),
            RoutePoint(
              kind: RoutePointKind.destination,
              label: l10n.routeDestination,
              title: SpotView.title(l10n, draft.destination!),
              subtitle: draft.destination!.detail,
            ),
          ]),
          const SizedBox(height: Space.x6),
          switch (estimate) {
            AsyncData(value: Ok(:final value)) => Text(
                l10n.reviewDistanceTime(
                  formatDistance(l10n, value.distanceMeters),
                  l10n.etaMinutes(math.max(1, value.duration.inMinutes)),
                ),
                style: context.typo.bodyStrong,
              ),
            AsyncData(value: Err(:final failure)) => StatusBanner(
                tone: Tone.danger,
                message: isNoRoad(failure) ? l10n.reviewNoRoad : failure.message(l10n),
                actionLabel: isNoRoad(failure) ? null : l10n.actionRetry,
                onAction: () => ref.invalidate(_estimateProvider(draft)),
              ),
            _ => const SkeletonView(child: SkeletonBox(width: 160, height: 20)),
          },
        ],
      ),
    );
  }
}
