import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class LoadHomeData extends HomeEvent {
  const LoadHomeData();
}

class RefreshHomeData extends HomeEvent {
  const RefreshHomeData();
}

class ViewAllNearbyStadiums extends HomeEvent {
  const ViewAllNearbyStadiums();
}

class ViewAllUpcomingMatches extends HomeEvent {
  const ViewAllUpcomingMatches();
}

class JoinMatch extends HomeEvent {
  final int matchId;

  const JoinMatch(this.matchId);

  @override
  List<Object> get props => [matchId];
}
