import 'package:flutter/material.dart';

/// Utility class for time-related operations
class TimeUtils {
  /// Converts a string time in format 'HH:MM' to TimeOfDay
  static TimeOfDay parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Converts a TimeOfDay to a string in format 'HH:MM'
  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
