import 'package:hive/hive.dart';

part 'prayer.g.dart';

@HiveType(typeId: 2)
class Prayer extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name; // Fajr, Dhuhr, Asr, Maghrib, Isha

  @HiveField(2)
  List<DateTime> completedDates;

  @HiveField(3)
  int streak;

  @HiveField(4)
  String description;

  @HiveField(5)
  DateTime prayerTime; // Calculated prayer time for today

  @HiveField(6)
  double latitude; // Location for prayer time calculation

  @HiveField(7)
  double longitude;

  @HiveField(8)
  int reminderMinutes;

  Prayer({
    required this.id,
    required this.name,
    this.description = '',
    required this.prayerTime,
    required this.latitude,
    required this.longitude,
    List<DateTime>? completedDates,
    this.streak = 0,
    this.reminderMinutes = 0,
  }) : completedDates = completedDates ?? [];

  bool isCompletedOn(DateTime date) {
    return completedDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  // Get prayer icon based on name
  String get iconName {
    switch (name.toLowerCase()) {
      case 'fajr':
        return 'dawn';
      case 'dhuhr':
        return 'sun';
      case 'asr':
        return 'afternoon';
      case 'maghrib':
        return 'sunset';
      case 'isha':
        return 'moon';
      default:
        return 'mosque';
    }
  }
}
