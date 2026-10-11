import 'package:flutter/material.dart';

import '../../../core/format/money_format.dart';
import '../../../core/format/time_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/wallet_movement.dart';

/// One wallet movement: what it was, when, and the signed amount (money in in green).
class MovementRow extends StatelessWidget {
  const MovementRow({super.key, required this.movement, this.showBalance = false});

  final WalletMovement movement;

  /// The balance after it, under the time (the statement shows it).
  final bool showBalance;

  static String titleOf(AppLocalizations l10n, MovementKind kind) => switch (kind) {
        MovementKind.topUp => l10n.movementTopUp,
        MovementKind.tripPayment => l10n.movementTrip,
        MovementKind.change => l10n.movementChange,
        MovementKind.transferOut => l10n.movementSent,
        MovementKind.transferIn => l10n.movementReceived,
        MovementKind.duePayment => l10n.movementDue,
        MovementKind.voucher => l10n.movementVoucher,
        MovementKind.refund => l10n.movementRefund,
        MovementKind.tip => l10n.movementTip,
        MovementKind.adjustment => l10n.movementAdjustment,
        MovementKind.other => l10n.movementOther,
      };

  static IconData iconOf(MovementKind kind) => switch (kind) {
        MovementKind.topUp => Icons.account_balance_wallet_outlined,
        MovementKind.tripPayment => Icons.local_taxi_outlined,
        MovementKind.change => Icons.payments_outlined,
        MovementKind.transferOut => Icons.north_east,
        MovementKind.transferIn => Icons.south_west,
        MovementKind.duePayment => Icons.receipt_long_outlined,
        MovementKind.voucher => Icons.redeem_outlined,
        MovementKind.refund => Icons.replay,
        MovementKind.tip => Icons.volunteer_activism_outlined,
        MovementKind.adjustment => Icons.tune,
        MovementKind.other => Icons.swap_horiz,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.typo;
    final m = movement;
    final at = m.at.toLocal();
    final balance = m.balanceAfter;
    final detail = [
      formatClock(l10n, at),
      if (showBalance && balance != null) l10n.movementBalanceAfter(formatMoney(l10n, balance)),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x2),
      child: Row(
        children: [
          CircleAvatar(
            radius: Sizes.avatar / 2,
            backgroundColor: m.isIn ? p.successSoft : p.surface2,
            child: Icon(iconOf(m.kind), color: m.isIn ? p.success : p.textPrimary, size: Sizes.iconSmall),
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titleOf(l10n, m.kind), style: t.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(detail, style: t.caption.copyWith(color: p.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: Space.x2),
          MoneyText(m.amount, style: t.bodyStrong, tone: m.isIn ? MoneyTone.credit : MoneyTone.neutral),
        ],
      ),
    );
  }
}

/// Movements under a header for each day, newest first.
List<Widget> movementsByDay(BuildContext context, List<WalletMovement> movements, {bool showBalance = false}) {
  final l10n = context.l10n;
  final widgets = <Widget>[];
  DateTime? day;

  for (final movement in movements) {
    final at = movement.at.toLocal();
    final today = DateTime(at.year, at.month, at.day);

    if (today != day) {
      day = today;
      widgets.add(Padding(
        padding: const EdgeInsetsDirectional.only(top: Space.x4, bottom: Space.x1),
        child: Text(formatDay(l10n, today, DateTime.now()), style: context.typo.h3),
      ));
    }

    widgets.add(MovementRow(movement: movement, showBalance: showBalance));
  }

  return widgets;
}
