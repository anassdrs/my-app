import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/adhkar_bloc.dart';
import '../../utils/constants.dart';
import '../../widgets/app_card.dart';

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Adhkar", style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<AdhkarBloc, AdhkarState>(
        builder: (context, state) {
          if (state is AdhkarLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdhkarError) {
            return Center(
              child: Text(
                state.message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.redAccent,
                ),
              ),
            );
          }
          if (state is AdhkarLoaded) {
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: state.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = state.items[index];
                return _AdhkarCard(item: item, index: index);
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _AdhkarCard extends StatelessWidget {
  final DhikrItem item;
  final int index;

  const _AdhkarCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: AppTextStyles.heading2.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(item.text, style: AppTextStyles.bodyLarge),
          if (item.translation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.translation,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Target: ${item.repeat}", style: AppTextStyles.bodyMedium),
              _Counter(item: item, index: index),
            ],
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final DhikrItem item;
  final int index;

  const _Counter({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final progress = item.repeat == 0
        ? 0.0
        : (item.count / item.repeat).clamp(0.0, 1.0);
    return Row(
      children: [
        Text(
          "${item.count}",
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            context.read<AdhkarBloc>().add(IncrementDhikrEvent(index));
          },
          icon: const Icon(Icons.add_circle),
        ),
        IconButton(
          onPressed: () {
            context.read<AdhkarBloc>().add(ResetDhikrEvent(index));
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}
