import 'package:equatable/equatable.dart';

class TimeOff {
  final String ID;
  final String title;
  final DateTime startTimeOff;
  final DateTime endTimeOff;
  final String frequency; // "Once", "Daily", "Weekly"
  final List<String> daysOfWeek; // Change from single dayOfWeek to a list
  final DateTime? specificDate; // For once frequency

  TimeOff({
    required this.ID,
    required this.title,
    required this.startTimeOff,
    required this.endTimeOff,
    required this.frequency,
    this.daysOfWeek = const [], // Default to empty list
    this.specificDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'ID': ID,
      'title': title,
      'startTimeOff': startTimeOff.toIso8601String(),
      'endTimeOff': endTimeOff.toIso8601String(),
      'frequency': frequency,
      'daysOfWeek': daysOfWeek,
      'specificDate': specificDate?.toIso8601String(),
    };
  }

  factory TimeOff.fromJson(Map<String, dynamic> json) {
    List<String> parseDaysOfWeek(dynamic daysOfWeekData) {
      if (daysOfWeekData == null) return [];
      if (daysOfWeekData is String && daysOfWeekData.isNotEmpty) {
        return [daysOfWeekData]; // Legacy support for old single day value
      } else if (daysOfWeekData is List) {
        return daysOfWeekData.map((item) => item.toString()).toList();
      }
      return [];
    }

    return TimeOff(
      ID: json['ID'],
      title: json['title'],
      startTimeOff: DateTime.parse(json['startTimeOff']),
      endTimeOff: DateTime.parse(json['endTimeOff']),
      frequency: json['frequency'],
      daysOfWeek: parseDaysOfWeek(json['daysOfWeek'] ?? json['dayOfWeek']),
      specificDate: json['specificDate'] != null
          ? DateTime.parse(json['specificDate'])
          : null,
    );
  }
}

abstract class TimeOffState extends Equatable {
  const TimeOffState();

  @override
  List<Object?> get props => [];
}

class TimeOffInitial extends TimeOffState {}

class TimeOffLoading extends TimeOffState {}

// New state for time off saving operation in progress
class TimeOffSaving extends TimeOffState {}

class TimeOffLoaded extends TimeOffState {
  final List<TimeOff> timeOffs;

  const TimeOffLoaded({required this.timeOffs});

  @override
  List<Object> get props => [timeOffs];
}

class TimeOffError extends TimeOffState {
  final String message;

  const TimeOffError({required this.message});

  @override
  List<Object> get props => [message];
}
