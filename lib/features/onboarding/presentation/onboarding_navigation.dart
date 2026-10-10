import 'package:flutter/material.dart';

import '../../auth/profile_setup_screen.dart';
import '../../rider/request_ride_screen.dart';
import '../domain/entities/next_step.dart';
import 'language/language_screen.dart';
import 'phone/phone_screen.dart';
import 'splash/splash_screen.dart';

/// Opens the screen for [step] as the only screen: the rider cannot go back into
/// sign-in once past it, nor back to the start screen.
///
/// The name screen (stage 2c) and the home screen (stage 3) are still the old ones;
/// their imports go when they are replaced.
void openStep(BuildContext context, NextStep step) {
  final Widget screen = switch (step) {
    NextStep.chooseLanguage => const LanguageScreen(),
    NextStep.enterPhone => const PhoneScreen(),
    NextStep.enterName => const ProfileSetupScreen(),
    NextStep.home => const RequestRideScreen(),
    NextStep.checkAgain => const SplashScreen(),
  };

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => screen),
    (_) => false,
  );
}
