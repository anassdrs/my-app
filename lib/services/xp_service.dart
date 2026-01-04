import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_model.dart';
import '../utils/boxes.dart';

class XpService {
  Future<void> applyXpDelta(int delta) async {
    final sessionBox = Hive.box(HiveBoxes.user);
    final email = sessionBox.get('email') as String?;
    if (email == null) return;

    final userBox = Hive.box<UserModel>(HiveBoxes.userProfiles);
    final user = userBox.get(email);
    if (user == null) return;

    if (delta >= 0) {
      user.addXp(delta);
    } else {
      final updated = (user.xp + delta).clamp(0, user.xp);
      user.xp = updated.toInt();
    }

    await user.save();
  }
}
