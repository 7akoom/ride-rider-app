import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_env.dart';
import '../core/l10n/app_locales.dart';
import '../core/l10n/localization_setup.dart';
import '../core/navigation.dart';
import '../design/responsive/text_scale_clamp.dart';
import '../features/dev_gallery/presentation/gallery_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../state/locale_provider.dart';
import '../state/theme_provider.dart';
import 'app_themes.dart';

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
      theme: AppThemes.light(locale),
      darkTheme: AppThemes.dark(locale),
      themeMode: themeMode,
      builder: (context, child) =>
          TextScaleClamp(child: child ?? const SizedBox.shrink()),
      home: AppEnv.showGallery ? const GalleryScreen() : const SplashScreen(),
    );
  }
}
