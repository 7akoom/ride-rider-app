import 'package:flutter/material.dart';

import '../../../core/format/money_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';
import '../../../design/tokens/metrics.dart';
import 'top_up_controller.dart';

/// 32: the payment being processed, and how it ended.
class TopUpProgressView extends StatelessWidget {
  const TopUpProgressView({
    super.key,
    required this.flow,
    required this.onReopen,
    required this.onTryAgain,
    required this.onDone,
  });

  final TopUpFlow flow;

  /// Opens ZainCash's page again (the rider closed it before paying).
  final VoidCallback onReopen;
  final VoidCallback onTryAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final amount = formatMoney(l10n, flow.amount);

    final (Widget mark, String title, String body) = switch (flow.phase) {
      TopUpPhase.succeeded => (
          _Mark(icon: Icons.check_rounded, color: p.success, background: p.successSoft),
          l10n.topUpDoneTitle(amount),
          l10n.topUpDoneBody,
        ),
      TopUpPhase.failed => (
          _Mark(icon: Icons.close_rounded, color: p.danger, background: p.dangerSoft),
          l10n.topUpFailedTitle,
          l10n.topUpFailedBody,
        ),
      TopUpPhase.slow => (
          _Mark(icon: Icons.schedule_rounded, color: p.info, background: p.infoSoft),
          l10n.topUpSlowTitle,
          l10n.topUpSlowBody(amount),
        ),
      _ => (
          SizedBox.square(
            dimension: Sizes.heroIcon,
            child: CircularProgressIndicator(strokeWidth: 4, color: p.brandStrong),
          ),
          l10n.topUpWaitingTitle,
          l10n.topUpWaitingBody(amount),
        ),
    };

    final List<Widget> actions = switch (flow.phase) {
      TopUpPhase.succeeded || TopUpPhase.slow => [
          AppButton(label: l10n.topUpDone, onPressed: onDone),
        ],
      TopUpPhase.failed => [
          AppButton(label: l10n.topUpTryAgain, onPressed: onTryAgain),
          const SizedBox(height: Space.x2),
          AppButton(label: l10n.actionClose, variant: AppButtonVariant.text, onPressed: onDone),
        ],
      _ => [
          if (flow.page != null)
            AppButton(label: l10n.topUpReopen, variant: AppButtonVariant.secondary, onPressed: onReopen),
        ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Semantics(
                liveRegion: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    mark,
                    const SizedBox(height: Space.x5),
                    Text(title, style: context.typo.h2, textAlign: TextAlign.center),
                    const SizedBox(height: Space.x2),
                    Text(body, style: context.typo.body.copyWith(color: p.textSecondary), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
        ...actions,
      ],
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.icon, required this.color, required this.background});

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Sizes.hero,
      height: Sizes.hero,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background),
      child: Icon(icon, size: Sizes.heroIcon, color: color),
    );
  }
}
