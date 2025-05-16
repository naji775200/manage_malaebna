import 'dart:async';
import '../models/player_model.dart';
import '../local/player_local_data_source.dart';
import '../remote/player_remote_data_source.dart';
import 'base_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class PlayerRepository implements BaseRepository<Player> {
  final PlayerLocalDataSource _localDataSource;
  final PlayerRemoteDataSource _remoteDataSource;
  final Connectivity _connectivity;

  PlayerRepository({
    PlayerLocalDataSource? localDataSource,
    PlayerRemoteDataSource? remoteDataSource,
    Connectivity? connectivity,
  })  : _localDataSource = localDataSource ?? PlayerLocalDataSource(),
        _remoteDataSource = remoteDataSource ?? PlayerRemoteDataSource(),
        _connectivity = connectivity ?? Connectivity();

  @override
  Future<Player> create(Player player) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      // Always save to local database
      await _localDataSource.insertPlayer(player);

      // If online, save to remote and update local with remote data
      if (connectivityResult != ConnectivityResult.none) {
        final remotePlayer = await _remoteDataSource.createPlayer(player);
        await _localDataSource.updatePlayer(remotePlayer);
        return remotePlayer;
      }

      return player;
    } catch (e) {
      print('Error creating player: $e');
      rethrow;
    }
  }

  @override
  Future<Player?> getById(String id) async {
    try {
      // First try to get from local database
      Player? player = await _localDataSource.getPlayerById(id);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch latest data from remote
      if (connectivityResult != ConnectivityResult.none) {
        final remotePlayer = await _remoteDataSource.getPlayerById(id);

        if (remotePlayer != null) {
          // Update local database with remote data
          await _localDataSource.updatePlayer(remotePlayer);
          return remotePlayer;
        }
      }

      return player;
    } catch (e) {
      print('Error getting player: $e');
      // Return local data if remote fetch fails
      return await _localDataSource.getPlayerById(id);
    }
  }

  @override
  Future<List<Player>> getAll() async {
    try {
      // First get from local database
      List<Player> localPlayers = await _localDataSource.getAllPlayers();

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch latest data from remote
      if (connectivityResult != ConnectivityResult.none) {
        final remotePlayers = await _remoteDataSource.getAllPlayers();

        // Update local database with remote data
        for (var player in remotePlayers) {
          await _localDataSource.updatePlayer(player);
        }

        return remotePlayers;
      }

      return localPlayers;
    } catch (e) {
      print('Error getting all players: $e');
      // Return local data if remote fetch fails
      return await _localDataSource.getAllPlayers();
    }
  }

  @override
  Future<Player> update(Player player) async {
    try {
      // Always update local database
      await _localDataSource.updatePlayer(player);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, update remote database
      if (connectivityResult != ConnectivityResult.none) {
        final remotePlayer = await _remoteDataSource.updatePlayer(player);
        await _localDataSource.updatePlayer(remotePlayer);
        return remotePlayer;
      }

      return player;
    } catch (e) {
      print('Error updating player: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      // Always delete from local database
      await _localDataSource.deletePlayer(id);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, delete from remote database
      if (connectivityResult != ConnectivityResult.none) {
        await _remoteDataSource.deletePlayer(id);
      }
    } catch (e) {
      print('Error deleting player: $e');
      rethrow;
    }
  }

  Future<List<Player>> getPlayersByStatus(String status) async {
    try {
      // First get from local database
      List<Player> localPlayers =
          await _localDataSource.getPlayersByStatus(status);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch latest data from remote
      if (connectivityResult != ConnectivityResult.none) {
        final remotePlayers =
            await _remoteDataSource.getPlayersByStatus(status);

        // Update local database with remote data
        for (var player in remotePlayers) {
          await _localDataSource.updatePlayer(player);
        }

        return remotePlayers;
      }

      return localPlayers;
    } catch (e) {
      print('Error getting players by status: $e');
      // Return local data if remote fetch fails
      return await _localDataSource.getPlayersByStatus(status);
    }
  }
}
