import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';

// --- Events ---
abstract class RegisterEvent {}

class RegisterSubmittedEvent extends RegisterEvent {
  final String email;
  final String password;
  RegisterSubmittedEvent({required this.email, required this.password});
}

// --- States ---
abstract class RegisterState {}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {}

class RegisterFailure extends RegisterState {
  final String error;
  RegisterFailure(this.error);
}

// --- BLoC ---
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthProvider authProvider;

  RegisterBloc({required this.authProvider}) : super(RegisterInitial()) {
    on<RegisterSubmittedEvent>((event, emit) async {
      emit(RegisterLoading());
      try {
        final error = await authProvider.register(event.email, event.password);
        if (error == null) {
          emit(RegisterSuccess());
        } else {
          emit(RegisterFailure(error));
        }
      } catch (e) {
        debugPrint('Register failed: $e');
        emit(RegisterFailure('Register failed, please try again.'));
      }
    });
  }
}
