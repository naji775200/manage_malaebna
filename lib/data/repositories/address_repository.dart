import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/address_model.dart';
import '../local/address_local_data_source.dart';
import '../remote/address_remote_data_source.dart';
import 'base_repository.dart';

class AddressRepository implements BaseRepository<Address> {
  final AddressLocalDataSource _localDataSource;
  final AddressRemoteDataSource _remoteDataSource;
  final Connectivity _connectivity;

  AddressRepository({
    AddressLocalDataSource? localDataSource,
    AddressRemoteDataSource? remoteDataSource,
    Connectivity? connectivity,
  })  : _localDataSource = localDataSource ?? AddressLocalDataSource(),
        _remoteDataSource = remoteDataSource ?? AddressRemoteDataSource(),
        _connectivity = connectivity ?? Connectivity();

  @override
  Future<Address> create(Address address) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      // Always save to local database
      await _localDataSource.insertAddress(address);

      // If online, save to remote and update local with remote data
      if (connectivityResult != ConnectivityResult.none) {
        final remoteAddress = await _remoteDataSource.createAddress(address);
        await _localDataSource.updateAddress(remoteAddress);
        return remoteAddress;
      }

      return address;
    } catch (e) {
      print('Error creating address: $e');
      rethrow;
    }
  }

  @override
  Future<Address?> getById(String id) async {
    try {
      // First try to get from local database
      Address? address = await _localDataSource.getAddressById(id);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch latest data from remote
      if (connectivityResult != ConnectivityResult.none) {
        final remoteAddress = await _remoteDataSource.getAddressById(id);

        if (remoteAddress != null) {
          // Update local database with remote data
          await _localDataSource.updateAddress(remoteAddress);
          return remoteAddress;
        }
      }

      return address;
    } catch (e) {
      print('Error getting address: $e');
      // Return local data if remote fetch fails
      return await _localDataSource.getAddressById(id);
    }
  }

  @override
  Future<List<Address>> getAll() async {
    try {
      // First get from local database
      List<Address> localAddresses = await _localDataSource.getAllAddresses();

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch latest data from remote
      if (connectivityResult != ConnectivityResult.none) {
        final remoteAddresses = await _remoteDataSource.getAllAddresses();

        // Update local database with remote data
        for (var address in remoteAddresses) {
          await _localDataSource.updateAddress(address);
        }

        return remoteAddresses;
      }

      return localAddresses;
    } catch (e) {
      print('Error getting all addresses: $e');
      // Return local data if remote fetch fails
      return await _localDataSource.getAllAddresses();
    }
  }

  @override
  Future<Address> update(Address address) async {
    try {
      // Always update local database
      await _localDataSource.updateAddress(address);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, update remote database
      if (connectivityResult != ConnectivityResult.none) {
        final remoteAddress = await _remoteDataSource.updateAddress(address);
        await _localDataSource.updateAddress(remoteAddress);
        return remoteAddress;
      }

      return address;
    } catch (e) {
      print('Error updating address: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      // Always delete from local database
      await _localDataSource.deleteAddress(id);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, delete from remote database
      if (connectivityResult != ConnectivityResult.none) {
        await _remoteDataSource.deleteAddress(id);
      }
    } catch (e) {
      print('Error deleting address: $e');
      rethrow;
    }
  }

  Future<List<Address>> getAddressesByCity(String city) async {
    try {
      // First get from local database
      List<Address> localAddresses =
          await _localDataSource.getAddressesByCity(city);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch latest data from remote
      if (connectivityResult != ConnectivityResult.none) {
        final remoteAddresses =
            await _remoteDataSource.getAddressesByCity(city);

        // Update local database with remote data
        for (var address in remoteAddresses) {
          await _localDataSource.updateAddress(address);
        }

        return remoteAddresses;
      }

      return localAddresses;
    } catch (e) {
      print('Error getting addresses by city: $e');
      // Return local data if remote fetch fails
      return await _localDataSource.getAddressesByCity(city);
    }
  }

  Future<List<Address>> getAddressesByCountry(String country) async {
    try {
      // First get from local database
      List<Address> localAddresses =
          await _localDataSource.getAddressesByCountry(country);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch latest data from remote
      if (connectivityResult != ConnectivityResult.none) {
        final remoteAddresses =
            await _remoteDataSource.getAddressesByCountry(country);

        // Update local database with remote data
        for (var address in remoteAddresses) {
          await _localDataSource.updateAddress(address);
        }

        return remoteAddresses;
      }

      return localAddresses;
    } catch (e) {
      print('Error getting addresses by country: $e');
      // Return local data if remote fetch fails
      return await _localDataSource.getAddressesByCountry(country);
    }
  }

  Future<List<Address>> getNearbyAddresses(
      double latitude, double longitude, double radiusKm) async {
    try {
      // First get from local database
      List<Address> localAddresses = await _localDataSource.getNearbyAddresses(
          latitude, longitude, radiusKm);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch latest data from remote
      if (connectivityResult != ConnectivityResult.none) {
        final remoteAddresses = await _remoteDataSource.getNearbyAddresses(
            latitude, longitude, radiusKm);

        // Update local database with remote data
        for (var address in remoteAddresses) {
          await _localDataSource.updateAddress(address);
        }

        return remoteAddresses;
      }

      return localAddresses;
    } catch (e) {
      print('Error getting nearby addresses: $e');
      // Return local data if remote fetch fails
      return await _localDataSource.getNearbyAddresses(
          latitude, longitude, radiusKm);
    }
  }
}
