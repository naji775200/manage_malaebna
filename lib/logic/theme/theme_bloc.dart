import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/theme.dart';

// Theme Events
abstract class ThemeEvent {}

class ThemeInitialEvent extends ThemeEvent {}

class ThemeChangedEvent extends ThemeEvent {
  final ThemeMode themeMode;
  ThemeChangedEvent(this.themeMode);
}

// Theme State
class ThemeState {
  final ThemeData themeData;
  final ThemeMode themeMode;

  ThemeState({required this.themeData, required this.themeMode});

  ThemeState copyWith({ThemeData? themeData, ThemeMode? themeMode}) {
    return ThemeState(
      themeData: themeData ?? this.themeData,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

// Theme Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc()
      : super(ThemeState(
          themeData: AppTheme.getLightTheme(),
          themeMode: ThemeMode.system,
        )) {
    on<ThemeInitialEvent>(_onThemeInitial);
    on<ThemeChangedEvent>(_onThemeChanged);
  }

  Future<void> _onThemeInitial(
      ThemeInitialEvent event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(AppConstants.themeMode) ?? 'system';

    ThemeMode themeMode;
    ThemeData themeData;

    switch (themeString) {
      case 'dark':
        themeMode = ThemeMode.dark;
        themeData = AppTheme.getDarkTheme();
        break;
      case 'light':
        themeMode = ThemeMode.light;
        themeData = AppTheme.getLightTheme();
        break;
      case 'system':
      default:
        themeMode = ThemeMode.system;
        themeData = AppTheme.getLightTheme();
        break;
    }

    await prefs.setString(AppConstants.themeMode, themeString);
    emit(state.copyWith(themeData: themeData, themeMode: themeMode));
  }

  Future<void> _onThemeChanged(
      ThemeChangedEvent event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    ThemeData themeData;
    String themeString;

    switch (event.themeMode) {
      case ThemeMode.dark:
        themeData = AppTheme.getDarkTheme();
        themeString = 'dark';
        break;
      case ThemeMode.light:
        themeData = AppTheme.getLightTheme();
        themeString = 'light';
        break;
      case ThemeMode.system:
      default:
        themeData = AppTheme.getLightTheme();
        themeString = 'system';
        break;
    }

    await prefs.setString(AppConstants.themeMode, themeString);
    emit(state.copyWith(themeData: themeData, themeMode: event.themeMode));
  }
}
