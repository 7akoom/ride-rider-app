import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// What appears instead of a widget that failed to build, in place of Flutter's red
/// error box. Shows a translated line when the app's texts are reachable, and only an
/// icon otherwise; never the technical error.
class FriendlyErrorWidget extends StatelessWidget {
  const FriendlyErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final hasDirection = Directionality.maybeOf(context) != null;
    const icon = Icon(Icons.error_outline, size: 24);

    if (l10n == null || !hasDirection) {
      return const Center(child: icon);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(l10n.errorPartFailed, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
