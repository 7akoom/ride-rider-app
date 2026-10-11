import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../rider/notifications_screen.dart';
import '../../rider/profile_screen.dart';
import '../../rider/ride_history_screen.dart';
import '../booking_providers.dart';
import '../domain/entities/ride.dart';
import 'searching/searching_screen.dart';
import 'trip/trip_screen.dart';

// The old screens the new app still opens, until their stages replace them: activity
// and account (6). This file goes with them.

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
    await openTrip(context, ride);
  } else if (ride.status == RideStatus.searching) {
    await openSearching(context, ride);
  }
}
