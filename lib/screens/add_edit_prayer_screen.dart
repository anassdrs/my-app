import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
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
  adhan.PrayerTimes? _prayerTimes;
  String? _selectedPrayerName;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  String? _locationError;
  int _reminderMinutes = 0;

  final List<String> _prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.prayer?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.prayer?.description ?? '',
    );
    _selectedPrayerName = widget.prayer?.name ?? _prayerNames.first;
    _reminderMinutes = widget.prayer?.reminderMinutes ?? 0;
    _fetchLocationAndTimes();
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
            if (_isLoadingLocation)
              const LinearProgressIndicator(minHeight: 3),
            if (_locationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _locationError!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _latitude == null || _longitude == null
                        ? 'Location not set'
                        : 'Lat ${_latitude!.toStringAsFixed(4)}, '
                            'Lng ${_longitude!.toStringAsFixed(4)}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _isLoadingLocation
                      ? null
                      : () => _fetchLocationAndTimes(),
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Use GPS'),
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
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reminder",
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _reminderMinutes == 0
                      ? "At prayer time"
                      : "$_reminderMinutes minutes before",
                  style: AppTextStyles.bodyMedium,
                ),
                Slider(
                  value: _reminderMinutes.toDouble(),
                  min: 0,
                  max: 60,
                  divisions: 12,
                  label: _reminderMinutes == 0
                      ? "At time"
                      : "$_reminderMinutes min",
                  onChanged: (value) {
                    setState(() {
                      _reminderMinutes = value.round();
                    });
                  },
                ),
              ],
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
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prayer name')),
      );
      return;
    }

    final prayerTime = _getPrayerTime(_selectedPrayerName!);
    final latitude = _latitude ?? 0;
    final longitude = _longitude ?? 0;

    if (widget.prayer != null) {
      widget.prayer!.name = _titleController.text;
      widget.prayer!.description = _descriptionController.text;
      widget.prayer!.latitude = latitude;
      widget.prayer!.longitude = longitude;
      widget.prayer!.reminderMinutes = _reminderMinutes;
      if (prayerTime != null) {
        widget.prayer!.prayerTime = prayerTime;
      }
      context.read<PrayerBloc>().add(UpdatePrayerEvent(widget.prayer!));

      // Update notification
      if (prayerTime != null) {
        final reminderTime = _getReminderTime(prayerTime, _reminderMinutes);
        NotificationService().scheduleDailyHabitNotification(
          id: widget.prayer!.id.hashCode,
          title: 'Prayer Reminder: ${widget.prayer!.name}',
          body: 'Time for ${_selectedPrayerName!} prayer',
          time: TimeOfDay.fromDateTime(reminderTime),
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
        reminderMinutes: _reminderMinutes,
      );
      context.read<PrayerBloc>().add(AddPrayerEvent(newPrayer));

      // Schedule notification
      if (prayerTime != null) {
        final reminderTime = _getReminderTime(prayerTime, _reminderMinutes);
        NotificationService().scheduleDailyHabitNotification(
          id: newPrayer.id.hashCode,
          title: 'Prayer Reminder: ${newPrayer.name}',
          body: 'Time for ${_selectedPrayerName!} prayer',
          time: TimeOfDay.fromDateTime(reminderTime),
        );
      }
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime _getReminderTime(DateTime prayerTime, int minutesBefore) {
    if (minutesBefore <= 0) return prayerTime;
    final reminderTime = prayerTime.subtract(
      Duration(minutes: minutesBefore),
    );
    if (reminderTime.day != prayerTime.day) {
      return prayerTime;
    }
    return reminderTime;
  }
}
