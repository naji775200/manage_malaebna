import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

// Onboarding Events
abstract class OnboardingEvent {}

class OnboardingCheckCompletionEvent extends OnboardingEvent {}

class OnboardingCompleteEvent extends OnboardingEvent {}

// Onboarding State
class OnboardingState {
  final bool isCompleted;

  OnboardingState({required this.isCompleted});

  OnboardingState copyWith({bool? isCompleted}) {
    return OnboardingState(
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

// Onboarding Bloc
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(OnboardingState(isCompleted: false)) {
    on<OnboardingCheckCompletionEvent>(_onCheckCompletion);
    on<OnboardingCompleteEvent>(_onComplete);
  }

  Future<void> _onCheckCompletion(OnboardingCheckCompletionEvent event,
      Emitter<OnboardingState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isCompleted =
        prefs.getBool(AppConstants.onboardingCompleted) ?? false;
    emit(state.copyWith(isCompleted: isCompleted));
  }

  Future<void> _onComplete(
      OnboardingCompleteEvent event, Emitter<OnboardingState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompleted, true);
    emit(state.copyWith(isCompleted: true));
  }
}
