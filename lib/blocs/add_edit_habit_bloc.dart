import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:adhan/adhan.dart' as adhan;
import '../../models/habit.dart';
import 'habit_bloc.dart';
import '../../services/notification_service.dart';
import 'package:flutter/material.dart';

// --- Events ---
abstract class AddEditHabitEvent {}

class InitializeHabitEvent extends AddEditHabitEvent {
  final Habit? habit;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialHabitType;

  InitializeHabitEvent({
    this.habit,
    this.initialTitle,
    this.initialDescription,
    this.initialHabitType,
  });
}

class UpdateHabitFieldsEvent extends AddEditHabitEvent {
  final String? title;
  final String? description;
  final String? habitType;
  final String? frequencyType;
  final int? frequencyValue;
  final List<int>? customDays;
  final int? windowStartMinutes;
  final int? windowEndMinutes;

  UpdateHabitFieldsEvent({
    this.title,
    this.description,
    this.habitType,
    this.frequencyType,
    this.frequencyValue,
    this.customDays,
    this.windowStartMinutes,
    this.windowEndMinutes,
  });
}

class FetchHabitLocationEvent extends AddEditHabitEvent {}

class SaveHabitEvent extends AddEditHabitEvent {}

// --- States ---
class AddEditHabitState {
  final Habit? initialHabit;
  final String title;
  final String description;
  final String habitType;
  final String frequencyType;
  final int frequencyValue;
  final List<int> customDays;
  final int windowStartMinutes;
  final int windowEndMinutes;

  final bool isLoadingLocation;
  final String? locationError;
  final bool isSuccess;
  final String? error;

  AddEditHabitState({
    this.initialHabit,
    this.title = '',
    this.description = '',
    this.habitType = 'general',
    this.frequencyType = 'daily',
    this.frequencyValue = 1,
    this.customDays = const [],
    this.windowStartMinutes = 0,
    this.windowEndMinutes = 0,
    this.isLoadingLocation = false,
    this.locationError,
    this.isSuccess = false,
    this.error,
  });

