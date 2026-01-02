import 'dart:async';

import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../blocs/prayer_bloc.dart';
import '../../models/prayer.dart';
import '../../providers/auth_provider.dart';
import '../../screens/add_edit_prayer_screen.dart';
import '../../screens/profile_screen/profile_screen.dart';
import '../../services/prayer_time_service.dart';
import '../../utils/constants.dart';
import 'adhkar_screen.dart';
import 'qibla_screen.dart';

class PrayerView extends StatefulWidget {
  const PrayerView({super.key});

  @override
  State<PrayerView> createState() => _PrayerViewState();
}

class _PrayerViewState extends State<PrayerView> {
  final PrayerTimeService _service = PrayerTimeService();
  adhan.PrayerTimes? _prayerTimes;
  bool _isFallback = false;
  String _locationLabel = 'Loading location...';
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    final result = await _service.getPrayerTimes();
    if (!mounted) return;
    setState(() {
      _prayerTimes = result.prayerTimes;
      _isFallback = result.usedFallback;
      _locationLabel = result.locationLabel;
    });
  }

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
            MaterialPageRoute(builder: (_) => const AddEditPrayerScreen()),
          );
        },
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadPrayerTimes,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildOverviewCard(context),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildTimesCard(context),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildQuickActions(context),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Tracked Prayers",
                  style: AppTextStyles.heading2,
                ),
              ),
              const SizedBox(height: 12),
              if (prayers.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      "No prayers tracked yet!",
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: prayers.length + 1,
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
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final nextPrayer = _getNextPrayer();
    final remaining = _getRemainingTime(nextPrayer?.time);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Next Prayer",
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            nextPrayer?.label ?? "Loading...",
            style: AppTextStyles.heading1.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            remaining ?? "--:--:--",
            style: AppTextStyles.heading2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _locationLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
              if (_isFallback)
                Text(
                  "Fallback",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimesCard(BuildContext context) {
    final times = _prayerTimes;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Times", style: AppTextStyles.heading2),
              IconButton(
                onPressed: _loadPrayerTimes,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildTimeRow(context, "Fajr", times?.fajr),
          _buildTimeRow(context, "Sunrise", times?.sunrise),
          _buildTimeRow(context, "Dhuhr", times?.dhuhr),
          _buildTimeRow(context, "Asr", times?.asr),
          _buildTimeRow(context, "Maghrib", times?.maghrib),
          _buildTimeRow(context, "Isha", times?.isha),
        ],
      ),
    );
  }

  Widget _buildTimeRow(BuildContext context, String label, DateTime? time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyLarge),
          Text(
            time == null ? "--:--" : TimeOfDay.fromDateTime(time).format(context),
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: "Qibla",
            subtitle: "Compass",
            icon: Icons.explore,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QiblaScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            title: "Adhkar",
            subtitle: "Tasbih",
            icon: Icons.auto_awesome,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdhkarScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  _NextPrayerInfo? _getNextPrayer() {
    final times = _prayerTimes;
    if (times == null) return null;
    final next = times.nextPrayerByDateTime(_now);
    if (next == adhan.Prayer.none) {
      final tomorrow = _now.add(const Duration(days: 1));
      final coords = times.coordinates;
      final params = times.calculationParameters;
      final dateComponents = adhan.DateComponents(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
      );
      final nextTimes = adhan.PrayerTimes(coords, dateComponents, params);
      return _NextPrayerInfo(
        label: "Fajr",
        time: nextTimes.fajr,
      );
    }
    final nextTime = times.timeForPrayer(next);
    return _NextPrayerInfo(
      label: _labelForPrayer(next),
      time: nextTime,
    );
  }

  String _labelForPrayer(adhan.Prayer prayer) {
    switch (prayer) {
      case adhan.Prayer.fajr:
        return "Fajr";
      case adhan.Prayer.sunrise:
        return "Sunrise";
      case adhan.Prayer.dhuhr:
        return "Dhuhr";
      case adhan.Prayer.asr:
        return "Asr";
      case adhan.Prayer.maghrib:
        return "Maghrib";
      case adhan.Prayer.isha:
        return "Isha";
      case adhan.Prayer.none:
      default:
        return "Fajr";
    }
  }

  String? _getRemainingTime(DateTime? target) {
    if (target == null) return null;
    final diff = target.difference(_now);
    if (diff.isNegative) return null;
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  Widget _buildPrayerCard(BuildContext context, Prayer prayer) {
    final isCompletedToday = prayer.isCompletedOn(DateTime.now());
    final locationLabel = _formatLocation(prayer);

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
                    locationLabel,
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
              if (prayer.reminderMinutes > 0) ...[
                const SizedBox(height: 4),
                Text(
                  "Reminder: ${prayer.reminderMinutes} min before",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
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
                auth.addExperience(15);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Prayer Completed! +15 XP"),
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

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextPrayerInfo {
  final String label;
  final DateTime? time;

  const _NextPrayerInfo({required this.label, required this.time});
}

String _formatLocation(Prayer prayer) {
  try {
    if (!prayer.latitude.isFinite || !prayer.longitude.isFinite) {
      return "Location unavailable";
    }
    return "${prayer.latitude.toStringAsFixed(2)}, ${prayer.longitude.toStringAsFixed(2)}";
  } catch (_) {
    return "Location unavailable";
  }
}
