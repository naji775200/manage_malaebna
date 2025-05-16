import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/utils/time_utils.dart';

class Price extends Equatable {
  final String id;
  final String fieldId;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double pricePerHour;
  final List<String> daysOfWeek;

  const Price({
    required this.id,
    required this.fieldId,
    required this.startTime,
    required this.endTime,
    required this.pricePerHour,
    required this.daysOfWeek,
  });

  @override
  List<Object?> get props => [
        id,
        fieldId,
        startTime,
        endTime,
        pricePerHour,
        daysOfWeek,
      ];

  Price copyWith({
    String? id,
    String? fieldId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    double? pricePerHour,
    List<String>? daysOfWeek,
  }) {
    return Price(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }

  factory Price.fromJson(Map<String, dynamic> json) {
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

    return Price(
      id: json['id'] as String,
      fieldId: json['field_id'] as String,
      startTime: TimeUtils.parseTime(json['start_time'] as String),
      endTime: TimeUtils.parseTime(json['end_time'] as String),
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      daysOfWeek: parsedDaysOfWeek,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field_id': fieldId,
      'start_time': TimeUtils.formatTime(startTime),
      'end_time': TimeUtils.formatTime(endTime),
      'price_per_hour': pricePerHour,
      'days_of_week':
          daysOfWeek, // Send as a native array instead of jsonEncode
    };
  }
}
