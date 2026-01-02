# Quick Start Guide - New Features

## 🎮 Gamification System

### How XP Works:
- **Complete a habit** → Earn **10 XP**
- **Level up** when you reach: `Current Level × 100 XP`
  - Level 1 → 2: Need 100 XP
  - Level 2 → 3: Need 200 XP
  - Level 3 → 4: Need 300 XP
  - And so on...

### Where to See Your Progress:
- **Dashboard**: Top left shows "Hello, [username]" with "Level X • Y XP" below
- **Habit Completion**: Snackbar appears with "+10 XP" message

### User Data:
- Stored in: `user_profiles_box` (Hive)
- Includes: email, username, XP, level, badges (array)

---

## 🔔 Notifications

### Setup (Automatic):
1. App requests permissions on first launch
2. Notifications are scheduled when you create/edit a habit

### How It Works:
- Each habit gets a **daily reminder** at its start time
- Notifications repeat every day at the same time
- Uses the habit's `startTime` field

### Customization:
```dart
// In add_edit_habit_screen.dart
NotificationService().scheduleDailyHabitNotification(
  id: habit.id.hashCode,  // Unique ID
  title: 'Habit Reminder: ${habit.title}',
  body: 'Time to complete your habit!',
  time: _startTime,  // TimeOfDay
);
```

### Cancel Notification:
```dart
NotificationService().cancelNotification(habitId.hashCode);
```

---

## 📊 Live Dashboard Analytics

### What's Shown:
- **Productivity Chart**: Last 7 days of habit completions
- **Y-axis**: Number of habits completed
- **X-axis**: Days of the week (Mon-Sun)

### Data Source:
```dart
// In HabitProvider
List<int> getLast7DaysStats() {
  // Returns array of completion counts for last 7 days
  // [day6ago, day5ago, ..., yesterday, today]
}
```

### Updates:
- **Real-time**: Chart updates immediately when you complete a habit
- **Automatic**: No manual refresh needed

---

## 🏷️ Categories (Foundation)

### Current Implementation:
- All habits have a `category` field (default: "General")
- Stored in Hive as `@HiveField(6)`

### Future Use:
```dart
// Filter habits by category
final healthHabits = habits.where((h) => h.category == 'Health');

// Group by category
final grouped = groupBy(habits, (h) => h.category);
```

---

## 🔧 Development Commands

### Regenerate Hive Adapters:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run the App:
```bash
flutter run
```

### Check for Issues:
```bash
flutter analyze
```

### Clean Build:
```bash
flutter clean
flutter pub get
```

---

## 📱 Testing Checklist

### Gamification:
- [ ] Register a new user
- [ ] Complete a habit
- [ ] Verify "+10 XP" snackbar appears
- [ ] Check dashboard shows level and XP
- [ ] Complete 10 habits to level up (100 XP)
- [ ] Verify level increases on dashboard

### Notifications:
- [ ] Create a habit with a specific time
- [ ] Grant notification permissions
- [ ] Verify notification appears at scheduled time
- [ ] Edit habit time, verify notification updates
- [ ] Delete habit, verify notification is cancelled

### Dashboard:
- [ ] Complete habits on different days
- [ ] Navigate to Dashboard
- [ ] Verify chart shows correct data
- [ ] Complete a habit, verify chart updates
- [ ] Check day labels are correct

---

## 🐛 Troubleshooting

### "User not found" after update:
- **Cause**: Old auth system used different storage
- **Fix**: Re-register your account

### Notifications not appearing:
- **Check**: Permissions granted in device settings
- **Check**: Notification time is in the future
- **Fix**: Recreate the habit to reschedule

### XP not increasing:
- **Check**: User is logged in (`auth.currentUser != null`)
- **Check**: Habit is being marked as complete (not uncomplete)
- **Debug**: Add print statement in `addExperience()` method

### Chart shows all zeros:
- **Cause**: No habits completed in last 7 days
- **Fix**: Complete some habits and check again

---

## 💡 Code Examples

### Award Custom XP:
```dart
// In any screen with AuthProvider access
final auth = Provider.of<AuthProvider>(context, listen: false);
auth.addExperience(50);  // Award 50 XP
```

### Check User Level:
```dart
Consumer<AuthProvider>(
  builder: (context, auth, _) {
    final level = auth.currentUser?.level ?? 1;
    if (level >= 10) {
      return Text('You are a master!');
    }
    return Text('Keep going!');
  },
)
```

### Schedule Custom Notification:
```dart
await NotificationService().scheduleDailyHabitNotification(
  id: 999,
  title: 'Custom Reminder',
  body: 'Don\'t forget!',
  time: TimeOfDay(hour: 20, minute: 0),  // 8:00 PM
);
```

---

## 📚 Key Files Reference

| Feature | Main Files |
|---------|-----------|
| Gamification | `models/user_model.dart`, `providers/auth_provider.dart` |
| Notifications | `services/notification_service.dart` |
| Dashboard | `screens/dashboard_view.dart`, `providers/habit_provider.dart` |
| Categories | `models/habit.dart` |

---

**Need Help?** Check `IMPROVEMENTS.md` for detailed implementation notes.
