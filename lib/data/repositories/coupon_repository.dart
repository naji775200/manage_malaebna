import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/coupon_local_data_source.dart';
import '../models/coupon_model.dart';
import '../remote/coupon_remote_data_source.dart';

class CouponRepository {
  final CouponRemoteDataSource _remoteDataSource;
  final CouponLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  CouponRepository({
    required CouponRemoteDataSource remoteDataSource,
    required CouponLocalDataSource localDataSource,
    required Connectivity connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _connectivity = connectivity;

  Future<bool> _hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<Coupon> getCouponById(String id, {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteCoupon = await _remoteDataSource.getCouponById(id);
        await _localDataSource.insertCoupon(remoteCoupon);
        return remoteCoupon;
      } catch (e) {
        final localCoupon = await _localDataSource.getCouponById(id);
        if (localCoupon != null) {
          return localCoupon;
        }
        rethrow;
      }
    } else {
      final localCoupon = await _localDataSource.getCouponById(id);
      if (localCoupon != null) {
        return localCoupon;
      }
      throw Exception('No internet connection and coupon not found locally');
    }
  }

  Future<List<Coupon>> getAllCoupons({bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteCoupons = await _remoteDataSource.getAllCoupons();
        for (var coupon in remoteCoupons) {
          await _localDataSource.insertCoupon(coupon);
        }
        return remoteCoupons;
      } catch (e) {
        return await _localDataSource.getAllCoupons();
      }
    } else {
      return await _localDataSource.getAllCoupons();
    }
  }

  Future<List<Coupon>> getCouponsByStadiumId(String stadiumId,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteCoupons =
            await _remoteDataSource.getCouponsByStadiumId(stadiumId);
        for (var coupon in remoteCoupons) {
          await _localDataSource.insertCoupon(coupon);
        }
        return remoteCoupons;
      } catch (e) {
        return await _localDataSource.getCouponsByStadiumId(stadiumId);
      }
    } else {
      return await _localDataSource.getCouponsByStadiumId(stadiumId);
    }
  }

  Future<List<Coupon>> getCouponsByStatus(String status,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteCoupons =
            await _remoteDataSource.getCouponsByStatus(status);
        for (var coupon in remoteCoupons) {
          await _localDataSource.insertCoupon(coupon);
        }
        return remoteCoupons;
      } catch (e) {
        return await _localDataSource.getCouponsByStatus(status);
      }
    } else {
      return await _localDataSource.getCouponsByStatus(status);
    }
  }

  Future<Coupon?> getCouponByCode(String code,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteCoupon = await _remoteDataSource.getCouponByCode(code);
        if (remoteCoupon != null) {
          await _localDataSource.insertCoupon(remoteCoupon);
        }
        return remoteCoupon;
      } catch (e) {
        return await _localDataSource.getCouponByCode(code);
      }
    } else {
      return await _localDataSource.getCouponByCode(code);
    }
  }

  Future<Coupon> createCoupon(Coupon coupon) async {
    if (await _hasInternetConnection()) {
      final createdCoupon = await _remoteDataSource.createCoupon(coupon);
      await _localDataSource.insertCoupon(createdCoupon);
      return createdCoupon;
    } else {
      throw Exception('No internet connection. Cannot create coupon.');
    }
  }

  Future<Coupon> updateCoupon(Coupon coupon) async {
    if (await _hasInternetConnection()) {
      final updatedCoupon = await _remoteDataSource.updateCoupon(coupon);
      await _localDataSource.updateCoupon(updatedCoupon);
      return updatedCoupon;
    } else {
      throw Exception('No internet connection. Cannot update coupon.');
    }
  }

  Future<void> deleteCoupon(String id) async {
    if (await _hasInternetConnection()) {
      await _remoteDataSource.deleteCoupon(id);
      await _localDataSource.deleteCoupon(id);
    } else {
      throw Exception('No internet connection. Cannot delete coupon.');
    }
  }
}
