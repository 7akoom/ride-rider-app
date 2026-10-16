import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/entities/wallet_pin.dart';
import '../wallet_providers.dart';
import 'wallet_state.dart';

/// Why the rider is setting a PIN: the first one, a change (the current one is
/// typed first), or a new one after signing in again (a forgotten PIN).
enum PinMode { create, change, reset }

/// Where the flow is.
enum PinStep { current, checking, fresh, confirm, saving, done }

/// What went wrong, shown under the dots.
sealed class PinProblem {
  const PinProblem();
}

/// 1111, 1234 and the like.
final class WeakPin extends PinProblem {
  const WeakPin();
}

/// The second entry is not the first.
final class PinMismatch extends PinProblem {
  const PinMismatch();
}

/// The current PIN was wrong; [attemptsLeft] before it locks.
final class WrongCurrentPin extends PinProblem {
  const WrongCurrentPin(this.attemptsLeft);

  final int attemptsLeft;
}

/// Wrong PINs locked it until [until]: only a reset (signing in again) helps now.
final class PinLocked extends PinProblem {
  const PinLocked(this.until);

  final DateTime until;
}

/// A new PIN without the current one needs a fresh sign-in, and that ran out.
final class PinSignInAgain extends PinProblem {
  const PinSignInAgain();
}

/// Anything else (no connection, the server).
final class PinFailed extends PinProblem {
  const PinFailed(this.failure);

  final Failure failure;
}

final class PinFlow {
  const PinFlow({
    required this.mode,
    required this.step,
    this.typed = '',
    this.current,
    this.fresh,
    this.problem,
  });

  final PinMode mode;
  final PinStep step;

  /// The digits of the entry in progress.
  final String typed;

  /// The current PIN, once typed (a change).
  final String? current;

  /// The new PIN, once typed the first time.
  final String? fresh;
  final PinProblem? problem;

  /// The rider can do nothing more here but reset the PIN.
  bool get stuck => problem is PinLocked || problem is PinSignInAgain;

  /// The server is asked: the pad waits.
  bool get busy => step == PinStep.checking || step == PinStep.saving;

  PinFlow copyWith({
    PinStep? step,
    String? typed,
    String? current,
    String? fresh,
    PinProblem? problem,
    bool clearProblem = false,
    bool clearFresh = false,
  }) =>
      PinFlow(
        mode: mode,
        step: step ?? this.step,
        typed: typed ?? this.typed,
        current: current ?? this.current,
        fresh: clearFresh ? null : fresh ?? this.fresh,
        problem: clearProblem ? null : problem ?? this.problem,
      );
}

final walletPinControllerProvider =
    NotifierProvider.autoDispose.family<WalletPinController, PinFlow, PinMode>(WalletPinController.new);

/// 38: creates or changes the wallet PIN: the current one (a change), the new one,
/// the new one again, then the server.
class WalletPinController extends AutoDisposeFamilyNotifier<PinFlow, PinMode> {
  bool _disposed = false;

  @override
  PinFlow build(PinMode arg) {
    ref.onDispose(() => _disposed = true);

    return PinFlow(mode: arg, step: arg == PinMode.change ? PinStep.current : PinStep.fresh);
  }

  /// The flow opened on a PIN that is locked already: only a reset helps.
  void startLocked(DateTime until) {
    state = state.copyWith(problem: PinLocked(until));
  }

  void digit(String digit) {
    final step = state.step;

    if (state.stuck || state.busy || step == PinStep.done || state.typed.length >= WalletPin.length) {
      return;
    }

    // A new entry after a problem: the message goes once the rider types again.
    final typed = '${state.typed}$digit';
    state = state.copyWith(typed: typed, clearProblem: state.typed.isEmpty);

    if (typed.length == WalletPin.length) {
      _entered(typed);
    }
  }

  void backspace() {
    final typed = state.typed;

    if (typed.isEmpty || state.busy) {
      return;
    }

    state = state.copyWith(typed: typed.substring(0, typed.length - 1));
  }

