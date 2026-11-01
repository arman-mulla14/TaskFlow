import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _shortDate = DateFormat('MMM d');
  static final DateFormat _mediumDate = DateFormat('MMM d, yyyy');
  static final DateFormat _dayOfWeek = DateFormat('EEE');
  static final DateFormat _timeFormat = DateFormat('h:mm a');

  static String formatShort(DateTime? date) {
    if (date == null) return '';
    return _shortDate.format(date);
  }

  static String formatMedium(DateTime? date) {
    if (date == null) return '';
    return _mediumDate.format(date);
  }

  static String formatDayOfWeek(DateTime date) {
    return _dayOfWeek.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  static String getRelativeDueDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < -1) return '${-diff} days overdue';
    if (diff <= 7) return 'In $diff days';
    return formatShort(date);
  }

  static bool isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isOverdue(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }
}
