import 'dart:convert';
import '../models/price_model.dart';
import 'base_local_data_source.dart';

class PriceLocalDataSource extends BaseLocalDataSource<Price> {
  PriceLocalDataSource() : super('prices');

  Future<Price?> getPriceById(String id) async {
    final map = await getById(id);
    if (map != null) {
      return Price.fromJson(map);
    }
    return null;
  }

  Future<List<Price>> getAllPrices() async {
    final maps = await getAll();
    return maps.map((map) => Price.fromJson(map)).toList();
  }

  Future<String> insertPrice(Price price) async {
    // Convert price to JSON
    final priceJson = price.toJson();

    // Convert daysOfWeek to a JSON string for SQLite
    priceJson['days_of_week'] = jsonEncode(priceJson['days_of_week']);

    return await insert(priceJson);
  }

  Future<int> updatePrice(Price price) async {
    // Convert price to JSON
    final priceJson = price.toJson();

    // Convert daysOfWeek to a JSON string for SQLite
    priceJson['days_of_week'] = jsonEncode(priceJson['days_of_week']);

    return await update(priceJson);
  }

  Future<int> deletePrice(String id) async {
    return await delete(id);
  }

  Future<List<Price>> getPricesByFieldId(String fieldId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'field_id = ?',
      whereArgs: [fieldId],
    );

    return maps.map((map) => Price.fromJson(map)).toList();
  }
}
