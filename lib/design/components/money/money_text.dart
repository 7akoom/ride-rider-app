import 'package:flutter/material.dart';

import '../../../core/format/money_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../design_context.dart';
import '../../tokens/palette.dart';

/// How an amount is coloured.
enum MoneyTone {
  /// The normal text colour.
  neutral,

  /// Money in: green with a "+" (wallet credits, refunds).
  credit,

  /// Struck through and muted (the price before a discount).
  struck,
}

/// An amount with the currency in the rider's language ("3,000 IQD" in English),
/// Western digits, aligned columns.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.style,
    this.tone = MoneyTone.neutral,
  });

  /// Whole currency units (the backend's amounts for this country).
  final int amount;
  final TextStyle? style;
  final MoneyTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = style ?? context.typo.price;

    return Text(
      formatMoney(context.l10n, amount, signed: tone == MoneyTone.credit),
      style: _styleFor(base, p),
      maxLines: 1,
      softWrap: false,
    );
  }

  TextStyle _styleFor(TextStyle base, Palette p) => switch (tone) {
        MoneyTone.neutral => base,
        MoneyTone.credit => base.copyWith(color: p.success),
        MoneyTone.struck => base.copyWith(
            color: p.textTertiary,
            decoration: TextDecoration.lineThrough,
          ),
      };
}
