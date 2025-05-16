import 'package:sqflite/sqflite.dart';
import '../models/booking_model.dart';
import '../models/booking_player_model.dart';
import '../models/cancellation_model.dart';
import 'base_local_data_source.dart';

class BookingLocalDataSource extends BaseLocalDataSource<Booking> {
  BookingLocalDataSource() : super('booking');

  Future<Booking?> getBookingById(String id) async {
    final db = await database;
    final bookingMap = await getById(id);

    if (bookingMap == null) {
      return null;
    }

    // Get booking players
    final bookingPlayers = await _getBookingPlayers(db, id);

    // Get cancellation if exists
    final cancellation = await _getCancellation(db, id);

    // Create booking with all related data
    final booking = Booking.fromJson(bookingMap);
    return booking.copyWith(
      players: bookingPlayers,
      cancellation: cancellation,
    );
  }

  Future<List<Booking>> getAllBookings() async {
    final db = await database;
    final bookingMaps = await getAll();

    final bookings = <Booking>[];
    for (final bookingMap in bookingMaps) {
      final booking = Booking.fromJson(bookingMap);

      // Get booking players
      final bookingPlayers = await _getBookingPlayers(db, booking.id);

      // Get cancellation if exists
      final cancellation = await _getCancellation(db, booking.id);

      // Add booking with all related data
      bookings.add(booking.copyWith(
        players: bookingPlayers,
        cancellation: cancellation,
      ));
    }

    return bookings;
  }

  Future<String> insertBooking(Booking booking) async {
    final db = await database;

    // Start a transaction to ensure all related data is inserted atomically
    return await db.transaction((txn) async {
      // Insert booking
      final bookingId = await txn.insert(
        tableName,
        booking.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert related booking players
      if (booking.players.isNotEmpty) {
        for (final player in booking.players) {
          await _insertBookingPlayer(txn, player);
        }
      }

      // Insert cancellation if exists
      if (booking.cancellation != null) {
        await _insertCancellation(txn, booking.cancellation!);
      }

      return booking.id;
    });
  }

  Future<int> updateBooking(Booking booking) async {
    final db = await database;

    // Start a transaction to ensure all related data is updated atomically
    return await db.transaction((txn) async {
      // Update booking
      final result = await txn.update(
        tableName,
        booking.toJson(),
        where: 'id = ?',
        whereArgs: [booking.id],
      );

      // Delete existing related data
      await _deleteRelatedData(txn, booking.id);

      // Insert updated related booking players
      if (booking.players.isNotEmpty) {
        for (final player in booking.players) {
          await _insertBookingPlayer(txn, player);
        }
      }

      // Insert updated cancellation if exists
      if (booking.cancellation != null) {
        await _insertCancellation(txn, booking.cancellation!);
      }

      return result;
    });
  }

  Future<int> deleteBooking(String id) async {
    final db = await database;

    // Start a transaction to ensure all related data is deleted atomically
    return await db.transaction((txn) async {
      // Delete related data
      await _deleteRelatedData(txn, id);

      // Delete booking
      final result = await txn.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      return result;
    });
  }

  Future<void> _deleteRelatedData(Transaction txn, String bookingId) async {
    // Delete booking players
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

  Future<void> _insertBookingPlayer(
      Transaction txn, BookingPlayer player) async {
    await txn.insert(
      'booking_players',
      player.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _insertCancellation(
      Transaction txn, Cancellation cancellation) async {
    await txn.insert(
      'cancellations',
      cancellation.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Booking>> getBookingsByPlayerId(String playerId) async {
    final db = await database;
    final bookingMaps = await db.query(
      tableName,
      where: 'player_id = ?',
      whereArgs: [playerId],
    );

    final bookings = <Booking>[];
    for (final bookingMap in bookingMaps) {
      final booking = Booking.fromJson(bookingMap);

      // Get booking players
      final bookingPlayers = await _getBookingPlayers(db, booking.id);

      // Get cancellation if exists
      final cancellation = await _getCancellation(db, booking.id);

      // Add booking with all related data
      bookings.add(booking.copyWith(
        players: bookingPlayers,
        cancellation: cancellation,
      ));
    }

    return bookings;
  }

  Future<List<Booking>> getBookingsByMatchId(String matchId) async {
    final db = await database;
    final bookingMaps = await db.query(
      tableName,
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

      // Add booking with all related data
      bookings.add(booking.copyWith(
        players: bookingPlayers,
        cancellation: cancellation,
      ));
    }

    return bookings;
  }

  Future<List<Booking>> getBookingsByStatus(String status) async {
    final db = await database;
    final bookingMaps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: [status],
    );

    final bookings = <Booking>[];
    for (final bookingMap in bookingMaps) {
      final booking = Booking.fromJson(bookingMap);

      // Get booking players
      final bookingPlayers = await _getBookingPlayers(db, booking.id);

      // Get cancellation if exists
      final cancellation = await _getCancellation(db, booking.id);

      // Add booking with all related data
      bookings.add(booking.copyWith(
        players: bookingPlayers,
        cancellation: cancellation,
      ));
    }

    return bookings;
  }
}
