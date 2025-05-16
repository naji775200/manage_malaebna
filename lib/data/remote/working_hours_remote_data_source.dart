import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/working_hour_model.dart';

class WorkingHoursRemoteDataSource {
  final SupabaseClient _supabaseClient;

  WorkingHoursRemoteDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  Future<WorkingHours> getWorkingHoursById(String id) async {
    final response = await _supabaseClient
        .from('working_hours')
        .select()
        .eq('id', id)
        .single();
    return WorkingHours.fromJson(response);
  }

  Future<List<WorkingHours>> getAllWorkingHours() async {
    final response = await _supabaseClient.from('working_hours').select();
    return response
        .map<WorkingHours>((json) => WorkingHours.fromJson(json))
        .toList();
  }

  Future<List<WorkingHours>> getWorkingHoursByStadiumId(
      String stadiumId) async {
    final response = await _supabaseClient
        .from('working_hours')
        .select()
        .eq('stadium_id', stadiumId);
    return response
        .map<WorkingHours>((json) => WorkingHours.fromJson(json))
        .toList();
  }

  Future<WorkingHours?> getWorkingHoursByStadiumIdAndDay(
      String stadiumId, String dayOfWeek) async {
    final response = await _supabaseClient
        .from('working_hours')
        .select()
        .eq('stadium_id', stadiumId)
        .eq('day_of_week', dayOfWeek)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return WorkingHours.fromJson(response);
  }

  Future<WorkingHours> createWorkingHours(WorkingHours workingHours) async {
    final response = await _supabaseClient
        .from('working_hours')
        .insert(workingHours.toJson())
        .select()
        .single();
    return WorkingHours.fromJson(response);
  }

  Future<WorkingHours> updateWorkingHours(WorkingHours workingHours) async {
    final response = await _supabaseClient
        .from('working_hours')
        .update(workingHours.toJson())
        .eq('id', workingHours.id)
        .select()
        .single();
    return WorkingHours.fromJson(response);
  }

  Future<void> deleteWorkingHours(String id) async {
    await _supabaseClient.from('working_hours').delete().eq('id', id);
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
