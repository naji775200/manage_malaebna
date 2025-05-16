import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/booking_local_data_source.dart';
import '../models/booking_model.dart';
import '../remote/booking_remote_data_source.dart';

class BookingRepository {
  final BookingRemoteDataSource _remoteDataSource;
  final BookingLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  BookingRepository({
    required BookingRemoteDataSource remoteDataSource,
    required BookingLocalDataSource localDataSource,
    required Connectivity connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _connectivity = connectivity;

  Future<bool> _hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<Booking> getBookingById(String id, {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteBooking = await _remoteDataSource.getBookingById(id);
        await _localDataSource.insertBooking(remoteBooking);
        return remoteBooking;
      } catch (e) {
        // If remote fetch fails, try local
        final localBooking = await _localDataSource.getBookingById(id);
        if (localBooking != null) {
          return localBooking;
        }
        rethrow; // If local fetch also fails, rethrow the exception
      }
    } else {
      // No internet, try local
      final localBooking = await _localDataSource.getBookingById(id);
      if (localBooking != null) {
        return localBooking;
      }
      throw Exception('No internet connection and booking not found locally');
    }
  }

  Future<List<Booking>> getAllBookings({bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteBookings = await _remoteDataSource.getAllBookings();
        for (var booking in remoteBookings) {
          await _localDataSource.insertBooking(booking);
        }
        return remoteBookings;
      } catch (e) {
        // If remote fetch fails, try local
        return await _localDataSource.getAllBookings();
      }
    } else {
      // No internet, use local
      return await _localDataSource.getAllBookings();
    }
  }

  Future<List<Booking>> getBookingsByPlayerId(String playerId,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteBookings =
            await _remoteDataSource.getBookingsByPlayerId(playerId);
        for (var booking in remoteBookings) {
          await _localDataSource.insertBooking(booking);
        }
        return remoteBookings;
      } catch (e) {
        // If remote fetch fails, try local
        return await _localDataSource.getBookingsByPlayerId(playerId);
      }
    } else {
      // No internet, use local
      return await _localDataSource.getBookingsByPlayerId(playerId);
    }
  }

  Future<List<Booking>> getBookingsByMatchId(String matchId,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteBookings =
            await _remoteDataSource.getBookingsByMatchId(matchId);
        for (var booking in remoteBookings) {
          await _localDataSource.insertBooking(booking);
        }
        return remoteBookings;
      } catch (e) {
        // If remote fetch fails, try local
        return await _localDataSource.getBookingsByMatchId(matchId);
      }
    } else {
      // No internet, use local
      return await _localDataSource.getBookingsByMatchId(matchId);
    }
  }

  Future<List<Booking>> getBookingsByStatus(String status,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteBookings =
            await _remoteDataSource.getBookingsByStatus(status);
        for (var booking in remoteBookings) {
          await _localDataSource.insertBooking(booking);
        }
        return remoteBookings;
      } catch (e) {
        // If remote fetch fails, try local
        return await _localDataSource.getBookingsByStatus(status);
      }
    } else {
      // No internet, use local
      return await _localDataSource.getBookingsByStatus(status);
    }
  }

  Future<Booking> createBooking(Booking booking) async {
    if (await _hasInternetConnection()) {
      final createdBooking = await _remoteDataSource.createBooking(booking);
      await _localDataSource.insertBooking(createdBooking);
      return createdBooking;
    } else {
      // Cannot create booking without internet
      throw Exception('No internet connection. Cannot create booking.');
    }
  }

  Future<Booking> updateBooking(Booking booking) async {
    if (await _hasInternetConnection()) {
      final updatedBooking = await _remoteDataSource.updateBooking(booking);
      await _localDataSource.updateBooking(updatedBooking);
      return updatedBooking;
    } else {
      // Cannot update without internet
      throw Exception('No internet connection. Cannot update booking.');
    }
  }

  Future<void> deleteBooking(String id) async {
    if (await _hasInternetConnection()) {
      await _remoteDataSource.deleteBooking(id);
      await _localDataSource.deleteBooking(id);
    } else {
      // Cannot delete without internet
      throw Exception('No internet connection. Cannot delete booking.');
    }
  }
}
