import 'package:equatable/equatable.dart';

abstract class MatchRequestsEvent extends Equatable {
  const MatchRequestsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMatchRequests extends MatchRequestsEvent {
  final String? stadiumId;

  const LoadMatchRequests({this.stadiumId});

  @override
  List<Object?> get props => [stadiumId];
}

class RefreshMatchRequests extends MatchRequestsEvent {
  final String? stadiumId;

  const RefreshMatchRequests({this.stadiumId});

  @override
  List<Object?> get props => [stadiumId];
}

class ApproveMatchRequest extends MatchRequestsEvent {
  final String bookingId;
  final String matchId;

  const ApproveMatchRequest({
    required this.bookingId,
    required this.matchId,
  });

  @override
  List<Object> get props => [bookingId, matchId];
}

class RejectMatchRequest extends MatchRequestsEvent {
  final String bookingId;
  final String? reason;

  const RejectMatchRequest({
    required this.bookingId,
    this.reason,
  });

  @override
  List<Object?> get props => [bookingId, reason];
}
