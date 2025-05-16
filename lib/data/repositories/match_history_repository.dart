import '../models/match_history_model.dart';
import '../local/match_history_local_data_source.dart';
import '../remote/match_history_remote_data_source.dart';

class MatchHistoryRepository {
  final MatchHistoryRemoteDataSource _remoteDataSource;
  final MatchHistoryLocalDataSource _localDataSource;

  MatchHistoryRepository({
    required MatchHistoryRemoteDataSource remoteDataSource,
    required MatchHistoryLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  Future<MatchHistory?> getMatchHistoryById(String id,
      {bool forceRemote = false}) async {
    if (forceRemote) {
      final matchHistory = await _remoteDataSource.getMatchHistoryById(id);
      if (matchHistory != null) {
        await _localDataSource.updateMatchHistory(matchHistory);
      }
      return matchHistory;
    }

    final localMatchHistory = await _localDataSource.getMatchHistoryById(id);
    if (localMatchHistory != null) {
      return localMatchHistory;
    }

    final remoteMatchHistory = await _remoteDataSource.getMatchHistoryById(id);
    if (remoteMatchHistory != null) {
      await _localDataSource.insertMatchHistory(remoteMatchHistory);
    }
    return remoteMatchHistory;
  }

  Future<List<MatchHistory>> getAllMatchHistories(
      {bool forceRemote = false}) async {
    if (forceRemote) {
      final matchHistories = await _remoteDataSource.getAllMatchHistories();
      // Update local cache
      for (final matchHistory in matchHistories) {
        await _localDataSource.updateMatchHistory(matchHistory);
      }
      return matchHistories;
    }

    final localMatchHistories = await _localDataSource.getAllMatchHistories();
    if (localMatchHistories.isNotEmpty) {
      return localMatchHistories;
    }

    final remoteMatchHistories = await _remoteDataSource.getAllMatchHistories();
    // Cache the match histories locally
    for (final matchHistory in remoteMatchHistories) {
      await _localDataSource.insertMatchHistory(matchHistory);
    }
    return remoteMatchHistories;
  }

  Future<String> createMatchHistory(MatchHistory matchHistory) async {
    final id = await _remoteDataSource.createMatchHistory(matchHistory);
    if (id == null) {
      throw Exception('Failed to create match history');
    }
    final matchHistoryWithId = matchHistory.copyWith(id: id);
    await _localDataSource.insertMatchHistory(matchHistoryWithId);
    return id;
  }

  Future<bool> updateMatchHistory(MatchHistory matchHistory) async {
    final updated = await _remoteDataSource.updateMatchHistory(matchHistory);
    if (updated) {
      await _localDataSource.updateMatchHistory(matchHistory);
      return true;
    }
    return false;
  }

  Future<bool> deleteMatchHistory(String id) async {
    final deleted = await _remoteDataSource.deleteMatchHistory(id);
    if (deleted) {
      await _localDataSource.deleteMatchHistory(id);
      return true;
    }
    return false;
  }

  Future<List<MatchHistory>> getMatchHistoriesByMatchId(String matchId,
      {bool forceRemote = false}) async {
    if (forceRemote) {
      final matchHistories =
          await _remoteDataSource.getMatchHistoriesByMatchId(matchId);
      // Update local cache
      for (final matchHistory in matchHistories) {
        await _localDataSource.updateMatchHistory(matchHistory);
      }
      return matchHistories;
    }

    final localMatchHistories =
        await _localDataSource.getMatchHistoriesByMatchId(matchId);
    if (localMatchHistories.isNotEmpty) {
      return localMatchHistories;
    }

    final remoteMatchHistories =
        await _remoteDataSource.getMatchHistoriesByMatchId(matchId);
    // Cache the match histories locally
    for (final matchHistory in remoteMatchHistories) {
      await _localDataSource.insertMatchHistory(matchHistory);
    }
    return remoteMatchHistories;
  }
}
