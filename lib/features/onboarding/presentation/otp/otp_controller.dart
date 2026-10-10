import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/next_step.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/values/otp_code.dart';
import '../../onboarding_providers.dart';

final class OtpState {
  const OtpState({
    required this.challenge,
    required this.resendAt,
    this.attempt = 0,
    this.verifying = false,
    this.resending = false,
    this.failure,
    this.failedOnResend = false,
  });

  /// The code the typed one is checked against; a resend replaces it.
  final OtpChallenge challenge;

  /// When "resend" becomes available.
  final DateTime resendAt;

  /// Goes up after every refused code and every new code, to empty the boxes.
  final int attempt;
  final bool verifying;
  final bool resending;
  final Failure? failure;

  /// Whether [failure] came from asking for a new code rather than from checking one.
  final bool failedOnResend;
}

final otpControllerProvider = NotifierProvider.autoDispose
    .family<OtpController, OtpState, OtpChallenge>(OtpController.new);

class OtpController extends AutoDisposeFamilyNotifier<OtpState, OtpChallenge> {
  @override
  OtpState build(OtpChallenge arg) => OtpState(challenge: arg, resendAt: _resendTime());

  static DateTime _resendTime() => DateTime.now().add(OtpChallenge.resendAfter);

  void clearFailure() {
    if (state.failure != null) {
      state = OtpState(
        challenge: state.challenge,
        resendAt: state.resendAt,
        attempt: state.attempt,
      );
    }
  }

  /// Where to go once the code is accepted; null when it was refused (the failure is
  /// in the state) or is not six digits yet.
  Future<NextStep?> confirm(String typed) async {
    final code = OtpCode.tryParse(typed);
    if (code == null || state.verifying) {
      return null;
    }

    final before = state;
    state = OtpState(
      challenge: before.challenge,
      resendAt: before.resendAt,
      attempt: before.attempt,
      verifying: true,
    );

    final result = await ref.read(confirmCodeProvider).call(before.challenge, code);

    return result.fold(
      (step) => step,
      (failure) {
        state = OtpState(
          challenge: before.challenge,
          resendAt: before.resendAt,
          attempt: before.attempt + 1,
          failure: failure,
        );

        return null;
      },
    );
  }

  /// Asks for a new code. True when it is on its way.
  Future<bool> resend() async {
    final before = state;
    if (before.resending || DateTime.now().isBefore(before.resendAt)) {
      return false;
    }

    state = OtpState(
      challenge: before.challenge,
      resendAt: before.resendAt,
      attempt: before.attempt,
      resending: true,
    );

    final result = await ref.read(sendCodeProvider).call(before.challenge.phone);

    state = result.fold(
      (challenge) => OtpState(
        challenge: challenge,
        resendAt: _resendTime(),
        attempt: before.attempt + 1,
      ),
      (failure) => OtpState(
        challenge: before.challenge,
        resendAt: before.resendAt,
        attempt: before.attempt,
        failure: failure,
        failedOnResend: true,
      ),
    );

    return result.fold((_) => true, (_) => false);
  }
}
