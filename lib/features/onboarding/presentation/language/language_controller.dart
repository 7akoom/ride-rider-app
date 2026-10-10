import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/language_preference.dart';
import '../../../../state/locale_provider.dart';
import '../../domain/entities/next_step.dart';
import '../../onboarding_providers.dart';

final languageControllerProvider = Provider<LanguageController>(
  LanguageController.new,
);

/// The language screen's actions. Picking a language switches the whole app at once,
/// direction included, so the rider sees the choice before confirming it.
class LanguageController {
  LanguageController(this._ref);

  final Ref _ref;

  void pick(Locale locale) {
    _ref.read(localeProvider.notifier).state = locale;
    unawaited(LanguagePreference.save(locale));
  }

  Future<NextStep> finish() => _ref.read(finishLanguageStepProvider).call();
}
