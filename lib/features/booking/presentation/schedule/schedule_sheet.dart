import 'package:flutter/material.dart';

import '../../../../core/format/time_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/components/components.dart';
import '../../../../design/design_context.dart';
import '../../../../design/tokens/metrics.dart';
import '../../domain/use_cases/schedule_window.dart';
import 'time_wheel.dart';

/// 13: the day and time to book the ride for. Returns the chosen time; only times
/// the backend allows can be chosen.
Future<DateTime?> showScheduleSheet(BuildContext context) => showAppSheet<DateTime>(
      context: context,
      builder: (_) => const SingleChildScrollView(child: ScheduleSheet()),
    );

class ScheduleSheet extends StatefulWidget {
  const ScheduleSheet({super.key, this.window = const ScheduleWindow(), this.now = DateTime.now});

  final ScheduleWindow window;

  /// The clock; tests pass their own.
  final DateTime Function() now;

  @override
  State<ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<ScheduleSheet> {
  late final DateTime _now = widget.now();
  late final List<DateTime> _days = widget.window.days(_now);
  int _day = 0;
  late List<DateTime> _times = widget.window.timesOn(_days.first, _now);
  int _time = 0;

  void _pickDay(int index) => setState(() {
        _day = index;
        _times = widget.window.timesOn(_days[index], _now);
        _time = 0;
      });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.typo;
    final window = widget.window;
    final chosen = _times[_time];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(title: l10n.scheduleTitle, onClose: () => Navigator.of(context).pop()),
        Text(l10n.scheduleExplain, style: t.caption.copyWith(color: p.textSecondary)),
        const SizedBox(height: Space.x4),
        Text(l10n.scheduleDay, style: t.bodyStrong),
        const SizedBox(height: Space.x2),
        AppChoiceChips<int>(
          options: [
            for (var i = 0; i < _days.length; i++) (i, formatDay(l10n, _days[i], _now)),
          ],
          selected: _day,
          onSelected: _pickDay,
        ),
        const SizedBox(height: Space.x4),
        Text(l10n.scheduleTime, style: t.bodyStrong),
        const SizedBox(height: Space.x2),
        TimeWheel(
          // A new day starts its wheel at its first time.
          key: ValueKey(_day),
          times: _times,
          onChanged: (index) => setState(() => _time = index),
        ),
        const SizedBox(height: Space.x3),
        StatusBanner(
          tone: Tone.info,
          message: l10n.scheduleRules(
            window.minAhead.inMinutes,
            window.maxAhead.inDays,
            window.dispatchLead.inMinutes,
          ),
        ),
        const SizedBox(height: Space.x3),
        Row(
          children: [
            Icon(Icons.event_available, size: Sizes.iconSmall, color: p.success),
            const SizedBox(width: Space.x2),
            Text(l10n.scheduleChosen, style: t.caption.copyWith(color: p.textSecondary)),
            const SizedBox(width: Space.x2),
            Expanded(
              child: Text(
                l10n.dayAndTime(formatDay(l10n, chosen, _now), formatClock(l10n, chosen)),
                style: t.bodyStrong,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.x4),
        AppButton(
          label: l10n.scheduleConfirm,
          icon: Icons.check_circle_outline,
          onPressed: () => Navigator.of(context).pop(chosen),
        ),
      ],
    );
  }
}
