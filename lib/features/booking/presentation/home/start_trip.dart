import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/spot.dart';
import '../../domain/entities/trip_draft.dart';
import '../choose_ride/choose_ride_screen.dart';
import '../where_to/where_to_controller.dart';
import '../where_to/where_to_screen.dart';
import 'home_state.dart';

// Starting a booking from the home or the booking map, the same way from both.

/// "Where to?": the search, from where the rider is. [schedule] opens the time
/// sheet once the prices are there (book ahead).
Future<void> openWhereTo(BuildContext context, WidgetRef ref, {bool schedule = false}) {
  final pickup = ref.read(pickupProvider).valueOrNull;

  return Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => WhereToScreen(start: WhereToStart(pickup: pickup, schedule: schedule)),
  ));
}

/// A known destination (a saved place, the last one): straight to the prices when the
/// pickup is known, through the search for the pickup otherwise.
Future<void> openTripTo(BuildContext context, WidgetRef ref, Spot destination) {
  final pickup = ref.read(pickupProvider).valueOrNull;

  return Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => pickup == null
        ? WhereToScreen(start: WhereToStart(destination: destination))
        : ChooseRideScreen(draft: TripDraft(pickup: pickup, destination: destination)),
  ));
}
