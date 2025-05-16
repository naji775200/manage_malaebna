import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final SupabaseClient supabase = Supabase.instance.client;
  final String tableName = 'notifications';

  Future<NotificationModel?> getNotificationById(String id) async {
    try {
      final response =
          await supabase.from(tableName).select().eq('id', id).maybeSingle();

      if (response != null) {
        return NotificationModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting notification by ID: $e');
      rethrow;
    }
  }

  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final response = await supabase
          .from(tableName)
          .select()
          .order('sent_at', ascending: false);

      return (response as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList();
    } catch (e) {
      print('Error getting all notifications: $e');
      rethrow;
    }
  }

  Future<NotificationModel> createNotification(
      NotificationModel notification) async {
    try {
      final response = await supabase
          .from(tableName)
          .insert(notification.toJson())
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  Future<NotificationModel> updateNotification(
      NotificationModel notification) async {
    try {
      final response = await supabase
          .from(tableName)
          .update(notification.toJson())
          .eq('id', notification.id)
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      print('Error updating notification: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await supabase.from(tableName).delete().eq('id', id);
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  Future<List<NotificationModel>> getNotificationsByReceiverId(
      String receiverId) async {
    try {
      final response = await supabase
          .from(tableName)
          .select()
          .eq('receiver_id', receiverId)
          .order('sent_at', ascending: false);

      return (response as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList();
    } catch (e) {
      print('Error getting notifications by receiver ID: $e');
      rethrow;
    }
  }

  Future<NotificationModel> markAsRead(String id) async {
    try {
      final response = await supabase
          .from(tableName)
          .update({'is_read': true})
          .eq('id', id)
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead(String receiverId) async {
    try {
      await supabase
          .from(tableName)
          .update({'is_read': true})
          .eq('receiver_id', receiverId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Future<int> getUnreadCount(String receiverId) async {
    try {
      final response = await supabase
          .from(tableName)
          .select()
          .eq('receiver_id', receiverId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('Error getting unread count: $e');
      rethrow;
    }
  }
}
