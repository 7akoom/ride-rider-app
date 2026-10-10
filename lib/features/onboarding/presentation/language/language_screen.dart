import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_locales.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../../../state/locale_provider.dart';
import '../onboarding_navigation.dart';
import 'language_controller.dart';

/// 02: Arabic, Kurdish or English, on the first run only.
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  bool _finishing = false;

  Future<void> _continue() async {
    setState(() => _finishing = true);
    final next = await ref.read(languageControllerProvider).finish();

    if (mounted) {
      openStep(context, next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = ref.watch(localeProvider);

    return AppScaffold(
      bottomAction: AppButton(
        label: l10n.actionContinue,
        loading: _finishing,
        onPressed: _continue,
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(top: Space.x8),
        children: [
          Text(l10n.languageTitle, style: context.typo.h1),
          const SizedBox(height: Space.x2),
          Text(
            l10n.languageSubtitle,
            style: context.typo.body.copyWith(color: context.palette.textSecondary),
          ),
          const SizedBox(height: Space.x6),
          for (final locale in AppLocales.all) ...[
            AppRadioTile(
              title: _nameOf(l10n, locale),
              selected: locale.languageCode == current.languageCode,
              onTap: () => ref.read(languageControllerProvider).pick(locale),
            ),
            const SizedBox(height: Space.x3),
          ],
        ],
      ),
    );
  }

  /// Each language is written in itself, whatever the app's language.
  static String _nameOf(AppLocalizations l10n, Locale locale) =>
      switch (locale.languageCode) {
        'ku' => l10n.languageNameKurdish,
        'en' => l10n.languageNameEnglish,
        _ => l10n.languageNameArabic,
      };
}

