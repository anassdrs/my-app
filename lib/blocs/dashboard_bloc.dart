import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/todo.dart';
import '../models/habit.dart';
import 'todo_bloc.dart';
import 'habit_bloc.dart';

// --- Events ---
abstract class DashboardEvent {}

class UpdateDashboardDataEvent extends DashboardEvent {
  final List<Todo> todos;
  final List<Habit> habits;
  UpdateDashboardDataEvent({required this.todos, required this.habits});
}

// --- States ---
class DashboardState {
  final List<Todo> todos;
  final List<Habit> habits;
  final bool isLoading;

  DashboardState({
    this.todos = const [],
    this.habits = const [],
    this.isLoading = true,
  });

  DashboardState copyWith({
    List<Todo>? todos,
    List<Habit>? habits,
    bool? isLoading,
  }) {
    return DashboardState(
      todos: todos ?? this.todos,
      habits: habits ?? this.habits,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- BLoC ---
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final TodoBloc todoBloc;
  final HabitBloc habitBloc;
  late StreamSubscription _todoSubscription;
  late StreamSubscription _habitSubscription;

  DashboardBloc({required this.todoBloc, required this.habitBloc})
    : super(DashboardState()) {
    on<UpdateDashboardDataEvent>((event, emit) {
      emit(
        state.copyWith(
          todos: event.todos,
          habits: event.habits,
          isLoading: false,
        ),
      );
    });

    // Listen to dependencies
    _todoSubscription = todoBloc.stream.listen((todoState) {
      if (todoState is TodoLoaded) {
        _update();
      }
    });

    _habitSubscription = habitBloc.stream.listen((habitState) {
      if (habitState is HabitLoaded) {
        _update();
      }
    });

    // Initial sync
    _update();
  }

  void _update() {
    final todos = todoBloc.state is TodoLoaded
        ? (todoBloc.state as TodoLoaded).todos
        : <Todo>[];
    final habits = habitBloc.state is HabitLoaded
        ? (habitBloc.state as HabitLoaded).habits
        : <Habit>[];

    add(UpdateDashboardDataEvent(todos: todos, habits: habits));
  }

  @override
  Future<void> close() {
    _todoSubscription.cancel();
    _habitSubscription.cancel();
    return super.close();
  }
}
