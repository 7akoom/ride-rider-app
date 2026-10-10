import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/location/location_access.dart';
import '../../../../design/components/components.dart';
import '../../../../design/map/app_map.dart';
import '../../../../design/tokens/metrics.dart';
import '../../booking_providers.dart';
import '../../domain/entities/saved_place.dart';
import '../../domain/entities/trip_draft.dart';
import '../../domain/use_cases/spot_of_saved.dart';
import '../choose_ride/choose_ride_screen.dart';
import '../legacy_routes.dart';
import '../where_to/where_to_controller.dart';
import '../where_to/where_to_screen.dart';
import 'home_panel.dart';
import 'home_state.dart';

/// 07: the map around the rider, and the panel that starts a booking.
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  AppMapController? _map;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the settings or from another app: location may have changed.
    _lifecycle = AppLifecycleListener(onResume: () => refreshHome(ref));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _centreOnPickup() {
    final point = ref.read(pickupProvider).valueOrNull?.point;

    if (point != null) {
      _map?.moveTo(point);
    }
  }

  Future<void> _myLocation() async {
    if (ref.read(locationStatusProvider).valueOrNull != LocationAccessStatus.granted) {
      await _turnOnLocation();

      return;
    }

    ref.invalidate(pickupProvider);
  }

  Future<void> _turnOnLocation() async {
    await ref.read(turnOnLocationProvider).call();

    if (mounted) {
      refreshHome(ref);
    }
  }

  void _whereTo() {
    final pickup = ref.read(pickupProvider).valueOrNull;

    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => WhereToScreen(start: WhereToStart(pickup: pickup)),
    ));
  }

  /// A saved place is the destination: straight to the trip when the pickup is known.
  void _goToSaved(SavedPlace place) {
    final pickup = ref.read(pickupProvider).valueOrNull;
    final destination = spotOfSaved(place);

    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => pickup == null
          ? WhereToScreen(start: WhereToStart(destination: destination))
          : ChooseRideScreen(draft: TripDraft(pickup: pickup, destination: destination)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final granted =
        ref.watch(locationStatusProvider).valueOrNull == LocationAccessStatus.granted;

    ref.listen(pickupProvider, (_, next) {
      if (next.valueOrNull != null) {
        _centreOnPickup();
      }
    });

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: AppMap(
                  showMyLocation: granted,
                  onCreated: (map) {
                    _map = map;
                    _centreOnPickup();
                  },
                ),
              ),
              PositionedDirectional(
                top: Space.x3,
                end: Space.gutter,
                child: AppIconButton(
                  icon: Icons.notifications_outlined,
                  semanticLabel: l10n.homeNotifications,
                  floating: true,
                  onPressed: () => openLegacyNotifications(context),
                ),
              ),
              PositionedDirectional(
                bottom: Space.x4,
                end: Space.gutter,
                child: AppIconButton(
                  icon: Icons.my_location,
                  semanticLabel: l10n.homeMyLocation,
                  floating: true,
                  onPressed: _myLocation,
                ),
              ),
            ],
          ),
        ),
        HomePanel(
          onWhereTo: _whereTo,
          onSavedPlace: _goToSaved,
          onTurnOnLocation: _turnOnLocation,
        ),
      ],
    );
  }
}
