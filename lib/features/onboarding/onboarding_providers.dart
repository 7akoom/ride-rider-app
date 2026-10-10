import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import 'data/onboarding_preferences_impl.dart';
import 'data/rider_account_api.dart';
import 'data/rider_account_repository_impl.dart';
import 'data/sign_in_api.dart';
import 'data/sign_in_repository_impl.dart';
import 'domain/repositories/onboarding_preferences.dart';
import 'domain/repositories/rider_account_repository.dart';
import 'domain/repositories/sign_in_repository.dart';
import 'domain/use_cases/confirm_code.dart';
import 'domain/use_cases/decide_start.dart';
import 'domain/use_cases/finish_language_step.dart';
import 'domain/use_cases/save_name.dart';
import 'domain/use_cases/send_code.dart';

// The feature's wiring: the one file that knows both the data classes and the domain
// interfaces. Screens and controllers read the use cases; tests override the
// repositories.

final signInRepositoryProvider = Provider<SignInRepository>(
  (ref) => SignInRepositoryImpl(SignInApi(ref.watch(apiClientProvider))),
);

final riderAccountRepositoryProvider = Provider<RiderAccountRepository>(
  (ref) => RiderAccountRepositoryImpl(RiderAccountApi(ref.watch(apiClientProvider))),
);

final onboardingPreferencesProvider = Provider<OnboardingPreferences>(
  (ref) => const OnboardingPreferencesImpl(),
);

final decideStartProvider = Provider<DecideStart>(
  (ref) => DecideStart(
    preferences: ref.watch(onboardingPreferencesProvider),
    signIn: ref.watch(signInRepositoryProvider),
    accounts: ref.watch(riderAccountRepositoryProvider),
  ),
);

final sendCodeProvider = Provider<SendCode>(
  (ref) => SendCode(ref.watch(signInRepositoryProvider)),
);

final confirmCodeProvider = Provider<ConfirmCode>(
  (ref) => ConfirmCode(
    signIn: ref.watch(signInRepositoryProvider),
    accounts: ref.watch(riderAccountRepositoryProvider),
  ),
);

final saveNameProvider = Provider<SaveName>(
  (ref) => SaveName(ref.watch(riderAccountRepositoryProvider)),
);

final finishLanguageStepProvider = Provider<FinishLanguageStep>(
  (ref) => FinishLanguageStep(ref.watch(onboardingPreferencesProvider)),
);
