import 'package:sqflite/sqflite.dart';
import '../models/stadium_services_model.dart';
import 'base_local_data_source.dart';

class StadiumServicesLocalDataSource
    extends BaseLocalDataSource<StadiumServicesModel> {
  StadiumServicesLocalDataSource() : super('stadiums_services');

  @override
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        stadium_id TEXT NOT NULL,
        service_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<StadiumServicesModel?> getStadiumServiceById(String id) async {
    final map = await getById(id);
    if (map != null) {
      return StadiumServicesModel.fromJson(map);
    }
    return null;
  }

  Future<List<StadiumServicesModel>> getStadiumServicesByStadiumId(
      String stadiumId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );
    return maps.map((map) => StadiumServicesModel.fromJson(map)).toList();
  }

  Future<List<StadiumServicesModel>> getStadiumServicesByServiceId(
      String serviceId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'service_id = ?',
      whereArgs: [serviceId],
    );
    return maps.map((map) => StadiumServicesModel.fromJson(map)).toList();
  }

  Future<String> insertStadiumService(
      StadiumServicesModel stadiumService) async {
    return await insert(stadiumService.toJson());
  }

  Future<int> updateStadiumService(StadiumServicesModel stadiumService) async {
    return await update(stadiumService.toJson());
  }

  Future<int> deleteStadiumService(String id) async {
    return await delete(id);
  }

  Future<int> deleteStadiumServiceByStadiumAndService(
      String stadiumId, String serviceId) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'stadium_id = ? AND service_id = ?',
      whereArgs: [stadiumId, serviceId],
    );
  }
}
