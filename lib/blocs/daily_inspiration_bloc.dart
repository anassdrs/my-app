import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../services/daily_inspiration_service.dart';
import '../services/notification_service.dart';
import '../utils/boxes.dart';

// --- Events ---
abstract class DailyInspirationEvent {}

class LoadDailyInspirationEvent extends DailyInspirationEvent {}

class ToggleNotificationsEvent extends DailyInspirationEvent {
  final bool enabled;
  ToggleNotificationsEvent(this.enabled);
}

class UpdateNotificationTimeEvent extends DailyInspirationEvent {
  final TimeOfDay time;
  UpdateNotificationTimeEvent(this.time);
}

// --- States ---
class DailyInspirationState {
  final DailyInspirationSet? today;
  final bool isLoading;
  final String? error;
  final bool notificationsEnabled;
  final TimeOfDay notificationTime;

  DailyInspirationState({
    this.today,
    this.isLoading = true,
    this.error,
    this.notificationsEnabled = false,
    this.notificationTime = const TimeOfDay(hour: 8, minute: 0),
  });

  DailyInspirationState copyWith({
    DailyInspirationSet? today,
    bool? isLoading,
    String? error,
    bool? notificationsEnabled,
    TimeOfDay? notificationTime,
  }) {
    return DailyInspirationState(
      today: today ?? this.today,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
    );
  }
}

// --- BLoC ---
class DailyInspirationBloc
    extends Bloc<DailyInspirationEvent, DailyInspirationState> {
  final DailyInspirationService _service = DailyInspirationService();

  DailyInspirationBloc() : super(DailyInspirationState()) {
    on<LoadDailyInspirationEvent>(_onLoad);
    on<ToggleNotificationsEvent>(_onToggleNotifications);
    on<UpdateNotificationTimeEvent>(_onUpdateTime);
  }

  Future<void> _onLoad(
    LoadDailyInspirationEvent event,
    Emitter<DailyInspirationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final data = await _service.loadToday();
      final box = Hive.box(HiveBoxes.user);
      final enabled =
          box.get('inspirationNotifications', defaultValue: false) as bool;
      final minutes = box.get('inspirationTimeMinutes') as int?;

      TimeOfDay time = const TimeOfDay(hour: 8, minute: 0);
      if (minutes != null) {
        time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
      }

      emit(
        state.copyWith(
          today: data,
          isLoading: false,
          notificationsEnabled: enabled,
          notificationTime: time,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onToggleNotifications(
    ToggleNotificationsEvent event,
    Emitter<DailyInspirationState> emit,
  ) async {
    final newState = state.copyWith(notificationsEnabled: event.enabled);
    emit(newState);
    await _saveSettings(newState);
  }

  Future<void> _onUpdateTime(
    UpdateNotificationTimeEvent event,
    Emitter<DailyInspirationState> emit,
  ) async {
    final newState = state.copyWith(notificationTime: event.time);
    emit(newState);
    await _saveSettings(newState);
  }

  Future<void> _saveSettings(DailyInspirationState s) async {
    final box = Hive.box(HiveBoxes.user);
    await box.put('inspirationNotifications', s.notificationsEnabled);
    final minutes = s.notificationTime.hour * 60 + s.notificationTime.minute;
    await box.put('inspirationTimeMinutes', minutes);

    if (!s.notificationsEnabled) {
      await NotificationService().cancelNotification(9001);
      return;
    }

    final message = s.today?.verse.en.isNotEmpty == true
        ? s.today!.verse.en
        : s.today?.verse.arabic ?? 'Daily inspiration';

    await NotificationService().scheduleDailyHabitNotification(
      id: 9001,
      title: 'Daily Inspiration',
      body: message,
      time: s.notificationTime,
    );
  }
}
