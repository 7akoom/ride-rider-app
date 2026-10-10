import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_locales.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens/metrics.dart';
import '../../../state/locale_provider.dart';
import '../../../state/theme_provider.dart';
import 'sections/buttons_section.dart';
import 'sections/inputs_section.dart';
import 'sections/lists_section.dart';
import 'sections/states_section.dart';
import 'sections/trip_section.dart';

/// Developer-only: every shared component, to review in each language and mode on a
/// real phone. Opened by debug builds run with --dart-define=SHOW_GALLERY=true.
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return AppScaffold(
      topBar: AppTopBar(
        title: l10n.galleryTitle,
        showBack: false,
        actions: [
          AppIconButton(
            icon: Icons.translate,
            semanticLabel: l10n.galleryToggleLanguage,
            onPressed: () => _nextLanguage(ref),
          ),
          AppIconButton(
            icon: Icons.contrast,
            semanticLabel: l10n.galleryToggleTheme,
            onPressed: () => _toggleTheme(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: Space.x8),
        children: const [
          ButtonsSection(),
          InputsSection(),
          ListsSection(),
          TripSection(),
          StatesSection(),
        ],
      ),
    );
  }

  void _nextLanguage(WidgetRef ref) {
    final current = ref.read(localeProvider);
    final index = AppLocales.all.indexWhere(
      (l) => l.languageCode == current.languageCode,
    );

    ref.read(localeProvider.notifier).state =
        AppLocales.all[(index + 1) % AppLocales.all.length];
  }

  void _toggleTheme(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.read(themeModeProvider.notifier).state = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}
