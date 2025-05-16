import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

abstract class WorkingHoursEvent extends Equatable {
  const WorkingHoursEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorkingHoursEvent extends WorkingHoursEvent {
  final String stadiumId;

  const LoadWorkingHoursEvent({required this.stadiumId});

  @override
  List<Object> get props => [stadiumId];
}

class UpdateWorkingHoursEvent extends WorkingHoursEvent {
  final List<bool> isChecked;
  final List<TimeOfDay> startTimes;
  final List<TimeOfDay> endTimes;
  final List<String> daysOfWeek;
  final String? stadiumId;

  const UpdateWorkingHoursEvent({
    required this.isChecked,
    required this.startTimes,
    required this.endTimes,
    required this.daysOfWeek,
    this.stadiumId,
  });

  @override
  List<Object?> get props =>
      [isChecked, startTimes, endTimes, daysOfWeek, stadiumId];
}
