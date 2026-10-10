/// A countdown as minutes and seconds with Western digits: 43 seconds -> "0:43",
/// 75 seconds -> "1:15". Negative durations show as "0:00".
String formatCountdown(Duration remaining) {
  final seconds = remaining.isNegative ? 0 : remaining.inSeconds;
  final minutes = seconds ~/ 60;
  final rest = (seconds % 60).toString().padLeft(2, '0');

  return '$minutes:$rest';
}
