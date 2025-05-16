import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/price_model.dart';

class PriceRemoteDataSource {
  final SupabaseClient _supabaseClient;

  PriceRemoteDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  Future<Price> getPriceById(String id) async {
    final response =
        await _supabaseClient.from('prices').select().eq('id', id).single();
    return Price.fromJson(response);
  }

  Future<List<Price>> getAllPrices() async {
    final response = await _supabaseClient.from('prices').select();
    return response.map<Price>((json) => Price.fromJson(json)).toList();
  }

  Future<List<Price>> getPricesByFieldId(String fieldId) async {
    final response =
        await _supabaseClient.from('prices').select().eq('field_id', fieldId);
    return response.map<Price>((json) => Price.fromJson(json)).toList();
  }

  Future<Price> createPrice(Price price) async {
    final response = await _supabaseClient
        .from('prices')
        .insert(price.toJson())
        .select()
        .single();
    return Price.fromJson(response);
  }

  Future<Price> updatePrice(Price price) async {
    final response = await _supabaseClient
        .from('prices')
        .update(price.toJson())
        .eq('id', price.id)
        .select()
        .single();
    return Price.fromJson(response);
  }

  Future<void> deletePrice(String id) async {
    await _supabaseClient.from('prices').delete().eq('id', id);
  }
}
