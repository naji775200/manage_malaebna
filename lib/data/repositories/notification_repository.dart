import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/notification_model.dart';
import '../local/notification_local_data_source.dart';
import '../remote/notification_remote_data_source.dart';
import 'base_repository.dart';

class NotificationRepository implements BaseRepository<NotificationModel> {
  final NotificationLocalDataSource _localDataSource;
  final NotificationRemoteDataSource _remoteDataSource;
  final Connectivity _connectivity;

  NotificationRepository({
    NotificationLocalDataSource? localDataSource,
    NotificationRemoteDataSource? remoteDataSource,
    Connectivity? connectivity,
  })  : _localDataSource = localDataSource ?? NotificationLocalDataSource(),
        _remoteDataSource = remoteDataSource ?? NotificationRemoteDataSource(),
        _connectivity = connectivity ?? Connectivity();

  @override
  Future<NotificationModel> create(NotificationModel notification) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      // Always save to local database
      await _localDataSource.insertNotification(notification);

      // If online, save to remote and update local with remote data
      if (connectivityResult != ConnectivityResult.none) {
        final remoteNotification =
            await _remoteDataSource.createNotification(notification);
        await _localDataSource.updateNotification(remoteNotification);
        return remoteNotification;
      }

      return notification;
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  @override
  Future<NotificationModel?> getById(String id) async {
    try {
      // First try to get from local database
      NotificationModel? notification =
          await _localDataSource.getNotificationById(id);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch latest data from remote
      if (connectivityResult != ConnectivityResult.none) {
        final remoteNotification =
            await _remoteDataSource.getNotificationById(id);

        if (remoteNotification != null) {
          // Update local database with remote data
          await _localDataSource.updateNotification(remoteNotification);
          return remoteNotification;
        }
      }

      return notification;
    } catch (e) {
      print('Error getting notification: $e');
      // Return local data if remote fetch fails
      return await _localDataSource.getNotificationById(id);
    }
  }

  @override
  Future<List<NotificationModel>> getAll() async {
    try {
      // First get from local database
      List<NotificationModel> localNotifications =
          await _localDataSource.getAllNotifications();

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch latest data from remote
      if (connectivityResult != ConnectivityResult.none) {
        final remoteNotifications =
            await _remoteDataSource.getAllNotifications();

        // Update local database with remote data
        for (var notification in remoteNotifications) {
          await _localDataSource.updateNotification(notification);
        }

        return remoteNotifications;
      }

      return localNotifications;
    } catch (e) {
      print('Error getting all notifications: $e');
      // Return local data if remote fetch fails
      return await _localDataSource.getAllNotifications();
    }
  }

  @override
  Future<NotificationModel> update(NotificationModel notification) async {
    try {
      // Always update local database
      await _localDataSource.updateNotification(notification);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, update remote database
      if (connectivityResult != ConnectivityResult.none) {
        final remoteNotification =
            await _remoteDataSource.updateNotification(notification);
        await _localDataSource.updateNotification(remoteNotification);
        return remoteNotification;
      }

      return notification;
    } catch (e) {
      print('Error updating notification: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      // Always delete from local database
      await _localDataSource.deleteNotification(id);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, delete from remote database
      if (connectivityResult != ConnectivityResult.none) {
        await _remoteDataSource.deleteNotification(id);
      }
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  Future<List<NotificationModel>> getNotificationsByReceiverId(
      String receiverId) async {
    try {
      // First get from local database
      List<NotificationModel> localNotifications =
          await _localDataSource.getNotificationsByReceiverId(receiverId);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, fetch latest data from remote
      if (connectivityResult != ConnectivityResult.none) {
        final remoteNotifications =
            await _remoteDataSource.getNotificationsByReceiverId(receiverId);

        // Update local database with remote data
        for (var notification in remoteNotifications) {
          await _localDataSource.updateNotification(notification);
        }

        return remoteNotifications;
      }

      return localNotifications;
    } catch (e) {
      print('Error getting notifications by receiver ID: $e');
      // Return local data if remote fetch fails
      return await _localDataSource.getNotificationsByReceiverId(receiverId);
    }
  }

  Future<NotificationModel> markAsRead(String id) async {
    try {
      // First mark as read in local database
      await _localDataSource.markAsRead(id);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, mark as read in remote database
      if (connectivityResult != ConnectivityResult.none) {
        final notification = await _remoteDataSource.markAsRead(id);
        return notification;
      }

      // Return the updated notification from local database
      final notification = await _localDataSource.getNotificationById(id);
      return notification!;
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead(String receiverId) async {
    try {
      // First mark all as read in local database
      await _localDataSource.markAllAsRead(receiverId);

      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, mark all as read in remote database
      if (connectivityResult != ConnectivityResult.none) {
        await _remoteDataSource.markAllAsRead(receiverId);
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Future<int> getUnreadCount(String receiverId) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      // If online, get unread count from remote database
      if (connectivityResult != ConnectivityResult.none) {
        return await _remoteDataSource.getUnreadCount(receiverId);
      }

      // Otherwise, get from local database
      return await _localDataSource.getUnreadCount(receiverId);
    } catch (e) {
      print('Error getting unread count: $e');
      // Return local data if remote fetch fails
      return await _localDataSource.getUnreadCount(receiverId);
    }
  }
}
