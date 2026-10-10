import 'package:flutter/material.dart';

import '../../tokens/metrics.dart';

/// A row of single-choice pills (filters, tabs inside a screen). Wraps to a new line
/// when they don't fit.
class AppChoiceChips<T> extends StatelessWidget {
  const AppChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  /// Each option's value and its (translated) label.
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Space.x2,
      runSpacing: Space.x2,
      children: [
        for (final (value, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: value == selected,
            showCheckmark: false,
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}
