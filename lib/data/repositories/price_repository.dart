import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/price_local_data_source.dart';
import '../models/price_model.dart';
import '../remote/price_remote_data_source.dart';

class PriceRepository {
  final PriceRemoteDataSource _remoteDataSource;
  final PriceLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  PriceRepository({
    required PriceRemoteDataSource remoteDataSource,
    required PriceLocalDataSource localDataSource,
    required Connectivity connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _connectivity = connectivity;

  Future<bool> _hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<Price> getPriceById(String id, {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remotePrice = await _remoteDataSource.getPriceById(id);
        await _localDataSource.insertPrice(remotePrice);
        return remotePrice;
      } catch (e) {
        final localPrice = await _localDataSource.getPriceById(id);
        if (localPrice != null) {
          return localPrice;
        }
        rethrow;
      }
    } else {
      final localPrice = await _localDataSource.getPriceById(id);
      if (localPrice != null) {
        return localPrice;
      }
      throw Exception('No internet connection and price not found locally');
    }
  }

  Future<List<Price>> getAllPrices({bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remotePrices = await _remoteDataSource.getAllPrices();
        for (var price in remotePrices) {
          await _localDataSource.insertPrice(price);
        }
        return remotePrices;
      } catch (e) {
        return await _localDataSource.getAllPrices();
      }
    } else {
      return await _localDataSource.getAllPrices();
    }
  }

  Future<List<Price>> getPricesByFieldId(String fieldId,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remotePrices =
            await _remoteDataSource.getPricesByFieldId(fieldId);
        for (var price in remotePrices) {
          await _localDataSource.insertPrice(price);
        }
        return remotePrices;
      } catch (e) {
        return await _localDataSource.getPricesByFieldId(fieldId);
      }
    } else {
      return await _localDataSource.getPricesByFieldId(fieldId);
    }
  }

  Future<Price> createPrice(Price price) async {
    if (await _hasInternetConnection()) {
      final createdPrice = await _remoteDataSource.createPrice(price);
      await _localDataSource.insertPrice(createdPrice);
      return createdPrice;
    } else {
      throw Exception('No internet connection. Cannot create price.');
    }
  }

  Future<Price> updatePrice(Price price) async {
    if (await _hasInternetConnection()) {
      final updatedPrice = await _remoteDataSource.updatePrice(price);
      await _localDataSource.updatePrice(updatedPrice);
      return updatedPrice;
    } else {
      throw Exception('No internet connection. Cannot update price.');
    }
  }

  Future<void> deletePrice(String id) async {
    if (await _hasInternetConnection()) {
      await _remoteDataSource.deletePrice(id);
      await _localDataSource.deletePrice(id);
    } else {
      throw Exception('No internet connection. Cannot delete price.');
    }
  }
}
