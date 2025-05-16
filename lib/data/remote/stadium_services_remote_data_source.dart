import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stadium_services_model.dart';

class StadiumServicesRemoteDataSource {
  final SupabaseClient _supabaseClient;

  StadiumServicesRemoteDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  Future<StadiumServicesModel> getStadiumServiceById(String id) async {
    final response = await _supabaseClient
        .from('stadiums_services')
        .select()
        .eq('id', id)
        .single();
    return StadiumServicesModel.fromJson(response);
  }

  Future<List<StadiumServicesModel>> getStadiumServicesByStadiumId(
      String stadiumId) async {
    final response = await _supabaseClient
        .from('stadiums_services')
        .select()
        .eq('stadium_id', stadiumId);
    return response
        .map<StadiumServicesModel>(
            (json) => StadiumServicesModel.fromJson(json))
        .toList();
  }

  Future<List<StadiumServicesModel>> getStadiumServicesByServiceId(
      String serviceId) async {
    final response = await _supabaseClient
        .from('stadiums_services')
        .select()
        .eq('service_id', serviceId);
    return response
        .map<StadiumServicesModel>(
            (json) => StadiumServicesModel.fromJson(json))
        .toList();
  }

  Future<StadiumServicesModel> createStadiumService(
      StadiumServicesModel stadiumService) async {
    final response = await _supabaseClient
        .from('stadiums_services')
        .insert(stadiumService.toJson())
        .select()
        .single();
    return StadiumServicesModel.fromJson(response);
  }

  Future<StadiumServicesModel> updateStadiumService(
      StadiumServicesModel stadiumService) async {
    final response = await _supabaseClient
        .from('stadiums_services')
        .update(stadiumService.toJson())
        .eq('id', stadiumService.id)
        .select()
        .single();
    return StadiumServicesModel.fromJson(response);
  }

  Future<void> deleteStadiumService(String id) async {
    await _supabaseClient.from('stadiums_services').delete().eq('id', id);
  }

  Future<void> deleteStadiumServiceByStadiumAndService(
      String stadiumId, String serviceId) async {
    await _supabaseClient
        .from('stadiums_services')
        .delete()
        .eq('stadium_id', stadiumId)
        .eq('service_id', serviceId);
  }
}
