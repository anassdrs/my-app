import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todo_habit_app/models/habit.dart';
import 'package:flutter_todo_habit_app/utils/habit_schedule_utils.dart';

void main() {
  test('habitDateKey normalizes dates', () {
    final key = habitDateKey(DateTime(2024, 5, 3, 14, 0));
    expect(key, '2024-05-03');
  });

  test('isWithinWindow respects start/end minutes', () {
    final time = DateTime(2024, 5, 3, 9, 30);
    expect(isWithinWindow(time, 9 * 60, 10 * 60), isTrue);
    expect(isWithinWindow(time, 10 * 60, 11 * 60), isFalse);
  });

  test('custom day scheduling uses weekdays', () {
    final habit = Habit(
      id: '1',
      title: 'Test',
      customDays: [DateTime.monday, DateTime.wednesday],
      frequencyType: 'custom_days',
    );
    expect(isScheduledOn(habit, DateTime(2024, 5, 6)), isTrue); // Monday
    expect(isScheduledOn(habit, DateTime(2024, 5, 7)), isFalse); // Tuesday
  });

  test('weekly completion count groups by week', () {
    final habit = Habit(
      id: '1',
      title: 'Test',
      frequencyType: 'weekly',
      frequencyValue: 2,
      completedDates: [
        DateTime(2024, 5, 6, 8, 0),
        DateTime(2024, 5, 7, 9, 0),
      ],
    );
    expect(completedCountForWeek(habit, DateTime(2024, 5, 8)), 2);
  });
}
