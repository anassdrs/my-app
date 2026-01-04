import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/habit.dart';
import '../../blocs/habit_bloc.dart';
import '../../blocs/add_edit_habit_bloc.dart';
import '../../utils/constants.dart';
import '../../widgets/primary_button.dart';

class AddEditHabitScreen extends StatelessWidget {
  final Habit? habit;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialHabitType;

  const AddEditHabitScreen({
    super.key,
    this.habit,
    this.initialTitle,
    this.initialDescription,
    this.initialHabitType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AddEditHabitBloc(habitBloc: context.read<HabitBloc>())..add(
            InitializeHabitEvent(
              habit: habit,
              initialTitle: initialTitle,
              initialDescription: initialDescription,
              initialHabitType: initialHabitType,
            ),
          ),
      child: const _AddEditHabitView(),
    );
  }
}

class _AddEditHabitView extends StatefulWidget {
  const _AddEditHabitView();

  @override
  State<_AddEditHabitView> createState() => _AddEditHabitViewState();
}

class _AddEditHabitViewState extends State<_AddEditHabitView> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  static const Map<int, String> _weekdayLabels = {
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };

  final List<String> _prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  void initState() {
    super.initState();
    final state = context.read<AddEditHabitBloc>().state;
    _titleController = TextEditingController(text: state.title);
    _descriptionController = TextEditingController(text: state.description);

    _titleController.addListener(() {
      context.read<AddEditHabitBloc>().add(
        UpdateHabitFieldsEvent(title: _titleController.text),
      );
    });
    _descriptionController.addListener(() {
      context.read<AddEditHabitBloc>().add(
        UpdateHabitFieldsEvent(description: _descriptionController.text),
      );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddEditHabitBloc, AddEditHabitState>(
      listener: (context, state) {
        if (state.isSuccess) Navigator.pop(context);
        if (state.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      child: BlocBuilder<AddEditHabitBloc, AddEditHabitState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                state.initialHabit == null ? "New Habit" : "Edit Habit",
                style: AppTextStyles.heading2,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildTypeSelector(context, state),
                    const SizedBox(height: 20),
                    if (state.habitType == 'prayer')
                      _buildPrayerSelector(context, state)
                    else
                      _buildGeneralFields(context, state),
                    const SizedBox(height: 20),
                    _buildFrequencySection(context, state),
                    const SizedBox(height: 16),
                    _buildTimeWindowSection(context, state),
                    const SizedBox(height: 16),
                    if (state.habitType == 'prayer' && state.isLoadingLocation)
                      const LinearProgressIndicator(minHeight: 3),
                    if (state.habitType == 'prayer' &&
                        state.locationError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          state.locationError!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: "Start Habit",
                      onPressed: () => context.read<AddEditHabitBloc>().add(
                        SaveHabitEvent(),
                      ),
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context, AddEditHabitState state) {
    return Row(
      children: [
        Expanded(
          child: _typeChip(
            context,
            state,
            'General',
            'general',
            Icons.auto_awesome,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _typeChip(context, state, 'Prayer', 'prayer', Icons.mosque),
        ),
      ],
    );
  }

  Widget _typeChip(
    BuildContext context,
    AddEditHabitState state,
    String label,
    String type,
    IconData icon,
  ) {
    final isSelected = state.habitType == type;
    return GestureDetector(
      onTap: () {
        context.read<AddEditHabitBloc>().add(
          UpdateHabitFieldsEvent(habitType: type),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? AppColors.secondary
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.black : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralFields(BuildContext context, AddEditHabitState state) {
    return Column(
      children: [
        TextField(
          controller: _titleController,
          style: AppTextStyles.heading2,
          decoration: InputDecoration(
            hintText: "Habit Name",
            hintStyle: AppTextStyles.heading2.copyWith(color: Colors.grey),
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descriptionController,
          style: AppTextStyles.bodyLarge,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: "Description (optional)",
            hintStyle: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
            border: InputBorder.none,
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerSelector(BuildContext context, AddEditHabitState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Prayer", style: AppTextStyles.bodyLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _prayerNames.map((name) {
            final isSelected = state.title == name;
            return GestureDetector(
              onTap: () {
                _titleController.text = name;
                context.read<AddEditHabitBloc>().add(FetchHabitLocationEvent());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.secondary
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFrequencySection(BuildContext context, AddEditHabitState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Frequency",
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: state.frequencyType,
          items: const [
            DropdownMenuItem(value: 'daily', child: Text('Daily')),
            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
            DropdownMenuItem(value: 'custom_days', child: Text('Custom Days')),
          ],
          onChanged: (val) {
            if (val != null) {
              context.read<AddEditHabitBloc>().add(
                UpdateHabitFieldsEvent(
                  frequencyType: val,
                  customDays: val == 'custom_days' && state.customDays.isEmpty
                      ? [DateTime.now().weekday]
                      : null,
                ),
              );
            }
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (state.frequencyType == 'weekly') ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Times per week", style: AppTextStyles.bodyMedium),
              DropdownButton<int>(
                value: state.frequencyValue,
                items: List.generate(
                  7,
                  (i) =>
                      DropdownMenuItem(value: i + 1, child: Text("${i + 1}")),
                ),
                onChanged: (val) {
                  if (val != null) {
                    context.read<AddEditHabitBloc>().add(
                      UpdateHabitFieldsEvent(frequencyValue: val),
                    );
                  }
                },
              ),
            ],
          ),
        ],
        if (state.frequencyType == 'custom_days') ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekdayLabels.entries.map((entry) {
              final isSelected = state.customDays.contains(entry.key);
              return GestureDetector(
                onTap: () {
                  final newDays = List<int>.from(state.customDays);
                  if (isSelected && newDays.length > 1) {
                    newDays.remove(entry.key);
                  } else {
                    newDays.add(entry.key);
                  }
                  context.read<AddEditHabitBloc>().add(
                    UpdateHabitFieldsEvent(customDays: newDays),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.secondary : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.secondary
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeWindowSection(
    BuildContext context,
    AddEditHabitState state,
  ) {
    final start = TimeOfDay(
      hour: state.windowStartMinutes ~/ 60,
      minute: state.windowStartMinutes % 60,
    );
    final end = TimeOfDay(
      hour: state.windowEndMinutes ~/ 60,
      minute: state.windowEndMinutes % 60,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Time Window",
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: start,
                  );
                  if (!context.mounted) return;
                  if (picked != null) {
                    context.read<AddEditHabitBloc>().add(
                      UpdateHabitFieldsEvent(
                        windowStartMinutes: picked.hour * 60 + picked.minute,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    "Start: ${start.format(context)}",
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: end,
                  );
                  if (!context.mounted) return;
                  if (picked != null) {
                    context.read<AddEditHabitBloc>().add(
                      UpdateHabitFieldsEvent(
                        windowEndMinutes: picked.hour * 60 + picked.minute,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    "End: ${end.format(context)}",
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
