import 'package:flutter/material.dart';

import '../../../../core/format/time_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';

/// A wheel of times to turn or tap; the one in the middle is chosen.
class TimeWheel extends StatefulWidget {
  const TimeWheel({super.key, required this.times, required this.onChanged});

  final List<DateTime> times;
  final ValueChanged<int> onChanged;

  static const double rowHeight = 44;
  static const int visibleRows = 3;

  @override
  State<TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<TimeWheel> {
  final _wheel = FixedExtentScrollController();
  int _selected = 0;

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  void _select(int index) {
    setState(() => _selected = index);
    widget.onChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    const radius = BorderRadius.all(Radius.circular(Radii.card));

    return Container(
      height: TimeWheel.rowHeight * TimeWheel.visibleRows,
      decoration: BoxDecoration(color: p.surface2, borderRadius: radius),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The band behind the chosen time.
          Container(
            height: TimeWheel.rowHeight,
            margin: const EdgeInsetsDirectional.symmetric(horizontal: Space.x3),
            decoration: BoxDecoration(color: p.brandSoft, borderRadius: radius),
          ),
          ListWheelScrollView.useDelegate(
            controller: _wheel,
            itemExtent: TimeWheel.rowHeight,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: _select,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.times.length,
              builder: (context, index) => GestureDetector(
                onTap: () => _wheel.animateToItem(
                  index,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                ),
                child: Center(
                  child: Text(
                    formatClock(l10n, widget.times[index]),
                    style: index == _selected
                        ? context.typo.h3
                        : context.typo.body.copyWith(color: p.textTertiary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
