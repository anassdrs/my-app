DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool isCompletedOnDate(List<DateTime> completedDates, DateTime date) {
  return completedDates.any(
    (d) => d.year == date.year && d.month == date.month && d.day == date.day,
  );
}

int calculateStreak(List<DateTime> completedDates, DateTime referenceDate) {
  if (completedDates.isEmpty) {
    return 0;
  }

  final normalizedToday = normalizeDate(referenceDate);

  int countBackFrom(DateTime startDate) {
    int streak = 0;
    var checkDate = startDate;
    while (isCompletedOnDate(completedDates, checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  if (isCompletedOnDate(completedDates, normalizedToday)) {
    return countBackFrom(normalizedToday);
  }

  final yesterday = normalizedToday.subtract(const Duration(days: 1));
  if (isCompletedOnDate(completedDates, yesterday)) {
    return countBackFrom(yesterday);
  }

  return 0;
}

List<int> last7DaysCompletionCounts(
  Iterable<List<DateTime>> completedLists,
  DateTime referenceDate,
) {
  final normalizedToday = normalizeDate(referenceDate);
  final counts = <int>[];

  for (int i = 6; i >= 0; i--) {
    final day = normalizedToday.subtract(Duration(days: i));
    int count = 0;
    for (final completedDates in completedLists) {
      if (isCompletedOnDate(completedDates, day)) {
        count++;
      }
    }
    counts.add(count);
  }

  return counts;
}
