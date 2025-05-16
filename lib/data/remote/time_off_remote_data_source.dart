import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/time_off_model.dart';

class TimeOffRemoteDataSource {
  final SupabaseClient _supabaseClient;

  TimeOffRemoteDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  Future<TimeOff> getTimeOffById(String id) async {
    final response =
        await _supabaseClient.from('times_off').select().eq('id', id).single();
    return TimeOff.fromJson(response);
  }

  Future<List<TimeOff>> getAllTimeOffs() async {
    final response = await _supabaseClient.from('times_off').select();
    return response.map<TimeOff>((json) => TimeOff.fromJson(json)).toList();
  }

  Future<List<TimeOff>> getTimeOffsByStadiumId(String stadiumId) async {
    final response = await _supabaseClient
        .from('times_off')
        .select()
        .eq('stadium_id', stadiumId);
    return response.map<TimeOff>((json) => TimeOff.fromJson(json)).toList();
  }

  Future<List<TimeOff>> getTimeOffsByFrequency(String frequency) async {
    final response = await _supabaseClient
        .from('times_off')
        .select()
        .eq('frequency', frequency);
    return response.map<TimeOff>((json) => TimeOff.fromJson(json)).toList();
  }

  Future<TimeOff> createTimeOff(TimeOff timeOff) async {
    final response = await _supabaseClient
        .from('times_off')
        .insert(timeOff.toJson())
        .select()
        .single();
    return TimeOff.fromJson(response);
  }

  Future<TimeOff> updateTimeOff(TimeOff timeOff) async {
    final response = await _supabaseClient
        .from('times_off')
        .update(timeOff.toJson())
        .eq('id', timeOff.id)
        .select()
        .single();
    return TimeOff.fromJson(response);
  }

  Future<void> deleteTimeOff(String id) async {
    await _supabaseClient.from('times_off').delete().eq('id', id);
  }

  Future<String?> getStadiumIdForUser(String userId) async {
    try {
      // Query the stadium table to find a stadium associated with this user
      final response = await _supabaseClient
          .from('stadium')
          .select('id')
          .eq('user_id', userId)
          .single();

      if (response['id'] != null) {
        return response['id'] as String;
      }
    } catch (e) {
      print('Error getting stadium ID for user: $e');
    }
    return null;
  }
}
