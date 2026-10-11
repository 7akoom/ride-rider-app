import 'package:flutter/material.dart';

import '../../../../core/format/money_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';

/// 26: thanks for the rating and the tip; back home from here.
class ThanksView extends StatelessWidget {
  const ThanksView({super.key, required this.tipped});

  /// The tip that went, 0 for none.
  final int tipped;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.typo;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.volunteer_activism_outlined, size: Sizes.heroIcon, color: context.palette.brandStrong),
            const SizedBox(height: Space.x3),
            Text(l10n.thanksTitle, style: t.h1, textAlign: TextAlign.center),
            const SizedBox(height: Space.x2),
            Text(
              tipped > 0 ? l10n.thanksTip(formatMoney(l10n, tipped)) : l10n.thanksRating,
              style: t.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.x6),
            AppButton(
              label: l10n.thanksHome,
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}
