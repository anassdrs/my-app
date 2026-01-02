import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 3)
class UserModel extends HiveObject {
  @HiveField(0)
  final String email;

  @HiveField(1)
  final String password; // In a real app, hash this!

  @HiveField(2)
  String username;

  @HiveField(3)
  int xp;

  @HiveField(4)
  int level;

  @HiveField(5)
  List<String> badges;

  UserModel({
    required this.email,
    required this.password,
    this.username = '',
    this.xp = 0,
    this.level = 1,
    this.badges = const [],
  });

  void addXp(int amount) {
    xp += amount;
    // Simple level up logic: e.g. Level * 100 XP to level up
    int xpToNextLevel = level * 100;
    while (xp >= xpToNextLevel) {
      xp -= xpToNextLevel;
      level++;
      xpToNextLevel = level * 100;
    }
  }
}
