import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_messages.dart';
import '../../../core/format/money_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import '../domain/entities/top_up.dart';
import 'amount_choice.dart';
import 'top_up_controller.dart';

/// 31: the amount, a ready one or another typed in a sheet, within the limits; then
/// "next".
class TopUpEntryView extends StatelessWidget {
  const TopUpEntryView({
    super.key,
    required this.flow,
    required this.options,
    required this.onAmount,
    required this.onNext,
  });

  final TopUpFlow flow;
  final TopUpOptions options;
  final ValueChanged<int> onAmount;
  final VoidCallback onNext;

  /// The ready amounts; those outside the limits show but cannot be picked.
  static const List<int> amounts = [5000, 10000, 25000, 50000, 100000];

  String _limits(AppLocalizations l10n) =>
      l10n.topUpLimits(formatMoney(l10n, options.min), formatMoney(l10n, options.max));

  String? _problem(AppLocalizations l10n, int amount) => switch (options.problemOf(amount)) {
        TopUpAmountProblem.tooSmall => l10n.topUpTooSmall(formatMoney(l10n, options.min)),
        TopUpAmountProblem.tooBig => l10n.topUpTooBig(formatMoney(l10n, options.max)),
        null => null,
      };

  Future<void> _other(BuildContext context) async {
    final l10n = context.l10n;
    final amount = await showAmountSheet(
      context,
      initial: amounts.contains(flow.amount) ? 0 : flow.amount,
      hint: _limits(l10n),
      problemOf: (amount) => _problem(l10n, amount),
    );

    if (amount != null) {
      onAmount(amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.typo;
    final failure = flow.failure;
    final problem = flow.amount == 0 ? null : _problem(l10n, flow.amount);
    final hint = failure != null
        ? (failure is PreconditionFailure ? l10n.topUpUnavailable : failure.message(l10n))
        : problem ?? _limits(l10n);
    final ready = flow.amount > 0 && problem == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              StatusBanner(tone: Tone.warning, message: l10n.topUpNote),
              const SizedBox(height: Space.x6),
              Semantics(
                liveRegion: true,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatMoney(l10n, flow.amount),
                      style: t.display.copyWith(color: flow.amount == 0 ? p.textTertiary : p.textPrimary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.x2),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: t.caption.copyWith(color: failure != null || problem != null ? p.danger : p.textSecondary),
              ),
              const SizedBox(height: Space.x6),
              AmountChoice(
                amounts: amounts,
                selected: flow.amount,
                allowed: (amount) => options.problemOf(amount) == null,
                onSelected: onAmount,
                onOther: () => unawaited(_other(context)),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.x3),
        AppButton(
          label: l10n.topUpNext,
          loading: flow.phase == TopUpPhase.opening,
          onPressed: ready ? onNext : null,
        ),
        const SizedBox(height: Space.x4),
      ],
    );
  }
}
