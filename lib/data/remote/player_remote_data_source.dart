import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player_model.dart';

class PlayerRemoteDataSource {
  final SupabaseClient supabase = Supabase.instance.client;
  final String tableName = 'players';

  Future<Player?> getPlayerById(String id) async {
    try {
      final response =
          await supabase.from(tableName).select().eq('id', id).maybeSingle();

      if (response != null) {
        return Player.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting player by ID: $e');
      rethrow;
    }
  }

  Future<List<Player>> getAllPlayers() async {
    try {
      final response = await supabase.from(tableName).select();

      return (response as List).map((item) => Player.fromJson(item)).toList();
    } catch (e) {
      print('Error getting all players: $e');
      rethrow;
    }
  }

  Future<Player> createPlayer(Player player) async {
    try {
      final response = await supabase
          .from(tableName)
          .insert(player.toJson())
          .select()
          .single();

      return Player.fromJson(response);
    } catch (e) {
      print('Error creating player: $e');
      rethrow;
    }
  }

  Future<Player> updatePlayer(Player player) async {
    try {
      final response = await supabase
          .from(tableName)
          .update(player.toJson())
          .eq('id', player.id)
          .select()
          .single();

      return Player.fromJson(response);
    } catch (e) {
      print('Error updating player: $e');
      rethrow;
    }
  }

  Future<void> deletePlayer(String id) async {
    try {
      await supabase.from(tableName).delete().eq('id', id);
    } catch (e) {
      print('Error deleting player: $e');
      rethrow;
    }
  }

  Future<List<Player>> getPlayersByStatus(String status) async {
    try {
      final response =
          await supabase.from(tableName).select().eq('status', status);

      return (response as List).map((item) => Player.fromJson(item)).toList();
    } catch (e) {
      print('Error getting players by status: $e');
      rethrow;
    }
  }
}
