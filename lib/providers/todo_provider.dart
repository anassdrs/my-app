import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo.dart';
import '../utils/boxes.dart';

class TodoProvider extends ChangeNotifier {
  List<Todo> get todos {
    final box = Hive.box<Todo>(HiveBoxes.todos);
    final list = box.values.toList();
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority);
      }
      return a.date.compareTo(b.date);
    });
    return list;
  }

  List<Todo> get incompleteTodos => todos.where((t) => !t.isCompleted).toList();
  List<Todo> get completedTodos => todos.where((t) => t.isCompleted).toList();

  Future<void> addTodo(Todo todo) async {
    final box = Hive.box<Todo>(HiveBoxes.todos);
    await box.add(todo);
    notifyListeners();
  }

  Future<void> updateTodo(Todo todo) async {
    await todo.save();
    notifyListeners();
  }

  Future<void> deleteTodo(Todo todo) async {
    await todo.delete();
    notifyListeners();
  }

  Future<void> toggleTodoStatus(Todo todo) async {
    todo.isCompleted = !todo.isCompleted;
    await todo.save();
    notifyListeners();
  }
}
