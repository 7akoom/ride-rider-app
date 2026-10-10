import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/trip.dart';
import '../domain/entities/payment_method.dart';
import '../domain/entities/trip_draft.dart';
import '../../../core/security/session_storage.dart';
import '../../../state/api_providers.dart';
import '../../rider/notifications_screen.dart';
import '../../rider/profile_screen.dart';
import '../../rider/ride_history_screen.dart';
import '../../rider/searching_driver_screen.dart';
import '../../rider/tracking_screen.dart';

// The old screens the new home still opens, until their stages replace them:
// searching for a captain (3c-2), the trip (4), activity and account (6). This file
// goes with them.

/// The trip was just requested: the old search screen follows it. Going back from it
/// leads home, not to the prices.
Future<void> openLegacySearching(
  BuildContext context, {
  required String tripId,
  required TripDraft draft,
  required String vehicleClass,
  required PaymentMethod payment,
  required String destinationLabel,
}) {
  // The search screen only follows the trip by its id; the rest is what was sent.
  final trip = Trip(
    id: tripId,
    riderId: '',
    driverId: '',
    status: TripStatus.requested,
    pickup: draft.pickup!.point,
    dropoff: draft.destination!.point,
    cancellationReason: '',
    vehicleClass: vehicleClass,
    paymentMethod: payment.name,
  );

  return Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => SearchingDriverScreen(trip: trip, destinationLabel: destinationLabel),
    ),
    (route) => route.isFirst,
  );
}

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
