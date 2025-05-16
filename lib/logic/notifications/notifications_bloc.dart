import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_malaebna/data/repositories/notification_repository.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationRepository _repository;
  final String _currentUserId;

  NotificationsBloc({
    required String userId,
    NotificationRepository? repository,
  })  : _repository = repository ?? NotificationRepository(),
        _currentUserId = userId,
        super(const NotificationsState()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<MarkNotificationRead>(_onMarkNotificationRead);
    on<MarkAllNotificationsRead>(_onMarkAllNotificationsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<ClearAllNotifications>(_onClearAllNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading));

    try {
      final notifications =
          await _repository.getNotificationsByReceiverId(_currentUserId);

      emit(state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: notifications,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: 'Failed to load notifications: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    // Keep existing notifications while loading
    emit(state.copyWith(status: NotificationsStatus.loading));

    try {
      final notifications =
          await _repository.getNotificationsByReceiverId(_currentUserId);

      emit(state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: notifications,
      ));
    } catch (e) {
      // If refresh fails, keep existing notifications but show error
      emit(state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: 'Failed to refresh notifications: ${e.toString()}',
      ));
    }
  }

  Future<void> _onMarkNotificationRead(
    MarkNotificationRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      // Update UI immediately for responsiveness
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == event.notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();

      emit(state.copyWith(
        notifications: updatedNotifications,
      ));

      // Update in database
      await _repository.markAsRead(event.notificationId);
    } catch (e) {
      emit(state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: 'Failed to mark notification as read: ${e.toString()}',
      ));
    }
  }

  Future<void> _onMarkAllNotificationsRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      // Update UI immediately for responsiveness
      final updatedNotifications = state.notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();

      emit(state.copyWith(
        notifications: updatedNotifications,
      ));

      // Update in database
      await _repository.markAllAsRead(_currentUserId);
    } catch (e) {
      emit(state.copyWith(
        status: NotificationsStatus.error,
        errorMessage:
            'Failed to mark all notifications as read: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      // Update UI immediately for responsiveness
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != event.notificationId)
          .toList();

      emit(state.copyWith(
        notifications: updatedNotifications,
      ));

      // Delete from database
      await _repository.delete(event.notificationId);
    } catch (e) {
      emit(state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: 'Failed to delete notification: ${e.toString()}',
      ));
    }
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      emit(state.copyWith(
        notifications: [],
      ));

      // Delete all from database - we'll need to get all notifications first
      final notifications =
          await _repository.getNotificationsByReceiverId(_currentUserId);
      for (var notification in notifications) {
        await _repository.delete(notification.id);
      }
    } catch (e) {
      emit(state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: 'Failed to clear notifications: ${e.toString()}',
      ));
    }
  }
}
