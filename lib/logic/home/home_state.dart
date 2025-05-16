import 'package:equatable/equatable.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final List<dynamic> nearbyStadiums; // Replace with actual Stadium model
  final List<dynamic> upcomingMatches; // Replace with actual Match model
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.nearbyStadiums = const [],
    this.upcomingMatches = const [],
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<dynamic>? nearbyStadiums,
    List<dynamic>? upcomingMatches,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      nearbyStadiums: nearbyStadiums ?? this.nearbyStadiums,
      upcomingMatches: upcomingMatches ?? this.upcomingMatches,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, nearbyStadiums, upcomingMatches, errorMessage];

  bool get isInitial => status == HomeStatus.initial;
  bool get isLoading => status == HomeStatus.loading;
  bool get isLoaded => status == HomeStatus.loaded;
  bool get isError => status == HomeStatus.error;
}
