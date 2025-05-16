import 'package:equatable/equatable.dart';

class StadiumServicesModel extends Equatable {
  final String id;
  final String stadiumId;
  final String serviceId;
  final String createdAt;

  const StadiumServicesModel({
    required this.id,
    required this.stadiumId,
    required this.serviceId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, stadiumId, serviceId, createdAt];

  StadiumServicesModel copyWith({
    String? id,
    String? stadiumId,
    String? serviceId,
    String? createdAt,
  }) {
    return StadiumServicesModel(
      id: id ?? this.id,
      stadiumId: stadiumId ?? this.stadiumId,
      serviceId: serviceId ?? this.serviceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory StadiumServicesModel.fromJson(Map<String, dynamic> json) {
    return StadiumServicesModel(
      id: json['id'] as String,
      stadiumId: json['stadium_id'] as String,
      serviceId: json['service_id'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stadium_id': stadiumId,
      'service_id': serviceId,
      'created_at': createdAt,
    };
  }
}
