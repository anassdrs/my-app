import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/todo.dart';
import 'models/habit.dart';
import 'models/prayer.dart';
import 'models/user_model.dart';
import 'blocs/todo_bloc.dart';
import 'blocs/habit_bloc.dart';
import 'blocs/prayer_bloc.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen/home_screen.dart';
import 'screens/login_screen/login_screen.dart';
import 'utils/constants.dart';
import 'utils/boxes.dart';
import 'services/notification_service.dart';

void main() async {
  try {
    print("App starting...");
    WidgetsFlutterBinding.ensureInitialized();
    print("Widgets initialized");

    await Hive.initFlutter();
    print("Hive initialized");

    Hive.registerAdapter(TodoAdapter());
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(PrayerAdapter());
    Hive.registerAdapter(UserModelAdapter());
    print("Adapters registered");

    await Hive.openBox<Todo>(HiveBoxes.todos);
    await Hive.openBox<Habit>(HiveBoxes.habits);
    await Hive.openBox<Prayer>(HiveBoxes.prayers);
    await Hive.openBox(HiveBoxes.user);
    await Hive.openBox<UserModel>(HiveBoxes.userProfiles);
    print("Boxes opened");

    // Initialize notifications
    await NotificationService().init();
    print("Notifications initialized");
    await NotificationService().requestPermissions();
    print("Permissions requested");

    runApp(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => TodoBloc()..add(LoadTodos())),
          BlocProvider(create: (_) => HabitBloc()..add(LoadHabits())),
          BlocProvider(create: (_) => PrayerBloc()..add(LoadPrayers())),
        ],
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
          ],
          child: const MyApp(),
        ),
      ),
    );
    print("runApp called");
  } catch (e, stack) {
    print("FATAL ERROR DURING STARTUP: $e");
    print(stack);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Antigravity Todo & Habits',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        print("AuthWrapper: isAuthenticated = ${auth.isAuthenticated}");
        if (auth.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
