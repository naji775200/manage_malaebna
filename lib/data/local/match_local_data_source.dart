import 'package:sqflite/sqflite.dart';
import '../models/match_model.dart';
import '../models/booking_model.dart';
import '../models/booking_player_model.dart';
import '../models/match_history_model.dart';
import '../models/cancellation_model.dart';
import 'base_local_data_source.dart';

class MatchLocalDataSource extends BaseLocalDataSource<Match> {
  MatchLocalDataSource() : super('matches');

  Future<Match?> getMatchById(String id) async {
    final db = await database;
    final matchMap = await getById(id);

    if (matchMap == null) {
      return null;
    }

    // Get related bookings
    final bookings = await _getBookings(db, id);

    // Get match history if exists
    final history = await _getMatchHistory(db, id);

    // Create match with all related data
    final match = Match.fromJson(matchMap);
    return match.copyWith(
      bookings: bookings,
      history: history,
    );
  }

  Future<List<Match>> getAllMatches() async {
    final db = await database;
    final matchMaps = await getAll();

    final matches = <Match>[];
    for (final matchMap in matchMaps) {
      final match = Match.fromJson(matchMap);

      // Get related bookings
      final bookings = await _getBookings(db, match.id);

      // Get match history if exists
      final history = await _getMatchHistory(db, match.id);

      // Add match with all related data
      matches.add(match.copyWith(
        bookings: bookings,
        history: history,
      ));
    }

    return matches;
  }

