import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_env.dart';
import '../core/l10n/app_locales.dart';
import '../core/l10n/localization_setup.dart';
import '../core/navigation.dart';
import '../features/onboarding/splash_screen.dart';
import '../state/locale_provider.dart';
import '../state/theme_provider.dart';
import '../theme/app_theme.dart';

class RiderApp extends ConsumerWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: AppEnv.appName,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocales.all,
      localizationsDelegates: appLocalizationsDelegates,
      // Replaced by the new design system in package 1b.
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
