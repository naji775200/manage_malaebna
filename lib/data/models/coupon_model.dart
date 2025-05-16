import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/utils/time_utils.dart';

class Coupon extends Equatable {
  final String id;
  final String stadiumId;
  final String name;
  final String code;
  final int discountPercentage;
  final DateTime expirationDate;
  final String status;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<String> daysOfWeek;

  const Coupon({
    required this.id,
    required this.stadiumId,
    required this.name,
    required this.code,
    required this.discountPercentage,
    required this.expirationDate,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.daysOfWeek,
  });

  @override
  List<Object?> get props => [
        id,
        stadiumId,
        name,
        code,
        discountPercentage,
        expirationDate,
        status,
        startTime,
        endTime,
        daysOfWeek,
      ];

  Coupon copyWith({
    String? id,
    String? stadiumId,
    String? name,
    String? code,
    int? discountPercentage,
    DateTime? expirationDate,
    String? status,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<String>? daysOfWeek,
  }) {
    return Coupon(
      id: id ?? this.id,
      stadiumId: stadiumId ?? this.stadiumId,
      name: name ?? this.name,
      code: code ?? this.code,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      expirationDate: expirationDate ?? this.expirationDate,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }

  factory Coupon.fromJson(Map<String, dynamic> json) {
    // Handle days_of_week that could be stored as a JSON string
    List<String> parsedDaysOfWeek;

    if (json['days_of_week'] is String) {
      // If it's a JSON string, parse it
      try {
        parsedDaysOfWeek =
            List<String>.from(jsonDecode(json['days_of_week'] as String));
      } catch (e) {
        // Fallback: Split by comma if JSON parsing fails
        parsedDaysOfWeek = (json['days_of_week'] as String).split(',');
      }
    } else if (json['days_of_week'] is List) {
      // If it's already a list, use it
      parsedDaysOfWeek = List<String>.from(json['days_of_week'] as List);
    } else {
      // Fallback to empty list if the format is unexpected
      parsedDaysOfWeek = [];
    }

    return Coupon(
      id: json['id'] as String,
      stadiumId: json['stadium_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      discountPercentage: json['discount_percentage'] as int,
      expirationDate: DateTime.parse(json['expiration_date'] as String),
      status: json['status'] as String,
      startTime: TimeUtils.parseTime(json['start_time'] as String),
      endTime: TimeUtils.parseTime(json['end_time'] as String),
      daysOfWeek: parsedDaysOfWeek,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stadium_id': stadiumId,
      'name': name,
      'code': code,
      'discount_percentage': discountPercentage,
      'expiration_date': expirationDate.toIso8601String(),
      'status': status,
      'start_time': TimeUtils.formatTime(startTime),
      'end_time': TimeUtils.formatTime(endTime),
      'days_of_week':
          daysOfWeek, // Send as a native array instead of jsonEncode
    };
  }
}