  Future<String> insertMatch(Match match) async {
    final db = await database;

    // Start a transaction to ensure all related data is inserted atomically
    return await db.transaction((txn) async {
      // Insert match
      await txn.insert(
        tableName,
        match.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert related bookings
      if (match.bookings.isNotEmpty) {
        for (final booking in match.bookings) {
          await _insertBooking(txn, booking);

          // Insert booking players
          if (booking.players.isNotEmpty) {
            for (final player in booking.players) {
              await _insertBookingPlayer(txn, player);
            }
          }
        }
      }

      // Insert match history if exists
      if (match.history != null) {
        await _insertMatchHistory(txn, match.history!);
      }

      return match.id;
    });
  }

  Future<int> updateMatch(Match match) async {
    final db = await database;

    // Start a transaction to ensure all related data is updated atomically
    return await db.transaction((txn) async {
      // Update match
      final result = await txn.update(
        tableName,
        match.toJson(),
        where: 'id = ?',
        whereArgs: [match.id],
      );

      // Delete existing related data
      await _deleteRelatedData(txn, match.id);

      // Insert updated related bookings
      if (match.bookings.isNotEmpty) {
        for (final booking in match.bookings) {
          await _insertBooking(txn, booking);

          // Insert booking players
          if (booking.players.isNotEmpty) {
            for (final player in booking.players) {
              await _insertBookingPlayer(txn, player);
            }
          }
        }
      }

      // Insert updated match history if exists
      if (match.history != null) {
        await _insertMatchHistory(txn, match.history!);
      }

      return result;
    });
  }

  Future<int> deleteMatch(String id) async {
    final db = await database;

    // Start a transaction to ensure all related data is deleted atomically
    return await db.transaction((txn) async {
      // Delete related data
      await _deleteRelatedData(txn, id);

      // Delete match
      final result = await txn.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      return result;
    });
  }

  Future<void> _deleteRelatedData(Transaction txn, String matchId) async {
    // Delete match history
    await txn.delete(
      'match_history',
      where: 'match_id = ?',
      whereArgs: [matchId],
    );

    // Get bookings for this match
    final bookings = await txn.query(
      'booking',
      columns: ['id'],
      where: 'match_id = ?',
      whereArgs: [matchId],
    );

    // Delete booking players for each booking
    for (final booking in bookings) {
      final bookingId = booking['id'] as String;
      await txn.delete(
        'booking_players',
        where: 'booking_id = ?',
        whereArgs: [bookingId],
      );

      // Delete cancellation if exists
      await txn.delete(
        'cancellations',
        where: 'booking_id = ?',
        whereArgs: [bookingId],
      );
    }

    // Delete bookings
    await txn.delete(
      'booking',
      where: 'match_id = ?',
      whereArgs: [matchId],
    );
  }

  Future<List<Booking>> _getBookings(Database db, String matchId) async {
    final bookingMaps = await db.query(
      'booking',
      where: 'match_id = ?',
      whereArgs: [matchId],
    );

    final bookings = <Booking>[];
    for (final bookingMap in bookingMaps) {
      final booking = Booking.fromJson(bookingMap);

      // Get booking players
      final bookingPlayers = await _getBookingPlayers(db, booking.id);

      // Get cancellation if exists
      final cancellation = await _getCancellation(db, booking.id);

      // Add booking with related data
      bookings.add(booking.copyWith(
        players: bookingPlayers,
        cancellation: cancellation,
      ));
    }

    return bookings;
  }

  Future<List<BookingPlayer>> _getBookingPlayers(
      Database db, String bookingId) async {
    final playerMaps = await db.query(
      'booking_players',
      where: 'booking_id = ?',
      whereArgs: [bookingId],
    );

    return playerMaps.map((map) => BookingPlayer.fromJson(map)).toList();
  }

  Future<Cancellation?> _getCancellation(Database db, String bookingId) async {
    final cancellationMaps = await db.query(
      'cancellations',
      where: 'booking_id = ?',
      whereArgs: [bookingId],
    );

    if (cancellationMaps.isEmpty) {
      return null;
    }

    return Cancellation.fromJson(cancellationMaps.first);
  }

  Future<MatchHistory?> _getMatchHistory(Database db, String matchId) async {
    final historyMaps = await db.query(
      'match_history',
      where: 'match_id = ?',
      whereArgs: [matchId],
    );

    if (historyMaps.isEmpty) {
      return null;
    }

    return MatchHistory.fromJson(historyMaps.first);
  }

  Future<void> _insertBooking(Transaction txn, Booking booking) async {
    await txn.insert(
      'booking',
      booking.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insert cancellation if exists
    if (booking.cancellation != null) {
      await txn.insert(
        'cancellations',
        booking.cancellation!.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _insertBookingPlayer(
      Transaction txn, BookingPlayer player) async {
    await txn.insert(
      'booking_players',
      player.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _insertMatchHistory(
      Transaction txn, MatchHistory history) async {
    await txn.insert(
      'match_history',
      history.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Match>> getMatchesByFieldId(String fieldId) async {
    final db = await database;
    final matchMaps = await db.query(
      tableName,
      where: 'field_id = ?',
      whereArgs: [fieldId],
    );

    final matches = <Match>[];
    for (final matchMap in matchMaps) {
      final match = Match.fromJson(matchMap);

      // Get related bookings
      final bookings = await _getBookings(db, match.id);

      // Get match history if exists
      final history = await _getMatchHistory(db, match.id);

      // Add match with all related data
      matches.add(match.copyWith(
        bookings: bookings,
        history: history,
      ));
    }

    return matches;
  }

  Future<List<Match>> getMatchesByStatus(String status) async {
    final db = await database;
    final matchMaps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: [status],
    );

    final matches = <Match>[];
    for (final matchMap in matchMaps) {
      final match = Match.fromJson(matchMap);

      // Get related bookings
      final bookings = await _getBookings(db, match.id);

      // Get match history if exists
      final history = await _getMatchHistory(db, match.id);

      // Add match with all related data
      matches.add(match.copyWith(
        bookings: bookings,
        history: history,
      ));
    }

    return matches;
  }

  Future<List<Match>> getMatchesByDate(DateTime date) async {
    final db = await database;
    final dateString =
        date.toIso8601String().split('T')[0]; // Get date part only

    final matchMaps = await db.query(
      tableName,
      where: 'date = ?',
      whereArgs: [dateString],
    );

    final matches = <Match>[];
    for (final matchMap in matchMaps) {
      final match = Match.fromJson(matchMap);

      // Get related bookings
      final bookings = await _getBookings(db, match.id);

      // Get match history if exists
      final history = await _getMatchHistory(db, match.id);

      // Add match with all related data
      matches.add(match.copyWith(
        bookings: bookings,
        history: history,
      ));
    }

    return matches;
  }
}
