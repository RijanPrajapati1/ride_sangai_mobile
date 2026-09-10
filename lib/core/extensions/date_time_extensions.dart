import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String get toMonthDay => DateFormat('MMM d').format(this);

  String get toWeekdayMonthDay => DateFormat('EEE, MMM d').format(this);

  String get toFullDate => DateFormat('EEEE, MMMM d, yyyy').format(this);

  String get toTime => DateFormat('h:mm a').format(this);

  String get toChatTimestamp => DateFormat('h:mm a').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isPast => isBefore(DateTime.now());

  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return toMonthDay;
  }

  String get relativeDayLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(year, month, day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return toWeekdayMonthDay;
  }
}
