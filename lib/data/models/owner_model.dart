import 'package:equatable/equatable.dart';

class Owner extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;
  final String status;

  const Owner({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.status,
  });

  @override
  List<Object?> get props => [id, name, phoneNumber, status];

  Owner copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? status,
  }) {
    return Owner(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
    );
  }

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'status': status,
    };
  }
}
