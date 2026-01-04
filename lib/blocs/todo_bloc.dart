import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo.dart';
import '../models/todo_transition.dart';
import '../utils/boxes.dart';
import '../services/xp_service.dart';
import '../utils/todo_focus_utils.dart' as focus_utils;
import '../utils/quran_memorization_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:quran/quran.dart' as quran;

// Events
abstract class TodoEvent {}

class LoadTodos extends TodoEvent {}

class AddTodoEvent extends TodoEvent {
  final Todo todo;
  AddTodoEvent(this.todo);
}

class UpdateTodoEvent extends TodoEvent {
  final Todo todo;
  UpdateTodoEvent(this.todo);
}

class DeleteTodoEvent extends TodoEvent {
  final Todo todo;
  DeleteTodoEvent(this.todo);
}

class ToggleTodoEvent extends TodoEvent {
  final Todo todo;
  ToggleTodoEvent(this.todo);
}

class ToggleSurahMasteryEvent extends TodoEvent {
  final int surahNumber;
  ToggleSurahMasteryEvent(this.surahNumber);
}

// States
abstract class TodoState {}

class TodoInitial extends TodoState {}

class TodoLoading extends TodoState {}

class TodoLoaded extends TodoState {
  final List<Todo> todos;
  TodoLoaded(this.todos);
}

class TodoError extends TodoState {
  final String message;
  TodoError(this.message);
}

