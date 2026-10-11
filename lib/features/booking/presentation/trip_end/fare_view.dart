import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/entities/trip_payment.dart';

/// What a finished trip cost and how it was paid, in one card (24 and 27).
class FareView extends StatelessWidget {
  const FareView({super.key, required this.payment});

  final TripPayment payment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final pay = payment;

    return Container(
      padding: const EdgeInsetsDirectional.all(Space.x4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.fareTitle, style: context.typo.h3),
          const SizedBox(height: Space.x3),
          _Line(label: l10n.fareTrip, amount: pay.fare),
          if (pay.tip > 0) _Line(label: l10n.fareTip, amount: pay.tip),
          Divider(height: Space.x6, color: p.border),
          _Line(label: l10n.fareTotal, amount: pay.total, strong: true),
          const SizedBox(height: Space.x2),
          if (pay.cash > 0) _Line(label: l10n.farePaidCash, amount: pay.cash, quiet: true),
          if (pay.fromWallet > 0) _Line(label: l10n.farePaidWallet, amount: pay.fromWallet, quiet: true),
          if (pay.change > 0) _Line(label: l10n.fareChange, amount: pay.change, quiet: true),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.amount, this.strong = false, this.quiet = false});

  final String label;
  final int amount;
  final bool strong;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final style = strong ? t.bodyStrong : (quiet ? t.caption.copyWith(color: context.palette.textSecondary) : t.body);

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: Space.x1),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          MoneyText(amount, style: style),
        ],
      ),
    );
  }
}
