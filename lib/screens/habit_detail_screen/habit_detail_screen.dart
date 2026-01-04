import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/habit.dart';
import '../../utils/constants.dart';
import '../habit_stats_screen/habit_stats_screen.dart';
import '../../blocs/habit_bloc.dart';
import '../../blocs/habit_detail_bloc.dart';

class HabitDetailScreen extends StatelessWidget {
  final Habit habit;
  const HabitDetailScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HabitDetailBloc(habitBloc: context.read<HabitBloc>())
            ..add(LoadHabitDetailEvent(habit.id)),
      child: const _HabitDetailView(),
    );
  }
}

class _HabitDetailView extends StatelessWidget {
  const _HabitDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitDetailBloc, HabitDetailState>(
      builder: (context, state) {
        if (state.isLoading || state.habit == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final h = state.habit!;

        return Scaffold(
          appBar: AppBar(
            title: Text(h.title, style: AppTextStyles.heading2),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.bar_chart, color: AppColors.secondary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HabitStatsScreen(habit: h),
                    ),
                  );
                },
                tooltip: 'View Statistics',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatCard(
                      "Streak",
                      "${h.streak} days",
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                    const SizedBox(width: 15),
                    _buildStatCard(
                      "Total",
                      "${h.completedDates.length} days",
                      Icons.check_circle,
                      AppColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text("History", style: AppTextStyles.heading2),
                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime(2020, 10, 16),
                    lastDay: DateTime(2030, 3, 14),
                    focusedDay: state.focusedDay,
                    calendarFormat: CalendarFormat.month,
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: AppColors.textPrimary,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: TextStyle(color: AppColors.textPrimary),
                      weekendTextStyle: TextStyle(color: AppColors.textPrimary),
                      outsideTextStyle: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    selectedDayPredicate: (day) => h.isCompletedOn(day),
                    onPageChanged: (focusedDay) {
                      context.read<HabitDetailBloc>().add(
                        UpdateFocusedDayEvent(focusedDay),
                      );
                    },
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        if (h.isCompletedOn(day)) {
                          return _buildCircle(
                            day,
                            AppColors.secondary,
                            Colors.white,
                          );
                        }
                        return null;
                      },
                      todayBuilder: (context, day, focusedDay) {
                        if (h.isCompletedOn(day)) {
                          return _buildCircle(
                            day,
                            AppColors.secondary,
                            Colors.white,
                          );
                        }
                        return _buildCircle(
                          day,
                          Colors.transparent,
                          AppColors.textPrimary,
                          border: true,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (h.description.isNotEmpty) ...[
                  Text("Description", style: AppTextStyles.heading2),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(h.description, style: AppTextStyles.bodyMedium),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircle(
    DateTime day,
    Color color,
    Color textColor, {
    bool border = false,
  }) {
    return Container(
      margin: const EdgeInsets.all(6.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border ? Border.all(color: AppColors.primary) : null,
      ),
      child: Text('${day.day}', style: TextStyle(color: textColor)),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(value, style: AppTextStyles.heading2.copyWith(fontSize: 20)),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
