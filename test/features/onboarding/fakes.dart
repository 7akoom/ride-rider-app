import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/phone/phone_number.dart';
import 'package:rider_app/features/onboarding/domain/entities/otp_challenge.dart';
import 'package:rider_app/features/onboarding/domain/entities/rider_account.dart';
import 'package:rider_app/features/onboarding/domain/repositories/onboarding_preferences.dart';
import 'package:rider_app/features/onboarding/domain/repositories/rider_account_repository.dart';
import 'package:rider_app/features/onboarding/domain/repositories/sign_in_repository.dart';
import 'package:rider_app/features/onboarding/domain/values/display_name.dart';
import 'package:rider_app/features/onboarding/domain/values/otp_code.dart';
import 'package:rider_app/features/onboarding/onboarding_providers.dart';

class FakePreferences implements OnboardingPreferences {
  FakePreferences({this.chosen = true});

  bool chosen;

  @override
  Future<bool> languageChosen() async => chosen;

  @override
  Future<void> markLanguageChosen() async => chosen = true;
}

class FakeSignIn implements SignInRepository {
  FakeSignIn({
    this.session = true,
    this.confirmResult = const Ok(null),
    this.sendFailure,
  });

  bool session;
  Result<void> confirmResult;

  /// When set, sending a code fails with it.
  Failure? sendFailure;
  bool forgotten = false;
  int codesSent = 0;

  @override
  Future<Result<OtpChallenge>> sendCode(PhoneNumber phone) async {
    final failure = sendFailure;
    if (failure != null) {
      return Err(failure);
    }

    codesSent++;

    return Ok(OtpChallenge(id: 'c$codesSent', phone: phone, expiresIn: const Duration(minutes: 5)));
  }

  @override
  Future<Result<void>> confirmCode(OtpChallenge challenge, OtpCode code) async =>
      confirmResult;

  @override
  Future<bool> hasSession() async => session;

  @override
  Future<void> forgetSession() async {
    forgotten = true;
    session = false;
  }
}

class FakeAccounts implements RiderAccountRepository {
  FakeAccounts(this.found);

  Result<RiderAccount?> found;

  @override
  Future<Result<RiderAccount?>> findMine() async => found;

  @override
  Future<Result<RiderAccount>> create(DisplayName name) async =>
      Ok(RiderAccount(id: 'r1', displayName: name.value));
}

const someone = RiderAccount(id: 'r1', displayName: 'Salem');

/// The onboarding repositories replaced by fakes, for screen tests.
List<Override> onboardingFakes({
  FakePreferences? preferences,
  FakeSignIn? signIn,
  FakeAccounts? accounts,
}) =>
    [
      onboardingPreferencesProvider.overrideWithValue(preferences ?? FakePreferences()),
      signInRepositoryProvider.overrideWithValue(signIn ?? FakeSignIn()),
      riderAccountRepositoryProvider.overrideWithValue(
        accounts ?? FakeAccounts(const Ok(someone)),
      ),
    ];
