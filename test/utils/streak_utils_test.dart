import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todo_habit_app/utils/streak_utils.dart';

void main() {
  group('calculateStreak', () {
    test('returns 0 when there are no completions', () {
      expect(calculateStreak([], DateTime(2024, 7, 10)), 0);
    });

    test('counts consecutive days ending today', () {
      final completions = [
        DateTime(2024, 7, 10, 8, 30),
        DateTime(2024, 7, 9, 21, 0),
        DateTime(2024, 7, 8, 6, 15),
      ];

      expect(calculateStreak(completions, DateTime(2024, 7, 10, 23, 59)), 3);
    });

    test('counts consecutive days ending yesterday when today missing', () {
      final completions = [
        DateTime(2024, 7, 9, 21, 0),
        DateTime(2024, 7, 8, 6, 15),
      ];

      expect(calculateStreak(completions, DateTime(2024, 7, 10, 10, 0)), 2);
    });

    test('returns 0 when the last completion is older than yesterday', () {
      final completions = [
        DateTime(2024, 7, 8, 6, 15),
      ];

      expect(calculateStreak(completions, DateTime(2024, 7, 10, 10, 0)), 0);
    });
  });

  group('last7DaysCompletionCounts', () {
    test('counts completions across multiple items', () {
      final habitA = [
        DateTime(2024, 7, 4),
        DateTime(2024, 7, 6, 23, 59),
      ];
      final habitB = [
        DateTime(2024, 7, 6, 9, 0),
        DateTime(2024, 7, 9),
      ];

      final counts = last7DaysCompletionCounts(
        [habitA, habitB],
        DateTime(2024, 7, 10, 12, 0),
      );

      expect(counts, [1, 0, 2, 0, 0, 1, 0]);
    });
  });
}
