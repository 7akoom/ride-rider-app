import 'package:flutter/material.dart';

import '../../rider/request_ride_screen.dart';
import '../domain/entities/next_step.dart';
import 'language/language_screen.dart';
import 'location/location_screen.dart';
import 'name/name_screen.dart';
import 'phone/phone_screen.dart';
import 'splash/splash_screen.dart';

/// Opens the screen for [step] as the only screen: the rider cannot go back into
/// sign-in once past it, nor back to the start screen.
///
/// The home screen is still the old one until stage 3 replaces it.
void openStep(BuildContext context, NextStep step) {
  final Widget screen = switch (step) {
    NextStep.chooseLanguage => const LanguageScreen(),
    NextStep.enterPhone => const PhoneScreen(),
    NextStep.enterName => const NameScreen(),
    NextStep.askLocation => const LocationScreen(),
    NextStep.home => const RequestRideScreen(),
    NextStep.checkAgain => const SplashScreen(),
  };

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => screen),
    (_) => false,
  );
}
