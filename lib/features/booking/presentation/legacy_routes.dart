import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/trip.dart';
import '../../../core/security/session_storage.dart';
import '../../../state/api_providers.dart';
import '../../rider/notifications_screen.dart';
import '../../rider/profile_screen.dart';
import '../../rider/request_ride_screen.dart';
import '../../rider/ride_history_screen.dart';
import '../../rider/searching_driver_screen.dart';
import '../../rider/tracking_screen.dart';

// The old screens the new home still opens, until their stages replace them:
// booking (3b/3c), the trip (4), activity and account (6). This file goes with them.

void openLegacyBooking(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RequestRideScreen()),
    );

void openLegacyNotifications(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );

Widget legacyActivityTab() => const RideHistoryScreen();

Widget legacyAccountTab() => const ProfileScreen();

/// A trip the rider already has (the app was closed during it) is opened again.
/// Not being able to check is not worth interrupting the rider for.
Future<void> resumeActiveTrip(BuildContext context, WidgetRef ref) async {
  try {
    final riderId = await SessionStorage.readRiderId();
    if (riderId == null) {
      return;
    }

    final trip = await ref.read(tripApiProvider).activeTrip(riderId);
    if (trip == null || !context.mounted) {
      return;
    }

    final Widget screen = trip.status == TripStatus.requested
        ? SearchingDriverScreen(trip: trip, destinationLabel: '')
        : TrackingScreen(trip: trip, destinationLabel: '');

    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  } catch (_) {
    // Checked again the next time the app opens.
  }
}
