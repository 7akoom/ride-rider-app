import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/map/app_map.dart';
import '../../domain/entities/ride.dart';
import '../../domain/use_cases/retry_ride.dart';
import '../choose_ride/choose_ride_screen.dart';
import '../legacy_routes.dart';
import 'no_captain_panel.dart';
import 'searching_controller.dart';
import 'searching_panel.dart';
import 'searching_state.dart';

/// Shows a ride that waits for a captain. Going back from it leads home; the ride
/// goes on, and opening the app again comes back here.
Future<void> openSearching(BuildContext context, Ride ride) => Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => SearchingScreen(ride: ride)),
      (route) => route.isFirst,
    );

/// 15 and 16: looking for a captain around the pickup, and what to do when none
/// was found.
class SearchingScreen extends ConsumerWidget {
  const SearchingScreen({super.key, required this.ride});

  final Ride ride;

  /// The panel takes at most this share of the screen; the map keeps the rest.
  static const double panelShare = 0.68;

  void _follow(BuildContext context, SearchingState? before, SearchingState now) {
    if (before?.phase == now.phase) {
      return;
    }

    final l10n = context.l10n;

    switch (now.phase) {
      case SearchPhase.captainFound:
        openLegacyTracking(context, now.ride);
      case SearchPhase.ended:
        showAppToast(
          context,
          now.cancelledByRider ? l10n.searchingCancelled : l10n.searchingEnded,
          tone: Tone.info,
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      default:
        break;
    }
  }

  void _chooseAnother(BuildContext context, Ride ride) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => ChooseRideScreen(draft: draftOf(ride))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = searchingControllerProvider(ride);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final searching = state.phase == SearchPhase.waiting || state.phase == SearchPhase.cancelling;

    ref.listen(provider, (before, now) => _follow(context, before, now));

    return AppScaffold(
      topBar: AppTopBar(title: context.l10n.searchingBarTitle),
      padded: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppMap(center: state.ride.pickup, zoom: AppMap.streetZoom),
                // The map opens on the pickup: the rings stand on it.
                if (searching) const IgnorePointer(child: Center(child: PulseRings())),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * panelShare,
            ),
            child: SingleChildScrollView(
              child: searching
                  ? SearchingPanel(state: state, onCancel: controller.cancel)
                  : NoCaptainPanel(
                      state: state,
                      onRetry: controller.retry,
                      onChange: () => _chooseAnother(context, state.ride),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
