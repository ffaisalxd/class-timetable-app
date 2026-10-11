int? parseTimeToMinutes(String time) {
  final regex = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false);
  final match = regex.firstMatch(time.trim());
  if (match == null) return null;

  int hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final period = match.group(3)!.toUpperCase();

  if (period == 'AM' && hour == 12) hour = 0;
  if (period == 'PM' && hour != 12) hour += 12;

  return hour * 60 + minute;
}