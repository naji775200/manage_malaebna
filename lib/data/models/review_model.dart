import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String playerId;
  final String stadiumId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String reviewerType;

  const Review({
    required this.id,
    required this.playerId,
    required this.stadiumId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.reviewerType,
  });

  @override
  List<Object?> get props => [
        id,
        playerId,
        stadiumId,
        rating,
        comment,
        createdAt,
        reviewerType,
      ];

  Review copyWith({
    String? id,
    String? playerId,
    String? stadiumId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    String? reviewerType,
  }) {
    return Review(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      stadiumId: stadiumId ?? this.stadiumId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      reviewerType: reviewerType ?? this.reviewerType,
    );
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      playerId: json['player_id'] as String,
      stadiumId: json['stadium_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewerType: json['reviewer_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_id': playerId,
      'stadium_id': stadiumId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'reviewer_type': reviewerType,
    };
  }
}
