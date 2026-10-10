import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_env.dart';
import '../core/error/error_reporter.dart';
import '../core/error/global_error_handlers.dart';
import '../core/l10n/language_preference.dart';
import '../design/fonts/font_licenses.dart';
import '../state/app_prefs.dart';
import '../state/locale_provider.dart';
import '../state/push_notifications.dart';
import '../state/theme_provider.dart';
import 'app.dart';
import 'config_error_app.dart';

/// Starts the app: error handlers first, then the configuration check, then the saved
/// preferences, then the UI.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();
  registerFontLicenses();

  final problems = AppEnv.problems();
  if (problems.isNotEmpty) {
    ErrorReporter.report(StateError('configuration: $problems'), null);
    runApp(const ConfigErrorApp());

    return;
  }

  await _initPush();

  final savedLocale = await LanguagePreference.read();
  final savedThemeMode = await AppPrefs.readThemeMode();

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => savedLocale),
        themeModeProvider.overrideWith((ref) => savedThemeMode),
      ],
      child: const RiderApp(),
    ),
  );
}

// Push is optional: a failure here (no Firebase setup yet) must not stop the app.
Future<void> _initPush() async {
  try {
    await PushNotifications.initialize();
  } catch (error, stack) {
    ErrorReporter.report(error, stack);
  }
}
