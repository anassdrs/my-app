import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../models/habit.dart';
import '../../blocs/habit_bloc.dart';
import '../../utils/constants.dart';
import '../../services/notification_service.dart';

class AddEditHabitScreen extends StatefulWidget {
  final Habit? habit;
  const AddEditHabitScreen({super.key, this.habit});

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TimeOfDay _startTime;
  String _habitType = 'general';
  final List<String> _prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.habit?.description ?? '',
    );
    _startTime = widget.habit != null
        ? TimeOfDay.fromDateTime(widget.habit!.startTime)
        : TimeOfDay.now();
    _habitType = widget.habit?.habitType ?? 'general';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.habit == null ? "New Habit" : "Edit Habit",
          style: AppTextStyles.heading2,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 20),
            if (_habitType == 'prayer')
              _buildPrayerSelector()
            else
              _buildGeneralFields(),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickTime,
              child: Row(
                children: [
                  Icon(Icons.access_time, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Text(
                    "Reminder Time: ${_startTime.format(context)}",
                    style: AppTextStyles.bodyLarge,
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Start Habit",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(child: _typeChip('General', 'general', Icons.auto_awesome)),
        const SizedBox(width: 10),
        Expanded(child: _typeChip('Prayer', 'prayer', Icons.mosque)),
      ],
    );
  }

  Widget _typeChip(String label, String type, IconData icon) {
    final isSelected = _habitType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _habitType = type;
          if (type == 'prayer' && _titleController.text.isEmpty) {
            _titleController.text = _prayerNames[0];
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? AppColors.secondary
                : Colors.grey.withOpacity(0.3),
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

  Widget _buildGeneralFields() {
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

  Widget _buildPrayerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Prayer", style: AppTextStyles.bodyLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _prayerNames.map((name) {
            final isSelected = _titleController.text == name;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _titleController.text = name;
                });
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
                        : Colors.grey.withOpacity(0.3),
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

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  void _saveHabit() {
    if (_titleController.text.isEmpty) return;

    final now = DateTime.now();
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime.hour,
      _startTime.minute,
    );

    if (widget.habit != null) {
      widget.habit!.title = _titleController.text;
      widget.habit!.description = _descriptionController.text;
      widget.habit!.startTime = startTime;
      widget.habit!.habitType = _habitType;
      context.read<HabitBloc>().add(UpdateHabitEvent(widget.habit!));

      // Update notification
      NotificationService().scheduleDailyHabitNotification(
        id: widget.habit!.id.hashCode,
        title: _habitType == 'prayer'
            ? 'Prayer Time: ${widget.habit!.title}'
            : 'Habit Reminder: ${widget.habit!.title}',
        body: _habitType == 'prayer'
            ? 'It\'s time for ${widget.habit!.title}'
            : 'Time to complete your habit!',
        time: _startTime,
      );
    } else {
      final newHabit = Habit(
        id: const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        startTime: startTime,
        category: _habitType == 'prayer' ? 'Prayer' : 'General',
        habitType: _habitType,
      );
      context.read<HabitBloc>().add(AddHabitEvent(newHabit));

      // Schedule notification
      NotificationService().scheduleDailyHabitNotification(
        id: newHabit.id.hashCode,
        title: _habitType == 'prayer'
            ? 'Prayer Time: ${newHabit.title}'
            : 'Habit Reminder: ${newHabit.title}',
        body: _habitType == 'prayer'
            ? 'It\'s time for ${newHabit.title}'
            : 'Time to complete your habit!',
        time: _startTime,
      );
    }

    Navigator.pop(context);
  }
}
