import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../booking_providers.dart';
import '../../domain/entities/fare_quote.dart';
import '../../domain/entities/passenger.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/trip_draft.dart';
import '../../domain/use_cases/order_ride.dart';
import '../../domain/use_cases/quote_ride.dart';
import 'choose_ride_state.dart';

final chooseRideControllerProvider = NotifierProvider.autoDispose
    .family<ChooseRideController, ChooseRideState, TripDraft>(ChooseRideController.new);

/// The prices for the drafted trip, kept fresh, and the rider's choices: ride type,
/// payment, coupon. Requests the trip.
class ChooseRideController extends AutoDisposeFamilyNotifier<ChooseRideState, TripDraft> {
  Timer? _refresh;
  int _loadNumber = 0;
  bool _closed = false;

  /// New prices are asked for this long before the current ones expire, so the price
  /// on screen can always be requested.
  static const Duration refreshAhead = Duration(seconds: 15);
  static const Duration shortestRefresh = Duration(seconds: 5);

  @override
  ChooseRideState build(TripDraft arg) {
    ref.onDispose(() {
      _closed = true;
      _refresh?.cancel();
    });
    // After build: loading reads and sets the state, which exists only once build
    // has returned it.
    unawaited(Future.microtask(_load));

    return const ChooseRideState();
  }

  Future<void> _load() async {
    _refresh?.cancel();
    final number = ++_loadNumber;
    state = state.copyWith(loading: true);

    final result = await ref
        .read(quoteRideProvider)
        .call(arg, couponCode: state.couponCode);

    // Closed, or a newer load started (the coupon changed) while this one ran.
    if (_closed || number != _loadNumber) {
      return;
    }

    switch (result) {
      case Ok(:final value):
        state = state.copyWith(
          loading: false,
          quotes: value,
          quoteFailure: null,
          selectedClass: _keptSelection(value),
        );
        _scheduleRefresh(value);
      case Err(:final failure):
        state = state.copyWith(loading: false, quotes: null, quoteFailure: failure);
    }
  }

  /// The ride type the rider chose, if it is still offered; the cheapest otherwise.
  String? _keptSelection(FareQuotes quotes) {
    final kept = quotes.ofClass(state.selectedClass);

    return kept?.vehicleClass ??
        (quotes.quotes.isEmpty ? null : quotes.quotes.first.vehicleClass);
  }

  void _scheduleRefresh(FareQuotes quotes) {
    final expiresAt = quotes.expiresAt;
    if (expiresAt == null) {
      return;
    }

    final wait = expiresAt.difference(DateTime.now()) - refreshAhead;
    _refresh = Timer(
      Duration(microseconds: math.max(wait.inMicroseconds, shortestRefresh.inMicroseconds)),
      () => unawaited(_load()),
    );
  }

  Future<void> retry() => _load();

  void select(String vehicleClass) =>
      state = state.copyWith(selectedClass: vehicleClass, orderFailure: null);

  void choosePayment(PaymentMethod method) => state = state.copyWith(payment: method);

  /// Someone else rides; null puts the rider back.
  void setPassenger(Passenger? passenger) =>
      state = state.copyWith(passenger: passenger, orderFailure: null);

  /// Tries [code] on every price. The result shows on the prices (CouponResult).
  Future<void> applyCoupon(String code) async {
    state = state.copyWith(couponCode: normalizeCoupon(code), orderFailure: null);
    await _load();
  }

  Future<void> removeCoupon() async {
    state = state.copyWith(couponCode: null);
    await _load();
  }

  /// Requests the trip at the chosen price. Returns the ride, or null when it did not
  /// go through (the reason is in [ChooseRideState.orderFailure]).
  Future<Ride?> order() async {
    final quote = state.selected;
    if (quote == null || !state.canOrder) {
      return null;
    }

    state = state.copyWith(ordering: true, orderFailure: null);
    final result = await ref
        .read(orderRideProvider)
        .call(draft: arg, quote: quote, payment: state.payment, passenger: state.passenger);

    if (_closed) {
      return null;
    }

    switch (result) {
      case Ok(:final value):
        state = state.copyWith(ordering: false);

        return value;
      case Err(:final failure):
        state = state.copyWith(ordering: false, orderFailure: failure);

        if (orderProblemOf(failure) == OrderProblem.pricesChanged) {
          unawaited(_load());
        }

        return null;
    }
  }
}
