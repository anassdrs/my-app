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

  @HiveField(8)
  String frequencyType; // daily, weekly, custom_days

  @HiveField(9)
  int frequencyValue; // weekly count

  @HiveField(10)
  List<int> customDays; // 1 = Monday ... 7 = Sunday

  @HiveField(11)
  int windowStartMinutes;

  @HiveField(12)
  int windowEndMinutes;

  @HiveField(13)
  List<String> evaluatedDates;

  @HiveField(14)
  DateTime? lastEvaluatedDate;

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    DateTime? startTime,
    List<DateTime>? completedDates,
    this.streak = 0,
    this.category = 'General',
    this.habitType = 'general',
    this.frequencyType = 'daily',
    this.frequencyValue = 1,
    List<int>? customDays,
    int? windowStartMinutes,
    int? windowEndMinutes,
    List<String>? evaluatedDates,
    this.lastEvaluatedDate,
  }) : completedDates = completedDates ?? [],
       customDays = customDays ?? [],
       evaluatedDates = evaluatedDates ?? [],
       startTime = startTime ?? DateTime.now(),
       windowStartMinutes =
           windowStartMinutes ?? (startTime ?? DateTime.now()).hour * 60 +
               (startTime ?? DateTime.now()).minute,
       windowEndMinutes =
           windowEndMinutes ?? (startTime ?? DateTime.now()).hour * 60 +
               (startTime ?? DateTime.now()).minute +
               60;

  bool isCompletedOn(DateTime date) {
    return completedDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }
}
