import '../models/time_off_model.dart';
import 'base_local_data_source.dart';

class TimeOffLocalDataSource extends BaseLocalDataSource<TimeOff> {
  TimeOffLocalDataSource() : super('times_off');

  Future<TimeOff?> getTimeOffById(String id) async {
    final map = await getById(id);
    if (map != null) {
      return TimeOff.fromJson(map);
    }
    return null;
  }

  Future<List<TimeOff>> getAllTimeOffs() async {
    final maps = await getAll();
    return maps.map((map) => TimeOff.fromJson(map)).toList();
  }

  Future<String> insertTimeOff(TimeOff timeOff) async {
    return await insert(timeOff.toJson());
  }

  Future<int> updateTimeOff(TimeOff timeOff) async {
    return await update(timeOff.toJson());
  }

  Future<int> deleteTimeOff(String id) async {
    return await delete(id);
  }

  Future<List<TimeOff>> getTimeOffsByStadiumId(String stadiumId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    return maps.map((map) => TimeOff.fromJson(map)).toList();
  }

  Future<List<TimeOff>> getTimeOffsByFrequency(String frequency) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'frequency = ?',
      whereArgs: [frequency],
    );

    return maps.map((map) => TimeOff.fromJson(map)).toList();
  }
}
