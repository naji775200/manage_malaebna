import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';
import '../models/booking_player_model.dart';
import '../models/cancellation_model.dart';

class BookingRemoteDataSource {
  final SupabaseClient _supabaseClient;

  // Table names - defined as constants for consistency
  static const String TABLE_BOOKING = 'booking';
  static const String TABLE_BOOKING_PLAYERS = 'booking_players';
  static const String TABLE_CANCELLATIONS = 'cancellations';

  BookingRemoteDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  Future<Booking> getBookingById(String id) async {
    print('📡 BookingRemoteDataSource: Getting booking with ID: $id');
    try {
      final response = await _supabaseClient
          .from(TABLE_BOOKING)
          .select()
          .eq('id', id)
          .single();

      print('📡 BookingRemoteDataSource: Booking found: $response');
      final booking = Booking.fromJson(response);

      // Get related booking players
      final players = await getBookingPlayers(booking.id);

      // Get cancellation if exists
      final cancellation = await getCancellation(booking.id);

      return booking.copyWith(
        players: players,
        cancellation: cancellation,
      );
    } catch (e) {
      print('❌ BookingRemoteDataSource ERROR: Failed to get booking: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<Booking>> getAllBookings() async {
    print('📡 BookingRemoteDataSource: Getting all bookings');
    try {
      final response = await _supabaseClient.from(TABLE_BOOKING).select();
      print('📡 BookingRemoteDataSource: Found ${response.length} bookings');

      final bookings = <Booking>[];
      for (var json in response) {
        final booking = Booking.fromJson(json);

        // Get related booking players
        final players = await getBookingPlayers(booking.id);

        // Get cancellation if exists
        final cancellation = await getCancellation(booking.id);

        bookings.add(booking.copyWith(
          players: players,
          cancellation: cancellation,
        ));
      }

      return bookings;
    } catch (e) {
      print('❌ BookingRemoteDataSource ERROR: Failed to get all bookings: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<Booking>> getBookingsByPlayerId(String playerId) async {
    try {
      final response = await _supabaseClient
          .from(TABLE_BOOKING)
          .select()
          .eq('player_id', playerId);

      final bookings = <Booking>[];
      for (var json in response) {
        final booking = Booking.fromJson(json);

        // Get related booking players
        final players = await getBookingPlayers(booking.id);

        // Get cancellation if exists
        final cancellation = await getCancellation(booking.id);

        bookings.add(booking.copyWith(
          players: players,
          cancellation: cancellation,
        ));
      }

      return bookings;
    } catch (e) {
      print('❌ ERROR: Failed to get bookings by player ID: $e');
      rethrow;
    }
  }

  Future<List<Booking>> getBookingsByMatchId(String matchId) async {
    try {
      final response = await _supabaseClient
          .from(TABLE_BOOKING)
          .select()
          .eq('match_id', matchId);

      final bookings = <Booking>[];
      for (var json in response) {
        final booking = Booking.fromJson(json);

        // Get related booking players
        final players = await getBookingPlayers(booking.id);

        // Get cancellation if exists
        final cancellation = await getCancellation(booking.id);

        bookings.add(booking.copyWith(
          players: players,
          cancellation: cancellation,
        ));
      }

      return bookings;
    } catch (e) {
      print('❌ ERROR: Failed to get bookings by match ID: $e');
      rethrow;
    }
  }

  Future<List<Booking>> getBookingsByStatus(String status) async {
    try {
      final response = await _supabaseClient
          .from(TABLE_BOOKING)
          .select()
          .eq('status', status);

      final bookings = <Booking>[];
      for (var json in response) {
        final booking = Booking.fromJson(json);

        // Get related booking players
        final players = await getBookingPlayers(booking.id);

        // Get cancellation if exists
        final cancellation = await getCancellation(booking.id);

        bookings.add(booking.copyWith(
          players: players,
          cancellation: cancellation,
        ));
      }

      return bookings;
    } catch (e) {
      print('❌ ERROR: Failed to get bookings by status: $e');
      rethrow;
    }
  }

  Future<Booking> createBooking(Booking booking) async {
    try {
      // First insert the booking
      final response = await _supabaseClient
          .from(TABLE_BOOKING)
          .insert(booking.toJson())
          .select()
          .single();

      final createdBooking = Booking.fromJson(response);

      // Insert related booking players
      if (booking.players.isNotEmpty) {
        for (final player in booking.players) {
          final playerWithBookingId = player.copyWith(
            bookingId: createdBooking.id,
          );
          await _supabaseClient
              .from(TABLE_BOOKING_PLAYERS)
              .insert(playerWithBookingId.toJson());
        }
      }

      // Insert cancellation if exists
      if (booking.cancellation != null) {
        final cancellationWithBookingId = booking.cancellation!.copyWith(
          bookingId: createdBooking.id,
        );
        await _supabaseClient
            .from(TABLE_CANCELLATIONS)
            .insert(cancellationWithBookingId.toJson());
      }

      // Return the booking with all related data
      return getBookingById(createdBooking.id);
    } catch (e) {
      print('❌ ERROR: Failed to create booking: $e');
      rethrow;
    }
  }

  Future<Booking> updateBooking(Booking booking) async {
    try {
      // Update the booking
      final response = await _supabaseClient
          .from(TABLE_BOOKING)
          .update(booking.toJson())
          .eq('id', booking.id)
          .select()
          .single();

      // Delete existing related data
      await _supabaseClient
          .from(TABLE_BOOKING_PLAYERS)
          .delete()
          .eq('booking_id', booking.id);

      await _supabaseClient
          .from(TABLE_CANCELLATIONS)
          .delete()
          .eq('booking_id', booking.id);

      // Insert updated related booking players
      if (booking.players.isNotEmpty) {
        for (final player in booking.players) {
          await _supabaseClient
              .from(TABLE_BOOKING_PLAYERS)
              .insert(player.toJson());
        }
      }

      // Insert updated cancellation if exists
      if (booking.cancellation != null) {
        await _supabaseClient
            .from(TABLE_CANCELLATIONS)
            .insert(booking.cancellation!.toJson());
      }

      return getBookingById(booking.id);
    } catch (e) {
      print('❌ ERROR: Failed to update booking: $e');
      rethrow;
    }
  }

  Future<void> deleteBooking(String id) async {
    try {
      // Delete related data first
      await _supabaseClient
          .from(TABLE_BOOKING_PLAYERS)
          .delete()
          .eq('booking_id', id);

      await _supabaseClient
          .from(TABLE_CANCELLATIONS)
          .delete()
          .eq('booking_id', id);

      // Delete the booking
      await _supabaseClient.from(TABLE_BOOKING).delete().eq('id', id);
    } catch (e) {
      print('❌ ERROR: Failed to delete booking: $e');
      rethrow;
    }
  }

  Future<List<BookingPlayer>> getBookingPlayers(String bookingId) async {
    try {
      final response = await _supabaseClient
          .from(TABLE_BOOKING_PLAYERS)
          .select()
          .eq('booking_id', bookingId);

      return response
          .map<BookingPlayer>((json) => BookingPlayer.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ ERROR: Failed to get booking players: $e');
      rethrow;
    }
  }

  Future<Cancellation?> getCancellation(String bookingId) async {
    try {
      final response = await _supabaseClient
          .from(TABLE_CANCELLATIONS)
          .select()
          .eq('booking_id', bookingId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Cancellation.fromJson(response);
    } catch (e) {
      print('❌ ERROR: Failed to get cancellation: $e');
      rethrow;
    }
  }
}
