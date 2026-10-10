import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../gallery_section.dart';

class StatesSection extends StatelessWidget {
  const StatesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GallerySection(
      title: l10n.gallerySectionStates,
      children: [
        StatusBanner(tone: Tone.warning, message: l10n.gallerySampleWarning),
        StatusBanner(
          tone: Tone.danger,
          message: l10n.errorNoConnection,
          actionLabel: l10n.actionRetry,
          onAction: () {},
        ),
        StatusBanner(tone: Tone.success, message: l10n.gallerySampleBody),
        StatusBanner(tone: Tone.info, message: l10n.gallerySampleBody),
        const SkeletonCard(),
        const SkeletonList(rows: 2),
        EmptyState(icon: Icons.inbox_outlined, message: l10n.emptyNothingYet),
        FailureView(failure: const NetworkFailure(), onRetry: () {}),
        AppButton(
          label: l10n.gallerySampleTitle,
          variant: AppButtonVariant.secondary,
          onPressed: () => showAppToast(context, l10n.gallerySampleBody),
        ),
        AppButton(
          label: l10n.gallerySectionInputs,
          variant: AppButtonVariant.secondary,
          onPressed: () => showAppSheet<void>(
            context: context,
            builder: (sheetContext) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetTitle(
                  title: l10n.gallerySampleTitle,
                  onClose: () => Navigator.of(sheetContext).pop(),
                ),
                Text(l10n.gallerySampleBody),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
