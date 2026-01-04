import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/habit.dart';
import 'habit_bloc.dart';

// --- Events ---
abstract class HabitStatsEvent {}

class LoadHabitStatsEvent extends HabitStatsEvent {
  final String habitId;
  LoadHabitStatsEvent(this.habitId);
}

// --- States ---
class HabitStatsState {
  final Habit? habit;
  final int bestStreak;
  final int successRate;
  final List<bool> last30Days;
  final List<Map<String, dynamic>> last30DaysWithDates;
  final Map<String, double> weekdayStats;
  final bool isLoading;

  HabitStatsState({
    this.habit,
    this.bestStreak = 0,
    this.successRate = 0,
    this.last30Days = const [],
    this.last30DaysWithDates = const [],
    this.weekdayStats = const {},
    this.isLoading = true,
  });

  HabitStatsState copyWith({
    Habit? habit,
    int? bestStreak,
    int? successRate,
    List<bool>? last30Days,
    List<Map<String, dynamic>>? last30DaysWithDates,
    Map<String, double>? weekdayStats,
    bool? isLoading,
  }) {
    return HabitStatsState(
      habit: habit ?? this.habit,
      bestStreak: bestStreak ?? this.bestStreak,
      successRate: successRate ?? this.successRate,
      last30Days: last30Days ?? this.last30Days,
      last30DaysWithDates: last30DaysWithDates ?? this.last30DaysWithDates,
      weekdayStats: weekdayStats ?? this.weekdayStats,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- BLoC ---
class HabitStatsBloc extends Bloc<HabitStatsEvent, HabitStatsState> {
  final HabitBloc habitBloc;

  HabitStatsBloc({required this.habitBloc}) : super(HabitStatsState()) {
    on<LoadHabitStatsEvent>((event, emit) {
      if (habitBloc.state is! HabitLoaded) return;
      final habit = (habitBloc.state as HabitLoaded).habits.firstWhere(
        (h) => h.id == event.habitId,
      );

      emit(
        state.copyWith(
          habit: habit,
          bestStreak: _calculateBestStreak(habit),
          successRate: _calculateSuccessRate(habit),
          last30Days: _getLast30DaysData(habit),
          last30DaysWithDates: _getLast30DaysWithDates(habit),
          weekdayStats: _getWeekdayStats(habit),
          isLoading: false,
        ),
      );
    });
  }

  int _calculateBestStreak(Habit habit) {
    if (habit.completedDates.isEmpty) return 0;
    final sorted = habit.completedDates.toList()
      ..sort((a, b) => a.compareTo(b));
    int best = 1, current = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  int _calculateSuccessRate(Habit habit) {
    final days = DateTime.now().difference(habit.startTime).inDays + 1;
    if (days <= 0) return 0;
    return (habit.completedDates.length / days * 100).clamp(0, 100).toInt();
  }

  List<bool> _getLast30DaysData(Habit habit) {
    final now = DateTime.now();
    return List.generate(
      30,
      (i) => habit.isCompletedOn(now.subtract(Duration(days: 29 - i))),
    );
  }

  List<Map<String, dynamic>> _getLast30DaysWithDates(Habit habit) {
    final now = DateTime.now();
    return List.generate(30, (i) {
      final d = now.subtract(Duration(days: 29 - i));
      return {'date': d, 'completed': habit.isCompletedOn(d)};
    });
  }

  Map<String, double> _getWeekdayStats(Habit habit) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final counts = List<int>.filled(7, 0);
    final totals = List<int>.filled(7, 0);
    for (final d in habit.completedDates) {
      counts[d.weekday - 1]++;
    }
    final days = DateTime.now().difference(habit.startTime).inDays + 1;
    final startWeekday = habit.startTime.weekday - 1;
    for (int i = 0; i < days; i++) {
      totals[(startWeekday + i) % 7]++;
    }
    final Map<String, double> stats = {};
    for (int i = 0; i < 7; i++) {
      stats[weekdays[i]] = totals[i] > 0 ? (counts[i] / totals[i] * 100) : 0.0;
    }
    return stats;
  }
}
