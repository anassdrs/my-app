import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';

// --- Events ---
abstract class LoginEvent {}

class LoginSubmittedEvent extends LoginEvent {
  final String email;
  final String password;
  LoginSubmittedEvent({required this.email, required this.password});
}

// --- States ---
abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {}

class LoginFailure extends LoginState {
  final String error;
  LoginFailure(this.error);
}

// --- BLoC ---
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthProvider authProvider;

  LoginBloc({required this.authProvider}) : super(LoginInitial()) {
    on<LoginSubmittedEvent>((event, emit) async {
      emit(LoginLoading());
      try {
        final error = await authProvider.login(event.email, event.password);
        if (error == null) {
          emit(LoginSuccess());
        } else {
          emit(LoginFailure(error));
        }
      } catch (e) {
        debugPrint('Login failed: $e');
        emit(LoginFailure('Login failed, please try again.'));
      }
    });
  }
}
