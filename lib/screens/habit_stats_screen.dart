import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../utils/constants.dart';

class HabitStatsScreen extends StatelessWidget {
  final Habit habit;

  const HabitStatsScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
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
            // Habit Title and Category
            Text(habit.title, style: AppTextStyles.heading1),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                habit.category,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Stats Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Current Streak',
                    '${habit.streak} days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Days',
                    '${habit.completedDates.length}',
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
                    '${_calculateBestStreak(habit)} days',
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Success Rate',
                    '${_calculateSuccessRate(habit)}%',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Monthly Progress Chart
            Text('Monthly Progress', style: AppTextStyles.heading2),
            const SizedBox(height: 15),
            _buildMonthlyChart(context, habit),

            const SizedBox(height: 30),

            // Weekly Heatmap
            Text('Weekly Pattern', style: AppTextStyles.heading2),
            const SizedBox(height: 15),
            _buildWeeklyHeatmap(context, habit),

            const SizedBox(height: 30),

            // Completion History
            Text('Last 30 Days', style: AppTextStyles.heading2),
            const SizedBox(height: 15),
            _buildCompletionHistory(context, habit),
          ],
        ),
      ),
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(BuildContext context, Habit habit) {
    final last30Days = _getLast30DaysData(habit);

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
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() % 5 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${value.toInt() + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: last30Days.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value ? 1 : 0,
                  color: entry.value
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.grey.withOpacity(0.2),
                  width: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWeeklyHeatmap(BuildContext context, Habit habit) {
    final weekdayStats = _getWeekdayStats(habit);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: weekdayStats.entries.map((entry) {
          final percentage = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    entry.key,
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
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage / 100,
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
                    '${percentage.toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompletionHistory(BuildContext context, Habit habit) {
    final last30Days = _getLast30DaysWithDates(habit);

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
          final dayData = last30Days[index];
          final isCompleted = dayData['completed'] as bool;
          final date = dayData['date'] as DateTime;

          return Tooltip(
            message: DateFormat('MMM d').format(date),
            child: Container(
              decoration: BoxDecoration(
                color: isCompleted
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper methods
  int _calculateBestStreak(Habit habit) {
    if (habit.completedDates.isEmpty) return 0;

    final sortedDates = habit.completedDates.toList()
      ..sort((a, b) => a.compareTo(b));

    int bestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }

    return bestStreak;
  }

  int _calculateSuccessRate(Habit habit) {
    final daysSinceStart =
        DateTime.now().difference(habit.startTime).inDays + 1;
    if (daysSinceStart == 0) return 0;

    final completionRate = (habit.completedDates.length / daysSinceStart * 100);
    return completionRate.clamp(0, 100).toInt();
  }

  List<bool> _getLast30DaysData(Habit habit) {
    final List<bool> data = [];
    final now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      data.add(habit.isCompletedOn(date));
    }

    return data;
  }

  List<Map<String, dynamic>> _getLast30DaysWithDates(Habit habit) {
    final List<Map<String, dynamic>> data = [];
    final now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      data.add({'date': date, 'completed': habit.isCompletedOn(date)});
    }

    return data;
  }

  Map<String, double> _getWeekdayStats(Habit habit) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final counts = List<int>.filled(7, 0);
    final totals = List<int>.filled(7, 0);

    // Count completions per weekday
    for (final date in habit.completedDates) {
      final weekday = date.weekday - 1; // 0 = Monday
      counts[weekday]++;
    }

    // Count total days per weekday since start
    final daysSinceStart =
        DateTime.now().difference(habit.startTime).inDays + 1;
    final startWeekday = habit.startTime.weekday - 1;

    for (int i = 0; i < daysSinceStart; i++) {
      final weekday = (startWeekday + i) % 7;
      totals[weekday]++;
    }

    // Calculate percentages
    final Map<String, double> stats = {};
    for (int i = 0; i < 7; i++) {
      final percentage = totals[i] > 0 ? (counts[i] / totals[i] * 100) : 0.0;
      stats[weekdays[i]] = percentage;
    }

    return stats;
  }
}
