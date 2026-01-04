import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/habit.dart';
import '../models/prayer.dart';
import '../models/todo.dart';
import '../models/user_model.dart';
import '../utils/boxes.dart';

class BackupService {
  static const int schemaVersion = 1;

  Future<String> createBackupJson() async {
    final todosBox = Hive.box<Todo>(HiveBoxes.todos);
    final habitsBox = Hive.box<Habit>(HiveBoxes.habits);
    final prayersBox = Hive.box<Prayer>(HiveBoxes.prayers);
    final userProfilesBox = Hive.box<UserModel>(HiveBoxes.userProfiles);
    final userBox = Hive.box(HiveBoxes.user);

    final data = <String, dynamic>{
      'version': schemaVersion,
      'todos': todosBox.values.map(_todoToMap).toList(),
      'habits': habitsBox.values.map(_habitToMap).toList(),
      'prayers': prayersBox.values.map(_prayerToMap).toList(),
      'userProfiles': userProfilesBox.values.map(_userToMap).toList(),
      'userSession': {
        'isAuthenticated': userBox.get('isAuthenticated', defaultValue: false),
        'email': userBox.get('email'),
      },
    };

    return jsonEncode(data);
  }

  Future<void> restoreFromJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup format.');
    }

    final version = decoded['version'];
    if (version != schemaVersion) {
      throw FormatException('Unsupported backup version: $version');
    }

    await _restoreTodos(decoded['todos'] as List<dynamic>?);
    await _restoreHabits(decoded['habits'] as List<dynamic>?);
    await _restorePrayers(decoded['prayers'] as List<dynamic>?);
    await _restoreUserProfiles(decoded['userProfiles'] as List<dynamic>?);
    await _restoreUserSession(decoded['userSession'] as Map<String, dynamic>?);
  }

  Map<String, dynamic> _todoToMap(Todo todo) {
    return {
      'id': todo.id,
      'title': todo.title,
      'description': todo.description,
      'date': todo.date.toIso8601String(),
      'isCompleted': todo.isCompleted,
      'endTime': todo.endTime?.toIso8601String(),
      'priority': todo.priority,
      'category': todo.category,
    };
  }

  Map<String, dynamic> _habitToMap(Habit habit) {
    return {
      'id': habit.id,
      'title': habit.title,
      'description': habit.description,
      'startTime': habit.startTime.toIso8601String(),
      'completedDates': habit.completedDates
          .map((date) => date.toIso8601String())
          .toList(),
      'streak': habit.streak,
      'category': habit.category,
      'habitType': habit.habitType,
      'frequencyType': habit.frequencyType,
      'frequencyValue': habit.frequencyValue,
      'customDays': habit.customDays,
      'windowStartMinutes': habit.windowStartMinutes,
      'windowEndMinutes': habit.windowEndMinutes,
      'evaluatedDates': habit.evaluatedDates,
      'lastEvaluatedDate': habit.lastEvaluatedDate?.toIso8601String(),
    };
  }

  Map<String, dynamic> _prayerToMap(Prayer prayer) {
    return {
      'id': prayer.id,
      'name': prayer.name,
      'description': prayer.description,
      'prayerTime': prayer.prayerTime.toIso8601String(),
      'latitude': prayer.latitude,
      'longitude': prayer.longitude,
      'completedDates': prayer.completedDates
          .map((date) => date.toIso8601String())
          .toList(),
      'streak': prayer.streak,
      'reminderMinutes': prayer.reminderMinutes,
    };
  }

  Map<String, dynamic> _userToMap(UserModel user) {
    return {
      'email': user.email,
      'password': user.password,
      'username': user.username,
      'xp': user.xp,
      'level': user.level,
      'badges': user.badges,
    };
  }

  Future<void> _restoreTodos(List<dynamic>? data) async {
    final todosBox = Hive.box<Todo>(HiveBoxes.todos);
    await todosBox.clear();
    if (data == null) return;

    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final todo = Todo(
        id: item['id'] as String,
        title: item['title'] as String? ?? '',
        description: item['description'] as String? ?? '',
        date: _parseDate(item['date'] as String?),
        isCompleted: item['isCompleted'] as bool? ?? false,
        endTime: _parseNullableDate(item['endTime'] as String?),
        priority: item['priority'] as int? ?? 1,
        category: item['category'] as String? ?? 'General',
      );
      await todosBox.add(todo);
    }
  }

  Future<void> _restoreHabits(List<dynamic>? data) async {
    final habitsBox = Hive.box<Habit>(HiveBoxes.habits);
    await habitsBox.clear();
    if (data == null) return;

    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final completed = _parseDateList(item['completedDates'] as List<dynamic>?);
      final habit = Habit(
        id: item['id'] as String,
        title: item['title'] as String? ?? '',
        description: item['description'] as String? ?? '',
        startTime: _parseDate(item['startTime'] as String?),
        completedDates: completed,
        streak: item['streak'] as int? ?? 0,
        category: item['category'] as String? ?? 'General',
        habitType: item['habitType'] as String? ?? 'general',
        frequencyType: item['frequencyType'] as String? ?? 'daily',
        frequencyValue: item['frequencyValue'] as int? ?? 1,
        customDays: (item['customDays'] as List<dynamic>?)
            ?.map((value) => value as int)
            .toList(),
        windowStartMinutes: item['windowStartMinutes'] as int?,
        windowEndMinutes: item['windowEndMinutes'] as int?,
        evaluatedDates: (item['evaluatedDates'] as List<dynamic>?)
            ?.map((value) => value.toString())
            .toList(),
        lastEvaluatedDate: _parseNullableDate(
          item['lastEvaluatedDate'] as String?,
        ),
      );
      await habitsBox.add(habit);
    }
  }

  Future<void> _restorePrayers(List<dynamic>? data) async {
    final prayersBox = Hive.box<Prayer>(HiveBoxes.prayers);
    await prayersBox.clear();
    if (data == null) return;

    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final completed = _parseDateList(item['completedDates'] as List<dynamic>?);
      final prayer = Prayer(
        id: item['id'] as String,
        name: item['name'] as String? ?? '',
        description: item['description'] as String? ?? '',
        prayerTime: _parseDate(item['prayerTime'] as String?),
        latitude: (item['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (item['longitude'] as num?)?.toDouble() ?? 0,
        completedDates: completed,
        streak: item['streak'] as int? ?? 0,
        reminderMinutes: item['reminderMinutes'] as int? ?? 0,
      );
      await prayersBox.add(prayer);
    }
  }

  Future<void> _restoreUserProfiles(List<dynamic>? data) async {
    final userBox = Hive.box<UserModel>(HiveBoxes.userProfiles);
    await userBox.clear();
    if (data == null) return;

    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final user = UserModel(
        email: item['email'] as String,
        password: item['password'] as String? ?? '',
        username: item['username'] as String? ?? '',
        xp: item['xp'] as int? ?? 0,
        level: item['level'] as int? ?? 1,
        badges:
            (item['badges'] as List<dynamic>?)
                ?.map((badge) => badge.toString())
                .toList() ??
            const [],
      );
      await userBox.put(user.email, user);
    }
  }

  Future<void> _restoreUserSession(Map<String, dynamic>? data) async {
    final sessionBox = Hive.box(HiveBoxes.user);
    await sessionBox.clear();
    if (data == null) return;

    await sessionBox.put(
      'isAuthenticated',
      data['isAuthenticated'] as bool? ?? false,
    );
    if (data['email'] != null) {
      await sessionBox.put('email', data['email']);
    }
  }

  DateTime _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now();
    }
    return DateTime.parse(value);
  }

  DateTime? _parseNullableDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.parse(value);
  }

  List<DateTime> _parseDateList(List<dynamic>? values) {
    if (values == null) return [];
    return values
        .map((value) => DateTime.parse(value.toString()))
        .toList();
  }
}
