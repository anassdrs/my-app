import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import '../../blocs/habit_bloc.dart';
import '../../blocs/dashboard_bloc.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/stat_card.dart';
import '../profile_screen/profile_screen.dart';
import '../quran_heart_screen/quran_heart_screen.dart';
import '../../models/todo.dart';
import '../../models/habit.dart';
import '../../widgets/app_card.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final user = auth.currentUser;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hello, ${user?.username ?? 'User'}",
                                style: AppTextStyles.heading1.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              if (user != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "Level ${user.level} • ${user.xp} XP",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "Let's be productive today.",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _QuranHeartCard(todos: state.todos),
                  const SizedBox(height: 30),
                  _buildProductivityChart(context, state.habits),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TableCalendar(
                      firstDay: DateTime(2020, 1, 1),
                      lastDay: DateTime(2030, 12, 31),
                      focusedDay: DateTime.now(),
                      calendarFormat: CalendarFormat.week,
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        weekendTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: _buildTodoStat(context, state.todos)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildHabitStat(context, state.habits)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductivityChart(BuildContext context, List<Habit> habits) {
    final stats = context.read<HabitBloc>().getLast7DaysStats(habits);
    final spots = List.generate(stats.length, (index) {
      return FlSpot(index.toDouble(), stats[index].toDouble());
    });

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < 7) {
                    DateTime date = DateTime.now().subtract(
                      Duration(days: 6 - index),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _getDayName(date.weekday),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                interval: 1,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              ),
            ),
          ],
          minX: 0,
          maxX: 6,
          minY: 0,
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Widget _buildTodoStat(BuildContext context, List<Todo> todos) {
    final total = todos.length;
    final completed = todos.where((todo) => todo.isCompleted).length;
    return StatCard(
      title: "Tasks",
      value: "$completed / $total",
      icon: Icons.check_circle_outline,
      color: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildHabitStat(BuildContext context, List<Habit> habits) {
    int maxStreak = 0;
    for (var h in habits) {
      if (h.streak > maxStreak) maxStreak = h.streak;
    }
    return StatCard(
      title: "Best Streak",
      value: "$maxStreak days",
      icon: Icons.local_fire_department_outlined,
      color: Colors.orangeAccent,
    );
  }
}

class _QuranHeartCard extends StatelessWidget {
  final List<Todo> todos;
  static const String _assetPath = 'assets/heart.svg';

  const _QuranHeartCard({required this.todos});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const QuranHeartScreen()));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quran Heart",
            style: AppTextStyles.heading2.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "Surahs marked as mastered turn red.",
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: rootBundle.loadString(_assetPath),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final baseSvg = snapshot.data ?? '';
              final mastered = todos
                  .where(
                    (todo) =>
                        todo.category == 'Quran Memorization' &&
                        todo.memorizationStatus == 'MASTERED' &&
                        todo.surahNumber != null,
                  )
                  .map((todo) => todo.surahNumber!)
                  .toSet();
              final coloredSvg = _applySurahColors(baseSvg, mastered);
              return AspectRatio(
                aspectRatio: 1,
                child: SvgPicture.string(coloredSvg, fit: BoxFit.contain),
              );
            },
          ),
        ],
      ),
    );
  }

  String _applySurahColors(String svg, Set<int> masteredSurahs) {
    var result = svg;
    for (final surah in masteredSurahs) {
      final pattern = RegExp('<path([^>]*?)id="surah_$surah"([^>]*)/>');
      result = result.replaceAllMapped(pattern, (match) {
        final full = match.group(0) ?? '';
        if (full.contains(' fill=')) {
          return full.replaceAll(RegExp(r'fill="[^"]*"'), 'fill="#ef4444"');
        }
        return full.replaceFirst('/>', ' fill="#ef4444"/>');
      });
    }
    return result;
  }
}
