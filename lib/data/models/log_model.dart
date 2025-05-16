import 'package:equatable/equatable.dart';

enum LogType {
  player,
  stadium,
  owner,
}

class Log extends Equatable {
  final String id;
  final LogType logType;
  final String entityId;
  final String action;
  final String? performedBy;
  final String? description;
  final DateTime createdAt;

  const Log({
    required this.id,
    required this.logType,
    required this.entityId,
    required this.action,
    this.performedBy,
    this.description,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        logType,
        entityId,
        action,
        performedBy,
        description,
        createdAt,
      ];

  Log copyWith({
    String? id,
    LogType? logType,
    String? entityId,
    String? action,
    String? performedBy,
    String? description,
    DateTime? createdAt,
  }) {
    return Log(
      id: id ?? this.id,
      logType: logType ?? this.logType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      performedBy: performedBy ?? this.performedBy,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      id: json['id'] as String,
      logType: _parseLogType(json['log_type'] as String),
      entityId: json['entity_id'] as String,
      action: json['action'] as String,
      performedBy: json['performed_by'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'log_type': logType.toString().split('.').last,
      'entity_id': entityId,
      'action': action,
      'performed_by': performedBy,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static LogType _parseLogType(String typeString) {
    switch (typeString) {
      case 'player':
        return LogType.player;
      case 'stadium':
        return LogType.stadium;
      case 'owner':
        return LogType.owner;
      default:
        throw ArgumentError('Invalid log type: $typeString');
    }
  }
}
