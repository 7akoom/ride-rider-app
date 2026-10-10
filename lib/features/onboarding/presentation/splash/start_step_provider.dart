import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/next_step.dart';
import '../../onboarding_providers.dart';

/// How long the start screen shows at least, so it does not flash by.
const Duration minimumStartTime = Duration(milliseconds: 800);

/// Where the app opens. Invalidated by "try again".
final startStepProvider = FutureProvider.autoDispose<Result<NextStep>>((ref) async {
  final decided = ref.read(decideStartProvider).call();

  await Future<void>.delayed(minimumStartTime);

  return decided;
});
