import '../models/field_model.dart';
import 'base_local_data_source.dart';

class FieldLocalDataSource extends BaseLocalDataSource<Field> {
  FieldLocalDataSource() : super('fields');

  Future<Field?> getFieldById(String id) async {
    final map = await getById(id);
    if (map != null) {
      return Field.fromJson(map);
    }
    return null;
  }

  Future<List<Field>> getAllFields() async {
    final maps = await getAll();
    return maps.map((map) => Field.fromJson(map)).toList();
  }

  Future<String> insertField(Field field) async {
    return await insert(field.toJson());
  }

  Future<int> updateField(Field field) async {
    return await update(field.toJson());
  }

  Future<int> deleteField(String id) async {
    return await delete(id);
  }

  Future<List<Field>> getFieldsByStadiumId(String stadiumId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    return maps.map((map) => Field.fromJson(map)).toList();
  }

  Future<List<Field>> getFieldsByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: [status],
    );

    return maps.map((map) => Field.fromJson(map)).toList();
  }

  Future<List<Field>> getFieldsBySurfaceType(String surfaceType) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'surface_type = ?',
      whereArgs: [surfaceType],
    );

    return maps.map((map) => Field.fromJson(map)).toList();
  }
}
