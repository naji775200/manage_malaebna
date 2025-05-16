import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/notifications/notifications_bloc.dart';
import '../../../logic/notifications/notifications_event.dart';
import '../../../logic/notifications/notifications_state.dart';
import '../../../data/models/notification_model.dart';
import '../../../logic/localization_bloc.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../core/services/translation_service.dart';
import '../../../logic/theme/theme_bloc.dart';

// Extension to add helper methods to NotificationModel
extension NotificationMetadata on NotificationModel {
  // Get a title based on notification type
  String get title {
    switch (type) {
      case NotificationType.match:
        return 'Match Notification';
      case NotificationType.friend:
        return 'Friend Request';
      case NotificationType.payment:
        return 'Payment Update';
      case NotificationType.system:
        return 'System Notification';
      case NotificationType.booking:
        return 'Booking Update';
      case NotificationType.review:
        return 'New Review';
      case NotificationType.coupon:
        return 'New Coupon';
      default:
        return 'Notification';
    }
  }

  // Get action text based on notification type
  String? get actionText {
    if (type == NotificationType.friend) {
      return 'Accept';
    } else if (type == NotificationType.match && !isRead) {
      return 'View';
    }
    return null;
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, localizationState) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            // For debugging only
            print('Auth Status: ${authState.status}');
            print('User ID: ${authState.userId}');

            // Get the user ID, use a fallback if not available
            // This ensures we don't pass an empty string to the NotificationsBloc
            final String userId = authState.userId.isNotEmpty
                ? authState.userId
                : 'default_user_id';

            // Create notifications screen - we skip authentication check since this is a protected route
            return BlocProvider(
              create: (context) {
                // Create the NotificationsBloc with error handling
                try {
                  return NotificationsBloc(
                    userId: userId,
                  )..add(const LoadNotifications());
                } catch (e) {
                  print('Error creating NotificationsBloc: $e');
                  // Return a fallback bloc that won't crash on null
                  return NotificationsBloc(
                    userId: 'default_user_id',
                  );
                }
              },
              child: BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, themeState) {
                  return Scaffold(
                    appBar: AppBar(
                      title: Text(translationService.tr(
                          'notifications.title', {}, context)),
                      actions: [
                        BlocBuilder<NotificationsBloc, NotificationsState>(
                          builder: (context, state) {
                            if (state.hasUnreadNotifications) {
                              return IconButton(
                                icon: const Icon(Icons.done_all),
                                tooltip: translationService.tr(
                                    'notifications.mark_all_read', {}, context),
                                onPressed: () {
                                  // Safely call the bloc action
                                  try {
                                    context
                                        .read<NotificationsBloc>()
                                        .add(const MarkAllNotificationsRead());
                                  } catch (e) {
                                    print('Error marking all as read: $e');
                                  }
                                },
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    body: BlocBuilder<NotificationsBloc, NotificationsState>(
                      builder: (context, state) {
                        if (state.isLoading && state.notifications.isEmpty) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (state.notifications.isEmpty) {
                          return _buildEmptyState(context);
                        }

                        return _buildNotificationsList(context, state);
                      },
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            translationService.tr(
                'notifications.no_notifications', {}, context),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            translationService.tr(
                'notifications.check_back_later', {}, context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
      BuildContext context, NotificationsState state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<NotificationsBloc>().add(const RefreshNotifications());
        // Wait for the refresh to complete
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.notifications.length,
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          return _buildNotificationItem(context, notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, NotificationModel notification) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Colors.red,
        alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        context
            .read<NotificationsBloc>()
            .add(DeleteNotification(notification.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                translationService.tr('notifications.deleted', {}, context)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: notification.isRead
            ? null
            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              context
                  .read<NotificationsBloc>()
                  .add(MarkNotificationRead(notification.id));
            }
            _handleNotificationTap(context, notification);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(context, notification),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimeAgo(context, notification.sentAt),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                        ),
                      ),
                      if (notification.actionText != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: isRtl
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              if (!notification.isRead) {
                                context
                                    .read<NotificationsBloc>()
                                    .add(MarkNotificationRead(notification.id));
                              }
                              _handleNotificationAction(context, notification);
                            },
                            child: Text(notification.actionText!),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(
      BuildContext context, NotificationModel notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.match:
        iconData = Icons.sports_soccer;
        iconColor = Colors.green;
        break;
      case NotificationType.friend:
        iconData = Icons.person_add;
        iconColor = Colors.blue;
        break;
      case NotificationType.system:
        iconData = Icons.info;
        iconColor = Colors.orange;
        break;
      case NotificationType.payment:
        iconData = Icons.payment;
        iconColor = Colors.purple;
        break;
      case NotificationType.booking:
        iconData = Icons.calendar_today;
        iconColor = Colors.amber;
        break;
      case NotificationType.review:
        iconData = Icons.star;
        iconColor = Colors.deepOrange;
        break;
      case NotificationType.coupon:
        iconData = Icons.local_offer;
        iconColor = Colors.teal;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Theme.of(context).colorScheme.primary;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _formatTimeAgo(BuildContext context, DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);

    // Strings for time units
    final String justNowText =
        translationService.tr('notifications.just_now', {}, context);
    final String minutesAgoText =
        translationService.tr('notifications.minutes_ago', {}, context);
    final String hoursAgoText =
        translationService.tr('notifications.hours_ago', {}, context);
    final String daysAgoText =
        translationService.tr('notifications.days_ago', {}, context);

    if (difference.inDays > 7) {
      // Return formatted date if older than a week
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} $daysAgoText';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} $hoursAgoText';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} $minutesAgoText';
    } else {
      return justNowText;
    }
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) {
    // Handle notification tap based on type
    switch (notification.type) {
      case NotificationType.match:
        // Navigate to match details
        print(
            'Navigate to match details for a ${notification.type} notification');
        break;
      case NotificationType.friend:
        // Navigate to friend profile
        print(
            'Navigate to friend profile for a ${notification.type} notification');
        break;
      case NotificationType.payment:
        // Navigate to payment details
        print(
            'Navigate to payment details for a ${notification.type} notification');
        break;
      case NotificationType.system:
      default:
        // Show a dialog with the full message for system notifications
        if (notification.type == NotificationType.system) {
          final String closeText =
              translationService.tr('notifications.close', {}, context);

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(notification.title),
              content: Text(notification.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(closeText),
                ),
              ],
            ),
          );
        }
    }
  }

  void _handleNotificationAction(
      BuildContext context, NotificationModel notification) {
    // Handle notification action button press
    switch (notification.type) {
      case NotificationType.match:
        // Join match or respond to invitation
        print('Join match for a ${notification.type} notification');
        break;
      case NotificationType.friend:
        // Accept friend request
        print('Accept friend request for a ${notification.type} notification');
        break;
      default:
        _handleNotificationTap(context, notification);
    }
  }
}
