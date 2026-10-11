import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/location/geo_point.dart';
import '../../booking_providers.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/route_estimate.dart';
import 'trip_state.dart';

/// How often the trip and the captain's position are read. Tests shorten it.
final tripCheckIntervalProvider = Provider<Duration>((ref) => const Duration(seconds: 4));

final tripControllerProvider =
    NotifierProvider.autoDispose.family<TripController, TripState, Ride>(TripController.new);

/// Follows a ride from the captain taking it to its end: the trip's state, who the
/// captain is, where they are and the road ahead of them. Cancels it before it starts.
class TripController extends AutoDisposeFamilyNotifier<TripState, Ride> {
  /// The road ahead is asked again this often (and whenever the stage changes).
  static const Duration routeEvery = Duration(seconds: 30);

  Timer? _poll;
  bool _checking = false;
  bool _closed = false;
  DateTime? _routedAt;
  TripStage? _routedFor;

  static bool _ongoing(TripStage stage) =>
      stage != TripStage.completed && stage != TripStage.cancelled;

  @override
  TripState build(Ride arg) {
    ref.onDispose(() {
      _closed = true;
      _poll?.cancel();
    });

    if (_ongoing(arg.stage)) {
      _poll = Timer.periodic(ref.read(tripCheckIntervalProvider), (_) => unawaited(_check()));
      unawaited(Future.microtask(_check));
    }

    return TripState.of(arg);
  }

  Future<void> _check() async {
    if (_checking || _closed || !_ongoing(state.stage)) {
      return;
    }

    _checking = true;
    try {
      await _read();
      await _route();
    } finally {
      _checking = false;
    }
  }

  /// A failed read keeps what is known; the next tick tries again.
  Future<void> _read() async {
    final id = state.ride.id;
    final ride = ref.read(loadRideProvider).call(id);
    final position = ref.read(locateCaptainProvider).call(id);
    final captain = state.captain == null ? ref.read(loadCaptainProvider).call(id) : null;
    final (rideResult, positionResult, captainResult) = (await ride, await position, await captain);

    if (_closed) {
      return;
    }

    final before = state.stage;
    var next = state.copyWith(
      ride: _valueOf(rideResult),
      // The type is named: inferred from the parameter it would drop the null.
      captainAt: _valueOf<GeoPoint?>(positionResult),
      captain: captainResult == null ? null : _valueOf(captainResult),
      failure: state.failure,
    );

    if (next.stage != before) {
      // The road ahead goes somewhere else now.
      next = next.withAhead(null);
    }

    state = next;

    if (!_ongoing(next.stage)) {
      _poll?.cancel();
    }
  }

  static T? _valueOf<T>(Result<T> result) => switch (result) {
        Ok(:final value) => value,
        Err() => null,
      };

  Future<void> _route() async {
    final from = state.captainAt;
    final now = DateTime.now();
    final last = _routedAt;

    if (from == null || !_ongoing(state.stage) || state.stage == TripStage.searching) {
      return;
    }

    if (_routedFor == state.stage && last != null && now.difference(last) < routeEvery) {
      return;
    }

    final stage = state.stage;
    _routedAt = now;
    _routedFor = stage;
    final result = await ref.read(routeAheadProvider).call(state.ride, from);

    if (!_closed && state.stage == stage && result is Ok<RouteEstimate>) {
      state = state.withAhead(result.value);
    }
  }

  Future<void> cancel() async {
    if (!state.canCancel || state.cancelling) {
      return;
    }

    state = state.copyWith(cancelling: true);
    final result = await ref.read(cancelRideProvider).call(state.ride.id);

    if (_closed) {
      return;
    }

    switch (result) {
      case Ok(:final value):
        _poll?.cancel();
        state = state.copyWith(ride: value, cancelling: false, cancelledByRider: true);
      case Err(:final failure):
        // The trip may have started meanwhile: the next read says so.
        state = state.copyWith(cancelling: false, failure: failure);
    }
  }
}
