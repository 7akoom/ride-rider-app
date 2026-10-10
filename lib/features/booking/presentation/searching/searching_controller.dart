import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../booking_providers.dart';
import '../../domain/entities/ride.dart';
import 'searching_state.dart';

/// How often the ride's state is read while waiting for a captain. Tests shorten it.
final searchCheckIntervalProvider = Provider<Duration>((ref) => const Duration(seconds: 4));

final searchingControllerProvider = NotifierProvider.autoDispose
    .family<SearchingController, SearchingState, Ride>(SearchingController.new);

/// Follows a requested ride until a captain takes it, the search runs out, or it is
/// cancelled; cancels it, or tries again when no captain was found.
class SearchingController extends AutoDisposeFamilyNotifier<SearchingState, Ride> {
  Timer? _poll;
  bool _checking = false;
  bool _closed = false;

  @override
  SearchingState build(Ride arg) {
    ref.onDispose(() {
      _closed = true;
      _poll?.cancel();
    });

    final phase = SearchingState.phaseOf(arg);
    if (phase == SearchPhase.waiting) {
      _startPolling();
    }

    return SearchingState(ride: arg, phase: phase);
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(ref.read(searchCheckIntervalProvider), (_) => unawaited(_check()));
  }

  Future<void> _check() async {
    if (_checking || state.phase != SearchPhase.waiting) {
      return;
    }

    _checking = true;
    final result = await ref.read(loadRideProvider).call(state.ride.id);
    _checking = false;

    // A failed read is tried again at the next tick.
    if (_closed || state.phase != SearchPhase.waiting || result is! Ok<Ride>) {
      return;
    }

    _show(result.value);
  }

  void _show(Ride ride, {bool byRider = false}) {
    final phase = SearchingState.phaseOf(ride);
    state = SearchingState(ride: ride, phase: phase, cancelledByRider: byRider);

    if (phase != SearchPhase.waiting) {
      _poll?.cancel();
    }
  }

  Future<void> cancel() async {
    if (state.phase != SearchPhase.waiting) {
      return;
    }

    state = SearchingState(ride: state.ride, phase: SearchPhase.cancelling);
    final result = await ref.read(cancelRideProvider).call(state.ride.id);

    if (_closed) {
      return;
    }

    switch (result) {
      case Ok(:final value):
        _show(value, byRider: true);
      case Err(:final failure):
        // A captain may have taken it meanwhile: the next read says so.
        state = SearchingState(ride: state.ride, phase: SearchPhase.waiting, failure: failure);
        unawaited(_check());
    }
  }

  /// No captain was found: the same trip again, at a new price.
  Future<void> retry() async {
    if (state.phase != SearchPhase.noCaptain) {
      return;
    }

    state = SearchingState(ride: state.ride, phase: SearchPhase.retrying);
    final result = await ref.read(retryRideProvider).call(state.ride);

    if (_closed) {
      return;
    }

    switch (result) {
      case Ok(:final value):
        _show(value);
        if (state.phase == SearchPhase.waiting) {
          _startPolling();
        }
      case Err(:final failure):
        state = SearchingState(ride: state.ride, phase: SearchPhase.noCaptain, failure: failure);
    }
  }
}
