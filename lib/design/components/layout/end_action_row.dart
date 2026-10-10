import 'package:flutter/material.dart';

import '../../tokens/metrics.dart';
import '../buttons/app_button.dart';

/// Content that takes the row, with an optional text action at the end ("Try again",
/// "All"). The action never takes more than [maxActionShare] of the width: a long
/// translation is shortened with an ellipsis instead of pushing the row off screen.
class EndActionRow extends StatelessWidget {
  const EndActionRow({
    super.key,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  static const double maxActionShare = 0.5;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;

    if (label == null) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(child: child),
          const SizedBox(width: Space.x2),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth * maxActionShare,
            ),
            child: AppButton(
              label: label,
              onPressed: onAction,
              variant: AppButtonVariant.text,
              expand: false,
            ),
          ),
        ],
      ),
    );
  }
}
