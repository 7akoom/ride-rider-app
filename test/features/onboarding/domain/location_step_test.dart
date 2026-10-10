import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/location/location_access.dart';
import 'package:rider_app/features/onboarding/domain/entities/next_step.dart';
import 'package:rider_app/features/onboarding/domain/use_cases/finish_location_step.dart';
import 'package:rider_app/features/onboarding/domain/use_cases/save_name.dart';
import 'package:rider_app/features/onboarding/domain/values/display_name.dart';

import '../fakes.dart';

void main() {
  group('AccountStep', () {
    test('no profile: the name screen', () async {
      expect(await accountStepWith().after(null), NextStep.enterName);
    });

    test('location screen once, unless location is already allowed', () async {
      final notShown = FakePreferences(locationShown: false);

      expect(await accountStepWith(preferences: notShown).after(someone), NextStep.askLocation);

      final allowed = FakePreferences(locationShown: false);
      final step = await accountStepWith(
        preferences: allowed,
        location: FakeLocation(current: LocationAccessStatus.granted),
      ).after(someone);

      expect(step, NextStep.home);
      expect(allowed.locationShown, isTrue);
    });

    test('shown once already: the app', () async {
      expect(await accountStepWith().after(someone), NextStep.home);
    });
  });

  group('FinishLocationStep', () {
    test('allow asks the system once, then the app', () async {
      final preferences = FakePreferences(locationShown: false);
      final location = FakeLocation();

      final next = await FinishLocationStep(preferences: preferences, location: location)
          .call(allow: true);

      expect(next, NextStep.home);
      expect(location.prompts, 1);
      expect(preferences.locationShown, isTrue);
    });

    test('refused for good: the settings page opens instead', () async {
      final location = FakeLocation(answer: LocationAccessStatus.deniedForever);

      await FinishLocationStep(preferences: FakePreferences(), location: location)
          .call(allow: true);

      expect(location.settingsOpened, 1);
    });

    test('"not now" never asks the system', () async {
      final location = FakeLocation();

      await FinishLocationStep(preferences: FakePreferences(), location: location)
          .call(allow: false);

      expect(location.prompts, 0);
    });
  });

  group('SaveName', () {
    final name = DisplayName.tryParse('Salem Suleiman')!;

    test('a new profile leads to the location screen', () async {
      final next = await SaveName(
        accounts: FakeAccounts(const Ok(null)),
        accountStep: accountStepWith(preferences: FakePreferences(locationShown: false)),
      ).call(name);

      expect(next.fold((step) => step, (_) => null), NextStep.askLocation);
    });

    test('a failure is passed on', () async {
      final next = await SaveName(
        accounts: FakeAccounts(const Ok(null), createFailure: const NetworkFailure()),
        accountStep: accountStepWith(),
      ).call(name);

      expect(next.fold((_) => null, (failure) => failure), isA<NetworkFailure>());
    });
  });
}

