import 'package:hive_flutter/hive_flutter.dart';

import '../models/todo_transition.dart';
import '../utils/boxes.dart';

class TodoWeeklyAnalytics {
  final DateTime weekStart;
  final DateTime weekEnd;
  final double completionRate;
  final double missRate;
  final int xpGained;
  final int xpLost;
  final double avgInProgressMinutes;
  final List<TodoSkipStat> mostSkipped;
  final int? bestCompletionHour;
  final int bestCompletionCount;
  final int doneCount;
  final int missedCount;
  final int archivedCount;

  const TodoWeeklyAnalytics({
    required this.weekStart,
    required this.weekEnd,
    required this.completionRate,
    required this.missRate,
    required this.xpGained,
    required this.xpLost,
    required this.avgInProgressMinutes,
    required this.mostSkipped,
    required this.bestCompletionHour,
    required this.bestCompletionCount,
    required this.doneCount,
    required this.missedCount,
    required this.archivedCount,
  });
}

class TodoSkipStat {
  final String title;
  final int count;

  const TodoSkipStat(this.title, this.count);
}

class TodoAnalyticsService {
  Future<TodoWeeklyAnalytics> getWeeklyAnalytics(DateTime referenceDate) async {
    final box = Hive.box<TodoTransition>(HiveBoxes.todoTransitions);
    final range = _weekRange(referenceDate);
    final transitions = box.values
        .where(
          (item) =>
              !item.timestamp.isBefore(range.start) &&
              item.timestamp.isBefore(range.end),
        )
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final doneTransitions =
        transitions.where((item) => item.toStatus == 'done').toList();
    final missedTransitions =
        transitions.where((item) => item.toStatus == 'missed').toList();
    final archivedTransitions =
        transitions.where((item) => item.toStatus == 'archived').toList();

    final doneCount = doneTransitions.length;
    final missedCount = missedTransitions.length;
    final archivedCount = archivedTransitions.length;

    final denominator = doneCount + missedCount;
    final completionRate =
        denominator == 0 ? 0.0 : doneCount / denominator;
    final missRate = denominator == 0 ? 0.0 : missedCount / denominator;

    int xpGained = 0;
    int xpLost = 0;
    for (final item in transitions) {
      if (item.xpDelta > 0) {
        xpGained += item.xpDelta;
      } else if (item.xpDelta < 0) {
        xpLost += item.xpDelta.abs();
      }
    }

    final avgInProgressMinutes = _averageInProgressMinutes(
      transitions,
      range,
    );

    final mostSkipped = _mostSkippedTitles(missedTransitions);
    final bestCompletion = _bestCompletionHour(doneTransitions);

    return TodoWeeklyAnalytics(
      weekStart: range.start,
      weekEnd: range.end,
      completionRate: completionRate,
      missRate: missRate,
      xpGained: xpGained,
      xpLost: xpLost,
      avgInProgressMinutes: avgInProgressMinutes,
      mostSkipped: mostSkipped,
      bestCompletionHour: bestCompletion.hour,
      bestCompletionCount: bestCompletion.count,
      doneCount: doneCount,
      missedCount: missedCount,
      archivedCount: archivedCount,
    );
  }

  _WeekRange _weekRange(DateTime referenceDate) {
    final normalized =
        DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final start = normalized.subtract(Duration(days: normalized.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return _WeekRange(start, end);
  }

  double _averageInProgressMinutes(
    List<TodoTransition> transitions,
    _WeekRange range,
  ) {
    final Map<String, DateTime?> inProgressStart = {};
    final List<int> durations = [];

    for (final transition in transitions) {
      if (transition.toStatus == 'in_progress') {
        inProgressStart[transition.todoId] = transition.timestamp;
        continue;
      }

      if (transition.toStatus == 'done') {
        final start = inProgressStart[transition.todoId];
        if (start != null) {
          final duration = transition.timestamp.difference(start).inMinutes;
          if (duration >= 0) {
            durations.add(duration);
          }
          inProgressStart[transition.todoId] = null;
        }
        continue;
      }

      if (transition.toStatus == 'paused' ||
          transition.toStatus == 'missed' ||
          transition.toStatus == 'archived') {
        inProgressStart[transition.todoId] = null;
      }
    }

    if (durations.isEmpty) return 0.0;
    final total = durations.reduce((a, b) => a + b);
    return total / durations.length;
  }

  List<TodoSkipStat> _mostSkippedTitles(
    List<TodoTransition> missedTransitions,
  ) {
    final Map<String, int> counts = {};
    for (final item in missedTransitions) {
      counts[item.title] = (counts[item.title] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(3)
        .map((entry) => TodoSkipStat(entry.key, entry.value))
        .toList();
  }

  _BestCompletion _bestCompletionHour(List<TodoTransition> doneTransitions) {
    if (doneTransitions.isEmpty) {
      return const _BestCompletion(null, 0);
    }
    final Map<int, int> hours = {};
    for (final item in doneTransitions) {
      final hour = item.timestamp.hour;
      hours[hour] = (hours[hour] ?? 0) + 1;
    }
    final bestEntry = hours.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return _BestCompletion(bestEntry.key, bestEntry.value);
  }
}

class _BestCompletion {
  final int? hour;
  final int count;

  const _BestCompletion(this.hour, this.count);
}

class _WeekRange {
  final DateTime start;
  final DateTime end;

  const _WeekRange(this.start, this.end);
}
