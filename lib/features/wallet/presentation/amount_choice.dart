import 'package:flutter/material.dart';

import '../../../core/format/money_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';

/// Ready amounts to tap, and "another amount" for any other: the wallet's way to pick
/// an amount (top-up, send), as on Careem's. An amount the rider may not use now is
/// shown but cannot be picked. An amount typed through "another amount" shows on
/// that chip, picked.
class AmountChoice extends StatelessWidget {
  const AmountChoice({
    super.key,
    required this.amounts,
    required this.selected,
    required this.allowed,
    required this.onSelected,
    required this.onOther,
  });

  final List<int> amounts;

  /// 0 when none is picked yet.
  final int selected;
  final bool Function(int amount) allowed;
  final ValueChanged<int> onSelected;
  final VoidCallback onOther;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final other = selected > 0 && !amounts.contains(selected);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Three to a row; the chips share the width.
        final width = (constraints.maxWidth - 2 * Space.x2) / 3;

        return Wrap(
          spacing: Space.x2,
          runSpacing: Space.x2,
          children: [
            for (final amount in amounts)
              SizedBox(
                width: width,
                child: _Chip(
                  label: formatAmount(amount),
                  selected: amount == selected,
                  onTap: allowed(amount) ? () => onSelected(amount) : null,
                ),
              ),
            SizedBox(
              width: width,
              child: _Chip(
                label: other ? formatAmount(selected) : l10n.amountOther,
                icon: other ? null : Icons.edit_outlined,
                selected: other,
                onTap: onOther,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final IconData? icon;

  /// Null: the amount cannot be picked now.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onTap != null;
    final color = enabled ? p.textPrimary : p.textTertiary;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: selected ? p.brandSoft : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(Radii.button)),
          side: BorderSide(color: selected ? p.brand : p.border, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(Radii.button)),
          onTap: onTap,
          child: SizedBox(
            height: Sizes.buttonHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: Sizes.iconSmall, color: color),
                  const SizedBox(width: Space.x1),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, style: context.typo.bodyStrong.copyWith(color: color)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Another amount": the number pad in a sheet. [problemOf] says what is wrong with an
/// amount (null when it can be used); [hint] shows while nothing is wrong. The amount
/// confirmed, or null.
Future<int?> showAmountSheet(
  BuildContext context, {
  required int initial,
  required String hint,
  required String? Function(int amount) problemOf,
}) =>
    showAppSheet<int>(
      context: context,
      builder: (_) => _AmountSheet(initial: initial, hint: hint, problemOf: problemOf),
    );

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({required this.initial, required this.hint, required this.problemOf});

  final int initial;
  final String hint;
  final String? Function(int amount) problemOf;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  static const int _maxDigits = 7;
  static const String _thousands = '000';

  late int _amount = widget.initial;

  void _digit(String digits) {
    final text = _amount == 0 ? digits : '$_amount$digits';
    final amount = int.parse(text);

    if (text.length <= _maxDigits && amount > 0) {
      setState(() => _amount = amount);
    }
  }

  void _backspace() {
    final text = '$_amount';
    setState(() => _amount = text.length <= 1 ? 0 : int.parse(text.substring(0, text.length - 1)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final problem = _amount == 0 ? null : widget.problemOf(_amount);
    final ready = _amount > 0 && problem == null;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(title: l10n.amountOtherTitle, onClose: () => Navigator.of(context).pop()),
          Semantics(
            liveRegion: true,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatMoney(l10n, _amount),
                  style: context.typo.display.copyWith(color: _amount == 0 ? p.textTertiary : p.textPrimary),
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.x2),
          Text(
            problem ?? widget.hint,
            textAlign: TextAlign.center,
            style: context.typo.caption.copyWith(color: problem != null ? p.danger : p.textSecondary),
          ),
          const SizedBox(height: Space.x4),
          NumericKeypad(
            onDigit: _digit,
            onBackspace: _backspace,
            extraKey: _thousands,
            onExtraKey: () => _digit(_thousands),
          ),
          const SizedBox(height: Space.x2),
          AppButton(
            label: l10n.amountOtherDone,
            onPressed: ready ? () => Navigator.of(context).pop(_amount) : null,
          ),
        ],
      ),
    );
  }
}
