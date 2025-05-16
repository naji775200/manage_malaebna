import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String? country;
  final String? city;
  final String? district;
  final double latitude;
  final double longitude;

  const Address({
    required this.id,
    this.country,
    this.city,
    this.district,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [
        id,
        country,
        city,
        district,
        latitude,
        longitude,
      ];

  Address copyWith({
    String? id,
    String? country,
    String? city,
    String? district,
    double? latitude,
    double? longitude,
  }) {
    return Address(
      id: id ?? this.id,
      country: country ?? this.country,
      city: city ?? this.city,
      district: district ?? this.district,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      country: json['country'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country': country,
      'city': city,
      'district': district,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