// BLoC
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final XpService _xpService = XpService();
  final Uuid _uuid = const Uuid();
  static const int focusBonusXp = 10;

  TodoBloc() : super(TodoInitial()) {
    on<LoadTodos>(_onLoadTodos);
    on<AddTodoEvent>(_onAddTodo);
    on<UpdateTodoEvent>(_onUpdateTodo);
    on<DeleteTodoEvent>(_onDeleteTodo);
    on<ToggleTodoEvent>(_onToggleTodo);
    on<ToggleSurahMasteryEvent>(_onToggleSurahMastery);
  }

  void _onLoadTodos(LoadTodos event, Emitter<TodoState> emit) async {
    emit(TodoLoading());
    try {
      final box = Hive.box<Todo>(HiveBoxes.todos);
      final todos = box.values.toList();
      final now = DateTime.now();
      for (final todo in todos) {
        _syncStatus(todo);
        _syncFocus(todo, now);
        await _syncSubtaskCompletion(todo, now);
        final dueDate =
            todo.endTime ??
            DateTime(todo.date.year, todo.date.month, todo.date.day, 23, 59);
        final isOverdue = dueDate.isBefore(now);
        if ((todo.status == 'active' || todo.status == 'in_progress') &&
            isOverdue) {
          await _applyStatusChange(
            todo,
            'missed',
            now,
            save: true,
            triggerReload: false,
          );
        }
      }
      await _evaluateFocusBonus(todos, now);
      todos.sort((a, b) {
        if (_isDone(a) != _isDone(b)) {
          return _isDone(a) ? 1 : -1;
        }
        if (a.priority != b.priority) {
          return b.priority.compareTo(a.priority);
        }
        return a.date.compareTo(b.date);
      });
      emit(TodoLoaded(todos));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void _onAddTodo(AddTodoEvent event, Emitter<TodoState> emit) async {
    try {
      _syncMemorizationSchedule(event.todo, DateTime.now());
      final box = Hive.box<Todo>(HiveBoxes.todos);
      await box.add(event.todo);
      add(LoadTodos());
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void _onUpdateTodo(UpdateTodoEvent event, Emitter<TodoState> emit) async {
    try {
      _syncStatus(event.todo);
      _syncMemorizationSchedule(event.todo, DateTime.now());
      await event.todo.save();
      add(LoadTodos());
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void _onDeleteTodo(DeleteTodoEvent event, Emitter<TodoState> emit) async {
    try {
      await event.todo.delete();
      add(LoadTodos());
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void _onToggleTodo(ToggleTodoEvent event, Emitter<TodoState> emit) async {
    try {
      _syncStatus(event.todo);
      if (event.todo.status == 'active') {
        await _applyStatusChange(event.todo, 'in_progress', DateTime.now());
      } else if (event.todo.status == 'in_progress') {
        await _applyStatusChange(event.todo, 'done', DateTime.now());
      }
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void _onToggleSurahMastery(
    ToggleSurahMasteryEvent event,
    Emitter<TodoState> emit,
  ) async {
    try {
      final box = Hive.box<Todo>(HiveBoxes.todos);
      final existingTodo = box.values.cast<Todo?>().firstWhere(
        (t) =>
            t?.category == 'Quran Memorization' &&
            t?.surahNumber == event.surahNumber,
        orElse: () => null,
      );

      if (existingTodo != null) {
        if (existingTodo.memorizationStatus == 'MASTERED') {
          existingTodo.memorizationStatus = 'NOT_STARTED';
          existingTodo.isCompleted = false;
          existingTodo.status = 'todo';
          existingTodo.completedAt = null;
        } else {
          existingTodo.memorizationStatus = 'MASTERED';
          existingTodo.isCompleted = true;
          existingTodo.status = 'done';
          existingTodo.completedAt = DateTime.now();
        }
        await existingTodo.save();
      } else {
        final title =
            'Memorize ${quran.getSurahNameEnglish(event.surahNumber)}';
        final todo = Todo(
          id: const Uuid().v4(),
          title: title,
          description: quran.getSurahNameArabic(event.surahNumber),
          date: DateTime.now(),
          isCompleted: true,
          completedAt: DateTime.now(),
          status: 'done',
          category: 'Quran Memorization',
          memorizationStatus: 'MASTERED',
          surahNumber: event.surahNumber,
        );
        await box.put(todo.id, todo);
      }
      add(LoadTodos());
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<TodoStatusUpdate> updateTodoStatus(
    Todo todo,
    String newStatus,
    DateTime timestamp,
  ) async {
    return _applyStatusChange(todo, newStatus, timestamp);
  }

  void _syncStatus(Todo todo) {
    if (todo.status.isEmpty) {
      todo.status = todo.isCompleted ? 'done' : 'active';
    }
    if (todo.isCompleted && todo.status != 'done') {
      todo.status = 'done';
    }
    if (!todo.isCompleted && todo.status == 'done') {
      todo.status = 'active';
    }
  }

  void _syncMemorizationSchedule(Todo todo, DateTime now) {
    if (todo.category != 'Quran Memorization') {
      todo.memorizationStatus = null;
      todo.reviewDueDate = null;
      todo.reviewIntervalDays = null;
      todo.lastReviewedAt = null;
      todo.reviewRepeatCount = null;
      todo.reviewInterval = null;
      return;
    }
    if ((todo.memorizationStatus ?? '').isEmpty) {
      todo.memorizationStatus = 'UNLEARNED';
    }
    if (todo.reviewInterval == null && todo.reviewIntervalDays != null) {
      todo.reviewInterval = Duration(days: todo.reviewIntervalDays!);
    }
    todo.reviewRepeatCount ??= 0;
    if (todo.memorizationStatus == 'UNLEARNED') {
      todo.reviewDueDate = null;
      todo.reviewIntervalDays = null;
      todo.reviewInterval = null;
      todo.lastReviewedAt = null;
      todo.reviewRepeatCount = 0;
      return;
    }
    final hasSchedule =
        todo.reviewDueDate != null ||
        todo.reviewInterval != null ||
        todo.lastReviewedAt != null;
    if (hasSchedule) {
      return;
    }
    switch (todo.memorizationStatus) {
      case 'LEARNING':
        todo.reviewInterval = baseMemorizationInterval;
        todo.reviewDueDate = todo.date.add(baseMemorizationInterval);
        todo.reviewRepeatCount = 0;
        todo.lastReviewedAt = null;
        break;
      case 'REVIEW':
        todo.reviewInterval = const Duration(days: 1);
        todo.reviewDueDate = todo.date.add(todo.reviewInterval!);
        break;
      case 'NEEDS_REVIEW':
        final current = todo.reviewInterval ?? baseMemorizationInterval;
        final next = scaleInterval(current, 0.5);
        todo.reviewInterval = next;
        todo.reviewDueDate = now.add(next);
        todo.reviewRepeatCount = todo.reviewRepeatCount! > 0
            ? todo.reviewRepeatCount! - 1
            : 0;
        break;
      case 'MASTERED':
        todo.reviewInterval = longMemorizationInterval;
        todo.reviewDueDate = now.add(longMemorizationInterval);
        todo.reviewRepeatCount = todo.reviewRepeatCount! + 1;
        break;
      default:
        break;
    }
    todo.reviewIntervalDays = todo.reviewInterval?.inDays;
  }

  bool _transitionTodo(Todo todo, String targetStatus) {
    final current = todo.status;
    final isValid = switch (targetStatus) {
      'in_progress' => current == 'active',
      'done' => current == 'in_progress',
      'paused' => current == 'active' || current == 'in_progress',
      'active' => current == 'paused' || current == 'missed',
      'missed' => current == 'active' || current == 'in_progress',
      'archived' => true,
      _ => false,
    };
    if (!isValid) return false;

    todo.status = targetStatus;
    todo.isCompleted = targetStatus == 'done';
    return true;
  }

  bool _isDone(Todo todo) => todo.status == 'done';

  Future<TodoStatusUpdate> _applyStatusChange(
    Todo todo,
    String targetStatus,
    DateTime timestamp, {
    bool save = true,
    bool triggerReload = true,
  }) async {
    try {
      _syncStatus(todo);
      final previous = todo.status;
      final updated = _transitionTodo(todo, targetStatus);
      if (!updated) {
        return const TodoStatusUpdate(false, 0);
      }

      final xpDelta = _calculateXpDelta(
        todo: todo,
        previousStatus: previous,
        targetStatus: targetStatus,
        timestamp: timestamp,
      );

      if (xpDelta != 0) {
        await _xpService.applyXpDelta(xpDelta);
        todo.xpApplied = true;
      }

      if (targetStatus == 'done') {
        todo.completedAt = timestamp;
      }

      if (targetStatus == 'done' ||
          targetStatus == 'missed' ||
          targetStatus == 'archived') {
        todo.isFocused = false;
        todo.focusDate = null;
      }

      await _logTransition(
        todo: todo,
        fromStatus: previous,
        toStatus: targetStatus,
        timestamp: timestamp,
        xpDelta: xpDelta,
      );

      if (save) {
        await todo.save();
      }
      if (triggerReload) {
        add(LoadTodos());
      }
      return TodoStatusUpdate(true, xpDelta);
    } catch (_) {
      return const TodoStatusUpdate(false, 0);
    }
  }

  int _calculateXpDelta({
    required Todo todo,
    required String previousStatus,
    required String targetStatus,
    required DateTime timestamp,
  }) {
    if (todo.xpApplied) {
      return 0;
    }

    if (targetStatus == 'missed') {
      return -1;
    }

    if (targetStatus == 'done' &&
        (previousStatus == 'active' || previousStatus == 'in_progress')) {
      final windowStart = todo.date;
      final windowEnd =
          todo.endTime ??
          DateTime(todo.date.year, todo.date.month, todo.date.day, 23, 59);

      if (timestamp.isBefore(windowStart)) {
        return 8;
      }
      if (!timestamp.isAfter(windowEnd)) {
        return 5;
      }
    }

    return 0;
  }

  void _syncFocus(Todo todo, DateTime now) {
    if (todo.isFocused && todo.focusDate != null) {
      if (!focus_utils.isSameDay(todo.focusDate!, now)) {
        todo.isFocused = false;
        todo.focusDate = null;
      }
    }
    if (todo.isFocused && !focus_utils.isEligibleForFocusStatus(todo.status)) {
      todo.isFocused = false;
      todo.focusDate = null;
    }
  }

  Future<void> _evaluateFocusBonus(List<Todo> todos, DateTime now) async {
    final focusTodos = todos
        .where((todo) => focus_utils.isFocusActive(todo, now))
        .toList();
    if (focusTodos.isEmpty) return;

    final bonusAlreadyAwarded = focusTodos.any(
      (todo) =>
          todo.focusBonusAwardedAt != null &&
          focus_utils.isSameDay(todo.focusBonusAwardedAt!, now),
    );
    if (bonusAlreadyAwarded) return;

    final allDone = focusTodos.every((todo) => todo.status == 'done');
    if (!allDone) return;

    await _xpService.applyXpDelta(focusBonusXp);
    for (final todo in focusTodos) {
      todo.focusBonusAwardedAt = now;
      await todo.save();
    }
  }

  Future<TodoStatusUpdate> updateTodoFocus(
    Todo todo,
    bool isFocused,
    DateTime timestamp,
  ) async {
    try {
      if (isFocused) {
        if (!focus_utils.isEligibleForFocusStatus(todo.status)) {
          return const TodoStatusUpdate(false, 0);
        }
        final box = Hive.box<Todo>(HiveBoxes.todos);
        final now = timestamp;
        final focusedCount = box.values
            .where((item) => focus_utils.isFocusActive(item, now))
            .length;
        if (!todo.isFocused && focusedCount >= 3) {
          return const TodoStatusUpdate(false, 0);
        }
        todo.isFocused = true;
        todo.focusDate = timestamp;
      } else {
        todo.isFocused = false;
        todo.focusDate = null;
      }
      await todo.save();
      add(LoadTodos());
      return const TodoStatusUpdate(true, 0);
    } catch (_) {
      return const TodoStatusUpdate(false, 0);
    }
  }

  Future<TodoStatusUpdate> updateTodoSubtasks(
    Todo todo,
    List<TodoSubtask> subtasks,
    DateTime timestamp,
  ) async {
    try {
      if (todo.status == 'archived' || todo.status == 'paused') {
        return const TodoStatusUpdate(false, 0);
      }
      if (subtasks.length > 5) {
        return const TodoStatusUpdate(false, 0);
      }
      todo.subtasks = subtasks;
      final allCompleted =
          subtasks.isNotEmpty && subtasks.every((item) => item.completed);
      if (allCompleted &&
          (todo.status == 'active' || todo.status == 'in_progress')) {
        return _applyStatusChange(todo, 'done', timestamp);
      }
      await todo.save();
      add(LoadTodos());
      return const TodoStatusUpdate(true, 0);
    } catch (_) {
      return const TodoStatusUpdate(false, 0);
    }
  }

  Future<TodoStatusUpdate> applyMemorizationOutcome(
    Todo todo, {
    required ReviewOutcome outcome,
    required DateTime timestamp,
  }) async {
    try {
      if (todo.category != 'Quran Memorization') {
        return const TodoStatusUpdate(false, 0);
      }
      final current =
          todo.reviewInterval ??
          (todo.reviewIntervalDays != null
              ? Duration(days: todo.reviewIntervalDays!)
              : baseMemorizationInterval);
      var nextInterval = current;
      var repeatCount = todo.reviewRepeatCount ?? 0;
      switch (outcome) {
        case ReviewOutcome.easy:
          nextInterval = scaleInterval(current, 2.5);
          repeatCount += 1;
          break;
        case ReviewOutcome.good:
          nextInterval = scaleInterval(current, 2.0);
          repeatCount += 1;
          break;
        case ReviewOutcome.hard:
          nextInterval = scaleInterval(current, 1.2);
          repeatCount += 1;
          break;
        case ReviewOutcome.forgot:
          nextInterval = baseMemorizationInterval;
          repeatCount = 0;
          todo.memorizationStatus = 'NEEDS_REVIEW';
          break;
      }

      todo.lastReviewedAt = timestamp;
      todo.reviewInterval = nextInterval;
      todo.reviewIntervalDays = nextInterval.inDays;
      todo.reviewDueDate = timestamp.add(nextInterval);
      todo.reviewRepeatCount = repeatCount;

      if (repeatCount >= masteredThreshold) {
        todo.memorizationStatus = 'MASTERED';
      } else if (todo.memorizationStatus == 'LEARNING' &&
          outcome != ReviewOutcome.forgot) {
        todo.memorizationStatus = 'REVIEW';
      }

      await todo.save();
      add(LoadTodos());
      return const TodoStatusUpdate(true, 0);
    } catch (_) {
      return const TodoStatusUpdate(false, 0);
    }
  }

  Future<void> _syncSubtaskCompletion(Todo todo, DateTime now) async {
    if (todo.subtasks.isEmpty) return;
    if (todo.status != 'active' && todo.status != 'in_progress') return;
    final allCompleted = todo.subtasks.every((item) => item.completed);
    if (!allCompleted) return;

    await _applyStatusChange(
      todo,
      'done',
      now,
      save: true,
      triggerReload: false,
    );
  }

  Future<void> _logTransition({
    required Todo todo,
    required String fromStatus,
    required String toStatus,
    required DateTime timestamp,
    required int xpDelta,
  }) async {
    final box = Hive.box<TodoTransition>(HiveBoxes.todoTransitions);
    final transition = TodoTransition(
      id: _uuid.v4(),
      todoId: todo.id,
      title: todo.title,
      fromStatus: fromStatus,
      toStatus: toStatus,
      timestamp: timestamp,
      xpDelta: xpDelta,
    );
    await box.add(transition);
  }
}

class TodoStatusUpdate {
  final bool success;
  final int xpDelta;

  const TodoStatusUpdate(this.success, this.xpDelta);
}

enum ReviewOutcome { easy, good, hard, forgot }
