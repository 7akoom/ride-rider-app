import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/wallet_pin.dart';

/// The wallet PIN being typed: four dots (always left to right), an error under them,
/// and the number pad. The digits themselves are never shown.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.typed,
    required this.onDigit,
    required this.onBackspace,
    this.error,
    this.enabled = true,
  });

  /// How many digits are typed so far.
  final int typed;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final String? error;

  /// False while the PIN is being checked: the pad ignores taps.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final error = this.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: context.l10n.pinEntered(typed),
          liveRegion: true,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < WalletPin.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.x2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < typed ? (error != null ? p.danger : p.textPrimary) : p.surface2,
                        border: Border.all(color: i < typed ? Colors.transparent : p.border),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: error == null
                ? null
                : Text(
                    error,
                    textAlign: TextAlign.center,
                    style: context.typo.caption.copyWith(color: p.danger),
                  ),
          ),
        ),
        IgnorePointer(
          ignoring: !enabled,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: enabled ? 1 : 0.5,
            child: NumericKeypad(onDigit: onDigit, onBackspace: onBackspace),
          ),
        ),
      ],
    );
  }
}
