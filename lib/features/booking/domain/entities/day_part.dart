/// Which greeting fits the time: morning until noon, afternoon until five, then evening.
enum DayPart {
  morning,
  afternoon,
  evening;

  static DayPart of(DateTime time) => switch (time.hour) {
        >= 5 && < 12 => DayPart.morning,
        >= 12 && < 17 => DayPart.afternoon,
        _ => DayPart.evening,
      };
}
