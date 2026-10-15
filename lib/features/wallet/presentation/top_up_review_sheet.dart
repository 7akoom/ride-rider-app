import 'package:flutter/material.dart';

import '../../../core/format/money_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';

/// True when the rider chose to pay.
Future<bool?> showTopUpReviewSheet(BuildContext context, int amount) => showAppSheet<bool>(
      context: context,
      builder: (_) => SingleChildScrollView(child: TopUpReviewSheet(amount: amount)),
    );

/// 31 (review and pay): the amount and how it is paid, before ZainCash's page opens.
class TopUpReviewSheet extends StatelessWidget {
  const TopUpReviewSheet({super.key, required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.typo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(title: l10n.topUpReviewTitle, onClose: () => Navigator.of(context).pop(false)),
        Container(
          padding: const EdgeInsetsDirectional.all(Space.x4),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatMoney(l10n, amount), style: t.h2),
              const SizedBox(height: Space.x1),
              Text(l10n.topUpReviewWhat, style: t.caption.copyWith(color: p.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: Space.x3),
        AppListRow(
          icon: Icons.account_balance_wallet_outlined,
          title: l10n.topUpZainCash,
          subtitle: l10n.topUpZainCashNote,
          showChevron: false,
        ),
        const SizedBox(height: Space.x6),
        AppButton(
          label: l10n.topUpPay(formatMoney(l10n, amount)),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
