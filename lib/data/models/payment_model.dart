import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String status;
  final String? transactionId;
  final String paymentStatus;

  const Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.status = 'active',
    this.transactionId,
    this.paymentStatus = 'pending',
  });

  @override
  List<Object?> get props => [
        id,
        amount,
        currency,
        paymentMethod,
        status,
        transactionId,
        paymentStatus,
      ];

  Payment copyWith({
    String? id,
    double? amount,
    String? currency,
    String? paymentMethod,
    String? status,
    String? transactionId,
    String? paymentStatus,
  }) {
    return Payment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    try {
      // Handle amount conversion safely
      double amount;
      if (json['amount'] is int) {
        amount = (json['amount'] as int).toDouble();
      } else if (json['amount'] is double) {
        amount = json['amount'] as double;
      } else if (json['amount'] is String) {
        amount = double.tryParse((json['amount'] as String)) ?? 0.0;
      } else {
        print(
            '⚠️ Payment Model: Unknown amount type: ${json['amount'].runtimeType}');
        amount = 0.0;
      }

      return Payment(
        id: json['id'] as String,
        amount: amount,
        currency: json['currency'] as String? ?? 'SAR',
        paymentMethod: json['payment_method'] as String? ?? 'unknown',
        status: json['status'] as String? ?? 'active',
        transactionId: json['transaction_id'] as String?,
        paymentStatus: json['payment_status'] as String? ?? 'pending',
      );
    } catch (e) {
      print('❌ Payment Model: Error creating from JSON: $e');
      print('❌ Payment Model: Problematic JSON: $json');

      // Return a fallback payment with basic data to avoid app crashes
      return Payment(
        id: json['id'] as String? ??
            'error-${DateTime.now().millisecondsSinceEpoch}',
        amount: 0.0,
        currency: 'SAR',
        paymentMethod: 'unknown',
        status: 'error',
        paymentStatus: 'error',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'status': status,
      'transaction_id': transactionId,
      'payment_status': paymentStatus,
    };
  }
}
