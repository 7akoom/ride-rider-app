import 'package:flutter/material.dart';

import '../../../core/format/money_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/voucher_credit.dart';

/// The voucher sheet once the voucher is in the wallet: how much, and the balance now;
/// or, for a voucher this rider had redeemed before, that nothing more was added.
class VoucherDoneView extends StatelessWidget {
  const VoucherDoneView({super.key, required this.credit, this.owed = 0});

  final VoucherCredit credit;

  /// What the rider owed before; it was paid from the voucher first.
  final int owed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.typo;
    final again = credit.alreadyRedeemed;
    final amount = formatMoney(l10n, credit.amount);

    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Space.x4),
          Center(
            child: Container(
              width: Sizes.hero,
              height: Sizes.hero,
              decoration: BoxDecoration(shape: BoxShape.circle, color: again ? p.infoSoft : p.successSoft),
              child: again
                  ? Icon(Icons.info_outline_rounded, size: Sizes.heroIcon, color: p.info)
                  : Icon(Icons.check_rounded, size: Sizes.heroIcon, color: p.success),
            ),
          ),
          const SizedBox(height: Space.x4),
          Text(
            again ? l10n.voucherAlready : l10n.voucherAdded(amount),
            style: t.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.x2),
          if (again) ...[
            Text(
              l10n.voucherAlreadyBody(amount),
              style: t.body.copyWith(color: p.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.x1),
          ],
          Text(
            l10n.voucherBalance(formatMoney(l10n, credit.balance)),
            style: t.body.copyWith(color: p.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (owed > 0 && !again) ...[
            const SizedBox(height: Space.x4),
            StatusBanner(tone: Tone.info, message: l10n.voucherDuesFirst),
          ],
          const SizedBox(height: Space.x6),
          AppButton(label: l10n.voucherDone, onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
