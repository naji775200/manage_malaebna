import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class WorkingHour {
  final String dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isActive;

  const WorkingHour({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': {
        'hour': startTime.hour,
        'minute': startTime.minute,
      },
      'endTime': {
        'hour': endTime.hour,
        'minute': endTime.minute,
      },
      'isActive': isActive,
    };
  }

  factory WorkingHour.fromJson(Map<String, dynamic> json) {
    return WorkingHour(
      dayOfWeek: json['dayOfWeek'],
      startTime: TimeOfDay(
        hour: json['startTime']['hour'],
        minute: json['startTime']['minute'],
      ),
      endTime: TimeOfDay(
        hour: json['endTime']['hour'],
        minute: json['endTime']['minute'],
      ),
      isActive: json['isActive'],
    );
  }
}

abstract class WorkingHoursState extends Equatable {
  const WorkingHoursState();

  @override
  List<Object> get props => [];
}

class WorkingHoursInitial extends WorkingHoursState {}

class WorkingHoursLoading extends WorkingHoursState {}

// New state for saving operation in progress
class WorkingHoursSaving extends WorkingHoursState {
  final List<bool> isChecked;
  final List<TimeOfDay> startTimes;
  final List<TimeOfDay> endTimes;
  final List<String> daysOfWeek;

  const WorkingHoursSaving({
    required this.isChecked,
    required this.startTimes,
    required this.endTimes,
    required this.daysOfWeek,
  });

  @override
  List<Object> get props => [isChecked, startTimes, endTimes, daysOfWeek];
}

class WorkingHoursLoaded extends WorkingHoursState {
  final List<bool> isChecked;
  final List<TimeOfDay> startTimes;
  final List<TimeOfDay> endTimes;
  final List<String> daysOfWeek;

  const WorkingHoursLoaded({
    required this.isChecked,
    required this.startTimes,
    required this.endTimes,
    required this.daysOfWeek,
  });

  @override
  List<Object> get props => [isChecked, startTimes, endTimes, daysOfWeek];
}

class WorkingHoursError extends WorkingHoursState {
  final String message;

  const WorkingHoursError({required this.message});

  @override
  List<Object> get props => [message];
}
