import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/models/trip.dart';
import '../../rider/notifications_screen.dart';
import '../../rider/profile_screen.dart';
import '../../rider/ride_history_screen.dart';
import '../../rider/tracking_screen.dart';
import '../booking_providers.dart';
import '../domain/entities/ride.dart';
import 'searching/searching_screen.dart';

// The old screens the new home still opens, until their stages replace them: the
// trip (4), activity and account (6). This file goes with them.

/// A captain took the ride: the old trip screen follows it, in place of the search.
Future<void> openLegacyTracking(BuildContext context, Ride ride) =>
    Navigator.of(context).pushReplacement(_tracking(ride));

void openLegacyNotifications(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );

Widget legacyActivityTab() => const RideHistoryScreen();

Widget legacyAccountTab() => const ProfileScreen();

/// A ride the rider already has (the app was closed during it) is opened again: the
/// search while no captain has it, the trip screen once one has. Not being able to
/// check is not worth interrupting the rider for: it is checked again next time.
Future<void> resumeActiveTrip(BuildContext context, WidgetRef ref) async {
  final result = await ref.read(findActiveRideProvider).call();
  final ride = result is Ok<Ride?> ? result.value : null;

  if (ride == null || !context.mounted) {
    return;
  }

  if (ride.hasCaptain) {
    await Navigator.of(context).push(_tracking(ride));
  } else if (ride.status == RideStatus.searching) {
    await openSearching(context, ride);
  }
}

MaterialPageRoute<void> _tracking(Ride ride) {
  // The trip screen reads the trip again by its id at once; the rest is what is known.
  final trip = Trip(
    id: ride.id,
    riderId: '',
    driverId: '',
    status: ride.status == RideStatus.onTrip ? TripStatus.inProgress : TripStatus.accepted,
    pickup: ride.pickup,
    dropoff: ride.dropoff,
    cancellationReason: '',
    vehicleClass: ride.vehicleClass,
    paymentMethod: ride.payment.name,
  );

  return MaterialPageRoute<void>(
    builder: (_) => TrackingScreen(trip: trip, destinationLabel: ride.dropoffAddress),
  );
}
