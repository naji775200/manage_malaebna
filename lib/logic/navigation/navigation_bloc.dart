import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState()) {
    on<NavigationTabChanged>(_onTabChanged);
    on<NavigateToHomeTab>(_onNavigateToHomeTab);
    on<NavigateToFieldsTab>(_onNavigateToFieldsTab);
    on<NavigateToRequestsTab>(_onNavigateToRequestsTab);
    on<NavigateToReportsTab>(_onNavigateToReportsTab);
    on<NavigateToProfileTab>(_onNavigateToProfileTab);
  }

  void _onTabChanged(
      NavigationTabChanged event, Emitter<NavigationState> emit) {
    emit(state.copyWith(selectedIndex: event.tabIndex));
  }

  void _onNavigateToHomeTab(
      NavigateToHomeTab event, Emitter<NavigationState> emit) {
    emit(state.copyWith(selectedIndex: 0));
  }

  void _onNavigateToFieldsTab(
      NavigateToFieldsTab event, Emitter<NavigationState> emit) {
    emit(state.copyWith(selectedIndex: 1));
  }

  void _onNavigateToRequestsTab(
      NavigateToRequestsTab event, Emitter<NavigationState> emit) {
    emit(state.copyWith(selectedIndex: 2));
  }

  void _onNavigateToReportsTab(
      NavigateToReportsTab event, Emitter<NavigationState> emit) {
    emit(state.copyWith(selectedIndex: 3));
  }

  void _onNavigateToProfileTab(
      NavigateToProfileTab event, Emitter<NavigationState> emit) {
    emit(state.copyWith(selectedIndex: 4));
  }
}
