import 'package:equatable/equatable.dart';

class MatchHistory extends Equatable {
  final String id;
  final String matchId;
  final String? result;

  const MatchHistory({
    required this.id,
    required this.matchId,
    this.result,
  });

  @override
  List<Object?> get props => [id, matchId, result];

  MatchHistory copyWith({
    String? id,
    String? matchId,
    String? result,
  }) {
    return MatchHistory(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      result: result ?? this.result,
    );
  }

  factory MatchHistory.fromJson(Map<String, dynamic> json) {
    return MatchHistory(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      result: json['result'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'result': result,
    };
  }
}
