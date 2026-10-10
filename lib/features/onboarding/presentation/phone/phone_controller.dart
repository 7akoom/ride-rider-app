import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/phone/phone_number.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../onboarding_providers.dart';

final class PhoneState {
  const PhoneState({this.sending = false, this.failure});

  final bool sending;

  /// Why the last send failed; null once the rider edits the number.
  final Failure? failure;
}

final phoneControllerProvider =
    NotifierProvider.autoDispose<PhoneController, PhoneState>(PhoneController.new);

class PhoneController extends AutoDisposeNotifier<PhoneState> {
  @override
  PhoneState build() => const PhoneState();

  void clearFailure() {
    if (state.failure != null) {
      state = const PhoneState();
    }
  }

  /// The challenge when the code is on its way. Null when sending failed (the failure
  /// is in the state) or a send is already running.
  Future<OtpChallenge?> send(PhoneNumber phone) async {
    if (state.sending) {
      return null;
    }

    state = const PhoneState(sending: true);
    final result = await ref.read(sendCodeProvider).call(phone);
    state = PhoneState(failure: result.fold((_) => null, (failure) => failure));

    return result.fold((challenge) => challenge, (_) => null);
  }
}
