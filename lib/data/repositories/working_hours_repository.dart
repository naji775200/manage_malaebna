import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/working_hours_local_data_source.dart';
import '../models/working_hour_model.dart';
import '../remote/working_hours_remote_data_source.dart';

class WorkingHoursRepository {
  final WorkingHoursRemoteDataSource _remoteDataSource;
  final WorkingHoursLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  WorkingHoursRepository({
    required WorkingHoursRemoteDataSource remoteDataSource,
    required WorkingHoursLocalDataSource localDataSource,
    required Connectivity connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _connectivity = connectivity;

  Future<bool> _hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<WorkingHours> getWorkingHoursById(String id,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteWorkingHours =
            await _remoteDataSource.getWorkingHoursById(id);
        await _localDataSource.insertWorkingHours(remoteWorkingHours);
        return remoteWorkingHours;
      } catch (e) {
        final localWorkingHours =
            await _localDataSource.getWorkingHoursById(id);
        if (localWorkingHours != null) {
          return localWorkingHours;
        }
        rethrow;
      }
    } else {
      final localWorkingHours = await _localDataSource.getWorkingHoursById(id);
      if (localWorkingHours != null) {
        return localWorkingHours;
      }
      throw Exception(
          'No internet connection and working hours not found locally');
    }
  }

  Future<List<WorkingHours>> getAllWorkingHours(
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteWorkingHours = await _remoteDataSource.getAllWorkingHours();
        for (var workingHours in remoteWorkingHours) {
          await _localDataSource.insertWorkingHours(workingHours);
        }
        return remoteWorkingHours;
      } catch (e) {
        return await _localDataSource.getAllWorkingHours();
      }
    } else {
      return await _localDataSource.getAllWorkingHours();
    }
  }

  Future<List<WorkingHours>> getWorkingHoursByStadiumId(String stadiumId,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteWorkingHours =
            await _remoteDataSource.getWorkingHoursByStadiumId(stadiumId);
        for (var workingHours in remoteWorkingHours) {
          await _localDataSource.insertWorkingHours(workingHours);
        }
        return remoteWorkingHours;
      } catch (e) {
        return await _localDataSource.getWorkingHoursByStadiumId(stadiumId);
      }
    } else {
      return await _localDataSource.getWorkingHoursByStadiumId(stadiumId);
    }
  }

  Future<WorkingHours?> getWorkingHoursByStadiumIdAndDay(
      String stadiumId, String dayOfWeek,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteWorkingHours = await _remoteDataSource
            .getWorkingHoursByStadiumIdAndDay(stadiumId, dayOfWeek);
        if (remoteWorkingHours != null) {
          await _localDataSource.insertWorkingHours(remoteWorkingHours);
        }
        return remoteWorkingHours;
      } catch (e) {
        return await _localDataSource.getWorkingHoursByStadiumIdAndDay(
            stadiumId, dayOfWeek);
      }
    } else {
      return await _localDataSource.getWorkingHoursByStadiumIdAndDay(
          stadiumId, dayOfWeek);
    }
  }

  Future<WorkingHours> createWorkingHours(WorkingHours workingHours) async {
    if (await _hasInternetConnection()) {
      final createdWorkingHours =
          await _remoteDataSource.createWorkingHours(workingHours);
      await _localDataSource.insertWorkingHours(createdWorkingHours);
      return createdWorkingHours;
    } else {
      throw Exception('No internet connection. Cannot create working hours.');
    }
  }

  Future<WorkingHours> updateWorkingHours(WorkingHours workingHours) async {
    if (await _hasInternetConnection()) {
      final updatedWorkingHours =
          await _remoteDataSource.updateWorkingHours(workingHours);
      await _localDataSource.updateWorkingHours(updatedWorkingHours);
      return updatedWorkingHours;
    } else {
      throw Exception('No internet connection. Cannot update working hours.');
    }
  }

  Future<void> deleteWorkingHours(String id) async {
    if (await _hasInternetConnection()) {
      await _remoteDataSource.deleteWorkingHours(id);
      await _localDataSource.deleteWorkingHours(id);
    } else {
      throw Exception('No internet connection. Cannot delete working hours.');
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
