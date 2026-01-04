import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:adhan/adhan.dart' as adhan;
import '../../models/prayer.dart';
import 'prayer_bloc.dart';
import '../../services/notification_service.dart';

// --- Events ---
abstract class AddEditPrayerEvent {}

class InitializePrayerEvent extends AddEditPrayerEvent {
  final Prayer? prayer;
  InitializePrayerEvent(this.prayer);
}

class UpdatePrayerFieldsEvent extends AddEditPrayerEvent {
  final String? name;
  final String? description;
  final int? reminderMinutes;
  UpdatePrayerFieldsEvent({this.name, this.description, this.reminderMinutes});
}

class FetchLocationEvent extends AddEditPrayerEvent {}

class SavePrayerEvent extends AddEditPrayerEvent {}

// --- States ---
class AddEditPrayerState {
  final Prayer? initialPrayer;
  final String name;
  final String description;
  final double? latitude;
  final double? longitude;
  final DateTime? prayerTime;
  final int reminderMinutes;

  final bool isLoadingLocation;
  final String? locationError;
  final bool isSuccess;
  final String? error;

  AddEditPrayerState({
    this.initialPrayer,
    this.name = 'Fajr',
    this.description = '',
    this.latitude,
    this.longitude,
    this.prayerTime,
    this.reminderMinutes = 0,
    this.isLoadingLocation = false,
    this.locationError,
    this.isSuccess = false,
    this.error,
  });

  AddEditPrayerState copyWith({
    Prayer? initialPrayer,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? prayerTime,
    int? reminderMinutes,
    bool? isLoadingLocation,
    String? locationError,
    bool? isSuccess,
    String? error,
  }) {
    return AddEditPrayerState(
      initialPrayer: initialPrayer ?? this.initialPrayer,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      prayerTime: prayerTime ?? this.prayerTime,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      locationError: locationError ?? this.locationError,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

// --- BLoC ---
class AddEditPrayerBloc extends Bloc<AddEditPrayerEvent, AddEditPrayerState> {
  final PrayerBloc prayerBloc;

  AddEditPrayerBloc({required this.prayerBloc}) : super(AddEditPrayerState()) {
    on<InitializePrayerEvent>((event, emit) {
      if (event.prayer != null) {
        final p = event.prayer!;
        emit(
          AddEditPrayerState(
            initialPrayer: p,
            name: p.name,
            description: p.description,
            latitude: p.latitude,
            longitude: p.longitude,
            prayerTime: p.prayerTime,
            reminderMinutes: p.reminderMinutes,
          ),
        );
      }
      add(FetchLocationEvent());
    });

    on<UpdatePrayerFieldsEvent>((event, emit) {
      final newState = state.copyWith(
        name: event.name,
        description: event.description,
        reminderMinutes: event.reminderMinutes,
      );
      emit(_calculatePrayerTime(newState));
    });

    on<FetchLocationEvent>((event, emit) async {
      emit(state.copyWith(isLoadingLocation: true, locationError: null));
      try {
        final position = await _determinePosition();
        final newState = state.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
          isLoadingLocation: false,
        );
        emit(_calculatePrayerTime(newState));
      } catch (e) {
        emit(
          state.copyWith(isLoadingLocation: false, locationError: e.toString()),
        );
      }
    });

    on<SavePrayerEvent>((event, emit) async {
      if (state.name.isEmpty) {
        emit(state.copyWith(error: 'Name cannot be empty'));
        return;
      }

      final prayer = Prayer(
        id: state.initialPrayer?.id ?? const Uuid().v4(),
        name: state.name,
        description: state.description,
        latitude: state.latitude ?? 0,
        longitude: state.longitude ?? 0,
        prayerTime: state.prayerTime ?? DateTime.now(),
        reminderMinutes: state.reminderMinutes,
      );

      if (state.initialPrayer != null) {
        prayerBloc.add(UpdatePrayerEvent(prayer));
      } else {
        prayerBloc.add(AddPrayerEvent(prayer));
      }

      // Schedule notification
      if (state.prayerTime != null) {
        final reminderTime = _getReminderTime(
          state.prayerTime!,
          state.reminderMinutes,
        );
        await NotificationService().scheduleDailyHabitNotification(
          id: prayer.id.hashCode,
          title: 'Prayer Reminder: ${prayer.name}',
          body: 'Time for ${state.name} prayer',
          time: TimeOfDay.fromDateTime(reminderTime),
        );
      }

      emit(state.copyWith(isSuccess: true));
    });
  }

  AddEditPrayerState _calculatePrayerTime(AddEditPrayerState s) {
    if (s.latitude == null || s.longitude == null) return s;

    final coordinates = adhan.Coordinates(s.latitude!, s.longitude!);
    final params = adhan.CalculationMethod.muslim_world_league.getParameters();
    params.madhab = adhan.Madhab.shafi;

    final now = DateTime.now();
    final dateComponents = adhan.DateComponents(now.year, now.month, now.day);
    final times = adhan.PrayerTimes(coordinates, dateComponents, params);

    DateTime? time;
    switch (s.name) {
      case 'Fajr':
        time = times.fajr;
        break;
      case 'Dhuhr':
        time = times.dhuhr;
        break;
      case 'Asr':
        time = times.asr;
        break;
      case 'Maghrib':
        time = times.maghrib;
        break;
      case 'Isha':
        time = times.isha;
        break;
    }

    return s.copyWith(prayerTime: time);
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  DateTime _getReminderTime(DateTime prayerTime, int minutesBefore) {
    if (minutesBefore <= 0) return prayerTime;
    final rTime = prayerTime.subtract(Duration(minutes: minutesBefore));
    if (rTime.day != prayerTime.day) return prayerTime;
    return rTime;
  }
}
