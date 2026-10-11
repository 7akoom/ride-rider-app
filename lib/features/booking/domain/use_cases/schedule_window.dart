/// When a ride can be booked ahead: the backend's limits (TRIP_SCHEDULE_MIN_AHEAD,
/// TRIP_SCHEDULE_MAX_AHEAD, TRIP_SCHEDULE_DISPATCH_LEAD), in steps of [step].
final class ScheduleWindow {
  const ScheduleWindow({
    this.minAhead = const Duration(minutes: 30),
    this.maxAhead = const Duration(days: 7),
    this.dispatchLead = const Duration(minutes: 10),
    this.step = const Duration(minutes: 5),
    this.margin = const Duration(minutes: 2),
  });

  final Duration minAhead;
  final Duration maxAhead;

  /// How long before the time the platform starts looking for a captain.
  final Duration dispatchLead;
  final Duration step;

  /// Room for the time it takes to choose and send, so the earliest time offered is
  /// still allowed when it arrives.
  final Duration margin;

  /// The first time offered: [minAhead] (and the margin) from now, on a step.
  DateTime earliest(DateTime now) {
    final from = now.add(minAhead + margin);
    final stepMinutes = step.inMinutes;
    final roundedUp = (from.minute + (from.second > 0 || from.millisecond > 0 ? 1 : 0) + stepMinutes - 1) ~/
        stepMinutes *
        stepMinutes;

    return DateTime(from.year, from.month, from.day, from.hour).add(Duration(minutes: roundedUp));
  }

  DateTime latest(DateTime now) => now.add(maxAhead);

  /// Every time that can be chosen on [day] (local time), in order.
  List<DateTime> timesOn(DateTime day, DateTime now) {
    final first = earliest(now);
    final last = latest(now);
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);

    return [
      for (var t = start; t.isBefore(end); t = t.add(step))
        if (!t.isBefore(first) && !t.isAfter(last)) t,
    ];
  }

  /// The days that have at least one time, from today.
  List<DateTime> days(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    return [
      for (var i = 0; i <= maxAhead.inDays; i++)
        if (timesOn(DateTime(today.year, today.month, today.day + i), now).isNotEmpty)
          DateTime(today.year, today.month, today.day + i),
    ];
  }

  bool allows(DateTime at, DateTime now) =>
      !at.isBefore(now.add(minAhead)) && !at.isAfter(latest(now));
}
