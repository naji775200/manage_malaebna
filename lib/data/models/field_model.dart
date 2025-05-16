import 'package:equatable/equatable.dart';

class Field extends Equatable {
  final String id;
  final String stadiumId;
  final String name;
  final String size;
  final String surfaceType;
  final DateTime createdAt;
  final String status;
  final int? recommendedPlayersNumber;

  const Field({
    required this.id,
    required this.stadiumId,
    required this.name,
    required this.size,
    required this.surfaceType,
    required this.createdAt,
    required this.status,
    this.recommendedPlayersNumber,
  });

  @override
  List<Object?> get props => [
        id,
        stadiumId,
        name,
        size,
        surfaceType,
        createdAt,
        status,
        recommendedPlayersNumber,
      ];

  Field copyWith({
    String? id,
    String? stadiumId,
    String? name,
    String? size,
    String? surfaceType,
    DateTime? createdAt,
    String? status,
    int? recommendedPlayersNumber,
  }) {
    return Field(
      id: id ?? this.id,
      stadiumId: stadiumId ?? this.stadiumId,
      name: name ?? this.name,
      size: size ?? this.size,
      surfaceType: surfaceType ?? this.surfaceType,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      recommendedPlayersNumber:
          recommendedPlayersNumber ?? this.recommendedPlayersNumber,
    );
  }

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'] as String,
      stadiumId: json['stadium_id'] as String,
      name: json['name'] as String,
      size: json['size'] as String,
      surfaceType: json['surface_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String,
      recommendedPlayersNumber: json['recommended_players_number'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stadium_id': stadiumId,
      'name': name,
      'size': size,
      'surface_type': surfaceType,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'recommended_players_number': recommendedPlayersNumber,
    };
  }
}
