import 'package:equatable/equatable.dart';

class Service extends Equatable {
  final String id;
  final String englishName;
  final String arabicName;
  final String iconName;

  const Service({
    required this.id,
    required this.englishName,
    required this.arabicName,
    required this.iconName,
  });

  @override
  List<Object?> get props => [id, englishName, arabicName, iconName];

  Service copyWith({
    String? id,
    String? englishName,
    String? arabicName,
    String? iconName,
  }) {
    return Service(
      id: id ?? this.id,
      englishName: englishName ?? this.englishName,
      arabicName: arabicName ?? this.arabicName,
      iconName: iconName ?? this.iconName,
    );
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      englishName: json['english_name'] as String? ??
          json['name'] as String? ??
          'Unknown',
      arabicName: json['arabic_name'] as String? ??
          json['name_ar'] as String? ??
          'غير معروف',
      iconName: json['icon_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'english_name': englishName,
      'arabic_name': arabicName,
      'icon_name': iconName,
    };
  }

  // Helper method to get localized name based on language code
  String getLocalizedName(String languageCode) {
    return languageCode == 'ar' ? arabicName : englishName;
  }
}
