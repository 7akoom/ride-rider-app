import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/entities/top_up.dart';
import '../wallet_providers.dart';
import 'wallet_state.dart';

final topUpControllerProvider = NotifierProvider.autoDispose<TopUpController, TopUpFlow>(TopUpController.new);

/// Where a top-up is: the amount being typed, the payment opening, the rider paying
/// on the provider's page, and how it ended.
enum TopUpPhase { entering, opening, waiting, slow, succeeded, failed }

final class TopUpFlow {
  const TopUpFlow({this.amount = 0, this.phase = TopUpPhase.entering, this.page, this.failure});

  /// Whole currency units; 0 before a digit.
  final int amount;
  final TopUpPhase phase;

  /// The provider's page, once the payment is open.
  final Uri? page;

  /// Why the payment could not be opened.
  final Failure? failure;

  /// The payment is open and its end not known yet.
  bool get following => phase == TopUpPhase.waiting || phase == TopUpPhase.slow;

  TopUpFlow copyWith({TopUpPhase? phase, Uri? page}) =>
      TopUpFlow(amount: amount, phase: phase ?? this.phase, page: page ?? this.page);
}

/// 31–32: types the amount, opens the ZainCash payment, and follows it: every few
/// seconds, and at once when the rider comes back from the payment page. The server
/// asks ZainCash each time, so the answer is ZainCash's.
class TopUpController extends AutoDisposeNotifier<TopUpFlow> {
  static const Duration checkEvery = Duration(seconds: 3);

  /// Checks before the screen says the confirmation is late (3 minutes).
  static const int slowAfterChecks = 60;

  /// Checks before the screen stops asking (15 minutes); the server goes on.
  static const int stopAfterChecks = 300;

  static const int maxDigits = 7;

  Timer? _timer;
  String? _id;
  int _checks = 0;
  bool _checking = false;
  bool _disposed = false;

  @override
  TopUpFlow build() {
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
    });

    return const TopUpFlow();
  }

  /// A key of the pad: a digit, or "000".
  void digit(String digits) {
    if (state.phase != TopUpPhase.entering) {
      return;
    }

    final text = state.amount == 0 ? digits : '${state.amount}$digits';

    if (text.length <= maxDigits) {
      state = TopUpFlow(amount: int.parse(text));
    }
  }

  void backspace() {
    if (state.phase != TopUpPhase.entering) {
      return;
    }

    final text = '${state.amount}';
    state = TopUpFlow(amount: text.length <= 1 ? 0 : int.parse(text.substring(0, text.length - 1)));
  }

  /// Opens the payment; its page, or null when it could not be opened.
  Future<Uri?> pay(TopUpOptions options, String language) async {
    if (state.phase != TopUpPhase.entering) {
      return null;
    }

    state = TopUpFlow(amount: state.amount, phase: TopUpPhase.opening);
    final result = await ref.read(startTopUpProvider).call(amount: state.amount, options: options, language: language);

    if (_disposed) {
      return null;
    }

    switch (result) {
      case Ok(:final value):
        _id = value.id;
        _checks = 0;
        state = state.copyWith(phase: TopUpPhase.waiting, page: value.page);
        _timer?.cancel();
        _timer = Timer.periodic(checkEvery, (_) {
          _checks++;
          unawaited(check());
        });

        return value.page;

      case Err(:final failure):
        state = TopUpFlow(amount: state.amount, failure: failure);

        return null;
    }
  }

  /// Asks how the payment stands now (also when the rider comes back to the app).
  Future<void> check() async {
    final id = _id;

    if (id == null || _checking || !state.following) {
      return;
    }

    _checking = true;
    final result = await ref.read(checkTopUpProvider).call(id);
    _checking = false;

    if (_disposed || !state.following) {
      return;
    }

    switch (result) {
      case Ok(value: TopUpStatus.succeeded):
        _timer?.cancel();
        state = state.copyWith(phase: TopUpPhase.succeeded);
        // The balance on the wallet and home screens.
        ref.invalidate(walletProvider);

      case Ok(value: TopUpStatus.failed):
        _timer?.cancel();
        state = state.copyWith(phase: TopUpPhase.failed);

      case _:
        // Still pending, or the server not reachable just now: ask again.
        if (_checks >= stopAfterChecks) {
          _timer?.cancel();
        }

        if (_checks >= slowAfterChecks && state.phase == TopUpPhase.waiting) {
          state = state.copyWith(phase: TopUpPhase.slow);
        }
    }
  }

  /// After a failed payment: the same amount, ready to pay again.
  void tryAgain() {
    _timer?.cancel();
    _id = null;
    state = TopUpFlow(amount: state.amount);
  }
}
