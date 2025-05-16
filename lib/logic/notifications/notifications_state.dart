import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';

enum NotificationsStatus { initial, loading, loaded, error }

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<NotificationModel> notifications;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, notifications, errorMessage];

  // Helpers
  bool get isInitial => status == NotificationsStatus.initial;
  bool get isLoading => status == NotificationsStatus.loading;
  bool get isLoaded => status == NotificationsStatus.loaded;
  bool get isError => status == NotificationsStatus.error;

  bool get hasUnreadNotifications =>
      notifications.any((notification) => !notification.isRead);
  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;

  // Create a copy of this state with modified fields
  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationModel>? notifications,
    String? errorMessage,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage,
    );
  }
}
