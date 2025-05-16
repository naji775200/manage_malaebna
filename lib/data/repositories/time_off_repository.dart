import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/time_off_local_data_source.dart';
import '../models/time_off_model.dart';
import '../remote/time_off_remote_data_source.dart';

class TimeOffRepository {
  final TimeOffRemoteDataSource _remoteDataSource;
  final TimeOffLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  TimeOffRepository({
    required TimeOffRemoteDataSource remoteDataSource,
    required TimeOffLocalDataSource localDataSource,
    required Connectivity connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _connectivity = connectivity;

  Future<bool> _hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<TimeOff> getTimeOffById(String id, {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteTimeOff = await _remoteDataSource.getTimeOffById(id);
        await _localDataSource.insertTimeOff(remoteTimeOff);
        return remoteTimeOff;
      } catch (e) {
        final localTimeOff = await _localDataSource.getTimeOffById(id);
        if (localTimeOff != null) {
          return localTimeOff;
        }
        rethrow;
      }
    } else {
      final localTimeOff = await _localDataSource.getTimeOffById(id);
      if (localTimeOff != null) {
        return localTimeOff;
      }
      throw Exception('No internet connection and time off not found locally');
    }
  }

  Future<List<TimeOff>> getAllTimeOffs({bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteTimeOffs = await _remoteDataSource.getAllTimeOffs();
        for (var timeOff in remoteTimeOffs) {
          await _localDataSource.insertTimeOff(timeOff);
        }
        return remoteTimeOffs;
      } catch (e) {
        return await _localDataSource.getAllTimeOffs();
      }
    } else {
      return await _localDataSource.getAllTimeOffs();
    }
  }

  Future<List<TimeOff>> getTimeOffsByStadiumId(String stadiumId,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteTimeOffs =
            await _remoteDataSource.getTimeOffsByStadiumId(stadiumId);
        for (var timeOff in remoteTimeOffs) {
          await _localDataSource.insertTimeOff(timeOff);
        }
        return remoteTimeOffs;
      } catch (e) {
        return await _localDataSource.getTimeOffsByStadiumId(stadiumId);
      }
    } else {
      return await _localDataSource.getTimeOffsByStadiumId(stadiumId);
    }
  }

  Future<List<TimeOff>> getTimeOffsByFrequency(String frequency,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteTimeOffs =
            await _remoteDataSource.getTimeOffsByFrequency(frequency);
        for (var timeOff in remoteTimeOffs) {
          await _localDataSource.insertTimeOff(timeOff);
        }
        return remoteTimeOffs;
      } catch (e) {
        return await _localDataSource.getTimeOffsByFrequency(frequency);
      }
    } else {
      return await _localDataSource.getTimeOffsByFrequency(frequency);
    }
  }

  Future<TimeOff> createTimeOff(TimeOff timeOff) async {
    if (await _hasInternetConnection()) {
      final createdTimeOff = await _remoteDataSource.createTimeOff(timeOff);
      await _localDataSource.insertTimeOff(createdTimeOff);
      return createdTimeOff;
    } else {
      throw Exception('No internet connection. Cannot create time off.');
    }
  }

  Future<TimeOff> updateTimeOff(TimeOff timeOff) async {
    if (await _hasInternetConnection()) {
      final updatedTimeOff = await _remoteDataSource.updateTimeOff(timeOff);
      await _localDataSource.updateTimeOff(updatedTimeOff);
      return updatedTimeOff;
    } else {
      throw Exception('No internet connection. Cannot update time off.');
    }
  }

  Future<void> deleteTimeOff(String id) async {
    if (await _hasInternetConnection()) {
      await _remoteDataSource.deleteTimeOff(id);
      await _localDataSource.deleteTimeOff(id);
    } else {
      throw Exception('No internet connection. Cannot delete time off.');
    }
  }

  // Method to get valid stadium ID from user ID
  Future<String?> getValidStadiumIdForUser(String userId) async {
    try {
      if (await _hasInternetConnection()) {
        // Query the stadium table to find a stadium with matching user_id
        final response = await _remoteDataSource.getStadiumIdForUser(userId);
        return response;
      }
    } catch (e) {
      print('Error getting valid stadium ID: $e');
    }
    return null;
  }
}
