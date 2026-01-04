import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/todo.dart';
import 'models/habit.dart';
import 'models/prayer.dart';
import 'models/user_model.dart';
import 'models/todo_transition.dart';
import 'models/duration_adapter.dart';
import 'blocs/todo_bloc.dart';
import 'blocs/habit_bloc.dart';
import 'blocs/prayer_bloc.dart';
import 'blocs/home_bloc.dart';
import 'blocs/quran_heart_bloc.dart';
import 'blocs/dashboard_bloc.dart';
import 'blocs/login_bloc.dart';
import 'blocs/register_bloc.dart';
import 'blocs/adhkar_bloc.dart';
import 'blocs/qibla_bloc.dart';
import 'blocs/daily_inspiration_bloc.dart';
import 'blocs/quran_bloc.dart';
import 'blocs/profile_bloc.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen/home_screen.dart';
import 'screens/login_screen/login_screen.dart';
import 'utils/constants.dart';
import 'utils/boxes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(TodoAdapter());
  Hive.registerAdapter(TodoTransitionAdapter());
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(PrayerAdapter());
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(DurationAdapter());

  // Open boxes
  await Hive.openBox<Todo>(HiveBoxes.todos);
  await Hive.openBox<Habit>(HiveBoxes.habits);
  await Hive.openBox<Prayer>(HiveBoxes.prayers);
  await Hive.openBox<TodoTransition>(HiveBoxes.todoTransitions);
  await Hive.openBox(HiveBoxes.quranMemorization);
  await Hive.openBox(HiveBoxes.user);
  await Hive.openBox<UserModel>(HiveBoxes.userProfiles);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => TodoBloc()..add(LoadTodos())),
          BlocProvider(create: (_) => HabitBloc()..add(LoadHabits())),
          BlocProvider(create: (_) => PrayerBloc()..add(LoadPrayers())),
          BlocProvider(create: (_) => HomeBloc()),
          BlocProvider(
            create: (_) => QuranHeartBloc()..add(LoadQuranHeartEvent()),
          ),
          BlocProvider(
            create: (context) => DashboardBloc(
              todoBloc: context.read<TodoBloc>(),
              habitBloc: context.read<HabitBloc>(),
            ),
          ),
          BlocProvider(
            create: (context) =>
                LoginBloc(authProvider: context.read<AuthProvider>()),
          ),
          BlocProvider(
            create: (context) =>
                RegisterBloc(authProvider: context.read<AuthProvider>()),
          ),
          BlocProvider(create: (_) => AdhkarBloc()..add(LoadAdhkarEvent())),
          BlocProvider(create: (_) => QiblaBloc()..add(LoadQiblaEvent())),
          BlocProvider(
            create: (_) =>
                DailyInspirationBloc()..add(LoadDailyInspirationEvent()),
          ),
          BlocProvider(create: (_) => QuranBloc()..add(LoadQuranEvent())),
          BlocProvider(
            create: (context) => ProfileBloc(
              authProvider: context.read<AuthProvider>(),
              themeProvider: context.read<ThemeProvider>(),
            ),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Productive Muslim',
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
        if (auth.isAuthenticated) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
