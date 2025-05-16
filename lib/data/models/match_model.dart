import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../data/models/match_history_model.dart';
import '../../data/models/booking_model.dart';

class Match extends Equatable {
  final String id;
  final String fieldId;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int currentPlayers;
  final int playersNeeded;
  final String status;
  final DateTime createdAt;
  final String? description;
  final String? level;
  final List<Booking> bookings;
  final MatchHistory? history;

  const Match({
    required this.id,
    required this.fieldId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.currentPlayers = 0,
    required this.playersNeeded,
    this.status = 'active',
    required this.createdAt,
    this.description,
    this.level,
    this.bookings = const [],
    this.history,
  });

  @override
  List<Object?> get props => [
        id,
        fieldId,
        date,
        startTime,
        endTime,
        currentPlayers,
        playersNeeded,
        status,
        createdAt,
        description,
        level,
        bookings,
        history,
      ];

  Match copyWith({
    String? id,
    String? fieldId,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? currentPlayers,
    int? playersNeeded,
    String? status,
    DateTime? createdAt,
    String? description,
    String? level,
    List<Booking>? bookings,
    MatchHistory? history,
  }) {
    return Match(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      playersNeeded: playersNeeded ?? this.playersNeeded,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      level: level ?? this.level,
      bookings: bookings ?? this.bookings,
      history: history ?? this.history,
    );
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      fieldId: json['field_id'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: _parseTime(json['start_time'] as String),
      endTime: _parseTime(json['end_time'] as String),
      currentPlayers: json['current_players'] as int? ?? 0,
      playersNeeded: json['players_needed'] as int,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      level: json['level'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field_id': fieldId,
      'date': date.toIso8601String(),
      'start_time': _formatTime(startTime),
      'end_time': _formatTime(endTime),
      'current_players': currentPlayers,
      'players_needed': playersNeeded,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'level': level,
    };
  }

  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

