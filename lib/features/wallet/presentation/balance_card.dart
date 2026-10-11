import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';

/// The wallet's balance on a dark card; the eye hides it from people around.
class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key, required this.balance});

  /// Null while it loads.
  final int? balance;

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.typo;
    final balance = widget.balance;

    return Container(
      padding: const EdgeInsetsDirectional.all(Space.x5),
      decoration: BoxDecoration(
        color: p.ink,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.card)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.walletBalance, style: t.caption.copyWith(color: p.onInk)),
                const SizedBox(height: Space.x2),
                if (balance == null)
                  const SkeletonView(child: SkeletonBox(width: 140, height: 36))
                else if (_hidden)
                  // Dots in place of the amount, its height kept.
                  SizedBox(
                    height: t.display.fontSize,
                    child: Row(children: [
                      for (var i = 0; i < 5; i++)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: Space.x1),
                          child: Icon(Icons.circle, size: Space.x3, color: p.onInk),
                        ),
                    ]),
                  )
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: MoneyText(balance, style: t.display.copyWith(color: p.onInk)),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: _hidden ? l10n.walletShow : l10n.walletHide,
            onPressed: () => setState(() => _hidden = !_hidden),
            icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: p.onInk),
          ),
        ],
      ),
    );
  }
}
