import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/phone/phone_number.dart';
import '../../onboarding/domain/entities/otp_challenge.dart';
import '../../onboarding/domain/values/otp_code.dart';
import '../../onboarding/onboarding_providers.dart';

final class PinResetState {
  const PinResetState({
    this.challenge,
    this.resendAt,
    this.sending = false,
    this.verifying = false,
    this.attempt = 0,
    this.failure,
    this.failedOnSend = false,
  });

  /// The code on its way; null until it is sent.
  final OtpChallenge? challenge;

  /// When another code may be asked for.
  final DateTime? resendAt;
  final bool sending;
  final bool verifying;

  /// Goes up after every refused code and every new code, to empty the boxes.
  final int attempt;
  final Failure? failure;

  /// Whether [failure] came from sending a code rather than from checking one.
  final bool failedOnSend;
}

final pinResetControllerProvider =
    NotifierProvider.autoDispose.family<PinResetController, PinResetState, PhoneNumber>(PinResetController.new);

/// A forgotten wallet PIN: a code to the rider's phone signs them in again (the same
/// account, a new session), and a new PIN may be set without the old one for the next
/// minutes. The code is sent as the screen opens.
class PinResetController extends AutoDisposeFamilyNotifier<PinResetState, PhoneNumber> {
  bool _disposed = false;

  @override
  PinResetState build(PhoneNumber arg) {
    ref.onDispose(() => _disposed = true);
    // After build: the state may not change while it is being made.
    unawaited(Future.microtask(send));

    return const PinResetState(sending: true);
  }

  /// Sends a code (the first, or another once [PinResetState.resendAt] has passed).
  Future<void> send() async {
    final before = state;

    if (_disposed || before.verifying) {
      return;
    }

    // Another code only once the last one may be replaced.
    final resendAt = before.resendAt;
    if (before.challenge != null && (before.sending || (resendAt != null && DateTime.now().isBefore(resendAt)))) {
      return;
    }

    state = PinResetState(
      challenge: before.challenge,
      resendAt: before.resendAt,
      sending: true,
      attempt: before.attempt,
    );
    final result = await ref.read(sendCodeProvider).call(arg);

    if (_disposed) {
      return;
    }

    state = switch (result) {
      Ok(value: final challenge) => PinResetState(
          challenge: challenge,
          resendAt: DateTime.now().add(OtpChallenge.resendAfter),
          attempt: before.attempt + 1,
        ),
      Err(:final failure) => PinResetState(
          challenge: before.challenge,
          resendAt: before.resendAt,
          attempt: before.attempt,
          failure: failure,
          failedOnSend: true,
        ),
    };
  }

  /// True once the code signed the rider in again.
  Future<bool> confirm(String typed) async {
    final code = OtpCode.tryParse(typed);
    final before = state;
    final challenge = before.challenge;

    if (code == null || challenge == null || before.verifying) {
      return false;
    }

    state = PinResetState(
      challenge: challenge,
      resendAt: before.resendAt,
      verifying: true,
      attempt: before.attempt,
    );
    final result = await ref.read(confirmCodeAgainProvider).call(challenge, code);

    if (_disposed) {
      return result is Ok;
    }

    if (result case Err(:final failure)) {
      state = PinResetState(
        challenge: challenge,
        resendAt: before.resendAt,
        attempt: before.attempt + 1,
        failure: failure,
      );

      return false;
    }

    return true;
  }

  void clearFailure() {
    final before = state;

    if (before.failure != null && !before.failedOnSend) {
      state = PinResetState(challenge: before.challenge, resendAt: before.resendAt, attempt: before.attempt);
    }
  }
}
