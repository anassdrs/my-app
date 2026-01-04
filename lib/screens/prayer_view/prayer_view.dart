import 'dart:async';

import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../blocs/prayer_bloc.dart';
import '../../models/prayer.dart';
import '../../providers/auth_provider.dart';
import '../add_edit_prayer_screen/add_edit_prayer_screen.dart';
import '../profile_screen/profile_screen.dart';
import '../../services/daily_inspiration_service.dart';
import '../../services/prayer_time_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_card.dart';
import '../../widgets/tracked_item_card.dart';
import '../adhkar_screen/adhkar_screen.dart';
import '../daily_inspiration_screen/daily_inspiration_screen.dart';
import '../qibla_screen/qibla_screen.dart';
import '../quran_screen/quran_screen.dart';

class PrayerView extends StatefulWidget {
  const PrayerView({super.key});

  @override
  State<PrayerView> createState() => _PrayerViewState();
}

class _PrayerViewState extends State<PrayerView> {
  final PrayerTimeService _service = PrayerTimeService();
  final DailyInspirationService _inspirationService = DailyInspirationService();
  adhan.PrayerTimes? _prayerTimes;
  bool _isFallback = false;
  String _locationLabel = 'Loading location...';
  Timer? _ticker;
  DateTime _now = DateTime.now();
  DailyInspirationSet? _dailySet;
  bool _inspirationLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    _loadDailyInspiration();
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

  Future<void> _loadDailyInspiration() async {
    try {
      final data = await _inspirationService.loadToday();
      if (!mounted) return;
      setState(() {
        _dailySet = data;
        _inspirationLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _inspirationLoading = false);
    }
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildDailyInspiration(context),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildQuranCard(context),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text("Tracked Prayers", style: AppTextStyles.heading2),
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
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 20,
      backgroundColor: Colors.transparent,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 16,
          offset: const Offset(0, 10),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
            ],
          ),
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
      ),
    );
  }

  Widget _buildTimesCard(BuildContext context) {
    final times = _prayerTimes;
    return AppCard(
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
            time == null
                ? "--:--"
                : TimeOfDay.fromDateTime(time).format(context),
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

  Widget _buildDailyInspiration(BuildContext context) {
    if (_inspirationLoading) {
      return const Center(child: LinearProgressIndicator());
    }
    if (_dailySet == null) {
      return _simpleCard(
        context,
        title: "Daily Inspiration",
        child: Text(
          "Unable to load today's inspiration.",
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    return _simpleCard(
      context,
      title: "Daily Inspiration",
      action: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyInspirationScreen()),
          );
        },
        child: const Text("Open"),
      ),
      child: Column(
        children: [
          _InspirationTile(
            label: "Verse",
            arabic: _dailySet!.verse.arabic,
            source: _dailySet!.verse.source,
          ),
          const SizedBox(height: 10),
          _InspirationTile(
            label: "Hadith",
            arabic: _dailySet!.hadith.arabic,
            source: _dailySet!.hadith.source,
          ),
          const SizedBox(height: 10),
          _InspirationTile(
            label: "Value",
            arabic: _dailySet!.value.arabic,
            source: _dailySet!.value.source,
          ),
        ],
      ),
    );
  }

  Widget _buildQuranCard(BuildContext context) {
    return _simpleCard(
      context,
      title: "Quran",
      action: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuranScreen()),
          );
        },
        child: const Text("Read"),
      ),
      child: Text(
        "Read Quran with Arabic, English, and French translation.",
        style: AppTextStyles.bodyMedium,
      ),
    );
  }

  Widget _simpleCard(
    BuildContext context, {
    required String title,
    required Widget child,
    Widget? action,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.heading2),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
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
      return _NextPrayerInfo(label: "Fajr", time: nextTimes.fajr);
    }
    final nextTime = times.timeForPrayer(next);
    return _NextPrayerInfo(label: _labelForPrayer(next), time: nextTime);
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

    return TrackedItemCard(
      isCompleted: isCompletedToday,
      streak: prayer.streak,
      streakIcon: FontAwesomeIcons.fire,
      streakColor: Colors.orange,
      title: prayer.name,
      description: prayer.description,
      infoLines: [
        Text(
          "Time: ${TimeOfDay.fromDateTime(prayer.prayerTime).format(context)}",
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).primaryColor,
            fontSize: 12,
          ),
        ),
        if (prayer.reminderMinutes > 0)
          Text(
            "Reminder: ${prayer.reminderMinutes} min before",
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        Text(
          "Location: $locationLabel",
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
      topRightWidgets: [
        const Icon(Icons.access_time, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          TimeOfDay.fromDateTime(prayer.prayerTime).format(context),
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
                builder: (_) => AddEditPrayerScreen(prayer: prayer),
              ),
            );
          },
          child: Icon(Icons.bar_chart, size: 16, color: AppColors.secondary),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<_PrayerMenuAction>(
          icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
          onSelected: (action) {
            switch (action) {
              case _PrayerMenuAction.edit:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditPrayerScreen(prayer: prayer),
                  ),
                );
              case _PrayerMenuAction.delete:
                context.read<PrayerBloc>().add(DeletePrayerEvent(prayer));
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: _PrayerMenuAction.edit, child: Text('Edit')),
            PopupMenuItem(
              value: _PrayerMenuAction.delete,
              child: Text('Delete'),
            ),
          ],
        ),
      ],
      onTapTitle: null,
      onToggle: () {
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
      activeBorderColor: AppColors.secondary,
      backgroundColor: AppColors.surface,
    );
  }
}

enum _PrayerMenuAction { edit, delete }

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
    return AppCard(
      onTap: onTap,
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
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPrayerInfo {
  final String label;
  final DateTime? time;

  const _NextPrayerInfo({required this.label, required this.time});
}

class _InspirationTile extends StatelessWidget {
  final String label;
  final String arabic;
  final String source;

  const _InspirationTile({
    required this.label,
    required this.arabic,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      boxShadow: const [],
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            arabic,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
          if (source.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              source,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
