import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/constants/app_constants.dart';
import '../core/services/localization_service.dart';

// Localization Events
abstract class LocalizationEvent {}

class LocalizationInitialEvent extends LocalizationEvent {}

class LocalizationChangedEvent extends LocalizationEvent {
  final String languageCode;
  LocalizationChangedEvent(this.languageCode);
}

// Localization State
class LocalizationState {
  final Locale locale;

  LocalizationState({required this.locale});

  LocalizationState copyWith({Locale? locale}) {
    return LocalizationState(
      locale: locale ?? this.locale,
    );
  }
}

// Localization Bloc
class LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> {
  final LocalizationService _localizationService = LocalizationService();

  LocalizationBloc()
      : super(LocalizationState(
          locale: const Locale(AppConstants.defaultLanguage),
        )) {
    on<LocalizationInitialEvent>(_onLocalizationInitial);
    on<LocalizationChangedEvent>(_onLocalizationChanged);
  }

  Future<void> _onLocalizationInitial(
      LocalizationInitialEvent event, Emitter<LocalizationState> emit) async {
    await _localizationService.init();
    emit(state.copyWith(locale: _localizationService.currentLocale));
  }

  Future<void> _onLocalizationChanged(
      LocalizationChangedEvent event, Emitter<LocalizationState> emit) async {
    await _localizationService.changeLanguage(event.languageCode);
    emit(state.copyWith(locale: _localizationService.currentLocale));
  }
}
