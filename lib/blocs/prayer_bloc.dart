import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:adhan/adhan.dart' as adhan;
import '../models/prayer.dart';
import '../utils/boxes.dart';
import '../utils/streak_utils.dart';

// Events
abstract class PrayerEvent {}

class LoadPrayers extends PrayerEvent {}

class AddPrayerEvent extends PrayerEvent {
  final Prayer prayer;
  AddPrayerEvent(this.prayer);
}

class UpdatePrayerEvent extends PrayerEvent {
  final Prayer prayer;
  UpdatePrayerEvent(this.prayer);
}

class DeletePrayerEvent extends PrayerEvent {
  final Prayer prayer;
  DeletePrayerEvent(this.prayer);
}

class TogglePrayerEvent extends PrayerEvent {
  final Prayer prayer;
  final DateTime date;
  TogglePrayerEvent(this.prayer, this.date);
}

// States
abstract class PrayerState {}

class PrayerInitial extends PrayerState {}

class PrayerLoading extends PrayerState {}

class PrayerLoaded extends PrayerState {
  final List<Prayer> prayers;
  PrayerLoaded(this.prayers);
}

class PrayerError extends PrayerState {
  final String message;
  PrayerError(this.message);
}

// BLoC
class PrayerBloc extends Bloc<PrayerEvent, PrayerState> {
  PrayerBloc() : super(PrayerInitial()) {
    on<LoadPrayers>(_onLoadPrayers);
    on<AddPrayerEvent>(_onAddPrayer);
    on<UpdatePrayerEvent>(_onUpdatePrayer);
    on<DeletePrayerEvent>(_onDeletePrayer);
    on<TogglePrayerEvent>(_onTogglePrayer);
  }

  void _onLoadPrayers(LoadPrayers event, Emitter<PrayerState> emit) async {
    emit(PrayerLoading());
    try {
      final box = Hive.box<Prayer>(HiveBoxes.prayers);
      final prayers = box.values.toList();
      for (final prayer in prayers) {
        if (!prayer.latitude.isFinite || !prayer.longitude.isFinite) {
          prayer.latitude = 0;
          prayer.longitude = 0;
          await prayer.save();
        }
        final updatedTime = _getPrayerTimeForToday(prayer);
        if (updatedTime != null && updatedTime != prayer.prayerTime) {
          prayer.prayerTime = updatedTime;
          await prayer.save();
        }
      }
      emit(PrayerLoaded(prayers));
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }

  void _onAddPrayer(AddPrayerEvent event, Emitter<PrayerState> emit) async {
    try {
      final box = Hive.box<Prayer>(HiveBoxes.prayers);
      await box.add(event.prayer);
      add(LoadPrayers());
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }

  void _onUpdatePrayer(
    UpdatePrayerEvent event,
    Emitter<PrayerState> emit,
  ) async {
    try {
      await event.prayer.save();
      add(LoadPrayers());
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }

  void _onDeletePrayer(
    DeletePrayerEvent event,
    Emitter<PrayerState> emit,
  ) async {
    try {
      await event.prayer.delete();
      add(LoadPrayers());
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }

  void _onTogglePrayer(
    TogglePrayerEvent event,
    Emitter<PrayerState> emit,
  ) async {
    try {
      final normalizedDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );

      if (event.prayer.isCompletedOn(normalizedDate)) {
        event.prayer.completedDates.removeWhere(
          (d) =>
              d.year == normalizedDate.year &&
              d.month == normalizedDate.month &&
              d.day == normalizedDate.day,
        );
      } else {
        event.prayer.completedDates.add(normalizedDate);
      }

      event.prayer.streak = calculateStreak(
        event.prayer.completedDates,
        DateTime.now(),
      );
      await event.prayer.save();
      add(LoadPrayers());
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }

  List<int> getLast7DaysStats(List<Prayer> prayers) {
    return last7DaysCompletionCounts(
      prayers.map((prayer) => prayer.completedDates),
      DateTime.now(),
    );
  }

  DateTime? _getPrayerTimeForToday(Prayer prayer) {
    if (!prayer.latitude.isFinite || !prayer.longitude.isFinite) {
      return null;
    }
    if (prayer.latitude == 0 && prayer.longitude == 0) {
      return null;
    }
    final coordinates = adhan.Coordinates(prayer.latitude, prayer.longitude);
    final params = adhan.CalculationMethod.muslim_world_league.getParameters();
    params.madhab = adhan.Madhab.shafi;
    final now = DateTime.now();
    final dateComponents = adhan.DateComponents(
      now.year,
      now.month,
      now.day,
    );
    final prayerTimes = adhan.PrayerTimes(coordinates, dateComponents, params);
    switch (prayer.name.toLowerCase()) {
      case 'fajr':
        return prayerTimes.fajr;
      case 'dhuhr':
        return prayerTimes.dhuhr;
      case 'asr':
        return prayerTimes.asr;
      case 'maghrib':
        return prayerTimes.maghrib;
      case 'isha':
        return prayerTimes.isha;
      default:
        return null;
    }
  }
}
