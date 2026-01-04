import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

// --- Models ---
class SurahInfo {
  final int number;
  final String arabicName;
  final String englishName;
  final String frenchName;

  SurahInfo({
    required this.number,
    required this.arabicName,
    required this.englishName,
    required this.frenchName,
  });
}

// --- Events ---
abstract class QuranEvent {}

class LoadQuranEvent extends QuranEvent {}

class FilterQuranEvent extends QuranEvent {
  final String query;
  FilterQuranEvent(this.query);
}

// --- States ---
class QuranState {
  final List<SurahInfo> allSurahs;
  final List<SurahInfo> filteredSurahs;
  final bool isLoading;

  QuranState({
    this.allSurahs = const [],
    this.filteredSurahs = const [],
    this.isLoading = true,
  });

  QuranState copyWith({
    List<SurahInfo>? allSurahs,
    List<SurahInfo>? filteredSurahs,
    bool? isLoading,
  }) {
    return QuranState(
      allSurahs: allSurahs ?? this.allSurahs,
      filteredSurahs: filteredSurahs ?? this.filteredSurahs,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- BLoC ---
class QuranBloc extends Bloc<QuranEvent, QuranState> {
  QuranBloc() : super(QuranState()) {
    on<LoadQuranEvent>(_onLoad);
    on<FilterQuranEvent>(_onFilter);
  }

  void _onLoad(LoadQuranEvent event, Emitter<QuranState> emit) {
    final List<SurahInfo> surahs = [];
    for (int i = 1; i <= quran.totalSurahCount; i++) {
      surahs.add(
        SurahInfo(
          number: i,
          arabicName: quran.getSurahNameArabic(i),
          englishName: quran.getSurahNameEnglish(i),
          frenchName: quran.getSurahNameFrench(i),
        ),
      );
    }
    emit(
      state.copyWith(
        allSurahs: surahs,
        filteredSurahs: surahs,
        isLoading: false,
      ),
    );
  }

  void _onFilter(FilterQuranEvent event, Emitter<QuranState> emit) {
    if (event.query.isEmpty) {
      emit(state.copyWith(filteredSurahs: state.allSurahs));
      return;
    }
    final filtered = state.allSurahs.where((s) {
      return s.englishName.toLowerCase().contains(event.query.toLowerCase()) ||
          s.number.toString().contains(event.query);
    }).toList();
    emit(state.copyWith(filteredSurahs: filtered));
  }
}
