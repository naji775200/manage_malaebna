import 'package:equatable/equatable.dart';

class BookingPlayer extends Equatable {
  final String id;
  final String bookingId;
  final String playerId;
  final String name;
  final String addedBy;

  const BookingPlayer({
    required this.id,
    required this.bookingId,
    required this.playerId,
    required this.name,
    required this.addedBy,
  });

  @override
  List<Object?> get props => [id, bookingId, playerId, name, addedBy];

  BookingPlayer copyWith({
    String? id,
    String? bookingId,
    String? playerId,
    String? name,
    String? addedBy,
  }) {
    return BookingPlayer(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      addedBy: addedBy ?? this.addedBy,
    );
  }

  factory BookingPlayer.fromJson(Map<String, dynamic> json) {
    return BookingPlayer(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      playerId: json['player_id'] as String,
      name: json['name'] as String,
      addedBy: json['added_by'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'player_id': playerId,
      'name': name,
      'added_by': addedBy,
    };
  }
}
