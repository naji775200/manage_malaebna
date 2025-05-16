import 'package:equatable/equatable.dart';
import 'booking_player_model.dart';
import '../../data/models/cancellation_model.dart';

class Booking extends Equatable {
  final String id;
  final String playerId;
  final String matchId;
  final String? paymentId;
  final int numberOfPlayers;
  final String status;
  final DateTime createdAt;
  final List<BookingPlayer> players;
  final Cancellation? cancellation;

  const Booking({
    required this.id,
    required this.playerId,
    required this.matchId,
    this.paymentId,
    required this.numberOfPlayers,
    this.status = 'pending',
    required this.createdAt,
    this.players = const [],
    this.cancellation,
  });

  @override
  List<Object?> get props => [
        id,
        playerId,
        matchId,
        paymentId,
        numberOfPlayers,
        status,
        createdAt,
        players,
        cancellation,
      ];

  Booking copyWith({
    String? id,
    String? playerId,
    String? matchId,
    String? paymentId,
    int? numberOfPlayers,
    String? status,
    DateTime? createdAt,
    List<BookingPlayer>? players,
    Cancellation? cancellation,
  }) {
    return Booking(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      matchId: matchId ?? this.matchId,
      paymentId: paymentId ?? this.paymentId,
      numberOfPlayers: numberOfPlayers ?? this.numberOfPlayers,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      players: players ?? this.players,
      cancellation: cancellation ?? this.cancellation,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      playerId: json['player_id'] as String,
      matchId: json['match_id'] as String,
      paymentId: json['payment_id'] as String?,
      numberOfPlayers: json['number_of_players'] as int,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_id': playerId,
      'match_id': matchId,
      'payment_id': paymentId,
      'number_of_players': numberOfPlayers,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
