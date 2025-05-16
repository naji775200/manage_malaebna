import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  // Add any repositories or services as dependencies here

  HomeBloc() : super(const HomeState()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<RefreshHomeData>(_onRefreshHomeData);
    on<ViewAllNearbyStadiums>(_onViewAllNearbyStadiums);
    on<ViewAllUpcomingMatches>(_onViewAllUpcomingMatches);
    on<JoinMatch>(_onJoinMatch);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      // Simulating API call with delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock data for demonstration
      final stadiums =
          List.generate(5, (index) => {'id': index, 'name': 'Stadium $index'});
      final matches =
          List.generate(3, (index) => {'id': index, 'name': 'Match $index'});

      emit(state.copyWith(
        status: HomeStatus.loaded,
        nearbyStadiums: stadiums,
        upcomingMatches: matches,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeData event,
    Emitter<HomeState> emit,
  ) async {
    // Keep the current data while refreshing
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      // Simulating API call with delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock refreshed data for demonstration
      final stadiums = List.generate(
          5, (index) => {'id': index, 'name': 'Refreshed Stadium $index'});
      final matches = List.generate(
          3, (index) => {'id': index, 'name': 'Refreshed Match $index'});

      emit(state.copyWith(
        status: HomeStatus.loaded,
        nearbyStadiums: stadiums,
        upcomingMatches: matches,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onViewAllNearbyStadiums(
    ViewAllNearbyStadiums event,
    Emitter<HomeState> emit,
  ) {
    // Here you would navigate to a "All Stadiums" screen
    // This can be handled in the UI using a BlocListener
  }

  void _onViewAllUpcomingMatches(
    ViewAllUpcomingMatches event,
    Emitter<HomeState> emit,
  ) {
    // Here you would navigate to a "All Matches" screen
    // This can be handled in the UI using a BlocListener
  }

  Future<void> _onJoinMatch(
    JoinMatch event,
    Emitter<HomeState> emit,
  ) async {
    try {
      // Simulating API call to join a match
      await Future.delayed(const Duration(milliseconds: 500));

      // Here you would update the state with the joined match status
      // For now we'll just refresh the data
      add(const RefreshHomeData());
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
