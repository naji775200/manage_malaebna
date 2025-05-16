import '../models/match_history_model.dart';
import 'base_remote_data_source.dart';

class MatchHistoryRemoteDataSource extends BaseRemoteDataSource<MatchHistory> {
  static const String TABLE_NAME = 'match_history';

  MatchHistoryRemoteDataSource() : super(TABLE_NAME);

  Future<MatchHistory?> getMatchHistoryById(String id) async {
    try {
      print('📡 MatchHistoryRemoteDataSource: Getting history with ID: $id');
      final response = await getById(id);
      if (response == null) return null;

      return MatchHistory.fromJson(response);
    } catch (e) {
      print(
          '❌ MatchHistoryRemoteDataSource ERROR: Failed to get history by ID: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  Future<List<MatchHistory>> getAllMatchHistories() async {
    try {
      print('📡 MatchHistoryRemoteDataSource: Getting all match histories');
      final response = await getAll();
      print(
          '📡 MatchHistoryRemoteDataSource: Found ${response.length} history records');

      return response.map((json) => MatchHistory.fromJson(json)).toList();
    } catch (e) {
      print(
          '❌ MatchHistoryRemoteDataSource ERROR: Failed to get all histories: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  Future<String?> createMatchHistory(MatchHistory matchHistory) async {
    try {
      print('📡 MatchHistoryRemoteDataSource: Creating match history');
      final response = await insert(matchHistory.toJson());
      if (response == null) return null;

      return response['id'];
    } catch (e) {
      print(
          '❌ MatchHistoryRemoteDataSource ERROR: Failed to create history: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  Future<bool> updateMatchHistory(MatchHistory matchHistory) async {
    try {
      print(
          '📡 MatchHistoryRemoteDataSource: Updating match history ID: ${matchHistory.id}');
      await update(matchHistory.id, matchHistory.toJson());
      return true;
    } catch (e) {
      print(
          '❌ MatchHistoryRemoteDataSource ERROR: Failed to update history: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<bool> deleteMatchHistory(String id) async {
    try {
      print('📡 MatchHistoryRemoteDataSource: Deleting match history ID: $id');
      await delete(id);
      return true;
    } catch (e) {
      print(
          '❌ MatchHistoryRemoteDataSource ERROR: Failed to delete history: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<List<MatchHistory>> getMatchHistoriesByMatchId(String matchId) async {
    try {
      print(
          '📡 MatchHistoryRemoteDataSource: Getting histories for match ID: $matchId');
      final response =
          await supabase.from(TABLE_NAME).select().eq('match_id', matchId);

      print(
          '📡 MatchHistoryRemoteDataSource: Found ${response.length} history records');
      return response.map((json) => MatchHistory.fromJson(json)).toList();
    } catch (e) {
      print(
          '❌ MatchHistoryRemoteDataSource ERROR: Failed to get histories by match ID: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }
}
