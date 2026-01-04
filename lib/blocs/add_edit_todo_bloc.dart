import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../models/todo.dart';
import 'todo_bloc.dart';

// --- Events ---
abstract class AddEditTodoEvent {}

class InitializeTodoEvent extends AddEditTodoEvent {
  final Todo? todo;
  InitializeTodoEvent(this.todo);
}

class UpdateTodoFieldsEvent extends AddEditTodoEvent {
  final String? title;
  final String? description;
  final String? category;
  final int? priority;
  final DateTime? date;
  final DateTime? endDate;
  final String? memorizationStatus;
  final int? surahNumber;
  final int? startAyah;
  final int? endAyah;
  final int? reviewIntervalMinutes;
  final int? reviewRepeatCount;

  UpdateTodoFieldsEvent({
    this.title,
    this.description,
    this.category,
    this.priority,
    this.date,
    this.endDate,
    this.memorizationStatus,
    this.surahNumber,
    this.startAyah,
    this.endAyah,
    this.reviewIntervalMinutes,
    this.reviewRepeatCount,
  });
}

class AddSubtaskEvent extends AddEditTodoEvent {}

class UpdateSubtaskEvent extends AddEditTodoEvent {
  final int index;
  final String title;
  UpdateSubtaskEvent(this.index, this.title);
}

class RemoveSubtaskEvent extends AddEditTodoEvent {
  final int index;
  RemoveSubtaskEvent(this.index);
}

class SaveTodoEvent extends AddEditTodoEvent {}

// --- States ---
class AddEditTodoState {
  final Todo? initialTodo;
  final String title;
  final String description;
  final String category;
  final int priority;
  final DateTime date;
  final DateTime? endDate;
  final List<TodoSubtask> subtasks;

  // Quran specific
  final String? memorizationStatus;
  final int? surahNumber;
  final int? startAyah;
  final int? endAyah;
  final int? reviewIntervalMinutes;
  final int? reviewRepeatCount;

  final bool isLoading;
  final bool isSuccess;
  final String? error;

  AddEditTodoState({
    this.initialTodo,
    this.title = '',
    this.description = '',
    this.category = 'General',
    this.priority = 1,
    required this.date,
    this.endDate,
    this.subtasks = const [],
    this.memorizationStatus,
    this.surahNumber,
    this.startAyah,
    this.endAyah,
    this.reviewIntervalMinutes,
    this.reviewRepeatCount,
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  AddEditTodoState copyWith({
    Todo? initialTodo,
    String? title,
    String? description,
    String? category,
    int? priority,
    DateTime? date,
    DateTime? endDate,
    List<TodoSubtask>? subtasks,
    String? memorizationStatus,
    int? surahNumber,
    int? startAyah,
    int? endAyah,
    int? reviewIntervalMinutes,
    int? reviewRepeatCount,
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) {
    return AddEditTodoState(
      initialTodo: initialTodo ?? this.initialTodo,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      subtasks: subtasks ?? this.subtasks,
      memorizationStatus: memorizationStatus ?? this.memorizationStatus,
      surahNumber: surahNumber ?? this.surahNumber,
      startAyah: startAyah ?? this.startAyah,
      endAyah: endAyah ?? this.endAyah,
      reviewIntervalMinutes:
          reviewIntervalMinutes ?? this.reviewIntervalMinutes,
      reviewRepeatCount: reviewRepeatCount ?? this.reviewRepeatCount,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

// --- BLoC ---
class AddEditTodoBloc extends Bloc<AddEditTodoEvent, AddEditTodoState> {
  final TodoBloc todoBloc;

  AddEditTodoBloc({required this.todoBloc})
    : super(AddEditTodoState(date: DateTime.now())) {
    on<InitializeTodoEvent>((event, emit) {
      if (event.todo != null) {
        final t = event.todo!;
        emit(
          AddEditTodoState(
            initialTodo: t,
            title: t.title,
            description: t.description,
            category: t.category,
            priority: t.priority,
            date: t.date,
            endDate: t.endTime,
            subtasks: t.subtasks,
            memorizationStatus: t.memorizationStatus,
            surahNumber: t.surahNumber,
            startAyah: t.startAyah,
            endAyah: t.endAyah,
            reviewIntervalMinutes: t.reviewInterval?.inMinutes,
            reviewRepeatCount: t.reviewRepeatCount,
          ),
        );
      }
    });

    on<UpdateTodoFieldsEvent>((event, emit) {
      emit(
        state.copyWith(
          title: event.title,
          description: event.description,
          category: event.category,
          priority: event.priority,
          date: event.date,
          endDate: event.endDate,
          memorizationStatus: event.memorizationStatus,
          surahNumber: event.surahNumber,
          startAyah: event.startAyah,
          endAyah: event.endAyah,
          reviewIntervalMinutes: event.reviewIntervalMinutes,
          reviewRepeatCount: event.reviewRepeatCount,
        ),
      );
    });

    on<AddSubtaskEvent>((event, emit) {
      final subtasks = List<TodoSubtask>.from(state.subtasks);
      subtasks.add(
        TodoSubtask(id: const Uuid().v4(), title: '', completed: false),
      );
      emit(state.copyWith(subtasks: subtasks));
    });

    on<UpdateSubtaskEvent>((event, emit) {
      final subtasks = List<TodoSubtask>.from(state.subtasks);
      final s = subtasks[event.index];
      subtasks[event.index] = TodoSubtask(
        id: s.id,
        title: event.title,
        completed: s.completed,
      );
      emit(state.copyWith(subtasks: subtasks));
    });

    on<RemoveSubtaskEvent>((event, emit) {
      final subtasks = List<TodoSubtask>.from(state.subtasks);
      subtasks.removeAt(event.index);
      emit(state.copyWith(subtasks: subtasks));
    });

    on<SaveTodoEvent>((event, emit) {
      if (state.title.isEmpty) {
        emit(state.copyWith(error: 'Title cannot be empty'));
        return;
      }

      final todo = Todo(
        id: state.initialTodo?.id ?? const Uuid().v4(),
        title: state.title,
        description: state.description,
        date: state.date,
        endTime: state.endDate,
        priority: state.priority,
        category: state.category,
        subtasks: state.subtasks,
        isCompleted: state.initialTodo?.isCompleted ?? false,
        status: state.initialTodo?.status ?? 'active',
        memorizationStatus: state.memorizationStatus,
        surahNumber: state.surahNumber,
        startAyah: state.startAyah,
        endAyah: state.endAyah,
        reviewInterval: state.reviewIntervalMinutes != null
            ? Duration(minutes: state.reviewIntervalMinutes!)
            : null,
        reviewRepeatCount: state.reviewRepeatCount,
        reviewDueDate: state.initialTodo?.reviewDueDate,
        lastReviewedAt: state.initialTodo?.lastReviewedAt,
      );

      if (state.initialTodo != null) {
        todoBloc.add(UpdateTodoEvent(todo));
      } else {
        todoBloc.add(AddTodoEvent(todo));
      }
      emit(state.copyWith(isSuccess: true));
    });
  }
}
