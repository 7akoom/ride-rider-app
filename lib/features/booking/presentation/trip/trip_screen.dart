import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/map/app_map.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/ride.dart';
import '../legacy_routes.dart';
import 'trip_controller.dart';
import 'trip_panel.dart';
import 'trip_state.dart';

/// Shows a ride a captain took. Going back from it leads home; the trip goes on, and
/// opening the app again comes back here.
Future<void> openTrip(BuildContext context, Ride ride) => Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => TripScreen(ride: ride)),
      (route) => route.isFirst,
    );

/// 18 to 20: the captain on the way, at the pickup, then the trip itself, with the
/// captain's car moving on the map.
class TripScreen extends ConsumerWidget {
  const TripScreen({super.key, required this.ride});

  final Ride ride;

  /// The sheet over the map: where it opens, how low and how high it goes (shares of
  /// the screen). The map is the whole screen under it.
  static const double sheetStart = 0.42;
  static const double sheetMin = 0.2;
  static const double sheetMax = 0.9;

  void _follow(BuildContext context, TripState? before, TripState now) {
    if (before?.stage == now.stage) {
      return;
    }

    final l10n = context.l10n;

    switch (now.stage) {
      case TripStage.completed:
        openLegacyTripComplete(context, now.ride);
      case TripStage.cancelled:
        final message = switch (now) {
          TripState(cancelledByRider: true) => l10n.tripCancelled,
          TripState(ride: Ride(cancelledByCaptain: true)) => l10n.tripCancelledByCaptain,
          _ => l10n.searchingEnded,
        };
        showAppToast(context, message, tone: Tone.info);
        Navigator.of(context).popUntil((route) => route.isFirst);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tripControllerProvider(ride);
    final state = ref.watch(provider);

    ref.listen(provider, (before, now) => _follow(context, before, now));

    return AppScaffold(
      topBar: AppTopBar(title: context.l10n.tripBarTitle),
      padded: false,
      body: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            Positioned.fill(
              child: AppMap(
                center: state.ride.pickup,
                zoom: AppMap.streetZoom,
                route: state.map,
                vehicle: state.captainAt,
                // The route is framed in the part of the map the sheet leaves open.
                frameBottom: box.maxHeight * sheetStart + Space.x6,
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: sheetStart,
              minChildSize: sheetMin,
              maxChildSize: sheetMax,
              snap: true,
              builder: (context, scroll) => LayoutBuilder(
                builder: (context, sheet) => SingleChildScrollView(
                  controller: scroll,
                  child: ConstrainedBox(
                    // The panel's colour reaches the sheet's bottom, however short it is.
                    constraints: BoxConstraints(minHeight: sheet.maxHeight),
                    child: TripPanel(state: state, onCancel: ref.read(provider.notifier).cancel),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
