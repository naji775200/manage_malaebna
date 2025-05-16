import 'package:equatable/equatable.dart';
import '../../data/models/match_model.dart';
import '../../data/models/booking_model.dart';

enum MatchRequestsStatus { initial, loading, success, failure }

class MatchRequestsState extends Equatable {
  final MatchRequestsStatus status;
  final List<Booking> pendingBookings;
  final List<Booking> rejectedBookings;
  final List<Booking> canceledBookings;
  final List<Match> acceptedMatches;
  final List<Match> matchesWithHistory;
  final String? errorMessage;
  final bool isRefreshing;

  const MatchRequestsState({
    this.status = MatchRequestsStatus.initial,
    this.pendingBookings = const [],
    this.rejectedBookings = const [],
    this.canceledBookings = const [],
    this.acceptedMatches = const [],
    this.matchesWithHistory = const [],
    this.errorMessage,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [
        status,
        pendingBookings,
        rejectedBookings,
        canceledBookings,
        acceptedMatches,
        matchesWithHistory,
        errorMessage,
        isRefreshing,
      ];

  MatchRequestsState copyWith({
    MatchRequestsStatus? status,
    List<Booking>? pendingBookings,
    List<Booking>? rejectedBookings,
    List<Booking>? canceledBookings,
    List<Match>? acceptedMatches,
    List<Match>? matchesWithHistory,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return MatchRequestsState(
      status: status ?? this.status,
      pendingBookings: pendingBookings ?? this.pendingBookings,
      rejectedBookings: rejectedBookings ?? this.rejectedBookings,
      canceledBookings: canceledBookings ?? this.canceledBookings,
      acceptedMatches: acceptedMatches ?? this.acceptedMatches,
      matchesWithHistory: matchesWithHistory ?? this.matchesWithHistory,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  // Helper getters
  bool get isInitial => status == MatchRequestsStatus.initial;
  bool get isLoading => status == MatchRequestsStatus.loading;
  bool get isSuccess => status == MatchRequestsStatus.success;
  bool get isError => status == MatchRequestsStatus.failure;

  bool get hasPendingBookings => pendingBookings.isNotEmpty;
  bool get hasRejectedBookings => rejectedBookings.isNotEmpty;
  bool get hasCanceledBookings => canceledBookings.isNotEmpty;
  bool get hasAcceptedMatches => acceptedMatches.isNotEmpty;
  bool get hasMatchHistory => matchesWithHistory.isNotEmpty;

  bool hasMatchRequestsWithStatus(String requestStatus) {
    switch (requestStatus) {
      case 'Pending':
        return hasPendingBookings;
      case 'Rejected':
        return hasRejectedBookings;
      case 'Canceled':
        return hasCanceledBookings;
      case 'Accepted':
        return hasAcceptedMatches;
      case 'Completed':
        return hasMatchHistory;
      default:
        return false;
    }
  }
}
