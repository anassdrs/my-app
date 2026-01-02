import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../blocs/prayer_bloc.dart';
import '../../models/prayer.dart';
import '../../utils/constants.dart';
import '../../screens/add_edit_prayer_screen.dart';
import '../../screens/profile_screen/profile_screen.dart';
import '../../providers/auth_provider.dart';

class PrayerView extends StatelessWidget {
  const PrayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerBloc, PrayerState>(
      builder: (context, state) {
        if (state is PrayerInitial || state is PrayerLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PrayerLoaded) {
          return _buildPrayerView(context, state.prayers);
        } else if (state is PrayerError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const Center(child: Text('Unknown state'));
      },
    );
  }

  Widget _buildPrayerView(BuildContext context, List<Prayer> prayers) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'prayer_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditPrayerScreen()),
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
                  Text("Prayers", style: AppTextStyles.heading1),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileScreen()),
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
            Expanded(
              child: prayers.isEmpty
                  ? Center(
                      child: Text(
                        "No prayers tracked yet!",
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
                      itemCount: prayers.length + 1, // spacing
                      itemBuilder: (context, index) {
                        if (index == prayers.length) {
                          return const SizedBox();
                        }
                        final prayer = prayers[index];
                        return _buildPrayerCard(context, prayer);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCard(BuildContext context, Prayer prayer) {
    final isCompletedToday = prayer.isCompletedOn(DateTime.now());

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
                    FontAwesomeIcons.fire,
                    color: isCompletedToday ? Colors.orange : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${prayer.streak}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isCompletedToday ? Colors.orange : Colors.grey,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    "${prayer.latitude.toStringAsFixed(2)}, ${prayer.longitude.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prayer.name,
                style: AppTextStyles.heading2.copyWith(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (prayer.description.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  prayer.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 5),
              Text(
                "Time: ${TimeOfDay.fromDateTime(prayer.prayerTime).format(context)}",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.blue,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              final isCompleting = !prayer.isCompletedOn(DateTime.now());
              context.read<PrayerBloc>().add(
                TogglePrayerEvent(prayer, DateTime.now()),
              );

              if (isCompleting) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                auth.addExperience(15); // Prayers give more XP

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Prayer Completed! +15 XP"),
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
