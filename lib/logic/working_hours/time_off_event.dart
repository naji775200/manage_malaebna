import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

abstract class TimeOffEvent extends Equatable {
  const TimeOffEvent();

  @override
  List<Object?> get props => [];
}

class LoadTimeOffEvent extends TimeOffEvent {
  final String stadiumId;

  const LoadTimeOffEvent({required this.stadiumId});

  @override
  List<Object> get props => [stadiumId];
}

class SaveTimeOffEvent extends TimeOffEvent {
  final String stadiumId;
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String frequency;
  final String? dayOfWeek;
  final DateTime? specificDate;
  final List<String> selectedDays;

  const SaveTimeOffEvent({
    required this.stadiumId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.frequency,
    this.dayOfWeek,
    this.specificDate,
    this.selectedDays = const [],
  });

  @override
  List<Object?> get props => [
        stadiumId,
        title,
        startTime,
        endTime,
        frequency,
        dayOfWeek,
        specificDate,
        selectedDays,
      ];
}

class DeleteTimeOffEvent extends TimeOffEvent {
  final String stadiumId;
  final String timeOffId;

  const DeleteTimeOffEvent({
    required this.stadiumId,
    required this.timeOffId,
  });

  @override
  List<Object> get props => [stadiumId, timeOffId];
}
