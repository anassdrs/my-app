import 'package:hive/hive.dart';

part 'todo_transition.g.dart';

@HiveType(typeId: 5)
class TodoTransition extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String todoId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String fromStatus;

  @HiveField(4)
  final String toStatus;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final int xpDelta;

  TodoTransition({
    required this.id,
    required this.todoId,
    required this.title,
    required this.fromStatus,
    required this.toStatus,
    required this.timestamp,
    required this.xpDelta,
  });
}
