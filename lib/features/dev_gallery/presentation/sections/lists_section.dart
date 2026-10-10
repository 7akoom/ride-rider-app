import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../gallery_section.dart';

class ListsSection extends StatelessWidget {
  const ListsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GallerySection(
      title: l10n.gallerySectionLists,
      children: [
        SectionHeader(
          title: l10n.gallerySampleTitle,
          actionLabel: l10n.actionContinue,
          onAction: () {},
        ),
        AppListRow(
          icon: Icons.home_outlined,
          title: l10n.gallerySampleDestination,
          subtitle: l10n.gallerySamplePickup,
          onTap: () {},
        ),
        AppListRow(
          icon: Icons.account_balance_wallet_outlined,
          title: l10n.gallerySampleTitle,
          trailing: const MoneyText(2700, tone: MoneyTone.credit),
          onTap: () {},
        ),
        AppListRow(
          icon: Icons.delete_outline,
          title: l10n.actionDeleteDigit,
          destructive: true,
          onTap: () {},
        ),
        AppBottomNav(current: RiderTab.home, onSelected: (_) {}),
      ],
    );
  }
}
