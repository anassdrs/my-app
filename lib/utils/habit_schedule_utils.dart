import '../models/habit.dart';

String habitDateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return "${normalized.year.toString().padLeft(4, '0')}-"
      "${normalized.month.toString().padLeft(2, '0')}-"
      "${normalized.day.toString().padLeft(2, '0')}";
}

DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime weekStart(DateTime date) {
  final normalized = normalizeDate(date);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

String habitWeekKey(DateTime date) {
  final start = weekStart(date);
  return "week-${habitDateKey(start)}";
}

int minutesSinceMidnight(DateTime date) {
  return date.hour * 60 + date.minute;
}

bool isWithinWindow(DateTime date, int startMinutes, int endMinutes) {
  if (endMinutes < startMinutes) {
    return false;
  }
  final minutes = minutesSinceMidnight(date);
  return minutes >= startMinutes && minutes <= endMinutes;
}

bool isScheduledOn(Habit habit, DateTime date) {
  switch (habit.frequencyType) {
    case 'weekly':
      return habit.frequencyValue > 0;
    case 'custom_days':
      return habit.customDays.contains(date.weekday);
    case 'daily':
    default:
      return true;
  }
}

int completedCountForWeek(Habit habit, DateTime date) {
  final start = weekStart(date);
  final weekEnd = start.add(const Duration(days: 6));
  final keys = <String>{};
  for (final completion in habit.completedDates) {
    final day = normalizeDate(completion);
    if (day.isBefore(start) || day.isAfter(weekEnd)) {
      continue;
    }
    keys.add(habitDateKey(day));
  }
  return keys.length;
}
