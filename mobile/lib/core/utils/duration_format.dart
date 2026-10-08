/// A ride's length at a glance: "45m", "3h 30m", "2 days 4h".
String formatDuration(int minutes) {
  if (minutes >= 1440) {
    final days = minutes ~/ 1440;
    final hours = (minutes % 1440) ~/ 60;
    final dayLabel = '$days day${days == 1 ? '' : 's'}';
    return hours == 0 ? dayLabel : '$dayLabel ${hours}h';
  }
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours == 0) return '${mins}m';
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}
