import '../models/owner_model.dart';
import 'base_local_data_source.dart';

class OwnerLocalDataSource extends BaseLocalDataSource<Owner> {
  OwnerLocalDataSource() : super('owners');

  Future<Owner?> getOwnerById(String id) async {
    final map = await getById(id);
    if (map != null) {
      return Owner.fromJson(map);
    }
    return null;
  }

  Future<List<Owner>> getAllOwners() async {
    final maps = await getAll();
    return maps.map((map) => Owner.fromJson(map)).toList();
  }

  Future<String> insertOwner(Owner owner) async {
    return await insert(owner.toJson());
  }

  Future<int> updateOwner(Owner owner) async {
    return await update(owner.toJson());
  }

  Future<int> deleteOwner(String id) async {
    return await delete(id);
  }

  Future<List<Owner>> getOwnersByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: [status],
    );

    return maps.map((map) => Owner.fromJson(map)).toList();
  }
}
