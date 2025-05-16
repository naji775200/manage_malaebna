import 'package:equatable/equatable.dart';

enum NotificationType {
  match, // Match-related notifications
  friend, // Friend requests
  payment, // Payment confirmations
  system, // System messages
  booking, // Booking confirmations
  review, // Review notifications
  coupon, // Coupon notifications
}

class NotificationModel extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime sentAt;

  const NotificationModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.sentAt,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        message,
        type,
        isRead,
        sentAt,
      ];

  NotificationModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? sentAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      message: json['message'] as String,
      type: _parseNotificationType(json['type'] as String),
      isRead: json['is_read'] as bool? ?? false,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'type': type.toString().split('.').last,
      'is_read': isRead,
      'sent_at': sentAt.toIso8601String(),
    };
  }

  static NotificationType _parseNotificationType(String typeString) {
    switch (typeString) {
      case 'match':
        return NotificationType.match;
      case 'friend':
        return NotificationType.friend;
      case 'payment':
        return NotificationType.payment;
      case 'system':
        return NotificationType.system;
      case 'booking':
        return NotificationType.booking;
      case 'review':
        return NotificationType.review;
      case 'coupon':
        return NotificationType.coupon;
      default:
        return NotificationType.system;
    }
  }
}
