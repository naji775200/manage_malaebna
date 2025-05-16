import '../models/owner_model.dart';
import 'base_remote_data_source.dart';

class OwnerRemoteDataSource extends BaseRemoteDataSource<Owner> {
  OwnerRemoteDataSource() : super('owners');

  Future<Owner?> getOwnerById(String id) async {
    try {
      final response = await getById(id);
      if (response == null) return null;

      return Owner.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<Owner>> getAllOwners() async {
    try {
      final response = await getAll();

      return response.map((json) => Owner.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> createOwner(Owner owner) async {
    try {
      final response = await insert(owner.toJson());
      if (response == null) return null;

      return response['id'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateOwner(Owner owner) async {
    try {
      await update(owner.id, owner.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteOwner(String id) async {
    try {
      await delete(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Owner>> getOwnersByStatus(String status) async {
    try {
      final response = await supabase
          .from('owners')
          .select()
          .eq('status', status)
          .order('name');

      return response.map((json) => Owner.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
