import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/daily_inspiration_bloc.dart';
import '../../services/daily_inspiration_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_card.dart';

class DailyInspirationScreen extends StatelessWidget {
  const DailyInspirationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Daily Inspiration", style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<DailyInspirationBloc, DailyInspirationState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(
              child: Text(
                state.error!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            );
          }
          if (state.today == null) {
            return const Center(child: Text("No data available"));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _NotificationCard(state: state),
              const SizedBox(height: 16),
              _InspirationCard(
                title: "Verse of the Day",
                item: state.today!.verse,
              ),
              const SizedBox(height: 16),
              _InspirationCard(title: "Hadith", item: state.today!.hadith),
              const SizedBox(height: 16),
              _InspirationCard(title: "Value", item: state.today!.value),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final DailyInspirationState state;

  const _NotificationCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Daily Reminder",
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Enable notifications", style: AppTextStyles.bodyMedium),
              Switch(
                value: state.notificationsEnabled,
                onChanged: (value) {
                  context.read<DailyInspirationBloc>().add(
                    ToggleNotificationsEvent(value),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Time", style: AppTextStyles.bodyMedium),
              TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: state.notificationTime,
                  );
                  if (!context.mounted) return;
                  if (picked != null) {
                    context.read<DailyInspirationBloc>().add(
                      UpdateNotificationTimeEvent(picked),
                    );
                  }
                },
                child: Text(state.notificationTime.format(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InspirationCard extends StatelessWidget {
  final String title;
  final DailyInspirationItem item;

  const _InspirationCard({required this.title, required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading2.copyWith(fontSize: 18)),
          const SizedBox(height: 10),
          Text(
            item.arabic,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
          if (item.en.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.en, style: AppTextStyles.bodyMedium),
          ],
          if (item.fr.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.fr,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (item.source.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.source,
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
