import 'dart:convert';
import '../models/coupon_model.dart';
import 'base_local_data_source.dart';

class CouponLocalDataSource extends BaseLocalDataSource<Coupon> {
  CouponLocalDataSource() : super('coupons');

  Future<Coupon?> getCouponById(String id) async {
    final map = await getById(id);
    if (map != null) {
      return Coupon.fromJson(map);
    }
    return null;
  }

  Future<List<Coupon>> getAllCoupons() async {
    final maps = await getAll();
    return maps.map((map) => Coupon.fromJson(map)).toList();
  }

  Future<String> insertCoupon(Coupon coupon) async {
    // Convert coupon to JSON
    final couponJson = coupon.toJson();

    // Convert daysOfWeek to a JSON string for SQLite
    couponJson['days_of_week'] = jsonEncode(couponJson['days_of_week']);

    return await insert(couponJson);
  }

  Future<int> updateCoupon(Coupon coupon) async {
    // Convert coupon to JSON
    final couponJson = coupon.toJson();

    // Convert daysOfWeek to a JSON string for SQLite
    couponJson['days_of_week'] = jsonEncode(couponJson['days_of_week']);

    return await update(couponJson);
  }

  Future<int> deleteCoupon(String id) async {
    return await delete(id);
  }

  Future<List<Coupon>> getCouponsByStadiumId(String stadiumId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    return maps.map((map) => Coupon.fromJson(map)).toList();
  }

  Future<List<Coupon>> getCouponsByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: [status],
    );

    return maps.map((map) => Coupon.fromJson(map)).toList();
  }

  Future<Coupon?> getCouponByCode(String code) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Coupon.fromJson(maps.first);
  }
}
