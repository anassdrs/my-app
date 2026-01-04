import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

// --- Events ---
abstract class ProfileEvent {}

class LoadProfileEvent extends ProfileEvent {}

class UpdateProfileFieldEvent extends ProfileEvent {
  final String? username;
  final String? bio;
  final int? accentColorValue;
  UpdateProfileFieldEvent({this.username, this.bio, this.accentColorValue});
}

class SaveProfileEvent extends ProfileEvent {}

class LogoutEvent extends ProfileEvent {}

class ToggleThemeEvent extends ProfileEvent {}

// --- States ---
class ProfileState {
  final String username;
  final String bio;
  final int? accentColorValue;
  final bool isDirty;
  final bool isLoading;
  final bool isDarkMode;
  final String? error;
  final bool success;

  ProfileState({
    this.username = '',
    this.bio = '',
    this.accentColorValue,
    this.isDirty = false,
    this.isLoading = false,
    this.isDarkMode = true,
    this.error,
    this.success = false,
  });

  ProfileState copyWith({
    String? username,
    String? bio,
    int? accentColorValue,
    bool? isDirty,
    bool? isLoading,
    bool? isDarkMode,
    String? error,
    bool? success,
  }) {
    return ProfileState(
      username: username ?? this.username,
      bio: bio ?? this.bio,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      isDirty: isDirty ?? this.isDirty,
      isLoading: isLoading ?? this.isLoading,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      error: error,
      success: success ?? false,
    );
  }
}

// --- BLoC ---
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthProvider authProvider;
  final ThemeProvider themeProvider;

  ProfileBloc({required this.authProvider, required this.themeProvider})
    : super(ProfileState()) {
    on<LoadProfileEvent>((event, emit) {
      emit(
        state.copyWith(
          username: authProvider.currentUser?.username ?? '',
          bio: authProvider.profileBio,
          accentColorValue: authProvider.accentColorValue,
          isDarkMode: themeProvider.isDarkMode,
        ),
      );
    });

    on<UpdateProfileFieldEvent>((event, emit) {
      emit(
        state.copyWith(
          username: event.username,
          bio: event.bio,
          accentColorValue: event.accentColorValue,
          isDirty: true,
        ),
      );
    });

    on<SaveProfileEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        await authProvider.updateProfile(
          username: state.username,
          bio: state.bio,
          accentColorValue: state.accentColorValue,
        );
        emit(state.copyWith(isLoading: false, isDirty: false, success: true));
      } catch (e) {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    });

    on<LogoutEvent>((event, emit) {
      authProvider.logout();
    });

    on<ToggleThemeEvent>((event, emit) {
      themeProvider.toggleTheme();
      emit(state.copyWith(isDarkMode: themeProvider.isDarkMode));
    });
  }
}
