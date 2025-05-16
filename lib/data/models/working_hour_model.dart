import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/utils/time_utils.dart';

class WorkingHours extends Equatable {
  final String id;
  final String stadiumId;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String dayOfWeek;
  

  const WorkingHours({
    required this.id,
    required this.stadiumId,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
  });

  @override
  List<Object?> get props => [id, stadiumId, startTime, endTime, dayOfWeek];

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      id: json['id'] as String,
      stadiumId: json['stadium_id'] as String,
      startTime: TimeUtils.parseTime(json['start_time'] as String),
      endTime: TimeUtils.parseTime(json['end_time'] as String),
      dayOfWeek: json['day_of_week'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stadium_id': stadiumId,
      'start_time': TimeUtils.formatTime(startTime),
      'end_time': TimeUtils.formatTime(endTime),
      'day_of_week': dayOfWeek,
    };
  }

  WorkingHours copyWith({
    String? id,
    String? stadiumId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? dayOfWeek,
  }) {
    return WorkingHours(
      id: id ?? this.id,
      stadiumId: stadiumId ?? this.stadiumId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    );
  }
}
