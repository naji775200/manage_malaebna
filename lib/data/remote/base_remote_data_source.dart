import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BaseRemoteDataSource<T> {
  final String tableName;

  BaseRemoteDataSource(this.tableName);

  SupabaseClient get supabase => Supabase.instance.client;

  Future<Map<String, dynamic>?> insert(Map<String, dynamic> data) async {
    final response =
        await supabase.from(tableName).insert(data).select().single();

    return response;
  }

  Future<Map<String, dynamic>?> update(
      String id, Map<String, dynamic> data) async {
    final response = await supabase
        .from(tableName)
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return response;
  }

  Future<void> delete(String id) async {
    await supabase.from(tableName).delete().eq('id', id);
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final response =
        await supabase.from(tableName).select().eq('id', id).maybeSingle();

    return response;
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final response = await supabase.from(tableName).select();

    return response;
  }
}
