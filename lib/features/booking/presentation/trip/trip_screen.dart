import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/map/app_map.dart';
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

  /// The panel takes at most this share of the screen; the map keeps the rest.
  static const double panelShare = 0.62;

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AppMap(
              center: state.ride.pickup,
              zoom: AppMap.streetZoom,
              route: state.map,
              vehicle: state.captainAt,
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * panelShare,
            ),
            child: SingleChildScrollView(
              child: TripPanel(state: state, onCancel: ref.read(provider.notifier).cancel),
            ),
          ),
        ],
      ),
    );
  }
}
