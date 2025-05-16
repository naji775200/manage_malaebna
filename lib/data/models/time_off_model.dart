import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/utils/time_utils.dart';
import 'dart:convert';

class TimeOff extends Equatable {
  final String id;
  final String stadiumId;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String frequency;
  final List<String> daysOfWeek;
  final DateTime? specificDate;
  final String title;

  const TimeOff({
    required this.id,
    required this.stadiumId,
    required this.startTime,
    required this.endTime,
    required this.frequency,
    required this.daysOfWeek,
    this.specificDate,
    required this.title,
  });

  @override
  List<Object?> get props => [
        id,
        stadiumId,
        startTime,
        endTime,
        frequency,
        daysOfWeek,
        specificDate,
        title,
      ];

  TimeOff copyWith({
    String? id,
    String? stadiumId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? frequency,
    List<String>? daysOfWeek,
    DateTime? specificDate,
    String? title,
  }) {
    return TimeOff(
      id: id ?? this.id,
      stadiumId: stadiumId ?? this.stadiumId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      frequency: frequency ?? this.frequency,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      specificDate: specificDate ?? this.specificDate,
      title: title ?? this.title,
    );
  }

  factory TimeOff.fromJson(Map<String, dynamic> json) {
    List<String> parseDaysOfWeek(dynamic daysOfWeekData) {
      print(
          'Parsing days_of_week data: $daysOfWeekData (type: ${daysOfWeekData.runtimeType})');

      if (daysOfWeekData == null) return [];

      if (daysOfWeekData is String) {
        try {
          // Try to parse as JSON string
          final List<dynamic> parsed = jsonDecode(daysOfWeekData);
          print('Successfully parsed days_of_week as JSON list: $parsed');
          return parsed.map((item) => item.toString()).toList();
        } catch (e) {
          print('Error parsing days_of_week as JSON: $e');
          // If not valid JSON, try comma-separated format or PostgreSQL array format
          if (daysOfWeekData.isNotEmpty) {
            // Remove potential PostgreSQL array braces and quotes
            String sanitized =
                daysOfWeekData.replaceAll('{', '').replaceAll('}', '');
            final result = sanitized
                .split(',')
                .map((s) => s.trim().replaceAll('"', ''))
                .toList();
            print('Parsed days_of_week using comma splitting: $result');
            return result;
          }
          return [];
        }
      } else if (daysOfWeekData is List) {
        // Handle direct List values
        final result = daysOfWeekData.map((item) => item.toString()).toList();
        print('Days_of_week was already a List: $result');
        return result;
      } else if (daysOfWeekData is Map) {
        // In case it's stored as a map with numeric keys
        final result =
            daysOfWeekData.values.map((item) => item.toString()).toList();
        print('Parsed days_of_week from Map values: $result');
        return result;
      }

      // If we can't determine the format, log and return empty array
      print(
          'Unknown format for days_of_week: $daysOfWeekData (type: ${daysOfWeekData.runtimeType})');
      return [];
    }

    return TimeOff(
      id: json['id'] as String,
      stadiumId: json['stadium_id'] as String,
      startTime: TimeUtils.parseTime(json['start_time'] as String),
      endTime: TimeUtils.parseTime(json['end_time'] as String),
      frequency: json['frequency'] as String,
      daysOfWeek: parseDaysOfWeek(json['days_of_week']),
      specificDate: json['specific_date'] != null
          ? DateTime.parse(json['specific_date'] as String)
          : null,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    // Ensure daysOfWeek is not null before accessing it
    List<String> formattedDaysOfWeek = daysOfWeek;

    return {
      'id': id,
      'stadium_id': stadiumId,
      'start_time': TimeUtils.formatTime(startTime),
      'end_time': TimeUtils.formatTime(endTime),
      'frequency': frequency,
      'days_of_week': jsonEncode(formattedDaysOfWeek),
      'specific_date': specificDate?.toIso8601String(),
      'title': title,
    };
  }
}
