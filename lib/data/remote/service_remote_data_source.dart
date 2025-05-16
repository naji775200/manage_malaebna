import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_model.dart';

class ServiceRemoteDataSource {
  final SupabaseClient _supabaseClient;

  ServiceRemoteDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  Future<Service> getServiceById(String id) async {
    final response =
        await _supabaseClient.from('services').select().eq('id', id).single();
    return Service.fromJson(response);
  }

  Future<List<Service>> getAllServices() async {
    final response = await _supabaseClient.from('services').select();
    return response.map<Service>((json) => Service.fromJson(json)).toList();
  }

  Future<List<Service>> getServicesByStadiumId(String stadiumId) async {
    final response = await _supabaseClient
        .from('stadiums_services')
        .select('service_id')
        .eq('stadium_id', stadiumId);

    if (response.isEmpty) {
      return [];
    }

    final serviceIds =
        response.map<String>((json) => json['service_id'] as String).toList();

    final services = await _supabaseClient
        .from('services')
        .select()
        .filter('id', 'in', serviceIds);

    return services.map<Service>((json) => Service.fromJson(json)).toList();
  }

  Future<Service> createService(Service service) async {
    final response = await _supabaseClient
        .from('services')
        .insert(service.toJson())
        .select()
        .single();
    return Service.fromJson(response);
  }

  Future<Service> updateService(Service service) async {
    final response = await _supabaseClient
        .from('services')
        .update(service.toJson())
        .eq('id', service.id)
        .select()
        .single();
    return Service.fromJson(response);
  }

  Future<void> deleteService(String id) async {
    await _supabaseClient.from('services').delete().eq('id', id);
  }

  Future<void> addServiceToStadium(String stadiumId, String serviceId) async {
    await _supabaseClient.from('stadiums_services').insert({
      'stadium_id': stadiumId,
      'service_id': serviceId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeServiceFromStadium(
      String stadiumId, String serviceId) async {
    await _supabaseClient
        .from('stadiums_services')
        .delete()
        .eq('stadium_id', stadiumId)
        .eq('service_id', serviceId);
  }
}
