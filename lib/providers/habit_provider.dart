import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../utils/boxes.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> get habits {
    final box = Hive.box<Habit>(HiveBoxes.habits);
    return box.values.toList();
  }

  Future<void> addHabit(Habit habit) async {
    final box = Hive.box<Habit>(HiveBoxes.habits);
    await box.add(habit);
    notifyListeners();
  }

  Future<void> deleteHabit(Habit habit) async {
    await habit.delete();
    notifyListeners();
  }

  Future<void> toggleHabitCompletion(Habit habit, DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (habit.isCompletedOn(normalizedDate)) {
      habit.completedDates.removeWhere(
        (d) =>
            d.year == normalizedDate.year &&
            d.month == normalizedDate.month &&
            d.day == normalizedDate.day,
      );
    } else {
      habit.completedDates.add(normalizedDate);
    }

    // Recalculate streak
    // Very basic streak logic: check consecutive days backwards from today
    int streak = 0;
    DateTime checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    // Check if completed today, if so start counting from today.
    // If not completed today, check yesterday. If completed yesterday, start counting from yesterday.
    // If neither, streak is 0.

    if (habit.isCompletedOn(checkDate)) {
      // Loop backwards
      while (habit.isCompletedOn(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else {
      DateTime yesterday = checkDate.subtract(const Duration(days: 1));
      if (habit.isCompletedOn(yesterday)) {
        checkDate = yesterday;
        while (habit.isCompletedOn(checkDate)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      }
    }

    habit.streak = streak;

    await habit.save();
    notifyListeners();
  }

  List<int> getLast7DaysStats() {
    List<int> counts = [];
    DateTime today = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime day = today.subtract(Duration(days: i));
      int count = 0;
      for (var habit in habits) {
        if (habit.isCompletedOn(day)) {
          count++;
        }
      }
      counts.add(count);
    }
    return counts;
  }
}
