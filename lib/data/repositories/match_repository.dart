import '../models/match_model.dart';
import '../local/match_local_data_source.dart';
import '../remote/match_remote_data_source.dart';

class MatchRepository {
  final MatchRemoteDataSource _remoteDataSource;
  final MatchLocalDataSource _localDataSource;

  MatchRepository({
    required MatchRemoteDataSource remoteDataSource,
    required MatchLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  Future<Match?> getMatchById(String id, {bool forceRemote = false}) async {
    if (forceRemote) {
      final match = await _remoteDataSource.getMatchById(id);
      if (match != null) {
        await _localDataSource.updateMatch(match);
      }
      return match;
    }

    final localMatch = await _localDataSource.getMatchById(id);
    if (localMatch != null) {
      return localMatch;
    }

    final remoteMatch = await _remoteDataSource.getMatchById(id);
    if (remoteMatch != null) {
      await _localDataSource.insertMatch(remoteMatch);
    }
    return remoteMatch;
  }

  Future<List<Match>> getAllMatches({bool forceRemote = false}) async {
    if (forceRemote) {
      final matches = await _remoteDataSource.getAllMatches();
      // Update local cache
      for (final match in matches) {
        await _localDataSource.updateMatch(match);
      }
      return matches;
    }

    final localMatches = await _localDataSource.getAllMatches();
    if (localMatches.isNotEmpty) {
      return localMatches;
    }

    final remoteMatches = await _remoteDataSource.getAllMatches();
    // Cache the matches locally
    for (final match in remoteMatches) {
      await _localDataSource.insertMatch(match);
    }
    return remoteMatches;
  }

  Future<String> createMatch(Match match) async {
    final id = await _remoteDataSource.insertMatch(match);
    final matchWithId = match.copyWith(id: id);
    await _localDataSource.insertMatch(matchWithId);
    return id;
  }

  Future<bool> updateMatch(Match match) async {
    final updated = await _remoteDataSource.updateMatch(match);
    if (updated) {
      await _localDataSource.updateMatch(match);
      return true;
    }
    return false;
  }

  Future<bool> deleteMatch(String id) async {
    final deleted = await _remoteDataSource.deleteMatch(id);
    if (deleted) {
      await _localDataSource.deleteMatch(id);
      return true;
    }
    return false;
  }

  Future<List<Match>> getMatchesByFieldId(String fieldId,
      {bool forceRemote = false}) async {
    if (forceRemote) {
      final matches = await _remoteDataSource.getMatchesByFieldId(fieldId);
      // Update local cache
      for (final match in matches) {
        await _localDataSource.updateMatch(match);
      }
      return matches;
    }

    final localMatches = await _localDataSource.getMatchesByFieldId(fieldId);
    if (localMatches.isNotEmpty) {
      return localMatches;
    }

    final remoteMatches = await _remoteDataSource.getMatchesByFieldId(fieldId);
    // Cache the matches locally
    for (final match in remoteMatches) {
      await _localDataSource.insertMatch(match);
    }
    return remoteMatches;
  }

  Future<List<Match>> getMatchesByStatus(String status,
      {bool forceRemote = false}) async {
    if (forceRemote) {
      final matches = await _remoteDataSource.getMatchesByStatus(status);
      // Update local cache
      for (final match in matches) {
        await _localDataSource.updateMatch(match);
      }
      return matches;
    }

    final localMatches = await _localDataSource.getMatchesByStatus(status);
    if (localMatches.isNotEmpty) {
      return localMatches;
    }

    final remoteMatches = await _remoteDataSource.getMatchesByStatus(status);
    // Cache the matches locally
    for (final match in remoteMatches) {
      await _localDataSource.insertMatch(match);
    }
    return remoteMatches;
  }

  Future<List<Match>> getMatchesByDate(DateTime date,
      {bool forceRemote = false}) async {
    if (forceRemote) {
      final matches = await _remoteDataSource.getMatchesByDate(date);
      // Update local cache
      for (final match in matches) {
        await _localDataSource.updateMatch(match);
      }
      return matches;
    }

    final localMatches = await _localDataSource.getMatchesByDate(date);
    if (localMatches.isNotEmpty) {
      return localMatches;
    }

    final remoteMatches = await _remoteDataSource.getMatchesByDate(date);
    // Cache the matches locally
    for (final match in remoteMatches) {
      await _localDataSource.insertMatch(match);
    }
    return remoteMatches;
  }

  Future<List<Match>> getMatchesByStadiumId(String stadiumId,
      {bool forceRemote = false}) async {
    try {
      print(
          '🏟️ MatchRepository: Getting matches for stadium ID: $stadiumId (forceRemote: $forceRemote)');

      if (forceRemote) {
        print(
            '🏟️ MatchRepository: Using remote data source for stadium matches');
        final remoteMatches = await _remoteDataSource.getByStadiumId(stadiumId);
        print(
            '🏟️ MatchRepository: Found ${remoteMatches.length} matches remotely');

        // Cache the matches locally
        for (var match in remoteMatches) {
          await _localDataSource.updateMatch(match);
        }
        return remoteMatches;
      }

      // Try local first if not forcing remote
      try {
        // Note: localDataSource doesn't have a direct method for this,
        // so we would need to first get the fields by stadium ID and then get matches by field ID
        // For simplicity, we'll use the remote source when needed
        print(
            '🏟️ MatchRepository: Local method not available, using remote source');
        final remoteMatches = await _remoteDataSource.getByStadiumId(stadiumId);

        // Cache the matches locally
        for (var match in remoteMatches) {
          await _localDataSource.updateMatch(match);
        }
        return remoteMatches;
      } catch (e) {
        print('🏟️ MatchRepository: Error getting matches locally: $e');
        final remoteMatches = await _remoteDataSource.getByStadiumId(stadiumId);

        // Cache the matches locally
        for (var match in remoteMatches) {
          await _localDataSource.updateMatch(match);
        }
        return remoteMatches;
      }
    } catch (e) {
      print('❌ MatchRepository ERROR: Failed to get matches for stadium: $e');
      rethrow;
    }
  }
}
