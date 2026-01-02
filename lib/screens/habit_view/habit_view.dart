import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../blocs/habit_bloc.dart';
import '../../models/habit.dart';
import '../../utils/constants.dart';
import '../add_edit_habit_screen/add_edit_habit_screen.dart';
import '../habit_detail_screen/habit_detail_screen.dart';
import '../profile_screen/profile_screen.dart';
import '../../providers/auth_provider.dart';
import '../habit_stats_screen.dart';

class HabitView extends StatelessWidget {
  const HabitView({super.key});

  static const List<_HabitTemplate> _templates = [
    _HabitTemplate(
      title: 'Drink Water',
      description: 'Stay hydrated throughout the day.',
      icon: Icons.water_drop,
      color: Color(0xFF2563EB),
    ),
    _HabitTemplate(
      title: 'Morning Stretch',
      description: 'Loosen up for 5 minutes.',
      icon: Icons.self_improvement,
      color: Color(0xFF16A34A),
    ),
    _HabitTemplate(
      title: 'Daily Walk',
      description: '10 minute outdoor walk.',
      icon: Icons.directions_walk,
      color: Color(0xFFF97316),
    ),
    _HabitTemplate(
      title: 'Focus Sprint',
      description: '25 minutes deep work.',
      icon: Icons.timer,
      color: Color(0xFF0EA5E9),
    ),
    _HabitTemplate(
      title: 'Plan Tomorrow',
      description: 'Pick your top 3 tasks.',
      icon: Icons.event_note,
      color: Color(0xFF7C3AED),
    ),
    _HabitTemplate(
      title: 'Strength Set',
      description: 'Push-ups, squats, or planks.',
      icon: Icons.fitness_center,
      color: Color(0xFFEF4444),
    ),
    _HabitTemplate(
      title: 'Fajr',
      description: 'Start the day with prayer.',
      icon: Icons.mosque,
      color: Color(0xFF059669),
      habitType: 'prayer',
    ),
    _HabitTemplate(
      title: 'Dhuhr',
      description: 'Midday prayer.',
      icon: Icons.mosque,
      color: Color(0xFF16A34A),
      habitType: 'prayer',
    ),
    _HabitTemplate(
      title: 'Asr',
      description: 'Afternoon prayer.',
      icon: Icons.mosque,
      color: Color(0xFF10B981),
      habitType: 'prayer',
    ),
    _HabitTemplate(
      title: 'Maghrib',
      description: 'Sunset prayer.',
      icon: Icons.mosque,
      color: Color(0xFF22C55E),
      habitType: 'prayer',
    ),
    _HabitTemplate(
      title: 'Isha',
      description: 'Night prayer.',
      icon: Icons.mosque,
      color: Color(0xFF0F766E),
      habitType: 'prayer',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitBloc, HabitState>(
      builder: (context, state) {
        if (state is HabitInitial || state is HabitLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is HabitLoaded) {
          return _buildHabitView(context, state.habits);
        } else if (state is HabitError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const Center(child: Text('Unknown state'));
      },
    );
  }

  Widget _buildHabitView(BuildContext context, List<Habit> habits) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'habit_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
          );
        },
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Habits", style: AppTextStyles.heading1),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.secondary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            _buildQuickAdd(context),
            const SizedBox(height: 12),
            Expanded(
              child: habits.isEmpty
                  ? Center(
                      child: Text(
                        "No habits tracked yet!",
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.72,
                          ),
                      itemCount: habits.length + 1, // spacing
                      itemBuilder: (context, index) {
                        if (index == habits.length) {
                          return const SizedBox();
                        }
                        final habit = habits[index];
                        return _buildHabitCard(context, habit);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAdd(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quick Start', style: AppTextStyles.heading2),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddEditHabitScreen(),
                    ),
                  );
                },
                child: const Text('Custom'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final template = _templates[index];
              return _buildTemplateCard(context, template);
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: _templates.length,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(BuildContext context, _HabitTemplate template) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditHabitScreen(
              initialTitle: template.title,
              initialDescription: template.description,
              initialHabitType: template.habitType,
            ),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.height * 0.2,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: template.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: template.color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: template.color.withOpacity(0.2),
              child: Icon(template.icon, color: template.color),
            ),
            const SizedBox(height: 10),
            Text(
              template.title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              template.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(BuildContext context, Habit habit) {
    final isCompletedToday = habit.isCompletedOn(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isCompletedToday
            ? Border.all(color: AppColors.secondary, width: 2)
            : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    habit.habitType == 'prayer'
                        ? Icons.mosque
                        : FontAwesomeIcons.fire,
                    color: isCompletedToday
                        ? (habit.habitType == 'prayer'
                              ? AppColors.secondary
                              : Colors.orange)
                        : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${habit.streak}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isCompletedToday
                          ? (habit.habitType == 'prayer'
                                ? AppColors.secondary
                                : Colors.orange)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    TimeOfDay.fromDateTime(habit.startTime).format(context),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HabitStatsScreen(habit: habit),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.bar_chart,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HabitDetailScreen(habit: habit),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: AppTextStyles.heading2.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (habit.description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    habit.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              final isCompleting = !habit.isCompletedOn(DateTime.now());
              context.read<HabitBloc>().add(
                ToggleHabitEvent(habit, DateTime.now()),
              );

              if (isCompleting) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                auth.addExperience(10);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Habit Completed! +10 XP"),
                    duration: const Duration(seconds: 1),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isCompletedToday
                    ? AppColors.secondary
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                isCompletedToday ? Icons.check : Icons.circle_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitTemplate {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String habitType;

  const _HabitTemplate({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.habitType = 'general',
  });
}
