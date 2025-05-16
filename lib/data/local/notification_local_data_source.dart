import 'package:sqflite/sqflite.dart';
import '../models/notification_model.dart';
import 'base_local_data_source.dart';

class NotificationLocalDataSource
    extends BaseLocalDataSource<NotificationModel> {
  NotificationLocalDataSource() : super('notifications');

  Future<NotificationModel?> getNotificationById(String id) async {
    final map = await getById(id);
    if (map != null) {
      return NotificationModel.fromJson(map);
    }
    return null;
  }

  Future<List<NotificationModel>> getAllNotifications() async {
    final maps = await getAll();
    return maps.map((map) => NotificationModel.fromJson(map)).toList();
  }

  Future<String> insertNotification(NotificationModel notification) async {
    return await insert(notification.toJson());
  }

  Future<int> updateNotification(NotificationModel notification) async {
    return await update(notification.toJson());
  }

  Future<int> deleteNotification(String id) async {
    return await delete(id);
  }

  Future<List<NotificationModel>> getNotificationsByReceiverId(
      String receiverId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'receiver_id = ?',
      whereArgs: [receiverId],
      orderBy: 'sent_at DESC',
    );

    return maps.map((map) => NotificationModel.fromJson(map)).toList();
  }

  Future<int> markAsRead(String id) async {
    final db = await database;
    return await db.update(
      tableName,
      {'is_read': true},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markAllAsRead(String receiverId) async {
    final db = await database;
    return await db.update(
      tableName,
      {'is_read': true},
      where: 'receiver_id = ? AND is_read = ?',
      whereArgs: [receiverId, false],
    );
  }

  Future<int> getUnreadCount(String receiverId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM $tableName
      WHERE receiver_id = ? AND is_read = ?
    ''', [receiverId, false]);

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
