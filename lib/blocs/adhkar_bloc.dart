import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- Models ---
class DhikrItem {
  final String title;
  final String text;
  final String translation;
  final int repeat;
  final int count;

  DhikrItem({
    required this.title,
    required this.text,
    required this.translation,
    required this.repeat,
    this.count = 0,
  });

  factory DhikrItem.fromMap(Map<String, dynamic> map) {
    return DhikrItem(
      title: map['title']?.toString() ?? 'Dhikr',
      text: map['text']?.toString() ?? '',
      translation: map['translation']?.toString() ?? '',
      repeat: map['repeat'] is int ? map['repeat'] as int : 0,
      count: map['count'] is int ? map['count'] as int : 0,
    );
  }

  DhikrItem copyWith({int? count}) {
    return DhikrItem(
      title: title,
      text: text,
      translation: translation,
      repeat: repeat,
      count: count ?? this.count,
    );
  }
}

// --- Events ---
abstract class AdhkarEvent {}

class LoadAdhkarEvent extends AdhkarEvent {}

class IncrementDhikrEvent extends AdhkarEvent {
  final int index;
  IncrementDhikrEvent(this.index);
}

class ResetDhikrEvent extends AdhkarEvent {
  final int index;
  ResetDhikrEvent(this.index);
}

// --- States ---
abstract class AdhkarState {}

class AdhkarInitial extends AdhkarState {}

class AdhkarLoading extends AdhkarState {}

class AdhkarLoaded extends AdhkarState {
  final List<DhikrItem> items;
  AdhkarLoaded(this.items);
}

class AdhkarError extends AdhkarState {
  final String message;
  AdhkarError(this.message);
}

// --- BLoC ---
class AdhkarBloc extends Bloc<AdhkarEvent, AdhkarState> {
  AdhkarBloc() : super(AdhkarInitial()) {
    on<LoadAdhkarEvent>(_onLoad);
    on<IncrementDhikrEvent>(_onIncrement);
    on<ResetDhikrEvent>(_onReset);
  }

  Future<void> _onLoad(LoadAdhkarEvent event, Emitter<AdhkarState> emit) async {
    emit(AdhkarLoading());
    try {
      final String response = await rootBundle.loadString(
        'assets/data/adhkar.json',
      );
      final List<dynamic> data = json.decode(response);
      final items = data.map((e) => DhikrItem.fromMap(e)).toList();
      emit(AdhkarLoaded(items));
    } catch (e) {
      emit(AdhkarError(e.toString()));
    }
  }

  void _onIncrement(IncrementDhikrEvent event, Emitter<AdhkarState> emit) {
    if (state is AdhkarLoaded) {
      final items = List<DhikrItem>.from((state as AdhkarLoaded).items);
      final item = items[event.index];
      items[event.index] = item.copyWith(count: item.count + 1);
      emit(AdhkarLoaded(items));
    }
  }

  void _onReset(ResetDhikrEvent event, Emitter<AdhkarState> emit) {
    if (state is AdhkarLoaded) {
      final items = List<DhikrItem>.from((state as AdhkarLoaded).items);
      items[event.index] = items[event.index].copyWith(count: 0);
      emit(AdhkarLoaded(items));
    }
  }
}
