import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/map/app_map.dart';
import '../../../../design/map/map_route.dart';
import '../../booking_providers.dart';
import '../../domain/entities/route_estimate.dart';
import '../../domain/entities/trip_draft.dart';
import '../../domain/use_cases/estimate_route.dart';
import '../legacy_routes.dart';
import '../spot_view.dart';
import 'choose_ride_controller.dart';
import 'choose_ride_panel.dart';
import 'payment_sheet.dart';

final _routeProvider = FutureProvider.autoDispose.family<Result<RouteEstimate>, TripDraft>(
  (ref, draft) => ref.watch(estimateRouteProvider).call(draft),
);

/// The trip on the map: its points at once, the road once it is known. One object
/// per answer, so the map only redraws when something changed.
final _mapRouteProvider = Provider.autoDispose.family<MapRoute, TripDraft>((ref, draft) {
  final estimate = ref.watch(_routeProvider(draft)).valueOrNull;

  return MapRoute(
    points: [
      (draft.pickup!.point, RoutePointKind.pickup),
      for (final stop in draft.stops) (stop.point, RoutePointKind.stop),
      (draft.destination!.point, RoutePointKind.destination),
    ],
    path: switch (estimate) {
      Ok(:final value) => value.path,
      _ => const [],
    },
  );
});

/// 11: the route on the map, and the ride types with their fixed prices. Requesting
/// opens the search for a captain.
class ChooseRideScreen extends ConsumerWidget {
  const ChooseRideScreen({super.key, required this.draft});

  /// A complete draft: pickup and destination are known.
  final TripDraft draft;

  Future<void> _order(BuildContext context, WidgetRef ref) async {
    final state = ref.read(chooseRideControllerProvider(draft));
    final quote = state.selected;
    final tripId = await ref.read(chooseRideControllerProvider(draft).notifier).order();

    if (tripId == null || quote == null || !context.mounted) {
      return;
    }

    await openLegacySearching(
      context,
      tripId: tripId,
      draft: draft,
      vehicleClass: quote.vehicleClass,
      payment: state.payment,
      destinationLabel: SpotView.title(context.l10n, draft.destination!),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noRoad = switch (ref.watch(_routeProvider(draft))) {
      AsyncData(value: Err(:final failure)) => isNoRoad(failure),
      _ => false,
    };

    return AppScaffold(
      topBar: AppTopBar(title: context.l10n.chooseRideTitle),
      padded: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AppMap(
              center: draft.pickup!.point,
              route: ref.watch(_mapRouteProvider(draft)),
            ),
          ),
          ChooseRidePanel(
            draft: draft,
            noRoad: noRoad,
            onPayment: () => showPaymentSheet(context, draft),
            onOrder: () => _order(context, ref),
          ),
        ],
      ),
    );
  }
}