  AddEditHabitState copyWith({
    Habit? initialHabit,
    String? title,
    String? description,
    String? habitType,
    String? frequencyType,
    int? frequencyValue,
    List<int>? customDays,
    int? windowStartMinutes,
    int? windowEndMinutes,
    bool? isLoadingLocation,
    String? locationError,
    bool? isSuccess,
    String? error,
  }) {
    return AddEditHabitState(
      initialHabit: initialHabit ?? this.initialHabit,
      title: title ?? this.title,
      description: description ?? this.description,
      habitType: habitType ?? this.habitType,
      frequencyType: frequencyType ?? this.frequencyType,
      frequencyValue: frequencyValue ?? this.frequencyValue,
      customDays: customDays ?? this.customDays,
      windowStartMinutes: windowStartMinutes ?? this.windowStartMinutes,
      windowEndMinutes: windowEndMinutes ?? this.windowEndMinutes,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      locationError: locationError ?? this.locationError,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

// --- BLoC ---
class AddEditHabitBloc extends Bloc<AddEditHabitEvent, AddEditHabitState> {
  final HabitBloc habitBloc;

  AddEditHabitBloc({required this.habitBloc}) : super(AddEditHabitState()) {
    on<InitializeHabitEvent>((event, emit) {
      if (event.habit != null) {
        final h = event.habit!;
        emit(
          AddEditHabitState(
            initialHabit: h,
            title: h.title,
            description: h.description,
            habitType: h.habitType,
            frequencyType: h.frequencyType,
            frequencyValue: h.frequencyValue,
            customDays: h.customDays,
            windowStartMinutes: h.windowStartMinutes,
            windowEndMinutes: h.windowEndMinutes,
          ),
        );
      } else {
        emit(
          state.copyWith(
            title: event.initialTitle,
            description: event.initialDescription,
            habitType: event.initialHabitType ?? 'general',
            windowStartMinutes:
                TimeOfDay.now().hour * 60 + TimeOfDay.now().minute,
            windowEndMinutes:
                (TimeOfDay.now().hour + 1) % 24 * 60 + TimeOfDay.now().minute,
          ),
        );
      }
      if (state.habitType == 'prayer') {
        add(FetchHabitLocationEvent());
      }
    });

    on<UpdateHabitFieldsEvent>((event, emit) {
      var newState = state.copyWith(
        title: event.title,
        description: event.description,
        habitType: event.habitType,
        frequencyType: event.frequencyType,
        frequencyValue: event.frequencyValue,
        customDays: event.customDays,
        windowStartMinutes: event.windowStartMinutes,
        windowEndMinutes: event.windowEndMinutes,
      );

      if (event.habitType == 'prayer' && state.habitType != 'prayer') {
        add(FetchHabitLocationEvent());
      }

      emit(newState);
    });

    on<FetchHabitLocationEvent>((event, emit) async {
      emit(state.copyWith(isLoadingLocation: true, locationError: null));
      try {
        final position = await _determinePosition();
        final coordinates = adhan.Coordinates(
          position.latitude,
          position.longitude,
        );
        final params = adhan.CalculationMethod.muslim_world_league
            .getParameters();
        params.madhab = adhan.Madhab.shafi;
        final times = adhan.PrayerTimes(
          coordinates,
          adhan.DateComponents.from(DateTime.now()),
          params,
        );

        DateTime? prayerTime;
        final name = state.title.toLowerCase();
        switch (name) {
          case 'fajr':
            prayerTime = times.fajr;
            break;
          case 'dhuhr':
            prayerTime = times.dhuhr;
            break;
          case 'asr':
            prayerTime = times.asr;
            break;
          case 'maghrib':
            prayerTime = times.maghrib;
            break;
          case 'isha':
            prayerTime = times.isha;
            break;
        }

        if (prayerTime != null) {
          final start = prayerTime.hour * 60 + prayerTime.minute;
          emit(
            state.copyWith(
              isLoadingLocation: false,
              windowStartMinutes: start,
              windowEndMinutes: (start + 60) % (24 * 60),
            ),
          );
        } else {
          emit(state.copyWith(isLoadingLocation: false));
        }
      } catch (e) {
        emit(
          state.copyWith(isLoadingLocation: false, locationError: e.toString()),
        );
      }
    });

    on<SaveHabitEvent>((event, emit) async {
      if (state.title.isEmpty) {
        emit(state.copyWith(error: 'Title cannot be empty'));
        return;
      }

      final now = DateTime.now();
      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        state.windowStartMinutes ~/ 60,
        state.windowStartMinutes % 60,
      );

      final habit = Habit(
        id: state.initialHabit?.id ?? const Uuid().v4(),
        title: state.title,
        description: state.description,
        startTime: startTime,
        category: state.habitType == 'prayer' ? 'Prayer' : 'General',
        habitType: state.habitType,
        frequencyType: state.frequencyType,
        frequencyValue: state.frequencyValue,
        customDays: state.customDays,
        windowStartMinutes: state.windowStartMinutes,
        windowEndMinutes: state.windowEndMinutes,
        streak: state.initialHabit?.streak ?? 0,
        completedDates: state.initialHabit?.completedDates ?? [],
      );

      if (state.initialHabit != null) {
        habitBloc.add(UpdateHabitEvent(habit));
      } else {
        habitBloc.add(AddHabitEvent(habit));
      }

      // Schedule notification
      await NotificationService().scheduleDailyHabitNotification(
        id: habit.id.hashCode,
        title: state.habitType == 'prayer'
            ? 'Prayer Time: ${state.title}'
            : 'Habit Reminder: ${state.title}',
        body: state.habitType == 'prayer'
            ? 'It\'s time for ${state.title}'
            : 'Time to complete your habit!',
        time: TimeOfDay(
          hour: state.windowStartMinutes ~/ 60,
          minute: state.windowStartMinutes % 60,
        ),
      );

      emit(state.copyWith(isSuccess: true));
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }
}
