import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/auth_utils.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/match_history_repository.dart';
import '../../data/repositories/field_repository.dart';
import 'match_requests_event.dart';
import 'match_requests_state.dart';

class MatchRequestsBloc extends Bloc<MatchRequestsEvent, MatchRequestsState> {
  final MatchRepository _matchRepository;
  final BookingRepository _bookingRepository;
  final MatchHistoryRepository _matchHistoryRepository;
  final FieldRepository _fieldRepository;

  MatchRequestsBloc({
    required MatchRepository matchRepository,
    required BookingRepository bookingRepository,
    required MatchHistoryRepository matchHistoryRepository,
    required FieldRepository fieldRepository,
  })  : _matchRepository = matchRepository,
        _bookingRepository = bookingRepository,
        _matchHistoryRepository = matchHistoryRepository,
        _fieldRepository = fieldRepository,
        super(const MatchRequestsState()) {
    on<LoadMatchRequests>(_onLoadMatchRequests);
    on<RefreshMatchRequests>(_onRefreshMatchRequests);
    on<ApproveMatchRequest>(_onApproveMatchRequest);
    on<RejectMatchRequest>(_onRejectMatchRequest);
  }

  Future<void> _onLoadMatchRequests(
    LoadMatchRequests event,
    Emitter<MatchRequestsState> emit,
  ) async {
    emit(state.copyWith(status: MatchRequestsStatus.loading));

    try {
      print('🔍 Starting to load match requests');
      print('🔍 Checking for stadium ID in event or auth');

      // Get stadium ID - use debug value for development testing if needed
      String? stadiumId =
          event.stadiumId ?? await AuthUtils.getStadiumIdFromAuth();

      // If still null and in dev/debug mode, use a test ID for development
      if (stadiumId == null) {
        // Only for testing/development
        const bool useTestIdForDebug = true; // Set to false for production
        if (useTestIdForDebug) {
          stadiumId =
              '00000000-0000-0000-0000-000000000001'; // Replace with your actual test stadium ID
          print('🏟️ DEBUG MODE: Using test stadium ID: $stadiumId');
        }
      }

      print('🏟️ Stadium ID: $stadiumId');

      if (stadiumId.isEmpty) {
        print(
            '⚠️ No stadium ID available - user may not be logged in or not a stadium manager');
        emit(state.copyWith(
          status: MatchRequestsStatus.failure,
          errorMessage:
              'No stadium ID available. Please login as a stadium manager.',
        ));
        return;
      }

      print(
          '🔍 Fetching all matches for stadium ID: $stadiumId with related data');

      // Get all matches for this stadium in a single query with all related data
      final allStadiumMatches = await _matchRepository
          .getMatchesByStadiumId(stadiumId, forceRemote: true);

      print('📊 Found ${allStadiumMatches.length} matches for stadium fields');

      if (allStadiumMatches.isEmpty) {
        print('⚠️ No matches found for stadium fields');
        emit(state.copyWith(
          status: MatchRequestsStatus.success,
          pendingBookings: [],
          rejectedBookings: [],
          canceledBookings: [],
          acceptedMatches: [],
          matchesWithHistory: [],
        ));
        return;
      }

      // Extract all bookings from matches
      final allBookings =
          allStadiumMatches.expand((match) => match.bookings).toList();

      // Filter for pending bookings
      final pendingBookings = allBookings
          .where((booking) => booking.status.toLowerCase() == 'pending')
          .toList();

      // Filter for rejected bookings
      final rejectedBookings = allBookings
          .where((booking) => booking.status.toLowerCase() == 'rejected')
          .toList();

      // Filter for canceled bookings (bookings with cancellation data)
      final canceledBookings =
          allBookings.where((booking) => booking.cancellation != null).toList();

      print('📊 Found ${pendingBookings.length} pending bookings');
      print('📊 Found ${rejectedBookings.length} rejected bookings');
      print('📊 Found ${canceledBookings.length} canceled bookings');

      // Get accepted matches
      final acceptedMatches = allStadiumMatches
          .where((match) => match.status.toLowerCase() == 'accepted')
          .toList();

      print('📊 Found ${acceptedMatches.length} accepted matches');

      // Get matches with history
      final matchesWithHistory =
          allStadiumMatches.where((match) => match.history != null).toList();

      print('📊 Found ${matchesWithHistory.length} matches with history');

      // Update state with all the data
      emit(state.copyWith(
        status: MatchRequestsStatus.success,
        pendingBookings: pendingBookings,
        rejectedBookings: rejectedBookings,
        canceledBookings: canceledBookings,
        acceptedMatches: acceptedMatches,
        matchesWithHistory: matchesWithHistory,
      ));

      print(
          '✅ State updated: ${pendingBookings.length} pending, ${rejectedBookings.length} rejected, ${canceledBookings.length} canceled, ${acceptedMatches.length} accepted, ${matchesWithHistory.length} history');
    } catch (e) {
      print('❌ ERROR loading match requests: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      emit(state.copyWith(
        status: MatchRequestsStatus.failure,
        errorMessage: 'Failed to load match requests: $e',
      ));
    }
  }

  Future<void> _onRefreshMatchRequests(
    RefreshMatchRequests event,
    Emitter<MatchRequestsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));

    try {
      await _onLoadMatchRequests(
          LoadMatchRequests(stadiumId: event.stadiumId), emit);
    } finally {
      emit(state.copyWith(isRefreshing: false));
    }
  }

  Future<void> _onApproveMatchRequest(
    ApproveMatchRequest event,
    Emitter<MatchRequestsState> emit,
  ) async {
    try {
      // Find the booking
      final bookingToApprove = state.pendingBookings.firstWhere(
        (booking) => booking.id == event.bookingId,
        orElse: () => throw Exception('Booking not found'),
      );

      // Find the match
      final matchToUpdate = await _matchRepository.getMatchById(event.matchId);
      if (matchToUpdate == null) {
        throw Exception('Match not found');
      }

      // Update booking status
      final updatedBooking = bookingToApprove.copyWith(status: 'accepted');
      await _bookingRepository.updateBooking(updatedBooking);

      // Update match status
      final updatedMatch = matchToUpdate.copyWith(status: 'accepted');
      await _matchRepository.updateMatch(updatedMatch);

      // Update state
      final updatedPendingBookings = state.pendingBookings
          .where((booking) => booking.id != event.bookingId)
          .toList();

      final updatedAcceptedMatches = [...state.acceptedMatches, updatedMatch];

      emit(state.copyWith(
        pendingBookings: updatedPendingBookings,
        acceptedMatches: updatedAcceptedMatches,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to approve match request: $e',
      ));
    }
  }

  Future<void> _onRejectMatchRequest(
    RejectMatchRequest event,
    Emitter<MatchRequestsState> emit,
  ) async {
    try {
      // Find the booking to reject
      final bookingToReject = state.pendingBookings.firstWhere(
        (booking) => booking.id == event.bookingId,
        orElse: () => throw Exception('Booking not found'),
      );

      // Update booking status to rejected
      final updatedBooking = bookingToReject.copyWith(status: 'rejected');
      await _bookingRepository.updateBooking(updatedBooking);

      // Remove from pending bookings list
      final updatedPendingBookings = state.pendingBookings
          .where((booking) => booking.id != event.bookingId)
          .toList();

      emit(state.copyWith(
        pendingBookings: updatedPendingBookings,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to reject match request: $e',
      ));
    }
  }
}
