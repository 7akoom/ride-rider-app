import 'package:flutter/material.dart';

import '../core/config/app_env.dart';
import '../core/l10n/app_locales.dart';
import '../core/l10n/l10n.dart';
import '../core/l10n/localization_setup.dart';

/// Shown instead of the app when the build's configuration is unsafe (for example a
/// release build pointing at a plain-HTTP API). The rider sees one translated line;
/// the details are for whoever made the build.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: AppEnv.appName,
      debugShowCheckedModeBanner: false,
      supportedLocales: AppLocales.all,
      localizationsDelegates: appLocalizationsDelegates,
      home: _ConfigErrorScreen(),
    );
  }
}

class _ConfigErrorScreen extends StatelessWidget {
  const _ConfigErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.l10n.errorAppMisconfigured,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
