import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../design_context.dart';
import '../../tokens/metrics.dart';

/// The on-screen number pad for amounts and PINs. Always 1-2-3 from the left: number
/// pads never mirror, in any language.
///
/// [extraKey] fills the bottom-start slot (for example "000" on amount screens).
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.extraKey,
    this.onExtraKey,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final String? extraKey;
  final VoidCallback? onExtraKey;

  static const String _zero = '0';

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in _rows)
            _KeyRow(children: [
              for (final digit in row) _Key(label: digit, onTap: () => onDigit(digit)),
            ]),
          _KeyRow(children: [
            if (extraKey == null)
              const SizedBox.shrink()
            else
              _Key(label: extraKey!, onTap: onExtraKey),
            _Key(label: _zero, onTap: () => onDigit(_zero)),
            _Key(
              icon: Icons.backspace_outlined,
              semanticLabel: context.l10n.actionDeleteDigit,
              onTap: onBackspace,
            ),
          ]),
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: Space.x2),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: Space.x2),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, this.semanticLabel, this.onTap});

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final content = icon != null
        ? Icon(icon, color: p.textPrimary, semanticLabel: semanticLabel)
        : Text(label ?? '', style: context.typo.h2);

    return Material(
      color: p.surface,
      borderRadius: const BorderRadius.all(Radius.circular(Radii.input)),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(Radii.input)),
        onTap: onTap,
        child: SizedBox(height: 56, child: Center(child: content)),
      ),
    );
  }
}
