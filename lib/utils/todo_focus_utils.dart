import '../models/todo.dart';

DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isEligibleForFocusStatus(String status) {
  return status == 'active' || status == 'in_progress';
}

bool isFocusActive(Todo todo, DateTime now) {
  if (!todo.isFocused || todo.focusDate == null) return false;
  return isSameDay(todo.focusDate!, now);
}

String dateKey(DateTime date) {
  final normalized = normalizeDate(date);
  return "${normalized.year.toString().padLeft(4, '0')}-"
      "${normalized.month.toString().padLeft(2, '0')}-"
      "${normalized.day.toString().padLeft(2, '0')}";
}
