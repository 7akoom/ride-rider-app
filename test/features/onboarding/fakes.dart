import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/location/location_providers.dart';
import 'package:rider_app/core/phone/phone_number.dart';
import 'package:rider_app/core/rider/rider_providers.dart';
import 'package:rider_app/features/onboarding/domain/entities/otp_challenge.dart';
import 'package:rider_app/features/onboarding/domain/repositories/onboarding_preferences.dart';
import 'package:rider_app/features/onboarding/domain/repositories/sign_in_repository.dart';
import 'package:rider_app/features/onboarding/domain/use_cases/account_step.dart';
import 'package:rider_app/features/onboarding/domain/values/otp_code.dart';
import 'package:rider_app/features/onboarding/onboarding_providers.dart';

import '../../helpers/fake_location.dart';
import '../../helpers/fake_rider.dart';

export '../../helpers/fake_location.dart';
export '../../helpers/fake_rider.dart';

class FakePreferences implements OnboardingPreferences {
  FakePreferences({this.chosen = true, this.locationShown = true});

  bool chosen;
  bool locationShown;

  @override
  Future<bool> languageChosen() async => chosen;

  @override
  Future<void> markLanguageChosen() async => chosen = true;

  @override
  Future<bool> locationAsked() async => locationShown;

  @override
  Future<void> markLocationAsked() async => locationShown = true;
}

/// The account step with fakes: location shown already unless [preferences] says not.
AccountStep accountStepWith({FakePreferences? preferences, FakeLocation? location}) =>
    AccountStep(
      preferences: preferences ?? FakePreferences(),
      location: location ?? FakeLocation(),
    );

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

/// The onboarding repositories replaced by fakes, for screen tests.
List<Override> onboardingFakes({
  FakePreferences? preferences,
  FakeSignIn? signIn,
  FakeAccounts? accounts,
  FakeLocation? location,
}) =>
    [
      locationAccessProvider.overrideWithValue(location ?? FakeLocation()),
      onboardingPreferencesProvider.overrideWithValue(preferences ?? FakePreferences()),
      signInRepositoryProvider.overrideWithValue(signIn ?? FakeSignIn()),
      riderAccountRepositoryProvider.overrideWithValue(
        accounts ?? FakeAccounts(const Ok(someone)),
      ),
    ];
