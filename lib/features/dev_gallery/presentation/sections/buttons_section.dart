import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/tokens/metrics.dart';
import '../gallery_section.dart';

class ButtonsSection extends StatelessWidget {
  const ButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GallerySection(
      title: l10n.gallerySectionButtons,
      children: [
        const Center(child: BrandMark()),
        AppButton(label: l10n.actionContinue, onPressed: () {}),
        AppButton(label: l10n.actionContinue, onPressed: () {}, loading: true),
        AppButton(label: l10n.actionContinue, onPressed: null),
        AppButton(
          label: l10n.actionSave,
          onPressed: () {},
          variant: AppButtonVariant.secondary,
        ),
        AppButton(
          label: l10n.actionConfirm,
          onPressed: () {},
          variant: AppButtonVariant.ink,
          icon: Icons.check,
        ),
        AppButton(
          label: l10n.actionCancel,
          onPressed: () {},
          variant: AppButtonVariant.danger,
        ),
        AppButton(
          label: l10n.actionRetry,
          onPressed: () {},
          variant: AppButtonVariant.text,
          expand: false,
        ),
        Wrap(
          spacing: Space.x2,
          children: [
            AppIconButton(
              icon: Icons.arrow_back,
              semanticLabel: l10n.actionBack,
              onPressed: () {},
            ),
            AppIconButton(
              icon: Icons.chat_bubble_outline,
              semanticLabel: l10n.actionChat,
              onPressed: () {},
              showBadge: true,
            ),
            AppIconButton(
              icon: Icons.call_outlined,
              semanticLabel: l10n.actionCall,
              onPressed: () {},
              filled: true,
            ),
            AppIconButton(
              icon: Icons.my_location,
              semanticLabel: l10n.routePickup,
              onPressed: () {},
              floating: true,
            ),
          ],
        ),
      ],
    );
  }
}
