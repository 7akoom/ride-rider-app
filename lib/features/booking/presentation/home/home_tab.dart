import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/location/location_access.dart';
import '../../../../design/components/components.dart';
import '../../../../design/map/app_map.dart';
import '../../../../design/tokens/metrics.dart';
import '../../booking_providers.dart';
import '../../domain/entities/saved_place.dart';
import '../../domain/use_cases/spot_of_saved.dart';
import 'home_panel.dart';
import 'home_state.dart';
import 'start_trip.dart';

/// Opens the booking map from the home ("Ride").
Future<void> openBookingMap(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BookingMapScreen()),
    );

/// 07 as its own screen, behind the home: the map around the rider and the panel
/// that starts a booking.
class BookingMapScreen extends StatelessWidget {
  const BookingMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      padded: false,
      body: HomeTab(onBack: () => Navigator.of(context).maybePop()),
    );
  }
}

/// 07: the map around the rider, and the panel that starts a booking.
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key, this.onBack});

  /// Shows a back button over the map.
  final VoidCallback? onBack;

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

  void _whereTo() => openWhereTo(context, ref);

  /// A saved place is the destination: straight to the trip when the pickup is known.
  void _goToSaved(SavedPlace place) => openTripTo(context, ref, spotOfSaved(place));

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

    return MapLayout(
      map: (_) => AppMap(
        showMyLocation: granted,
        onCreated: (map) {
          _map = map;
          _centreOnPickup();
        },
      ),
      buttons: Stack(
        children: [
          if (widget.onBack != null)
            PositionedDirectional(
              top: Space.x3,
              start: Space.gutter,
              child: AppIconButton(
                icon: Icons.arrow_back,
                semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
                floating: true,
                onPressed: widget.onBack,
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
      panel: HomePanel(
        onWhereTo: _whereTo,
        onSavedPlace: _goToSaved,
        onTurnOnLocation: _turnOnLocation,
      ),
    );
  }
}
