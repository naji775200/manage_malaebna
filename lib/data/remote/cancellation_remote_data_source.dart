import '../models/cancellation_model.dart';
import 'base_remote_data_source.dart';

class CancellationRemoteDataSource extends BaseRemoteDataSource<Cancellation> {
  CancellationRemoteDataSource() : super('cancellations');

  Future<Cancellation?> getCancellationById(String id) async {
    try {
      final response = await getById(id);
      if (response == null) return null;

      return Cancellation.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<Cancellation>> getAllCancellations() async {
    try {
      final response = await getAll();

      return response.map((json) => Cancellation.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> createCancellation(Cancellation cancellation) async {
    try {
      final response = await insert(cancellation.toJson());
      if (response == null) return null;

      return response['id'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateCancellation(Cancellation cancellation) async {
    try {
      await update(cancellation.id, cancellation.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCancellation(String id) async {
    try {
      await delete(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Cancellation?> getCancellationByBookingId(String bookingId) async {
    try {
      final response = await supabase
          .from('cancellations')
          .select()
          .eq('booking_id', bookingId)
          .maybeSingle();

      if (response == null) return null;
      return Cancellation.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
