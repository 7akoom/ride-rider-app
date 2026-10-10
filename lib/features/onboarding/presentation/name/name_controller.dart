import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/rider/display_name.dart';
import '../../domain/entities/next_step.dart';
import '../../onboarding_providers.dart';

final class NameState {
  const NameState({this.saving = false, this.failure});

  final bool saving;
  final Failure? failure;
}

final nameControllerProvider =
    NotifierProvider.autoDispose<NameController, NameState>(NameController.new);

class NameController extends AutoDisposeNotifier<NameState> {
  @override
  NameState build() => const NameState();

  void clearFailure() {
    if (state.failure != null) {
      state = const NameState();
    }
  }

  /// Where to go once the profile is made; null when saving failed (the failure is in
  /// the state) or is already running.
  Future<NextStep?> save(DisplayName name) async {
    if (state.saving) {
      return null;
    }

    state = const NameState(saving: true);
    final result = await ref.read(saveNameProvider).call(name);

    return result.fold(
      (next) => next,
      (failure) {
        state = NameState(failure: failure);

        return null;
      },
    );
  }
}
