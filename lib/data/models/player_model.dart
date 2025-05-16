import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String id;
  final String name;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? authProvider;
  final DateTime? dateOfBirth;
  final String? addressId;
  final int numberOfMatches;
  final double averageRating;
  final String? level;
  final String status;
  final List<String> imageUrls;

  const Player({
    required this.id,
    required this.name,
    this.phoneNumber,
    required this.createdAt,
    this.lastLoginAt,
    this.authProvider,
    this.dateOfBirth,
    this.addressId,
    this.numberOfMatches = 0,
    this.averageRating = 0,
    this.level,
    this.status = 'active',
    this.imageUrls = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phoneNumber,
        createdAt,
        lastLoginAt,
        authProvider,
        dateOfBirth,
        addressId,
        numberOfMatches,
        averageRating,
        level,
        status,
        imageUrls,
      ];

  Player copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? authProvider,
    DateTime? dateOfBirth,
    String? addressId,
    int? numberOfMatches,
    double? averageRating,
    String? level,
    String? status,
    List<String>? imageUrls,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      authProvider: authProvider ?? this.authProvider,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      addressId: addressId ?? this.addressId,
      numberOfMatches: numberOfMatches ?? this.numberOfMatches,
      averageRating: averageRating ?? this.averageRating,
      level: level ?? this.level,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      authProvider: json['auth_provider'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      addressId: json['address_id'] as String?,
      numberOfMatches: json['number_of_matches'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      level: json['level'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'auth_provider': authProvider,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address_id': addressId,
      'number_of_matches': numberOfMatches,
      'average_rating': averageRating,
      'level': level,
      'status': status,
    };
  }
}
