import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/stadium_model.dart';
import '../local/stadium_local_data_source.dart';
import '../remote/stadium_remote_data_source.dart';
import '../models/working_hour_model.dart';
import 'base_repository.dart';

class StadiumRepository implements BaseRepository<Stadium> {
  final StadiumLocalDataSource _localDataSource;
  final StadiumRemoteDataSource _remoteDataSource;
  final Connectivity _connectivity;

  StadiumRepository({
    StadiumLocalDataSource? localDataSource,
    StadiumRemoteDataSource? remoteDataSource,
    Connectivity? connectivity,
  })  : _localDataSource = localDataSource ?? StadiumLocalDataSource(),
        _remoteDataSource = remoteDataSource ?? StadiumRemoteDataSource(),
        _connectivity = connectivity ?? Connectivity();

  @override
  Future<Stadium> create(Stadium stadium) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      // Always save to local database
      await _localDataSource.insertStadium(stadium);

      // If online, save to remote and update local with remote data
      if (connectivityResult != ConnectivityResult.none) {
        final remoteStadium = await _remoteDataSource.createStadium(stadium);
        await _localDataSource.updateStadium(remoteStadium);
        return remoteStadium;
      }

      return stadium;
    } catch (e) {
      print('Error creating stadium: $e');
      rethrow;
    }
  }

  @override
  Future<Stadium?> getById(String id) async {
    try {
      // Validate ID first
      if (id.isEmpty) {
        print('Error: Empty stadium ID provided to StadiumRepository.getById');
        return null;
      }

      print('StadiumRepository: Fetching stadium with ID: $id');

      // First try to get from local database
      Stadium? stadium = await _localDataSource.getStadiumById(id);

      if (stadium != null) {
        print(
            'StadiumRepository: Found stadium in local database: ${stadium.name}');
      } else {
        print(
            'StadiumRepository: No stadium found in local database for ID: $id');
      }

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch latest data from remote
      if (connectivityResult != ConnectivityResult.none) {
        print('StadiumRepository: Online - fetching from remote for ID: $id');
        try {
          final remoteStadium = await _remoteDataSource.getStadiumById(id);

          if (remoteStadium != null) {
            print(
                'StadiumRepository: Successfully fetched stadium from remote: ${remoteStadium.name}');
            // Update local database with remote data
            await _localDataSource.updateStadium(remoteStadium);
            return remoteStadium;
          } else {
            print(
                'StadiumRepository: No stadium found in remote database for ID: $id');
          }
        } catch (e) {
          print('StadiumRepository: Error fetching from remote: $e');
          // Continue and return local data
        }
      } else {
        print('StadiumRepository: Offline - using only local data');
      }

      return stadium;
    } catch (e) {
      print('StadiumRepository: Error getting stadium: $e');
      // Attempt to return local data as a fallback
      try {
        return await _localDataSource.getStadiumById(id);
      } catch (localError) {
        print(
            'StadiumRepository: Error getting local stadium data: $localError');
        return null;
      }
    }
  }

  // New method to get basic stadium data without related entities
  Future<Stadium?> getBasicStadiumById(String id) async {
    try {
      // Validate ID first
      if (id.isEmpty) {
        print(
            'Error: Empty stadium ID provided to StadiumRepository.getBasicStadiumById');
        return null;
      }

      print('StadiumRepository: Fetching basic stadium data with ID: $id');

      // First try to get from local database
      Stadium? stadium = await _localDataSource.getStadiumById(id);

      if (stadium != null) {
        print(
            'StadiumRepository: Found stadium in local database: ${stadium.name}');
      } else {
        print(
            'StadiumRepository: No stadium found in local database for ID: $id');
      }

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch basic data from remote
      if (connectivityResult != ConnectivityResult.none) {
        try {
          print(
              'StadiumRepository: Online - fetching basic data from remote for ID: $id');
          final remoteStadium = await _remoteDataSource.getBasicStadiumById(id);

          if (remoteStadium != null) {
            print(
                'StadiumRepository: Successfully fetched basic stadium from remote: ${remoteStadium.name}');
            // Update local database with BASIC stadium data only
            await _localDataSource.updateBasicStadium(remoteStadium);
            return remoteStadium;
          } else {
            print(
                'StadiumRepository: No stadium found in remote database for ID: $id');
            // If not found in remote, we'll return the local stadium (which might be null)
          }
        } catch (e) {
          print(
              'StadiumRepository: Error fetching basic stadium data from remote: $e');
          // Return local stadium as fallback
          if (stadium != null) {
            print(
                'StadiumRepository: Returning local stadium data as fallback after remote error');
            return stadium;
          }

          // If both remote and local data are unavailable, rethrow with a more descriptive error
          throw Exception('Stadium not found or data error: $e');
        }
      } else {
        print('StadiumRepository: Offline - using only local data');
      }

      // If we got here without returning, it means no stadium was found in either local or remote
      if (stadium == null) {
        print(
            'StadiumRepository: No stadium found in either local or remote for ID: $id');
        throw Exception('Stadium not found with ID: $id');
      }

      return stadium;
    } catch (e) {
      print('StadiumRepository: Error getting basic stadium data: $e');
      throw Exception('Stadium not found');
    }
  }

  @override
  Future<List<Stadium>> getAll() async {
    try {
      // First get from local database
      List<Stadium> localStadiums = await _localDataSource.getAllStadiums();

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch latest data from remote
      if (connectivityResult != ConnectivityResult.none) {
        final remoteStadiums = await _remoteDataSource.getAllStadiums();

        // Update local database with remote data
        for (var stadium in remoteStadiums) {
          await _localDataSource.updateStadium(stadium);
        }

        return remoteStadiums;
      }

      return localStadiums;
    } catch (e) {
      print('Error getting all stadiums: $e');
      // Return local data if remote fetch fails
      return await _localDataSource.getAllStadiums();
    }
  }

  @override
  Future<Stadium> update(Stadium stadium) async {
    try {
      // Always update local database
      await _localDataSource.updateStadium(stadium);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, update remote database
      if (connectivityResult != ConnectivityResult.none) {
        final remoteStadium = await _remoteDataSource.updateStadium(stadium);
        await _localDataSource.updateStadium(remoteStadium);
        return remoteStadium;
      }

      return stadium;
    } catch (e) {
      print('Error updating stadium: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      // Always delete from local database
      await _localDataSource.deleteStadium(id);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, delete from remote database
      if (connectivityResult != ConnectivityResult.none) {
        await _remoteDataSource.deleteStadium(id);
      }
    } catch (e) {
      print('Error deleting stadium: $e');
      rethrow;
    }
  }

  // New method to get only working hours for a stadium
  Future<List<WorkingHours>> getStadiumWorkingHours(String stadiumId) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch data from remote source
      if (connectivityResult != ConnectivityResult.none) {
        try {
          // Get working hours from remote source
          final workingHours =
              await _remoteDataSource.getStadiumWorkingHours(stadiumId);

          // Store in local database for offline use
          // This would typically be handled by a dedicated WorkingHoursRepository
          // but we can update the local stadium here as well

          return workingHours;
        } catch (e) {
          print('Error getting working hours from remote: $e');
          // Fall back to local data
        }
      }

      // Get from local data source if offline or remote fetch failed
      final stadium = await _localDataSource.getStadiumById(stadiumId);
      return stadium?.workingHours ?? [];
    } catch (e) {
      print('Error getting stadium working hours: $e');
      rethrow;
    }
  }
}
