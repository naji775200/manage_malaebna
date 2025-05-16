import '../models/working_hour_model.dart';
import 'base_local_data_source.dart';

class WorkingHoursLocalDataSource extends BaseLocalDataSource<WorkingHours> {
  WorkingHoursLocalDataSource() : super('working_hours');

  Future<WorkingHours?> getWorkingHoursById(String id) async {
    final map = await getById(id);
    if (map != null) {
      return WorkingHours.fromJson(map);
    }
    return null;
  }

  Future<List<WorkingHours>> getAllWorkingHours() async {
    final maps = await getAll();
    return maps.map((map) => WorkingHours.fromJson(map)).toList();
  }

  Future<String> insertWorkingHours(WorkingHours workingHours) async {
    return await insert(workingHours.toJson());
  }

  Future<int> updateWorkingHours(WorkingHours workingHours) async {
    return await update(workingHours.toJson());
  }

  Future<int> deleteWorkingHours(String id) async {
    return await delete(id);
  }

  Future<List<WorkingHours>> getWorkingHoursByStadiumId(
      String stadiumId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    return maps.map((map) => WorkingHours.fromJson(map)).toList();
  }

  Future<WorkingHours?> getWorkingHoursByStadiumIdAndDay(
      String stadiumId, String dayOfWeek) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'stadium_id = ? AND day_of_week = ?',
      whereArgs: [stadiumId, dayOfWeek],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return WorkingHours.fromJson(maps.first);
  }
}
