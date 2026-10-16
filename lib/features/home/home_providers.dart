import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/result.dart';
import '../../core/network/api_client_provider.dart';
import '../booking/booking_providers.dart';
import '../booking/domain/entities/captain.dart';
import '../booking/domain/entities/ride.dart';
import '../booking/domain/entities/spot.dart';
import '../booking/presentation/home/home_state.dart';
import '../offers/offers_providers.dart';
import '../wallet/presentation/wallet_state.dart';
import 'data/recent_destinations_repository_impl.dart';
import 'domain/recent_destination.dart';

// What the home shows besides the offers. Each part loads on its own and a failed
// part is left out, so the rest of the home never waits for it.

final recentDestinationsRepositoryProvider = Provider<RecentDestinationsRepository>(
  (ref) => RecentDestinationsRepositoryImpl(ref.watch(apiClientProvider)),
);

/// How often the home asks again about a ride under way, as the trip screens do.
final homeRideCheckIntervalProvider = Provider<Duration>((ref) => const Duration(seconds: 4));

/// The ride the rider has under way: searching, the captain coming or there, or on
/// the trip. Null when there is none, or when it could not be checked (checked again
/// next time).
final homeRideProvider = FutureProvider.autoDispose<Ride?>((ref) async {
  final result = await ref.watch(findActiveRideProvider).call();
  final ride = result is Ok<Ride?> ? result.value : null;

  return ride != null && (ride.hasCaptain || ride.status == RideStatus.searching) ? ride : null;
});

/// The captain of a ride, read once per ride (not on every check); null when it
/// could not be read.
final homeCaptainProvider = FutureProvider.autoDispose.family<Captain?, String>((ref, rideId) async {
  final captain = await ref.watch(loadCaptainProvider).call(rideId);

  return captain is Ok<Captain> ? captain.value : null;
});

/// Where the rider's last trip ended, as a place to go again; null without one.
final lastDestinationProvider = FutureProvider.autoDispose<Spot?>((ref) async {
  final result = await ref.watch(recentDestinationsRepositoryProvider).recent();

  return switch (result) {
    Ok(value: [final last, ...]) when last.address.isNotEmpty =>
      Spot(point: last.point, kind: SpotKind.other, title: last.address),
    _ => null,
  };
});

/// How many money requests wait for the rider: the wallet tile's badge.
final waitingRequestsProvider = Provider.autoDispose<int>((ref) {
  return switch (ref.watch(incomingRequestsProvider).valueOrNull) {
    Ok(:final value) => value.length,
    _ => 0,
  };
});

/// Reads the whole home again: pulled down, back to the app, back from a screen.
void refreshLanding(WidgetRef ref) {
  refreshHome(ref);
  ref
    ..invalidate(homeRideProvider)
    ..invalidate(lastDestinationProvider)
    ..invalidate(offersProvider)
    ..invalidate(keptCodeProvider)
    ..invalidate(walletProvider)
    ..invalidate(incomingRequestsProvider);
}
