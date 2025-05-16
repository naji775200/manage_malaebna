import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/service_local_data_source.dart';
import '../models/service_model.dart';
import '../remote/service_remote_data_source.dart';

class ServiceRepository {
  final ServiceRemoteDataSource _remoteDataSource;
  final ServiceLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  ServiceRepository({
    required ServiceRemoteDataSource remoteDataSource,
    required ServiceLocalDataSource localDataSource,
    required Connectivity connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _connectivity = connectivity;

  Future<bool> _hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<Service> getServiceById(String id, {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteService = await _remoteDataSource.getServiceById(id);
        await _localDataSource.insertService(remoteService);
        return remoteService;
      } catch (e) {
        final localService = await _localDataSource.getServiceById(id);
        if (localService != null) {
          return localService;
        }
        rethrow;
      }
    } else {
      final localService = await _localDataSource.getServiceById(id);
      if (localService != null) {
        return localService;
      }
      throw Exception('No internet connection and service not found locally');
    }
  }

  Future<List<Service>> getAllServices({bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteServices = await _remoteDataSource.getAllServices();
        for (var service in remoteServices) {
          await _localDataSource.insertService(service);
        }
        return remoteServices;
      } catch (e) {
        return await _localDataSource.getAllServices();
      }
    } else {
      return await _localDataSource.getAllServices();
    }
  }

  Future<List<Service>> getServicesByStadiumId(String stadiumId,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteServices =
            await _remoteDataSource.getServicesByStadiumId(stadiumId);
        for (var service in remoteServices) {
          await _localDataSource.insertService(service);
        }
        return remoteServices;
      } catch (e) {
        return await _localDataSource.getServicesByStadiumId(stadiumId);
      }
    } else {
      return await _localDataSource.getServicesByStadiumId(stadiumId);
    }
  }

  Future<Service> createService(Service service) async {
    if (await _hasInternetConnection()) {
      final createdService = await _remoteDataSource.createService(service);
      await _localDataSource.insertService(createdService);
      return createdService;
    } else {
      throw Exception('No internet connection. Cannot create service.');
    }
  }

  Future<Service> updateService(Service service) async {
    if (await _hasInternetConnection()) {
      final updatedService = await _remoteDataSource.updateService(service);
      await _localDataSource.updateService(updatedService);
      return updatedService;
    } else {
      throw Exception('No internet connection. Cannot update service.');
    }
  }

  Future<void> deleteService(String id) async {
    if (await _hasInternetConnection()) {
      await _remoteDataSource.deleteService(id);
      await _localDataSource.deleteService(id);
    } else {
      throw Exception('No internet connection. Cannot delete service.');
    }
  }

  Future<void> addServiceToStadium(String stadiumId, String serviceId) async {
    if (await _hasInternetConnection()) {
      await _remoteDataSource.addServiceToStadium(stadiumId, serviceId);
      await _localDataSource.addServiceToStadium(stadiumId, serviceId);
    } else {
      throw Exception('No internet connection. Cannot add service to stadium.');
    }
  }

  Future<void> removeServiceFromStadium(
      String stadiumId, String serviceId) async {
    if (await _hasInternetConnection()) {
      await _remoteDataSource.removeServiceFromStadium(stadiumId, serviceId);
      await _localDataSource.removeServiceFromStadium(stadiumId, serviceId);
    } else {
      throw Exception(
          'No internet connection. Cannot remove service from stadium.');
    }
  }
}
