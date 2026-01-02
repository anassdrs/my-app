import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../utils/boxes.dart';
import '../utils/streak_utils.dart';

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
      final normalizedDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );

      if (event.habit.isCompletedOn(normalizedDate)) {
        event.habit.completedDates.removeWhere(
          (d) =>
              d.year == normalizedDate.year &&
              d.month == normalizedDate.month &&
              d.day == normalizedDate.day,
        );
      } else {
        event.habit.completedDates.add(normalizedDate);
      }

      event.habit.streak = calculateStreak(
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
    return last7DaysCompletionCounts(
      habits.map((habit) => habit.completedDates),
      DateTime.now(),
    );
  }
}
