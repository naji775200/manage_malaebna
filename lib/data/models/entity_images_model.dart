import 'package:equatable/equatable.dart';

class EntityImages extends Equatable {
  final String id;
  final String entityType; // fields, stadium , owners
  final String entityId; // field id, stadium id, owner id
  final String imageUrl;
  final DateTime createdAt;

  const EntityImages({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.imageUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, entityType, entityId, imageUrl, createdAt];

  EntityImages copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return EntityImages(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory EntityImages.fromJson(Map<String, dynamic> json) {
    // Handle created_at as either DateTime or String
    final createdAt = json['created_at'] is DateTime
        ? json['created_at'] as DateTime
        : DateTime.parse(json['created_at'] as String);

    return EntityImages(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      imageUrl: json['image_url'] as String,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'image_url': imageUrl,
      'created_at':
          createdAt.toIso8601String(), // Convert DateTime to ISO8601 string
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
