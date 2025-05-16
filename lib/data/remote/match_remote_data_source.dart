import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking_model.dart';
import '../models/booking_player_model.dart';
import '../models/cancellation_model.dart';
import '../models/match_history_model.dart';
import '../models/match_model.dart';
import 'base_remote_data_source.dart';

// Add the DatabaseException class definition
class DatabaseException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  DatabaseException({required this.message, this.code, this.details});

  @override
  String toString() =>
      'DatabaseException: $message${code != null ? ' (Code: $code)' : ''}${details != null ? ' - $details' : ''}';
}

class MatchRemoteDataSource extends BaseRemoteDataSource<Match> {
  // Define table names as constants for consistency
  static const String TABLE_MATCHES = 'matches';
  static const String TABLE_BOOKING = 'booking';
  static const String TABLE_BOOKING_PLAYERS = 'booking_players';
  static const String TABLE_CANCELLATIONS = 'cancellations';
  static const String TABLE_MATCH_HISTORY = 'match_history';
  static const String TABLE_FIELD = 'fields';

  @override
  String get tableName => TABLE_MATCHES;

  MatchRemoteDataSource() : super(TABLE_MATCHES);

  Future<Match> getByIdWithRelations(String id) async {
    try {
      print('📡 MatchRemoteDataSource: Getting match with relations, ID: $id');
      final matchData = await getById(id);
      if (matchData == null) {
        throw Exception('Match not found');
      }

      final match = Match.fromJson(matchData);
      final history = await _getMatchHistory(id);
      return match.copyWith(
        bookings: await _getBookings(id),
        history: history.isNotEmpty ? history.first : null,
      );
    } catch (e) {
      print(
          '❌ MatchRemoteDataSource ERROR: Failed to get match with relations: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<Match>> getAllWithRelations() async {
    try {
      print('📡 MatchRemoteDataSource: Getting all matches with relations');
      final matchesData = await getAll();
      final matches =
          matchesData.map<Match>((json) => Match.fromJson(json)).toList();

      // Load related data for each match
      List<Match> completeMatches = [];
      for (var match in matches) {
        final bookings = await _getBookings(match.id);
        final history = await _getMatchHistory(match.id);
        completeMatches.add(match.copyWith(
          bookings: bookings,
          history: history.isNotEmpty ? history.first : null,
        ));
      }

      return completeMatches;
    } catch (e) {
      print(
          '❌ MatchRemoteDataSource ERROR: Failed to get all matches with relations: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<Match?> getMatchById(String id) async {
    try {
      print(
          '📡 MatchRemoteDataSource: Getting match by ID: $id with a single query');

      // Use a join query to get all related data at once
      final response = await supabase.from(TABLE_MATCHES).select('''
            *,
            $TABLE_BOOKING:$TABLE_BOOKING(
              *,
              $TABLE_BOOKING_PLAYERS:$TABLE_BOOKING_PLAYERS(*),
              $TABLE_CANCELLATIONS:$TABLE_CANCELLATIONS(*)
            ),
            $TABLE_MATCH_HISTORY:$TABLE_MATCH_HISTORY(*)
          ''').eq('id', id).maybeSingle();

      if (response == null) {
        print('📡 MatchRemoteDataSource: No match found with ID: $id');
        return null;
      }

      try {
        // Extract match data
        final matchJson = Map<String, dynamic>.from(response);

        // Remove nested data before creating Match object
        final bookingsData = matchJson.remove(TABLE_BOOKING) ?? [];
        final historyData = matchJson.remove(TABLE_MATCH_HISTORY) ?? [];

        // Create the match
        final match = Match.fromJson(matchJson);

        // Process bookings
        final bookings = <Booking>[];
        for (var bookingData in bookingsData) {
          final bookingJson = Map<String, dynamic>.from(bookingData);

          // Extract nested booking data
          final playersData = bookingJson.remove(TABLE_BOOKING_PLAYERS) ?? [];
          final cancellationsData =
              bookingJson.remove(TABLE_CANCELLATIONS) ?? [];

          // Create the booking
          final booking = Booking.fromJson(bookingJson);

          // Process booking players
          final players = playersData
              .map<BookingPlayer>(
                  (playerData) => BookingPlayer.fromJson(playerData))
              .toList();

          // Process cancellation (should be at most one)
          Cancellation? cancellation;
          if (cancellationsData.isNotEmpty) {
            cancellation = Cancellation.fromJson(cancellationsData[0]);
          }

          // Add the complete booking with its related data
          bookings.add(
              booking.copyWith(players: players, cancellation: cancellation));
        }

        // Process match history (should be at most one)
        MatchHistory? history;
        if (historyData.isNotEmpty) {
          history = MatchHistory.fromJson(historyData[0]);
        }

        // Return the complete match with all its related data
        return match.copyWith(bookings: bookings, history: history);
      } catch (e) {
        print(
            '❌ MatchRemoteDataSource ERROR: Failed to process match data: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        rethrow;
      }
    } catch (e) {
      print('❌ MatchRemoteDataSource ERROR: Failed to get match by ID: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<Match>> getAllMatches() async {
    try {
      print(
          '📡 MatchRemoteDataSource: Getting all matches with a single query');

      // Use a single query with joins to get all related data at once
      final response = await supabase.from(TABLE_MATCHES).select('''
            *,
            $TABLE_BOOKING:$TABLE_BOOKING(
              *,
              $TABLE_BOOKING_PLAYERS:$TABLE_BOOKING_PLAYERS(*),
              $TABLE_CANCELLATIONS:$TABLE_CANCELLATIONS(*)
            ),
            $TABLE_MATCH_HISTORY:$TABLE_MATCH_HISTORY(*)
          ''');

      print('📡 MatchRemoteDataSource: Query completed, processing results');

      final matches = <Match>[];
      for (var matchData in response) {
        try {
          // Extract match data
          final matchJson = Map<String, dynamic>.from(matchData);

          // Remove nested data before creating Match object
          final bookingsData = matchJson.remove(TABLE_BOOKING) ?? [];
          final historyData = matchJson.remove(TABLE_MATCH_HISTORY) ?? [];

          // Create the match
          final match = Match.fromJson(matchJson);

          // Process bookings
          final bookings = <Booking>[];
          for (var bookingData in bookingsData) {
            final bookingJson = Map<String, dynamic>.from(bookingData);

            // Extract nested booking data
            final playersData = bookingJson.remove(TABLE_BOOKING_PLAYERS) ?? [];
            final cancellationsData =
                bookingJson.remove(TABLE_CANCELLATIONS) ?? [];

            // Create the booking
            final booking = Booking.fromJson(bookingJson);

            // Process booking players
            final players = playersData
                .map<BookingPlayer>(
                    (playerData) => BookingPlayer.fromJson(playerData))
                .toList();

            // Process cancellation (should be at most one)
            Cancellation? cancellation;
            if (cancellationsData.isNotEmpty) {
              cancellation = Cancellation.fromJson(cancellationsData[0]);
            }

            // Add the complete booking with its related data
            bookings.add(
                booking.copyWith(players: players, cancellation: cancellation));
          }

          // Process match history (should be at most one)
          MatchHistory? history;
          if (historyData.isNotEmpty) {
            history = MatchHistory.fromJson(historyData[0]);
          }

          // Add the complete match with all its related data
          matches.add(match.copyWith(bookings: bookings, history: history));
        } catch (e) {
          print('❌ Error processing match data: $e');
          // Continue with next match if one fails
          continue;
        }
      }

      print(
          '📡 MatchRemoteDataSource: Successfully processed ${matches.length} matches');
      return matches;
    } catch (e) {
      print('❌ MatchRemoteDataSource ERROR: Failed to get all matches: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<String> insertMatch(Match match) async {
    final data = await insert(match.toJson());
    if (data == null) {
      throw Exception('Failed to insert match');
    }

    final newMatch = Match.fromJson(data);

    // Insert related bookings if any
    if (match.bookings.isNotEmpty) {
      await _insertBookings(newMatch.id, match.bookings);
    }

    // Insert related history if exists
    if (match.history != null) {
      final historyList = [match.history!];
      await _insertMatchHistory(newMatch.id, historyList);
    }

    return newMatch.id;
  }

  Future<bool> updateMatch(Match match) async {
    try {
      await update(match.id, match.toJson());

      // Handle related bookings
      await _deleteBookings(match.id);
      if (match.bookings.isNotEmpty) {
        await _insertBookings(match.id, match.bookings);
      }

      // Handle related history
      await _deleteMatchHistory(match.id);
      if (match.history != null) {
        final historyList = [match.history!];
        await _insertMatchHistory(match.id, historyList);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMatch(String id) async {
    try {
      // Delete related data first
      await _deleteBookings(id);
      await _deleteMatchHistory(id);

      // Then delete the match
      await delete(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Match>> getMatchesByFieldId(String fieldId) async {
    try {
      print(
          '📡 MatchRemoteDataSource: Getting matches by field ID: $fieldId with a single query');

      // Use a join query to get all related data at once
      final response = await supabase.from(TABLE_MATCHES).select('''
            *,
            $TABLE_BOOKING:$TABLE_BOOKING(
              *,
              $TABLE_BOOKING_PLAYERS:$TABLE_BOOKING_PLAYERS(*),
              $TABLE_CANCELLATIONS:$TABLE_CANCELLATIONS(*)
            ),
            $TABLE_MATCH_HISTORY:$TABLE_MATCH_HISTORY(*)
          ''').eq('field_id', fieldId);

      print('📡 MatchRemoteDataSource: Query completed, processing results');

      final matches = <Match>[];
      for (var matchData in response) {
        try {
          // Extract match data
          final matchJson = Map<String, dynamic>.from(matchData);

          // Remove nested data before creating Match object
          final bookingsData = matchJson.remove(TABLE_BOOKING) ?? [];
          final historyData = matchJson.remove(TABLE_MATCH_HISTORY) ?? [];

          // Create the match
          final match = Match.fromJson(matchJson);

          // Process bookings
          final bookings = <Booking>[];
          for (var bookingData in bookingsData) {
            final bookingJson = Map<String, dynamic>.from(bookingData);

            // Extract nested booking data
            final playersData = bookingJson.remove(TABLE_BOOKING_PLAYERS) ?? [];
            final cancellationsData =
                bookingJson.remove(TABLE_CANCELLATIONS) ?? [];

            // Create the booking
            final booking = Booking.fromJson(bookingJson);

            // Process booking players
            final players = playersData
                .map<BookingPlayer>(
                    (playerData) => BookingPlayer.fromJson(playerData))
                .toList();

            // Process cancellation (should be at most one)
            Cancellation? cancellation;
            if (cancellationsData.isNotEmpty) {
              cancellation = Cancellation.fromJson(cancellationsData[0]);
            }

            // Add the complete booking with its related data
            bookings.add(
                booking.copyWith(players: players, cancellation: cancellation));
          }

          // Process match history (should be at most one)
          MatchHistory? history;
          if (historyData.isNotEmpty) {
            history = MatchHistory.fromJson(historyData[0]);
          }

          // Add the complete match with all its related data
          matches.add(match.copyWith(bookings: bookings, history: history));
        } catch (e) {
          print('❌ Error processing match data: $e');
          // Continue with next match if one fails
          continue;
        }
      }

      print(
          '📡 MatchRemoteDataSource: Successfully processed ${matches.length} matches for field ID: $fieldId');
      return matches;
    } catch (e) {
      print(
          '❌ MatchRemoteDataSource ERROR: Failed to get matches by field ID: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<Match>> getMatchesByDate(DateTime date) async {
    try {
      // Convert DateTime to string format YYYY-MM-DD
      final dateString = date.toIso8601String().split('T')[0];

      print(
          '📡 MatchRemoteDataSource: Getting matches by date: $dateString with a single query');

      // Use a join query to get all related data at once
      final response = await supabase.from(TABLE_MATCHES).select('''
            *,
            $TABLE_BOOKING:$TABLE_BOOKING(
              *,
              $TABLE_BOOKING_PLAYERS:$TABLE_BOOKING_PLAYERS(*),
              $TABLE_CANCELLATIONS:$TABLE_CANCELLATIONS(*)
            ),
            $TABLE_MATCH_HISTORY:$TABLE_MATCH_HISTORY(*)
          ''').eq('date', dateString);

      print('📡 MatchRemoteDataSource: Query completed, processing results');

      final matches = <Match>[];
      for (var matchData in response) {
        try {
          // Extract match data
          final matchJson = Map<String, dynamic>.from(matchData);

          // Remove nested data before creating Match object
          final bookingsData = matchJson.remove(TABLE_BOOKING) ?? [];
          final historyData = matchJson.remove(TABLE_MATCH_HISTORY) ?? [];

          // Create the match
          final match = Match.fromJson(matchJson);

          // Process bookings
          final bookings = <Booking>[];
          for (var bookingData in bookingsData) {
            final bookingJson = Map<String, dynamic>.from(bookingData);

            // Extract nested booking data
            final playersData = bookingJson.remove(TABLE_BOOKING_PLAYERS) ?? [];
            final cancellationsData =
                bookingJson.remove(TABLE_CANCELLATIONS) ?? [];

            // Create the booking
            final booking = Booking.fromJson(bookingJson);

            // Process booking players
            final players = playersData
                .map<BookingPlayer>(
                    (playerData) => BookingPlayer.fromJson(playerData))
                .toList();

            // Process cancellation (should be at most one)
            Cancellation? cancellation;
            if (cancellationsData.isNotEmpty) {
              cancellation = Cancellation.fromJson(cancellationsData[0]);
            }

            // Add the complete booking with its related data
            bookings.add(
                booking.copyWith(players: players, cancellation: cancellation));
          }

          // Process match history (should be at most one)
          MatchHistory? history;
          if (historyData.isNotEmpty) {
            history = MatchHistory.fromJson(historyData[0]);
          }

          // Add the complete match with all its related data
          matches.add(match.copyWith(bookings: bookings, history: history));
        } catch (e) {
          print('❌ Error processing match data: $e');
          // Continue with next match if one fails
          continue;
        }
      }

      print(
          '📡 MatchRemoteDataSource: Successfully processed ${matches.length} matches for date: $dateString');
      return matches;
    } catch (e) {
      print('❌ MatchRemoteDataSource ERROR: Failed to get matches by date: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<Match>> getMatchesByStatus(String status) async {
    try {
      print(
          '📡 MatchRemoteDataSource: Getting matches by status: $status with a single query');

      // Use a join query to get all related data at once
      final response = await supabase.from(TABLE_MATCHES).select('''
            *,
            $TABLE_BOOKING:$TABLE_BOOKING(
              *,
              $TABLE_BOOKING_PLAYERS:$TABLE_BOOKING_PLAYERS(*),
              $TABLE_CANCELLATIONS:$TABLE_CANCELLATIONS(*)
            ),
            $TABLE_MATCH_HISTORY:$TABLE_MATCH_HISTORY(*)
          ''').eq('status', status);

      print('📡 MatchRemoteDataSource: Query completed, processing results');

      final matches = <Match>[];
      for (var matchData in response) {
        try {
          // Extract match data
          final matchJson = Map<String, dynamic>.from(matchData);

          // Remove nested data before creating Match object
          final bookingsData = matchJson.remove(TABLE_BOOKING) ?? [];
          final historyData = matchJson.remove(TABLE_MATCH_HISTORY) ?? [];

          // Create the match
          final match = Match.fromJson(matchJson);

          // Process bookings
          final bookings = <Booking>[];
          for (var bookingData in bookingsData) {
            final bookingJson = Map<String, dynamic>.from(bookingData);

            // Extract nested booking data
            final playersData = bookingJson.remove(TABLE_BOOKING_PLAYERS) ?? [];
            final cancellationsData =
                bookingJson.remove(TABLE_CANCELLATIONS) ?? [];

            // Create the booking
            final booking = Booking.fromJson(bookingJson);

            // Process booking players
            final players = playersData
                .map<BookingPlayer>(
                    (playerData) => BookingPlayer.fromJson(playerData))
                .toList();

            // Process cancellation (should be at most one)
            Cancellation? cancellation;
            if (cancellationsData.isNotEmpty) {
              cancellation = Cancellation.fromJson(cancellationsData[0]);
            }

            // Add the complete booking with its related data
            bookings.add(
                booking.copyWith(players: players, cancellation: cancellation));
          }

          // Process match history (should be at most one)
          MatchHistory? history;
          if (historyData.isNotEmpty) {
            history = MatchHistory.fromJson(historyData[0]);
          }

          // Add the complete match with all its related data
          matches.add(match.copyWith(bookings: bookings, history: history));
        } catch (e) {
          print('❌ Error processing match data: $e');
          // Continue with next match if one fails
          continue;
        }
      }

      print(
          '📡 MatchRemoteDataSource: Successfully processed ${matches.length} matches with status: $status');
      return matches;
    } catch (e) {
      print(
          '❌ MatchRemoteDataSource ERROR: Failed to get matches by status: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  @override
  Future<List<Match>> getByStadiumId(String stadiumId) async {
    try {
      print(
          '📡 MatchRemoteDataSource: Fetching matches for stadium ID: $stadiumId');

      // Get all fields for this stadium
      final fieldsData = await supabase
          .from(TABLE_FIELD)
          .select('id')
          .eq('stadium_id', stadiumId);

      print(
          '📡 MatchRemoteDataSource: Found ${fieldsData.length} fields for stadium ID: $stadiumId');

      if (fieldsData.isEmpty) {
        print(
            '📡 MatchRemoteDataSource: No fields found for stadium ID: $stadiumId');
        return [];
      }

      // Extract field IDs
      final fieldIds =
          fieldsData.map<String>((field) => field['id'] as String).toList();
      print('📡 MatchRemoteDataSource: Field IDs: $fieldIds');

      // Use a join query to get matches and all related data in one go
      final response = await supabase.from(TABLE_MATCHES).select('''
            *,
            $TABLE_BOOKING(*,
              $TABLE_BOOKING_PLAYERS(*),
              $TABLE_CANCELLATIONS(*)
            ),
            $TABLE_MATCH_HISTORY(*)
          ''').inFilter('field_id', fieldIds);

      print(
          '📡 MatchRemoteDataSource: Retrieved ${response.length} matches with related data');

      // Process and convert the response to Match objects
      final List<Match> matches = [];
      for (final matchData in response) {
        try {
          // Extract nested data
          List<dynamic> bookingsData = matchData[TABLE_BOOKING] ?? [];
          List<dynamic> historyData = matchData[TABLE_MATCH_HISTORY] ?? [];

          // Process bookings
          final List<Booking> bookings = [];
          for (final bookingData in bookingsData) {
            try {
              // Extract nested data for this booking
              List<dynamic> bookingPlayersData =
                  bookingData[TABLE_BOOKING_PLAYERS] ?? [];
              List<dynamic> cancellationsData =
                  bookingData[TABLE_CANCELLATIONS] ?? [];

              // Process players for this booking
              final List<BookingPlayer> players = bookingPlayersData
                  .map<BookingPlayer>(
                      (playerData) => BookingPlayer.fromJson(playerData))
                  .toList();

              // Process cancellation for this booking
              final cancellation = cancellationsData.isNotEmpty
                  ? Cancellation.fromJson(cancellationsData.first)
                  : null;

              // Remove nested data before creating Booking
              final bookingDataCopy = Map<String, dynamic>.from(bookingData);
              bookingDataCopy.remove(TABLE_BOOKING_PLAYERS);
              bookingDataCopy.remove(TABLE_CANCELLATIONS);

              // Create booking with its related data
              final booking = Booking.fromJson(bookingDataCopy)
                  .copyWith(players: players, cancellation: cancellation);

              bookings.add(booking);
            } catch (e) {
              print('Error processing booking: $e');
              // Continue processing other bookings
            }
          }

          // Process match history
          MatchHistory? history;
          if (historyData.isNotEmpty) {
            history = MatchHistory.fromJson(historyData.first);
          }

          // Remove nested data before creating Match
          final matchDataCopy = Map<String, dynamic>.from(matchData);
          matchDataCopy.remove(TABLE_BOOKING);
          matchDataCopy.remove(TABLE_MATCH_HISTORY);

          // Create match with its related data
          final match = Match.fromJson(matchDataCopy)
              .copyWith(bookings: bookings, history: history);

          matches.add(match);
        } catch (e) {
          print('Error processing match: $e');
          // Continue processing other matches
        }
      }

      print('getByStadiumId: Returning ${matches.length} matches');
      return matches;
    } on PostgrestException catch (error) {
      throw DatabaseException(
          message: 'Failed to get matches: ${error.message}',
          code: error.code,
          details: error.details);
    } catch (error) {
      throw DatabaseException(
          message: 'Failed to get matches: ${error.toString()}');
    }
  }

  // Helper methods for related data
  Future<List<Booking>> _getBookings(String matchId) async {
    try {
      print(
          '📡 MatchRemoteDataSource: Getting bookings for match ID: $matchId');
      final bookingsData =
          await supabase.from(TABLE_BOOKING).select().eq('match_id', matchId);
      print('📡 MatchRemoteDataSource: Found ${bookingsData.length} bookings');

      List<Booking> bookings = [];
      for (var bookingData in bookingsData) {
        final booking = Booking.fromJson(bookingData);

        // Get booking players
        final bookingPlayersData = await supabase
            .from(TABLE_BOOKING_PLAYERS)
            .select()
            .eq('booking_id', booking.id);

        final bookingPlayers = bookingPlayersData
            .map<BookingPlayer>((json) => BookingPlayer.fromJson(json))
            .toList();

        // Get cancellation if exists
        final cancellationData = await supabase
            .from(TABLE_CANCELLATIONS)
            .select()
            .eq('booking_id', booking.id)
            .maybeSingle();

        bookings.add(booking.copyWith(
          players: bookingPlayers,
          cancellation: cancellationData != null
              ? Cancellation.fromJson(cancellationData)
              : null,
        ));
      }

      return bookings;
    } catch (e) {
      print('❌ MatchRemoteDataSource ERROR: Failed to get bookings: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<MatchHistory>> _getMatchHistory(String matchId) async {
    try {
      print(
          '📡 MatchRemoteDataSource: Getting match history for match ID: $matchId');
      final historyData = await supabase
          .from(TABLE_MATCH_HISTORY)
          .select()
          .eq('match_id', matchId);
      print(
          '📡 MatchRemoteDataSource: Found ${historyData.length} history records');

      return historyData
          .map<MatchHistory>((json) => MatchHistory.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ MatchRemoteDataSource ERROR: Failed to get match history: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> _insertBookings(String matchId, List<Booking> bookings) async {
    try {
      print(
          '📡 MatchRemoteDataSource: Inserting ${bookings.length} bookings for match ID: $matchId');

      for (var booking in bookings) {
        // Ensure the booking has the correct match_id
        final bookingWithMatchId = booking.copyWith(matchId: matchId);

        // Insert the booking
        final bookingData = await supabase
            .from(TABLE_BOOKING)
            .insert(bookingWithMatchId.toJson())
            .select()
            .single();

        final newBooking = Booking.fromJson(bookingData);
        print(
            '📡 MatchRemoteDataSource: Inserted booking with ID: ${newBooking.id}');

        // Insert booking players if any
        if (booking.players.isNotEmpty) {
          print(
              '📡 MatchRemoteDataSource: Inserting ${booking.players.length} players for booking ID: ${newBooking.id}');
          for (var player in booking.players) {
            // Ensure the player has the correct booking_id
            final playerWithBookingId =
                player.copyWith(bookingId: newBooking.id);
            await supabase
                .from(TABLE_BOOKING_PLAYERS)
                .insert(playerWithBookingId.toJson());
          }
        }

        // Insert cancellation if exists
        if (booking.cancellation != null) {
          print(
              '📡 MatchRemoteDataSource: Inserting cancellation for booking ID: ${newBooking.id}');
          final cancellationWithBookingId = booking.cancellation!.copyWith(
            bookingId: newBooking.id,
          );
          await supabase
              .from(TABLE_CANCELLATIONS)
              .insert(cancellationWithBookingId.toJson());
        }
      }

      print(
          '📡 MatchRemoteDataSource: Successfully inserted all bookings for match ID: $matchId');
    } catch (e) {
      print('❌ MatchRemoteDataSource ERROR: Failed to insert bookings: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> _insertMatchHistory(
      String matchId, List<MatchHistory> historyEntries) async {
    try {
      print(
          '📡 MatchRemoteDataSource: Inserting ${historyEntries.length} history entries for match ID: $matchId');

      for (var history in historyEntries) {
        // Ensure the history entry has the correct match_id
        final historyWithMatchId = history.copyWith(matchId: matchId);
        await supabase
            .from(TABLE_MATCH_HISTORY)
            .insert(historyWithMatchId.toJson());
      }

      print(
          '📡 MatchRemoteDataSource: Successfully inserted history for match ID: $matchId');
    } catch (e) {
      print(
          '❌ MatchRemoteDataSource ERROR: Failed to insert match history: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> _deleteBookings(String matchId) async {
    try {
      print(
          '📡 MatchRemoteDataSource: Deleting bookings for match ID: $matchId');

      // Get all bookings for this match
      final bookingsData = await supabase
          .from(TABLE_BOOKING)
          .select('id')
          .eq('match_id', matchId);

      print(
          '📡 MatchRemoteDataSource: Found ${bookingsData.length} bookings to delete');

      for (var bookingData in bookingsData) {
        final bookingId = bookingData['id'];
        print(
            '📡 MatchRemoteDataSource: Deleting related data for booking ID: $bookingId');

        // Delete related booking players
        await supabase
            .from(TABLE_BOOKING_PLAYERS)
            .delete()
            .eq('booking_id', bookingId);

        // Delete related cancellations
        await supabase
            .from(TABLE_CANCELLATIONS)
            .delete()
            .eq('booking_id', bookingId);
      }

      // Delete the bookings
      await supabase.from(TABLE_BOOKING).delete().eq('match_id', matchId);
      print(
          '📡 MatchRemoteDataSource: Successfully deleted all bookings for match ID: $matchId');
    } catch (e) {
      print('❌ MatchRemoteDataSource ERROR: Failed to delete bookings: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> _deleteMatchHistory(String matchId) async {
    try {
      print(
          '📡 MatchRemoteDataSource: Deleting match history for match ID: $matchId');
      await supabase.from(TABLE_MATCH_HISTORY).delete().eq('match_id', matchId);
      print(
          '📡 MatchRemoteDataSource: Successfully deleted match history for match ID: $matchId');
    } catch (e) {
      print(
          '❌ MatchRemoteDataSource ERROR: Failed to delete match history: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
}