  void _entered(String pin) {
    switch (state.step) {
      case PinStep.current:
        unawaited(_checkCurrent(pin));

      case PinStep.fresh:
        if (WalletPin.isWeak(pin)) {
          state = state.copyWith(typed: '', problem: const WeakPin());
        } else {
          state = state.copyWith(step: PinStep.confirm, typed: '', fresh: pin);
        }

      case PinStep.confirm:
        if (pin != state.fresh) {
          state = state.copyWith(step: PinStep.fresh, typed: '', clearFresh: true, problem: const PinMismatch());
        } else {
          unawaited(_save(pin));
        }

      case PinStep.checking || PinStep.saving || PinStep.done:
        break;
    }
  }

  /// The current PIN is checked as soon as it is typed: a wrong one is said at once
  /// (and counts toward the lock), before a new PIN is asked for.
  Future<void> _checkCurrent(String pin) async {
    state = state.copyWith(step: PinStep.checking);
    final result = await ref.read(verifyWalletPinProvider).call(pin);

    if (_disposed) {
      return;
    }

    if (result case Ok(value: PinCheck(result: PinCheckResult.wrong || PinCheckResult.locked))) {
      // The wallet's PIN row shows the tries left or the lock.
      ref.invalidate(pinStatusProvider);
    }

    state = switch (result) {
      Ok(value: PinCheck(result: PinCheckResult.ok || PinCheckResult.notSet)) =>
        state.copyWith(step: PinStep.fresh, typed: '', current: pin, clearProblem: true),
      Ok(value: PinCheck(result: PinCheckResult.wrong, :final attemptsLeft)) =>
        PinFlow(mode: state.mode, step: PinStep.current, problem: WrongCurrentPin(attemptsLeft)),
      Ok(value: PinCheck(:final lockedUntil)) => PinFlow(
          mode: state.mode,
          step: PinStep.current,
          problem: PinLocked(lockedUntil ?? DateTime.now().add(const Duration(minutes: 15))),
        ),
      Err(:final failure) => PinFlow(mode: state.mode, step: PinStep.current, problem: PinFailed(failure)),
    };
  }

  Future<void> _save(String pin) async {
    state = state.copyWith(step: PinStep.saving);
    final result = await ref.read(setWalletPinProvider).call(
          newPin: pin,
          currentPin: state.mode == PinMode.change ? state.current : null,
        );

    if (_disposed) {
      return;
    }

    switch (result) {
      case Ok():
        ref.invalidate(pinStatusProvider);
        // Paying with a fingerprint or the face keeps working with the new PIN.
        final biometric = ref.read(biometricPinProvider);

        if (await biometric.kept() != null) {
          await biometric.keep(pin);
        }

        if (_disposed) {
          return;
        }

        state = state.copyWith(step: PinStep.done, typed: '', clearProblem: true);

      case Err(failure: InvalidInputFailure()):
        state = state.copyWith(step: PinStep.fresh, typed: '', clearFresh: true, problem: const WeakPin());

      case Err(failure: ForbiddenFailure() || PreconditionFailure()):
        await _refused();

      case Err(:final failure):
        // Nothing was saved: the rider types the confirmation again to retry.
        state = state.copyWith(step: PinStep.confirm, typed: '', problem: PinFailed(failure));
    }
  }

  /// The server refused the change: the status says whether the current PIN was
  /// wrong, the PIN is locked, or a reset needs a fresh sign-in.
  Future<void> _refused() async {
    ref.invalidate(pinStatusProvider);
    final status = await ref.read(loadPinStatusProvider).call();
    final now = DateTime.now();

    if (_disposed) {
      return;
    }

    final PinProblem problem = switch (status) {
      Ok(:final value) when value.lockedAt(now) => PinLocked(value.lockedUntil!),
      Ok(:final value) when state.mode == PinMode.change => WrongCurrentPin(value.attemptsLeft),
      Ok() => const PinSignInAgain(),
      Err(:final failure) => PinFailed(failure),
    };

    state = switch (problem) {
      WrongCurrentPin() => PinFlow(mode: state.mode, step: PinStep.current, problem: problem),
      _ => state.copyWith(step: PinStep.confirm, typed: '', problem: problem),
    };
  }
}
