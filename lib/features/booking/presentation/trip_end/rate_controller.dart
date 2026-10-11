import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../booking_providers.dart';
import '../../domain/entities/ride.dart';
import '../../domain/use_cases/finish_trip.dart';
import '../../trip_end_providers.dart';

final rateControllerProvider =
    NotifierProvider.autoDispose.family<RateController, RateState, Ride>(RateController.new);

final class RateState {
  const RateState({
    this.stars = 0,
    this.tip = 0,
    this.customTip = false,
    this.balance,
    this.sending = false,
    this.rated = false,
    this.tipped = 0,
    this.done = false,
    this.tipProblem,
    this.failure,
  });

  final int stars;

  /// The tip chosen, whole currency units; 0 for none.
  final int tip;

  /// The rider types the tip rather than picking one.
  final bool customTip;

  /// The wallet's balance, once read.
  final int? balance;
  final bool sending;

  /// Already sent (a retry after a failed tip does not rate again).
  final bool rated;
  final int tipped;

  /// Everything went: the thanks show (26).
  final bool done;
  final TipProblem? tipProblem;
  final Failure? failure;

  bool get canSend => !sending && (stars > 0 || tip > 0);

  RateState copyWith({
    int? stars,
    int? tip,
    bool? customTip,
    int? balance,
    bool? sending,
    bool? rated,
    int? tipped,
    bool? done,
    TipProblem? tipProblem,
    Failure? failure,
  }) =>
      RateState(
        stars: stars ?? this.stars,
        tip: tip ?? this.tip,
        customTip: customTip ?? this.customTip,
        balance: balance ?? this.balance,
        sending: sending ?? this.sending,
        rated: rated ?? this.rated,
        tipped: tipped ?? this.tipped,
        done: done ?? this.done,
        tipProblem: tipProblem,
        failure: failure,
      );
}

/// 25: the stars, a word for the operator and a tip from the wallet, sent together.
class RateController extends AutoDisposeFamilyNotifier<RateState, Ride> {
  String _comment = '';

  @override
  RateState build(Ride arg) {
    unawaited(Future.microtask(_loadBalance));

    return const RateState();
  }

  Future<void> _loadBalance() async {
    final result = await ref.read(loadWalletBalanceProvider).call();

    if (result case Ok(:final value)) {
      state = state.copyWith(balance: value, tipProblem: state.tipProblem, failure: state.failure);
    }
  }

  void setStars(int stars) => state = state.copyWith(stars: stars);

  void setComment(String comment) => _comment = comment;

  void setTip(int amount, {bool custom = false}) =>
      state = state.copyWith(tip: amount, customTip: custom);

  Future<void> send() async {
    if (!state.canSend) {
      return;
    }

    final tip = state.tip;
    final problem = tip > 0 ? TipCaptain.problemOf(tip, state.balance ?? 0) : null;
    if (problem != null) {
      state = state.copyWith(tipProblem: problem);
      return;
    }

    state = state.copyWith(sending: true);

    if (state.stars > 0 && !state.rated) {
      final rated = await ref.read(rateCaptainProvider).call(arg.id, state.stars, _comment);
      if (rated case Err(:final failure)) {
        state = state.copyWith(sending: false, failure: failure);
        return;
      }
      state = state.copyWith(rated: true);
    }

    if (tip > 0) {
      // One tip per trip: the same key on a retry is the same tip.
      final tipped = await ref.read(tipCaptainProvider).call(arg.id, tip, 'tip-${arg.id}');
      if (tipped case Err(:final failure)) {
        state = state.copyWith(sending: false, failure: failure);
        return;
      }
    }

    state = state.copyWith(sending: false, tipped: tip, done: true);
  }
}
