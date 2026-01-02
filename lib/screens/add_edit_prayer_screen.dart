import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:adhan/adhan.dart' as adhan;
import '../../models/prayer.dart';
import '../../blocs/prayer_bloc.dart';
import '../../utils/constants.dart';
import '../../services/notification_service.dart';

class AddEditPrayerScreen extends StatefulWidget {
  final Prayer? prayer;
  const AddEditPrayerScreen({super.key, this.prayer});

  @override
  State<AddEditPrayerScreen> createState() => _AddEditPrayerScreenState();
}

class _AddEditPrayerScreenState extends State<AddEditPrayerScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  adhan.PrayerTimes? _prayerTimes;
  String? _selectedPrayerName;

  final List<String> _prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.prayer?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.prayer?.description ?? '',
    );
    _latitudeController = TextEditingController(
      text: widget.prayer?.latitude.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.prayer?.longitude.toString() ?? '',
    );
    _selectedPrayerName = widget.prayer?.name ?? _prayerNames.first;
    _calculatePrayerTimes();
  }

  void _calculatePrayerTimes() {
    if (_latitudeController.text.isNotEmpty &&
        _longitudeController.text.isNotEmpty) {
      try {
        final latitude = double.parse(_latitudeController.text);
        final longitude = double.parse(_longitudeController.text);

        final coordinates = adhan.Coordinates(latitude, longitude);
        final params = adhan.CalculationMethod.muslim_world_league
            .getParameters();
        params.madhab = adhan.Madhab.shafi;

        final now = DateTime.now();
        final dateComponents = adhan.DateComponents(
          now.year,
          now.month,
          now.day,
        );
        _prayerTimes = adhan.PrayerTimes(coordinates, dateComponents, params);
        setState(() {});
      } catch (e) {
        // Invalid coordinates
        _prayerTimes = null;
        setState(() {});
      }
    }
  }

  DateTime? _getPrayerTime(String prayerName) {
    if (_prayerTimes == null) return null;

    switch (prayerName) {
      case 'Fajr':
        return _prayerTimes!.fajr;
      case 'Dhuhr':
        return _prayerTimes!.dhuhr;
      case 'Asr':
        return _prayerTimes!.asr;
      case 'Maghrib':
        return _prayerTimes!.maghrib;
      case 'Isha':
        return _prayerTimes!.isha;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.prayer == null ? "New Prayer" : "Edit Prayer",
          style: AppTextStyles.heading2,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedPrayerName,
              decoration: InputDecoration(
                labelText: "Prayer Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _prayerNames.map((prayer) {
                return DropdownMenuItem(value: prayer, child: Text(prayer));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPrayerName = value;
                  _titleController.text = value ?? '';
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              style: AppTextStyles.bodyLarge,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Description (optional)",
                hintStyle: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latitudeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Latitude",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _calculatePrayerTimes(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _longitudeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Longitude",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _calculatePrayerTimes(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_prayerTimes != null && _selectedPrayerName != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Prayer Time for $_selectedPrayerName:",
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _getPrayerTime(
                              _selectedPrayerName!,
                            )?.toLocal().toString() ??
                            "Not available",
                        style: AppTextStyles.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _savePrayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Add Prayer",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savePrayer() {
    if (_titleController.text.isEmpty ||
        _latitudeController.text.isEmpty ||
        _longitudeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final latitude = double.tryParse(_latitudeController.text);
    final longitude = double.tryParse(_longitudeController.text);

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid coordinates')));
      return;
    }

    final prayerTime = _getPrayerTime(_selectedPrayerName!);

    if (widget.prayer != null) {
      widget.prayer!.name = _titleController.text;
      widget.prayer!.description = _descriptionController.text;
      widget.prayer!.latitude = latitude;
      widget.prayer!.longitude = longitude;
      if (prayerTime != null) {
        widget.prayer!.prayerTime = prayerTime;
      }
      context.read<PrayerBloc>().add(UpdatePrayerEvent(widget.prayer!));

      // Update notification
      if (prayerTime != null) {
        NotificationService().scheduleDailyHabitNotification(
          id: widget.prayer!.id.hashCode,
          title: 'Prayer Reminder: ${widget.prayer!.name}',
          body: 'Time for ${_selectedPrayerName!} prayer',
          time: TimeOfDay.fromDateTime(prayerTime),
        );
      }
    } else {
      final newPrayer = Prayer(
        id: const Uuid().v4(),
        name: _titleController.text,
        description: _descriptionController.text,
        latitude: latitude,
        longitude: longitude,
        prayerTime: prayerTime ?? DateTime.now(), // Provide default if null
      );
      context.read<PrayerBloc>().add(AddPrayerEvent(newPrayer));

      // Schedule notification
      if (prayerTime != null) {
        NotificationService().scheduleDailyHabitNotification(
          id: newPrayer.id.hashCode,
          title: 'Prayer Reminder: ${newPrayer.name}',
          body: 'Time for ${_selectedPrayerName!} prayer',
          time: TimeOfDay.fromDateTime(prayerTime),
        );
      }
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
}
