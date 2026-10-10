import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/location/location_access.dart';
import '../../../../design/components/components.dart';
import '../../../../design/map/app_map.dart';
import '../../../../design/tokens/metrics.dart';
import '../../booking_providers.dart';
import '../legacy_routes.dart';
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
          onWhereTo: () => openLegacyBooking(context),
          onSavedPlace: (_) => openLegacyBooking(context),
          onTurnOnLocation: _turnOnLocation,
        ),
      ],
    );
  }
}
