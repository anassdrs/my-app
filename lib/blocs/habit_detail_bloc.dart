import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/habit.dart';
import 'habit_bloc.dart';

// --- Events ---
abstract class HabitDetailEvent {}

class LoadHabitDetailEvent extends HabitDetailEvent {
  final String habitId;
  LoadHabitDetailEvent(this.habitId);
}

class UpdateFocusedDayEvent extends HabitDetailEvent {
  final DateTime day;
  UpdateFocusedDayEvent(this.day);
}

class _UpdateHabitInstanceEvent extends HabitDetailEvent {
  final Habit habit;
  _UpdateHabitInstanceEvent(this.habit);
}

// --- States ---
class HabitDetailState {
  final Habit? habit;
  final DateTime focusedDay;
  final bool isLoading;

  HabitDetailState({
    this.habit,
    required this.focusedDay,
    this.isLoading = true,
  });

  HabitDetailState copyWith({
    Habit? habit,
    DateTime? focusedDay,
    bool? isLoading,
  }) {
    return HabitDetailState(
      habit: habit ?? this.habit,
      focusedDay: focusedDay ?? this.focusedDay,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- BLoC ---
class HabitDetailBloc extends Bloc<HabitDetailEvent, HabitDetailState> {
  final HabitBloc habitBloc;
  StreamSubscription? _habitSubscription;

  HabitDetailBloc({required this.habitBloc})
    : super(HabitDetailState(focusedDay: DateTime.now())) {
    on<LoadHabitDetailEvent>((event, emit) {
      if (habitBloc.state is! HabitLoaded) return;
      final habit = (habitBloc.state as HabitLoaded).habits.firstWhere(
        (h) => h.id == event.habitId,
      );
      emit(state.copyWith(habit: habit, isLoading: false));

      _habitSubscription?.cancel();
      _habitSubscription = habitBloc.stream.listen((habitState) {
        if (habitState is! HabitLoaded) return;
        try {
          final updated = habitState.habits.firstWhere(
            (h) => h.id == event.habitId,
          );
          add(_UpdateHabitInstanceEvent(updated));
        } catch (_) {
          // Habit might have been deleted
        }
      });
    });

    on<UpdateFocusedDayEvent>((event, emit) {
      emit(state.copyWith(focusedDay: event.day));
    });

    on<_UpdateHabitInstanceEvent>((event, emit) {
      emit(state.copyWith(habit: event.habit));
    });
  }

  @override
  Future<void> close() {
    _habitSubscription?.cancel();
    return super.close();
  }
}
