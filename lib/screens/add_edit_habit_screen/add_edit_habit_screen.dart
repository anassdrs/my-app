import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:adhan/adhan.dart' as adhan;
import '../../models/habit.dart';
import '../../blocs/habit_bloc.dart';
import '../../utils/constants.dart';
import '../../services/notification_service.dart';

class AddEditHabitScreen extends StatefulWidget {
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
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TimeOfDay _startTime;
  String _habitType = 'general';
  final List<String> _prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  adhan.PrayerTimes? _prayerTimes;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.habit?.title ?? widget.initialTitle ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.habit?.description ?? widget.initialDescription ?? '',
    );
    _startTime = widget.habit != null
        ? TimeOfDay.fromDateTime(widget.habit!.startTime)
        : TimeOfDay.now();
    _habitType = widget.habit?.habitType ?? widget.initialHabitType ?? 'general';
    if (_habitType == 'prayer' && _titleController.text.isEmpty) {
      _titleController.text = _prayerNames[0];
    }
    if (_habitType == 'prayer') {
      _fetchLocationAndTimes();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
            if (_habitType == 'prayer' && _isLoadingLocation)
              const LinearProgressIndicator(minHeight: 3),
            if (_habitType == 'prayer' && _locationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _locationError!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            GestureDetector(
              onTap: _habitType == 'prayer' ? null : _pickTime,
              child: Row(
                children: [
                  Icon(Icons.access_time, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Text(
                    _habitType == 'prayer'
                        ? "Prayer Time: ${_startTime.format(context)}"
                        : "Reminder Time: ${_startTime.format(context)}",
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
        if (type == 'prayer') {
          _fetchLocationAndTimes();
        }
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
                _setPrayerTimeFromName();
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

  Future<void> _fetchLocationAndTimes() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied.';
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permission permanently denied.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!position.latitude.isFinite || !position.longitude.isFinite) {
        throw 'Invalid location received.';
      }

      _latitude = position.latitude;
      _longitude = position.longitude;
      _calculatePrayerTimes();
      _setPrayerTimeFromName();
    } catch (e) {
      _locationError = e.toString();
      _prayerTimes = null;
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingLocation = false);
    }
  }

  void _calculatePrayerTimes() {
    if (_latitude == null || _longitude == null) {
      _prayerTimes = null;
      return;
    }

    final coordinates = adhan.Coordinates(_latitude!, _longitude!);
    final params = adhan.CalculationMethod.muslim_world_league.getParameters();
    params.madhab = adhan.Madhab.shafi;

    final now = DateTime.now();
    final dateComponents = adhan.DateComponents(now.year, now.month, now.day);
    _prayerTimes = adhan.PrayerTimes(coordinates, dateComponents, params);
  }

  void _setPrayerTimeFromName() {
    if (_prayerTimes == null) return;
    DateTime? prayerTime;
    final name = _titleController.text.toLowerCase();
    switch (name) {
      case 'fajr':
        prayerTime = _prayerTimes!.fajr;
      case 'dhuhr':
        prayerTime = _prayerTimes!.dhuhr;
      case 'asr':
        prayerTime = _prayerTimes!.asr;
      case 'maghrib':
        prayerTime = _prayerTimes!.maghrib;
      case 'isha':
        prayerTime = _prayerTimes!.isha;
    }

    if (prayerTime == null) return;
    setState(() {
      _startTime = TimeOfDay.fromDateTime(prayerTime!);
    });
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
