import 'dart:async';
import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../services/prayer_time_service.dart';

// --- Events ---
abstract class QiblaEvent {}

class LoadQiblaEvent extends QiblaEvent {}

class UpdateHeadingEvent extends QiblaEvent {
  final double heading;
  UpdateHeadingEvent(this.heading);
}

// --- States ---
abstract class QiblaState {}

class QiblaInitial extends QiblaState {}

class QiblaLoading extends QiblaState {}

class QiblaLoaded extends QiblaState {
  final double qiblaAngle;
  final String locationLabel;
  final bool isFallback;
  final double? heading;

  QiblaLoaded({
    required this.qiblaAngle,
    required this.locationLabel,
    required this.isFallback,
    this.heading,
  });

  QiblaLoaded copyWith({double? heading}) {
    return QiblaLoaded(
      qiblaAngle: qiblaAngle,
      locationLabel: locationLabel,
      isFallback: isFallback,
      heading: heading ?? this.heading,
    );
  }
}

class QiblaError extends QiblaState {
  final String message;
  QiblaError(this.message);
}

// --- BLoC ---
class QiblaBloc extends Bloc<QiblaEvent, QiblaState> {
  StreamSubscription<CompassEvent>? _compassSubscription;

  QiblaBloc() : super(QiblaInitial()) {
    on<LoadQiblaEvent>(_onLoad);
    on<UpdateHeadingEvent>(_onUpdateHeading);
  }

  Future<void> _onLoad(LoadQiblaEvent event, Emitter<QiblaState> emit) async {
    emit(QiblaLoading());
    try {
      final service = PrayerTimeService();
      final result = await service.getPrayerTimes();
      final qiblaAngle = adhan.Qibla(result.coordinates).direction;

      emit(
        QiblaLoaded(
          qiblaAngle: qiblaAngle,
          locationLabel: result.locationLabel,
          isFallback: result.usedFallback,
        ),
      );

      _compassSubscription?.cancel();
      _compassSubscription = FlutterCompass.events!.listen((event) {
        if (event.heading != null) {
          add(UpdateHeadingEvent(event.heading!));
        }
      });
    } catch (e) {
      emit(QiblaError(e.toString()));
    }
  }

  void _onUpdateHeading(UpdateHeadingEvent event, Emitter<QiblaState> emit) {
    if (state is QiblaLoaded) {
      emit((state as QiblaLoaded).copyWith(heading: event.heading));
    }
  }

  @override
  Future<void> close() {
    _compassSubscription?.cancel();
    return super.close();
  }
}
