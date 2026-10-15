import 'package:flutter/material.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_messages.dart';
import '../../../core/format/money_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/top_up.dart';
import 'top_up_controller.dart';

/// 31: the amount, typed on the pad, within the limits; then "next".
class TopUpEntryView extends StatelessWidget {
  const TopUpEntryView({
    super.key,
    required this.flow,
    required this.options,
    required this.onDigit,
    required this.onBackspace,
    required this.onNext,
  });

  final TopUpFlow flow;
  final TopUpOptions options;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onNext;

  static const String _thousands = '000';

  String _hint(AppLocalizations l10n) {
    final failure = flow.failure;

    if (failure != null) {
      return failure is PreconditionFailure ? l10n.topUpUnavailable : failure.message(l10n);
    }

    return switch (flow.amount == 0 ? null : options.problemOf(flow.amount)) {
      TopUpAmountProblem.tooSmall => l10n.topUpTooSmall(formatMoney(l10n, options.min)),
      TopUpAmountProblem.tooBig => l10n.topUpTooBig(formatMoney(l10n, options.max)),
      null => l10n.topUpLimits(formatMoney(l10n, options.min), formatMoney(l10n, options.max)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.typo;
    final wrong = flow.failure != null || (flow.amount > 0 && options.problemOf(flow.amount) != null);
    final ready = flow.amount > 0 && options.problemOf(flow.amount) == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusBanner(tone: Tone.warning, message: l10n.topUpNote),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  liveRegion: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatMoney(l10n, flow.amount),
                      style: t.display.copyWith(color: flow.amount == 0 ? p.textTertiary : p.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: Space.x2),
                Text(
                  _hint(l10n),
                  textAlign: TextAlign.center,
                  style: t.caption.copyWith(color: wrong ? p.danger : p.textSecondary),
                ),
              ],
            ),
          ),
        ),
        AppButton(
          label: l10n.topUpNext,
          loading: flow.phase == TopUpPhase.opening,
          onPressed: ready ? onNext : null,
        ),
        const SizedBox(height: Space.x4),
        NumericKeypad(
          onDigit: onDigit,
          onBackspace: onBackspace,
          extraKey: _thousands,
          onExtraKey: () => onDigit(_thousands),
        ),
      ],
    );
  }
}
