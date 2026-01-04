import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class HomeEvent {}

class ChangeTabEvent extends HomeEvent {
  final int index;
  ChangeTabEvent(this.index);
}

// States
class HomeState {
  final int currentIndex;
  const HomeState({this.currentIndex = 0});
}

// BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState()) {
    on<ChangeTabEvent>((event, emit) {
      emit(HomeState(currentIndex: event.index));
    });
  }
}
