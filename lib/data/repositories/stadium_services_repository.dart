import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/stadium_services_local_data_source.dart';
import '../models/stadium_services_model.dart';
import '../remote/stadium_services_remote_data_source.dart';

class StadiumServicesRepository {
  final StadiumServicesRemoteDataSource _remoteDataSource;
  final StadiumServicesLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  StadiumServicesRepository({
    required StadiumServicesRemoteDataSource remoteDataSource,
    required StadiumServicesLocalDataSource localDataSource,
    required Connectivity connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _connectivity = connectivity;

  Future<bool> _hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<StadiumServicesModel> getStadiumServiceById(String id,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteStadiumService =
            await _remoteDataSource.getStadiumServiceById(id);
        await _localDataSource.insertStadiumService(remoteStadiumService);
        return remoteStadiumService;
      } catch (e) {
        final localStadiumService =
            await _localDataSource.getStadiumServiceById(id);
        if (localStadiumService != null) {
          return localStadiumService;
        }
        rethrow;
      }
    } else {
      final localStadiumService =
          await _localDataSource.getStadiumServiceById(id);
      if (localStadiumService != null) {
        return localStadiumService;
      }
      throw Exception(
          'No internet connection and stadium service not found locally');
    }
  }

  Future<List<StadiumServicesModel>> getStadiumServicesByStadiumId(
      String stadiumId,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteStadiumServices =
            await _remoteDataSource.getStadiumServicesByStadiumId(stadiumId);
        for (var stadiumService in remoteStadiumServices) {
          await _localDataSource.insertStadiumService(stadiumService);
        }
        return remoteStadiumServices;
      } catch (e) {
        return await _localDataSource.getStadiumServicesByStadiumId(stadiumId);
      }
    } else {
      return await _localDataSource.getStadiumServicesByStadiumId(stadiumId);
    }
  }

  Future<List<StadiumServicesModel>> getStadiumServicesByServiceId(
      String serviceId,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteStadiumServices =
            await _remoteDataSource.getStadiumServicesByServiceId(serviceId);
        for (var stadiumService in remoteStadiumServices) {
          await _localDataSource.insertStadiumService(stadiumService);
        }
        return remoteStadiumServices;
      } catch (e) {
        return await _localDataSource.getStadiumServicesByServiceId(serviceId);
      }
    } else {
      return await _localDataSource.getStadiumServicesByServiceId(serviceId);
    }
  }

  Future<StadiumServicesModel> createStadiumService(
      StadiumServicesModel stadiumService) async {
    if (await _hasInternetConnection()) {
      final createdStadiumService =
          await _remoteDataSource.createStadiumService(stadiumService);
      await _localDataSource.insertStadiumService(createdStadiumService);
      return createdStadiumService;
    } else {
      throw Exception('No internet connection. Cannot create stadium service.');
    }
  }

  Future<StadiumServicesModel> updateStadiumService(
      StadiumServicesModel stadiumService) async {
    if (await _hasInternetConnection()) {
      final updatedStadiumService =
          await _remoteDataSource.updateStadiumService(stadiumService);
      await _localDataSource.updateStadiumService(updatedStadiumService);
      return updatedStadiumService;
    } else {
      throw Exception('No internet connection. Cannot update stadium service.');
    }
  }

  Future<void> deleteStadiumService(String id) async {
    if (await _hasInternetConnection()) {
      await _remoteDataSource.deleteStadiumService(id);
      await _localDataSource.deleteStadiumService(id);
    } else {
      throw Exception('No internet connection. Cannot delete stadium service.');
    }
  }

  Future<void> deleteStadiumServiceByStadiumAndService(
      String stadiumId, String serviceId) async {
    if (await _hasInternetConnection()) {
      await _remoteDataSource.deleteStadiumServiceByStadiumAndService(
          stadiumId, serviceId);
      await _localDataSource.deleteStadiumServiceByStadiumAndService(
          stadiumId, serviceId);
    } else {
      throw Exception('No internet connection. Cannot delete stadium service.');
    }
  }
}
