import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/location/location_access.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../../booking/booking_providers.dart';
import '../../booking/domain/entities/ride.dart';
import '../../booking/domain/entities/saved_place.dart';
import '../../booking/domain/use_cases/spot_of_saved.dart';
import '../../booking/presentation/home/home_state.dart';
import '../../booking/presentation/home/home_tab.dart';
import '../../booking/presentation/home/start_trip.dart';
import '../../booking/presentation/legacy_routes.dart';
import '../../booking/presentation/searching/searching_screen.dart';
import '../../booking/presentation/trip/trip_screen.dart';
import '../../offers/presentation/offers_section.dart';
import '../../wallet/presentation/wallet_screen.dart';
import '../../wallet/presentation/wallet_state.dart';
import '../home_providers.dart';
import 'active_ride_card.dart';
import 'home_header.dart';
import 'home_tiles.dart';

/// The first tab: what the rider can do from here, built from what the platform has
/// for them. A ride under way, the services (ride now, book ahead, the wallet), their
/// shortcuts, and the offers when there are any.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final AppLifecycleListener _lifecycle;

  /// Asks again about the ride under way while there is one and the home is in
  /// front: the card follows the ride (captain on the way, there, on the trip, done).
  Timer? _rideCheck;

  /// A screen opened from the home is in front; the home waits.
  bool _away = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    // Back from the settings or from another app: location, the ride and the wallet
    // may have changed.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _paused = false;
        refreshLanding(ref);
      },
      onPause: () {
        _paused = true;
        _followRide(null);
      },
    );
  }

  @override
  void dispose() {
    _rideCheck?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _followRide(Ride? ride) {
    final follow = ride != null && !_away && !_paused;

    if (!follow) {
      _rideCheck?.cancel();
      _rideCheck = null;
    } else {
      _rideCheck ??= Timer.periodic(
        ref.read(homeRideCheckIntervalProvider),
        (_) => ref.invalidate(homeRideProvider),
      );
    }
  }

  /// Opens a screen and reads the home again once the rider is back.
  Future<void> _visit(Future<void> Function() open) async {
    _away = true;
    _followRide(null);
    await open();
    _away = false;

    if (mounted) {
      refreshLanding(ref);
    }
  }

  Future<void> _turnOnLocation() async {
    await ref.read(turnOnLocationProvider).call();

    if (mounted) {
      refreshLanding(ref);
    }
  }

  void _openRide(Ride ride) => unawaited(_visit(
        () => ride.hasCaptain ? openTrip(context, ride) : openSearching(context, ride),
      ));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = ref.watch(locationStatusProvider).valueOrNull;

    ref.listen(homeRideProvider, (_, next) {
      if (!next.isLoading) {
        _followRide(next.valueOrNull);
      }
    });

    return RefreshIndicator(
      onRefresh: () async => refreshLanding(ref),
      child: ListView(
        padding: const EdgeInsetsDirectional.only(top: Space.x3, bottom: Space.x8),
        children: [
          _Gutter(
            child: HomeHeader(
              onWhereTo: () => unawaited(_visit(() => openWhereTo(context, ref))),
              onNotifications: () => unawaited(_visit(() => openLegacyNotifications(context))),
            ),
          ),
          if (status != null && status != LocationAccessStatus.granted)
            _Gutter(
              top: Space.x3,
              child: StatusBanner(
                tone: Tone.warning,
                message: l10n.homeLocationOff,
                actionLabel: l10n.homeLocationTurnOn,
                onAction: () => unawaited(_turnOnLocation()),
              ),
            ),
          _Gutter(child: ActiveRideCard(onOpen: _openRide, top: Space.x3)),
          _Gutter(
            top: Space.x3,
            child: _Services(visit: _visit),
          ),
          const SizedBox(height: Space.section),
          _Shortcuts(visit: _visit),
          const OffersSection(top: Space.section),
          const SizedBox(height: Space.section),
          const _Gutter(child: PromoCodeCard()),
        ],
      ),
    );
  }
}

class _Gutter extends StatelessWidget {
  const _Gutter({required this.child, this.top = 0});

  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsetsDirectional.fromSTEB(Space.gutter, top, Space.gutter, 0),
        child: child,
      );
}

class _Services extends ConsumerWidget {
  const _Services({required this.visit});

  final Future<void> Function(Future<void> Function() open) visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final waiting = ref.watch(waitingRequestsProvider);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ServiceTile(
              icon: Icons.local_taxi_outlined,
              label: l10n.homeRide,
              onTap: () => unawaited(visit(() => openBookingMap(context))),
            ),
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: ServiceTile(
              icon: Icons.event_outlined,
              label: l10n.homeSchedule,
              onTap: () => unawaited(visit(() => openWhereTo(context, ref, schedule: true))),
            ),
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: ServiceTile(
              icon: Icons.account_balance_wallet_outlined,
              label: l10n.walletTitle,
              badge: waiting,
              badgeLabel: waiting > 0 ? l10n.homeWaitingRequests(waiting) : null,
              onTap: () => unawaited(visit(() => openWallet(context))),
            ),
          ),
        ],
      ),
    );
  }
}

/// The balance, home and work, and where the last trip went, in one row that scrolls.
class _Shortcuts extends ConsumerWidget {
  const _Shortcuts({required this.visit});

  final Future<void> Function(Future<void> Function() open) visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final balance = ref.watch(walletBalanceProvider);
    final saved = (ref.watch(shortcutsProvider).valueOrNull ?? const <SavedPlace>[])
        .where((place) => place.kind != SavedPlaceKind.other)
        .toList();
    final last = ref.watch(lastDestinationProvider).valueOrNull;

    final cards = <Widget>[
      HomeShortcutCard(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.homeBalance,
        value: balance == null
            ? Text('—', style: context.typo.bodyStrong)
            : MoneyText(balance, style: context.typo.bodyStrong),
        onTap: () => unawaited(visit(() => openWallet(context))),
      ),
      for (final place in saved)
        HomeShortcutCard(
          icon: place.kind == SavedPlaceKind.home ? Icons.home_outlined : Icons.work_outline,
          title: l10n.homeRideTo,
          detail: place.kind == SavedPlaceKind.home ? l10n.savedHome : l10n.savedWork,
          onTap: () => unawaited(visit(() => openTripTo(context, ref, spotOfSaved(place)))),
        ),
      if (last != null)
        HomeShortcutCard(
          icon: Icons.history,
          title: l10n.homeLastTrip,
          detail: last.title,
          onTap: () => unawaited(visit(() => openTripTo(context, ref, last))),
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.gutter),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: Space.x3),
              cards[i],
            ],
          ],
        ),
      ),
    );
  }
}
