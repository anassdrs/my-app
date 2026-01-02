import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/prayer.dart';
import '../utils/boxes.dart';

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

      // Recalculate streak
      int streak = 0;
      DateTime checkDate = DateTime.now();
      checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

      if (event.prayer.isCompletedOn(checkDate)) {
        while (event.prayer.isCompletedOn(checkDate)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      } else {
        DateTime yesterday = checkDate.subtract(const Duration(days: 1));
        if (event.prayer.isCompletedOn(yesterday)) {
          checkDate = yesterday;
          while (event.prayer.isCompletedOn(checkDate)) {
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          }
        }
      }

      event.prayer.streak = streak;
      await event.prayer.save();
      add(LoadPrayers());
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }

  List<int> getLast7DaysStats(List<Prayer> prayers) {
    List<int> counts = [];
    DateTime today = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime day = today.subtract(Duration(days: i));
      int count = 0;
      for (var prayer in prayers) {
        if (prayer.isCompletedOn(day)) {
          count++;
        }
      }
      counts.add(count);
    }
    return counts;
  }
}
