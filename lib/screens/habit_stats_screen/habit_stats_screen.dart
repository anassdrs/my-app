import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/habit.dart';
import '../../utils/constants.dart';
import '../../blocs/habit_bloc.dart';
import '../../blocs/habit_stats_bloc.dart';

class HabitStatsScreen extends StatelessWidget {
  final Habit habit;
  const HabitStatsScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HabitStatsBloc(habitBloc: context.read<HabitBloc>())
            ..add(LoadHabitStatsEvent(habit.id)),
      child: const _HabitStatsView(),
    );
  }
}

class _HabitStatsView extends StatelessWidget {
  const _HabitStatsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitStatsBloc, HabitStatsState>(
      builder: (context, state) {
        if (state.isLoading || state.habit == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final h = state.habit!;

        return Scaffold(
          appBar: AppBar(
            title: Text('Statistics', style: AppTextStyles.heading2),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.title, style: AppTextStyles.heading1),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    h.category,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Current Streak',
                        '${h.streak} days',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total Days',
                        '${h.completedDates.length}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Best Streak',
                        '${state.bestStreak} days',
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Success Rate',
                        '${state.successRate}%',
                        Icons.trending_up,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text('Monthly Progress', style: AppTextStyles.heading2),
                const SizedBox(height: 15),
                _buildMonthlyChart(context, state),
                const SizedBox(height: 30),
                Text('Weekly Pattern', style: AppTextStyles.heading2),
                const SizedBox(height: 15),
                _buildWeeklyHeatmap(context, state),
                const SizedBox(height: 30),
                Text('Last 30 Days', style: AppTextStyles.heading2),
                const SizedBox(height: 15),
                _buildCompletionHistory(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(BuildContext context, HabitStatsState state) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) => (val.toInt() % 5 == 0)
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${val.toInt() + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: state.last30Days
              .asMap()
              .entries
              .map(
                (e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value ? 1 : 0,
                      color: e.value
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.grey.withValues(alpha: 0.2),
                      width: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildWeeklyHeatmap(BuildContext context, HabitStatsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: state.weekdayStats.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: e.value / 100,
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${e.value.toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCompletionHistory(BuildContext context, HabitStatsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 30,
        itemBuilder: (context, index) {
          final d = state.last30DaysWithDates[index];
          final completed = d['completed'] as bool;
          final date = d['date'] as DateTime;
          return Tooltip(
            message: DateFormat('MMM d').format(date),
            child: Container(
              decoration: BoxDecoration(
                color: completed
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: completed ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
