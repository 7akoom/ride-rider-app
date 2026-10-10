import 'package:flutter/material.dart';

import '../../design_context.dart';
import '../../tokens/metrics.dart';
import '../layout/end_action_row.dart';

/// A section title with an optional action at the end ("All", "Edit").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: Space.x2, bottom: Space.x2),
      child: EndActionRow(
        actionLabel: actionLabel,
        onAction: onAction,
        child: Semantics(
          header: true,
          child: Text(title, style: context.typo.h3),
        ),
      ),
    );
  }
}
