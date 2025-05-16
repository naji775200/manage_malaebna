import 'dart:math' as math;
import '../models/address_model.dart';
import 'base_local_data_source.dart';

class AddressLocalDataSource extends BaseLocalDataSource<Address> {
  AddressLocalDataSource() : super('addresses');

  Future<Address?> getAddressById(String id) async {
    final map = await getById(id);
    if (map != null) {
      return Address.fromJson(map);
    }
    return null;
  }

  Future<List<Address>> getAllAddresses() async {
    final maps = await getAll();
    return maps.map((map) => Address.fromJson(map)).toList();
  }

  Future<String> insertAddress(Address address) async {
    return await insert(address.toJson());
  }

  Future<int> updateAddress(Address address) async {
    return await update(address.toJson());
  }

  Future<int> deleteAddress(String id) async {
    return await delete(id);
  }

  Future<List<Address>> getAddressesByCity(String city) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'city = ?',
      whereArgs: [city],
    );

    return maps.map((map) => Address.fromJson(map)).toList();
  }

  Future<List<Address>> getAddressesByCountry(String country) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'country = ?',
      whereArgs: [country],
    );

    return maps.map((map) => Address.fromJson(map)).toList();
  }

  Future<List<Address>> getNearbyAddresses(
      double latitude, double longitude, double radiusKm) async {
    final db = await database;

    // Calculate latitude and longitude ranges for the bounding box
    // 1 degree of latitude = ~111 km
    final latDelta = radiusKm / 111.0;
    // 1 degree of longitude = ~111 * cos(latitude) km
    final longDelta = radiusKm / (111.0 * math.cos(latitude * math.pi / 180));

    final minLat = latitude - latDelta;
    final maxLat = latitude + latDelta;
    final minLong = longitude - longDelta;
    final maxLong = longitude + longDelta;

    // Get addresses within the bounding box
    final maps = await db.query(
      tableName,
      where: 'latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?',
      whereArgs: [minLat, maxLat, minLong, maxLong],
    );

    return maps.map((map) => Address.fromJson(map)).toList();
  }
}
