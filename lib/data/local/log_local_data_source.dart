import '../models/log_model.dart';
import 'base_local_data_source.dart';

class LogLocalDataSource extends BaseLocalDataSource<Log> {
  LogLocalDataSource() : super('logs');

  Future<Log?> getLogById(String id) async {
    final map = await getById(id);
    if (map != null) {
      return Log.fromJson(map);
    }
    return null;
  }

  Future<List<Log>> getAllLogs() async {
    final maps = await getAll();
    return maps.map((map) => Log.fromJson(map)).toList();
  }

  Future<String> insertLog(Log log) async {
    return await insert(log.toJson());
  }

  Future<int> updateLog(Log log) async {
    return await update(log.toJson());
  }

  Future<int> deleteLog(String id) async {
    return await delete(id);
  }

  Future<List<Log>> getLogsByEntityId(String entityId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'entity_id = ?',
      whereArgs: [entityId],
    );

    return maps.map((map) => Log.fromJson(map)).toList();
  }

  Future<List<Log>> getLogsByType(LogType logType) async {
    final db = await database;
    final typeString = logType.toString().split('.').last;
    final maps = await db.query(
      tableName,
      where: 'log_type = ?',
      whereArgs: [typeString],
    );

    return maps.map((map) => Log.fromJson(map)).toList();
  }

  Future<List<Log>> getLogsByAction(String action) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'action = ?',
      whereArgs: [action],
    );

    return maps.map((map) => Log.fromJson(map)).toList();
  }
}
