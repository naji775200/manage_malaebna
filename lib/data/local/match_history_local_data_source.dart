import '../models/match_history_model.dart';
import 'base_local_data_source.dart';

class MatchHistoryLocalDataSource extends BaseLocalDataSource<MatchHistory> {
  MatchHistoryLocalDataSource() : super('match_history');

  Future<MatchHistory?> getMatchHistoryById(String id) async {
    final map = await getById(id);
    if (map != null) {
      return MatchHistory.fromJson(map);
    }
    return null;
  }

  Future<List<MatchHistory>> getAllMatchHistories() async {
    final maps = await getAll();
    return maps.map((map) => MatchHistory.fromJson(map)).toList();
  }

  Future<String> insertMatchHistory(MatchHistory matchHistory) async {
    return await insert(matchHistory.toJson());
  }

  Future<int> updateMatchHistory(MatchHistory matchHistory) async {
    return await update(matchHistory.toJson());
  }

  Future<int> deleteMatchHistory(String id) async {
    return await delete(id);
  }

  Future<List<MatchHistory>> getMatchHistoriesByMatchId(String matchId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'match_id = ?',
      whereArgs: [matchId],
    );

    return maps.map((map) => MatchHistory.fromJson(map)).toList();
  }
}
