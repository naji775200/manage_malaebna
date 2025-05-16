import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/field_model.dart';

class FieldRemoteDataSource {
  final SupabaseClient _supabaseClient;

  FieldRemoteDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  Future<Field> getFieldById(String id) async {
    final response =
        await _supabaseClient.from('fields').select().eq('id', id).single();
    return Field.fromJson(response);
  }

  Future<List<Field>> getAllFields() async {
    final response = await _supabaseClient.from('fields').select();
    return response.map<Field>((json) => Field.fromJson(json)).toList();
  }

  Future<List<Field>> getFieldsByStadiumId(String stadiumId) async {
    try {
      print(
          '📡 FieldRemoteDataSource: Querying fields with stadium_id = "$stadiumId"');
      final response = await _supabaseClient
          .from('fields')
          .select()
          .eq('stadium_id', stadiumId);

      print('📡 FieldRemoteDataSource: Response from Supabase: $response');
      final fields =
          response.map<Field>((json) => Field.fromJson(json)).toList();
      print(
          '📡 FieldRemoteDataSource: Parsed ${fields.length} fields from response');

      return fields;
    } catch (e) {
      print(
          '❌ FieldRemoteDataSource ERROR: Failed to get fields for stadium: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<Field>> getFieldsByStatus(String status) async {
    final response =
        await _supabaseClient.from('fields').select().eq('status', status);
    return response.map<Field>((json) => Field.fromJson(json)).toList();
  }

  Future<Field> createField(Field field) async {
    try {
      print('RemoteDataSource: Creating field in Supabase...');
      print('Field data being sent: ${field.toJson()}');

      // Remove the id if it's a temporary one to let Supabase generate a real ID
      final fieldData = Map<String, dynamic>.from(field.toJson());
      if (fieldData['id'].toString().startsWith('temp_')) {
        print('Removing temporary ID to let Supabase generate one');
        fieldData.remove('id');
      }

      // Ensure all required fields are present
      if (fieldData['stadium_id'] == null || fieldData['stadium_id'].isEmpty) {
        throw Exception('Stadium ID is required');
      }

      if (fieldData['name'] == null || fieldData['name'].isEmpty) {
        throw Exception('Field name is required');
      }

      print('Sending request to Supabase...');
      final response = await _supabaseClient
          .from('fields')
          .insert(fieldData)
          .select()
          .single();

      print('Supabase response: $response');
      return Field.fromJson(response);
    } catch (e) {
      print('Error in remote data source createField: $e');
      rethrow;
    }
  }

  Future<Field> updateField(Field field) async {
    final response = await _supabaseClient
        .from('fields')
        .update(field.toJson())
        .eq('id', field.id)
        .select()
        .single();
    return Field.fromJson(response);
  }

  Future<void> deleteField(String id) async {
    await _supabaseClient.from('fields').delete().eq('id', id);
  }
}
