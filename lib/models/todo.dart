import 'package:hive/hive.dart';

part 'todo.g.dart';

@HiveType(typeId: 0)
class Todo extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  DateTime? endTime;

  @HiveField(6)
  int priority; // 0 = Low, 1 = Medium, 2 = High

  @HiveField(7)
  String category;

  Todo({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.isCompleted = false,
    this.endTime,
    this.priority = 1, // Default to Medium
    this.category = 'General',
  });
}

enum TodoPriority {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case TodoPriority.low:
        return 'Low';
      case TodoPriority.medium:
        return 'Medium';
      case TodoPriority.high:
        return 'High';
    }
  }

  int get value {
    switch (this) {
      case TodoPriority.low:
        return 0;
      case TodoPriority.medium:
        return 1;
      case TodoPriority.high:
        return 2;
    }
  }

  static TodoPriority fromValue(int value) {
    switch (value) {
      case 0:
        return TodoPriority.low;
      case 2:
        return TodoPriority.high;
      default:
        return TodoPriority.medium;
    }
  }
}
