import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 1)
class Habit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  List<DateTime> completedDates;

  @HiveField(3)
  int streak;

  @HiveField(4)
  String description;

  @HiveField(5)
  DateTime startTime;

  @HiveField(6)
  String category;

  @HiveField(7)
  String habitType; // 'general' or 'prayer'

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    DateTime? startTime,
    List<DateTime>? completedDates,
    this.streak = 0,
    this.category = 'General',
    this.habitType = 'general',
  }) : completedDates = completedDates ?? [],
       startTime = startTime ?? DateTime.now();

  bool isCompletedOn(DateTime date) {
    return completedDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }
}
