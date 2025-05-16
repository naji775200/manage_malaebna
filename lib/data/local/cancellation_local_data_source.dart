import '../models/cancellation_model.dart';
import 'base_local_data_source.dart';

class CancellationLocalDataSource extends BaseLocalDataSource<Cancellation> {
  CancellationLocalDataSource() : super('cancellations');

  Future<Cancellation?> getCancellationById(String id) async {
    final map = await getById(id);
    if (map != null) {
      return Cancellation.fromJson(map);
    }
    return null;
  }

  Future<List<Cancellation>> getAllCancellations() async {
    final maps = await getAll();
    return maps.map((map) => Cancellation.fromJson(map)).toList();
  }

  Future<String> insertCancellation(Cancellation cancellation) async {
    return await insert(cancellation.toJson());
  }

  Future<int> updateCancellation(Cancellation cancellation) async {
    return await update(cancellation.toJson());
  }

  Future<int> deleteCancellation(String id) async {
    return await delete(id);
  }

  Future<Cancellation?> getCancellationByBookingId(String bookingId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'booking_id = ?',
      whereArgs: [bookingId],
    );

    if (maps.isNotEmpty) {
      return Cancellation.fromJson(maps.first);
    }
    return null;
  }
}
