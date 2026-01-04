import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../utils/boxes.dart';
import '../utils/streak_utils.dart' as streak_utils;
import '../utils/habit_schedule_utils.dart' as habit_utils;
import '../services/xp_service.dart';

// Events
abstract class HabitEvent {}

class LoadHabits extends HabitEvent {}

class AddHabitEvent extends HabitEvent {
  final Habit habit;
  AddHabitEvent(this.habit);
}

class UpdateHabitEvent extends HabitEvent {
  final Habit habit;
  UpdateHabitEvent(this.habit);
}

class DeleteHabitEvent extends HabitEvent {
  final Habit habit;
  DeleteHabitEvent(this.habit);
}

class ToggleHabitEvent extends HabitEvent {
  final Habit habit;
  final DateTime date;
  ToggleHabitEvent(this.habit, this.date);
}

// States
abstract class HabitState {}

class HabitInitial extends HabitState {}

class HabitLoading extends HabitState {}

class HabitLoaded extends HabitState {
  final List<Habit> habits;
  HabitLoaded(this.habits);
}

class HabitError extends HabitState {
  final String message;
  HabitError(this.message);
}

// BLoC
class HabitBloc extends Bloc<HabitEvent, HabitState> {
  final XpService _xpService = XpService();

  HabitBloc() : super(HabitInitial()) {
    on<LoadHabits>(_onLoadHabits);
    on<AddHabitEvent>(_onAddHabit);
    on<UpdateHabitEvent>(_onUpdateHabit);
    on<DeleteHabitEvent>(_onDeleteHabit);
    on<ToggleHabitEvent>(_onToggleHabit);
  }

  void _onLoadHabits(LoadHabits event, Emitter<HabitState> emit) async {
    emit(HabitLoading());
    try {
      final box = Hive.box<Habit>(HiveBoxes.habits);
      final habits = box.values.toList();
      final now = DateTime.now();
      for (final habit in habits) {
        await _applyMissedEvaluations(habit, now);
      }
      emit(HabitLoaded(habits));
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }

  void _onAddHabit(AddHabitEvent event, Emitter<HabitState> emit) async {
    try {
      final box = Hive.box<Habit>(HiveBoxes.habits);
      await box.add(event.habit);
      add(LoadHabits());
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }

  void _onUpdateHabit(UpdateHabitEvent event, Emitter<HabitState> emit) async {
    try {
      await event.habit.save();
      add(LoadHabits());
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }

  void _onDeleteHabit(DeleteHabitEvent event, Emitter<HabitState> emit) async {
    try {
      await event.habit.delete();
      add(LoadHabits());
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }

  void _onToggleHabit(ToggleHabitEvent event, Emitter<HabitState> emit) async {
    try {
      final completionTime = event.date;
      final normalizedDate = habit_utils.normalizeDate(completionTime);
      final dateKey = habit_utils.habitDateKey(normalizedDate);

      if (event.habit.isCompletedOn(normalizedDate)) {
        event.habit.completedDates.removeWhere(
          (d) =>
              d.year == normalizedDate.year &&
              d.month == normalizedDate.month &&
              d.day == normalizedDate.day,
        );
      } else {
        final completedCountBefore = habit_utils.completedCountForWeek(
          event.habit,
          normalizedDate,
        );
        final scheduled = habit_utils.isScheduledOn(event.habit, normalizedDate);
        final weeklyAvailable = event.habit.frequencyType == 'weekly'
            ? completedCountBefore < event.habit.frequencyValue
            : true;
        final withinWindow = habit_utils.isWithinWindow(
          completionTime,
          event.habit.windowStartMinutes,
          event.habit.windowEndMinutes,
        );
        event.habit.completedDates.add(completionTime);
        if (scheduled &&
            weeklyAvailable &&
            !event.habit.evaluatedDates.contains(dateKey)) {
          if (withinWindow) {
            await _xpService.applyXpDelta(10);
          } else {
            await _xpService.applyXpDelta(-1);
          }
          event.habit.evaluatedDates.add(dateKey);
          event.habit.lastEvaluatedDate = habit_utils.normalizeDate(DateTime.now());
        }
      }

      event.habit.streak = streak_utils.calculateStreak(
        event.habit.completedDates,
        DateTime.now(),
      );
      await event.habit.save();
      add(LoadHabits());
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }

  List<int> getLast7DaysStats(List<Habit> habits) {
    return streak_utils.last7DaysCompletionCounts(
      habits.map((habit) => habit.completedDates),
      DateTime.now(),
    );
  }

  Future<void> _applyMissedEvaluations(Habit habit, DateTime now) async {
    final today = habit_utils.normalizeDate(now);
    final lastEvaluated = habit.lastEvaluatedDate == null
        ? today
        : habit_utils.normalizeDate(habit.lastEvaluatedDate!);
    if (!lastEvaluated.isBefore(today)) {
      return;
    }

    if (habit.frequencyType == 'weekly' && habit.frequencyValue > 0) {
      final previousWeekKey = habit_utils.habitWeekKey(lastEvaluated);
      final currentWeekKey = habit_utils.habitWeekKey(today);
      if (previousWeekKey != currentWeekKey &&
          !habit.evaluatedDates.contains(previousWeekKey)) {
        final completedCount =
            habit_utils.completedCountForWeek(habit, lastEvaluated);
        final missing = habit.frequencyValue - completedCount;
        if (missing > 0) {
          await _xpService.applyXpDelta(-missing);
        }
        habit.evaluatedDates.add(previousWeekKey);
      }
      habit.lastEvaluatedDate = today;
      await habit.save();
      return;
    }

    var day = lastEvaluated.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    while (!day.isAfter(yesterday)) {
      final key = habit_utils.habitDateKey(day);
      final scheduled = habit_utils.isScheduledOn(habit, day);
      final completed = habit.isCompletedOn(day);

      if (scheduled && !completed && !habit.evaluatedDates.contains(key)) {
        await _xpService.applyXpDelta(-1);
        habit.evaluatedDates.add(key);
      }

      day = day.add(const Duration(days: 1));
    }

    habit.lastEvaluatedDate = today;
    await habit.save();
  }
}
