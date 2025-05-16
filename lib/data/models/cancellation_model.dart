import 'package:equatable/equatable.dart';

class Cancellation extends Equatable {
  final String id;
  final String bookingId;
  final String reason;
  final double refundAmount;
  final DateTime canceledAt;

  const Cancellation({
    required this.id,
    required this.bookingId,
    required this.reason,
    required this.refundAmount,
    required this.canceledAt,
  });

  @override
  List<Object?> get props => [id, bookingId, reason, refundAmount, canceledAt];

  Cancellation copyWith({
    String? id,
    String? bookingId,
    String? reason,
    double? refundAmount,
    DateTime? canceledAt,
  }) {
    return Cancellation(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      reason: reason ?? this.reason,
      refundAmount: refundAmount ?? this.refundAmount,
      canceledAt: canceledAt ?? this.canceledAt,
    );
  }

  factory Cancellation.fromJson(Map<String, dynamic> json) {
    return Cancellation(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      reason: json['reason'] as String,
      refundAmount: (json['refund_amount'] as num).toDouble(),
      canceledAt: DateTime.parse(json['canceled_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'reason': reason,
      'refund_amount': refundAmount,
      'canceled_at': canceledAt.toIso8601String(),
    };
  }
}
