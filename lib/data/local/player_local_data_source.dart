import '../models/player_model.dart';
import 'base_local_data_source.dart';

class PlayerLocalDataSource extends BaseLocalDataSource<Player> {
  PlayerLocalDataSource() : super('players');

  Future<Player?> getPlayerById(String id) async {
    final map = await getById(id);
    if (map != null) {
      return Player.fromJson(map);
    }
    return null;
  }

  Future<List<Player>> getAllPlayers() async {
    final maps = await getAll();
    return maps.map((map) => Player.fromJson(map)).toList();
  }

  Future<String> insertPlayer(Player player) async {
    return await insert(player.toJson());
  }

  Future<int> updatePlayer(Player player) async {
    return await update(player.toJson());
  }

  Future<int> deletePlayer(String id) async {
    return await delete(id);
  }

  Future<List<Player>> getPlayersByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: [status],
    );

    return maps.map((map) => Player.fromJson(map)).toList();
  }
}
