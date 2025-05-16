import 'package:equatable/equatable.dart';
import '../../data/models/service_model.dart';
import '../../data/models/field_model.dart';
import '../../data/models/working_hour_model.dart';
import '../../data/models/time_off_model.dart';
import '../../data/models/price_model.dart';
import '../../data/models/coupon_model.dart';
import '../../data/models/review_model.dart';
import '../../data/models/owner_model.dart';

class Stadium extends Equatable {
  final String id;
  final String name;
  final String addressId;
  final String description;
  final String bankNumber;
  final double averageReview;
  final int bookedCount;
  final String phoneNumber;
  final String type;
  final String status;
  final List<String> imageUrls;
  final List<Service> services;
  final List<Field> fields;
  final List<WorkingHours> workingHours;
  final List<TimeOff> timesOff;
  final List<Price> prices;
  final List<Coupon> coupons;
  final List<Review> reviews;
  final List<Owner> owners;

  const Stadium({
    required this.id,
    required this.name,
    required this.addressId,
    required this.description,
    required this.bankNumber,
    required this.averageReview,
    required this.bookedCount,
    required this.phoneNumber,
    required this.type,
    required this.status,
    this.imageUrls = const [],
    this.services = const [],
    this.fields = const [],
    this.workingHours = const [],
    this.timesOff = const [],
    this.prices = const [],
    this.coupons = const [],
    this.reviews = const [],
    this.owners = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        addressId,
        description,
        bankNumber,
        averageReview,
        bookedCount,
        phoneNumber,
        type,
        status,
        imageUrls,
        services,
        fields,
        workingHours,
        timesOff,
        prices,
        coupons,
        reviews,
        owners,
      ];

  Stadium copyWith({
    String? id,
    String? name,
    String? addressId,
    String? description,
    String? bankNumber,
    double? averageReview,
    int? bookedCount,
    String? phoneNumber,
    String? type,
    String? status,
    List<String>? imageUrls,
    List<Service>? services,
    List<Field>? fields,
    List<WorkingHours>? workingHours,
    List<TimeOff>? timesOff,
    List<Price>? prices,
    List<Coupon>? coupons,
    List<Review>? reviews,
    List<Owner>? owners,
  }) {
    return Stadium(
      id: id ?? this.id,
      name: name ?? this.name,
      addressId: addressId ?? this.addressId,
      description: description ?? this.description,
      bankNumber: bankNumber ?? this.bankNumber,
      averageReview: averageReview ?? this.averageReview,
      bookedCount: bookedCount ?? this.bookedCount,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      services: services ?? this.services,
      fields: fields ?? this.fields,
      workingHours: workingHours ?? this.workingHours,
      timesOff: timesOff ?? this.timesOff,
      prices: prices ?? this.prices,
      coupons: coupons ?? this.coupons,
      reviews: reviews ?? this.reviews,
      owners: owners ?? this.owners,
    );
  }

  factory Stadium.fromJson(Map<String, dynamic> json) {
    return Stadium(
      id: json['id'] as String,
      name: json['name'] as String,
      addressId: json['address_id'] as String,
      description: json['description'] as String,
      bankNumber: json['bank_number'] as String,
      averageReview: (json['average_review'] != null)
          ? (json['average_review'] as num).toDouble()
          : 0.0,
      bookedCount: json['booked_count'] as int? ?? 0,
      phoneNumber: json['phone_number'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address_id': addressId,
      'description': description,
      'bank_number': bankNumber,
      'average_review': averageReview,
      'booked_count': bookedCount,
      'phone_number': phoneNumber,
      'type': type,
      'status': status,
    };
  }
}
